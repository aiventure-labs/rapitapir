# frozen_string_literal: true

require 'rack'
require 'json'
require_relative '../core/endpoint'
require_relative 'path_matcher'

module RapiTapir
  module Server
    class RackAdapter
      attr_reader :endpoints, :middleware_stack

      def initialize
        @endpoints = []
        @middleware_stack = []
      end

      # Register an endpoint with the adapter
      def register_endpoint(endpoint, handler)
        unless endpoint.is_a?(RapiTapir::Core::Endpoint)
          raise ArgumentError, 'Endpoint must be a RapiTapir::Core::Endpoint'
        end
        raise ArgumentError, 'Handler must respond to call' unless handler.respond_to?(:call)

        endpoint.validate!
        path_matcher = PathMatcher.new(endpoint.path)
        @endpoints << { endpoint: endpoint, handler: handler, path_matcher: path_matcher }
      end

      # Add middleware to the processing stack
      def use(middleware_class, *args, &block)
        @middleware_stack << [middleware_class, args, block]
      end

      # Main Rack application call method
      def call(env)
        app = build_app
        app.call(env)
      end

      # Build the complete middleware stack
      def build_app
        app = method(:handle_request)

        @middleware_stack.reverse.each do |middleware_class, args, block|
          app = middleware_class.new(app, *args, &block)
        end

        app
      end

      # Core request handler (without middleware)
      def handle_request(env)
        request = Rack::Request.new(env)

        # Find matching endpoint
        endpoint_match = find_matching_endpoint(request)
        return not_found_response unless endpoint_match

        begin
          # Process the request through the endpoint
          process_request(request, endpoint_match)
        rescue StandardError => e
          error_response(e)
        end
      end

      private

      def find_matching_endpoint(request)
        @endpoints.find do |endpoint_data|
          endpoint = endpoint_data[:endpoint]
          path_matcher = endpoint_data[:path_matcher]
          matches_method?(endpoint, request) && path_matcher.matches?(request.path_info)
        end
      end

      def matches_method?(endpoint, request)
        endpoint.method.to_s.upcase == request.request_method
      end

      def process_request(request, endpoint_match)
        endpoint = endpoint_match[:endpoint]
        handler = endpoint_match[:handler]
        path_matcher = endpoint_match[:path_matcher]

        # Extract path parameters
        path_params = path_matcher.match(request.path_info) || {}

        # Extract and validate inputs
        processed_inputs = extract_inputs(request, endpoint, path_params)

        # Call the handler with processed inputs
        result = handler.call(processed_inputs)

        # Serialize and return response
        serialize_response(result, endpoint)
      end

      def extract_inputs(request, endpoint, path_params = {})
        inputs = {}

        endpoint.inputs.each do |input|
          value = case input.kind
                  when :query
                    request.params[input.name.to_s]
                  when :header
                    request.get_header("HTTP_#{input.name.to_s.upcase}")
                  when :path
                    path_params[input.name]
                  when :body
                    parse_body(request, input)
                  end

          # Validate and coerce the value
          raise ArgumentError, "Required input '#{input.name}' is missing" if value.nil? && input.required?

          # Only coerce non-nil values, or include nil for optional parameters
          if value.nil?
            inputs[input.name] = nil unless input.required?
          else
            inputs[input.name] = input.coerce(value)
          end
        end

        inputs
      end

      def parse_body(request, input)
        body = request.body.read
        request.body.rewind

        return nil if body.empty?

        if input.type == Hash || input.type.is_a?(Hash)
          JSON.parse(body)
        else
          body
        end
      rescue JSON::ParserError
        raise ArgumentError, 'Invalid JSON in request body'
      end

      def serialize_response(result, endpoint)
        # Find the appropriate output definition
        output = endpoint.outputs.find { |o| o.kind == :json } || endpoint.outputs.first

        if output
          serialized = output.serialize(result)
          content_type = determine_content_type(output)
          status_code = determine_status_code(endpoint)

          [status_code, { 'Content-Type' => content_type }, [serialized]]
        else
          # Default response if no output defined
          [200, { 'Content-Type' => 'text/plain' }, [result.to_s]]
        end
      end

      def determine_content_type(output)
        # For enhanced outputs, use the content_type attribute directly
        return output.content_type if output.respond_to?(:content_type) && output.content_type

        # Fallback to kind-based detection for legacy outputs
        case output.kind
        when :json
          'application/json'
        when :xml
          'application/xml'
        else
          'text/plain'
        end
      end

      def determine_status_code(endpoint)
        status_output = endpoint.outputs.find { |o| o.kind == :status }
        status_output ? status_output.type : 200
      end

      def not_found_response
        [404, { 'Content-Type' => 'application/json' }, ['{"error":"Not Found"}']]
      end

      def error_response(error)
        error_data = {
          error: error.class.name,
          message: error.message
        }

        status_code = case error
                      when ArgumentError
                        400
                      else
                        500
                      end

        [status_code, { 'Content-Type' => 'application/json' }, [JSON.generate(error_data)]]
      end
    end
  end
end
