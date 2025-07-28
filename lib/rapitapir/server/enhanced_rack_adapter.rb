# frozen_string_literal: true

require 'rack'
require 'json'
require_relative '../core/enhanced_endpoint'
require_relative '../dsl/enhanced_endpoint_dsl'
require_relative 'path_matcher'

module RapiTapir
  module Server
    # Enhanced Rack adapter that integrates with the new type system
    class EnhancedRackAdapter
      attr_reader :endpoints, :middleware_stack, :error_handlers

      def initialize
        @endpoints = []
        @middleware_stack = []
        @error_handlers = {}
      end

      # Register an endpoint with a handler
      def mount(endpoint, &handler)
        raise ArgumentError, 'Endpoint must be provided' unless endpoint
        raise ArgumentError, 'Handler block must be provided' unless block_given?

        # Ensure we're working with an enhanced endpoint
        enhanced_endpoint = case endpoint
                           when Core::EnhancedEndpoint
                             endpoint
                           when Core::Endpoint
                             # Convert regular endpoint to enhanced endpoint
                             convert_to_enhanced(endpoint)
                           else
                             raise ArgumentError, 'Endpoint must be a RapiTapir::Core::Endpoint'
                           end

        enhanced_endpoint.validate!
        path_matcher = PathMatcher.new(enhanced_endpoint.path)
        
        @endpoints << {
          endpoint: enhanced_endpoint,
          handler: handler,
          path_matcher: path_matcher
        }
      end

      # Add middleware to the processing stack
      def use(middleware_class, *args, &block)
        @middleware_stack << [middleware_class, args, block]
      end

      # Register error handlers
      def on_error(error_class, &handler)
        @error_handlers[error_class] = handler
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

      # Core request handler with enhanced type validation
      def handle_request(env)
        request = Rack::Request.new(env)
        
        # Find matching endpoint
        endpoint_match = find_matching_endpoint(request)
        return not_found_response unless endpoint_match

        begin
          # Process the request through the endpoint with full validation
          process_enhanced_request(request, endpoint_match)
        rescue Core::EnhancedEndpoint::ValidationError => e
          validation_error_response(e)
        rescue Types::ValidationError => e
          type_validation_error_response(e)
        rescue Types::CoercionError => e
          coercion_error_response(e)
        rescue StandardError => e
          handle_custom_error(e) || error_response(e)
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

      def process_enhanced_request(request, endpoint_match)
        endpoint = endpoint_match[:endpoint]
        handler = endpoint_match[:handler]
        path_matcher = endpoint_match[:path_matcher]

        # Extract path parameters
        path_params = path_matcher.match(request.path_info) || {}

        # Extract and validate inputs using the enhanced type system
        processed_inputs = extract_and_validate_inputs(request, endpoint, path_params)
        
        # Validate the complete request
        validated_inputs = endpoint.process_request(processed_inputs)
        
        # Call the handler with validated inputs
        result = handler.call(validated_inputs)
        
        # Validate and serialize response
        serialize_validated_response(result, endpoint)
      end

      def extract_and_validate_inputs(request, endpoint, path_params = {})
        inputs = {}
        
        endpoint.inputs.each do |input|
          value = extract_input_value(request, input, path_params)
          
          # Handle required inputs
          if value.nil? && input.required?
            raise Core::EnhancedEndpoint::ValidationError, "Required input '#{input.name}' is missing"
          end

          # Skip optional nil values
          next if value.nil? && input.optional?

          # Coerce and validate the value
          begin
            coerced_value = input.coerce(value)
            validation_result = input.validate(coerced_value)
            
            unless validation_result[:valid]
              errors = validation_result[:errors].join(', ')
              raise Core::EnhancedEndpoint::ValidationError, "Input '#{input.name}' validation failed: #{errors}"
            end
            
            inputs[input.name] = coerced_value
          rescue Types::CoercionError => e
            raise Core::EnhancedEndpoint::ValidationError, "Input '#{input.name}' coercion failed: #{e.message}"
          end
        end

        inputs
      end

      def extract_input_value(request, input, path_params)
        case input.kind
        when :query
          request.params[input.name.to_s]
        when :header
          extract_header_value(request, input)
        when :path
          path_params[input.name]
        when :body
          parse_request_body(request, input)
        else
          nil
        end
      end

      def extract_header_value(request, input)
        header_name = case input.name
                     when :authorization
                       'HTTP_AUTHORIZATION'
                     else
                       "HTTP_#{input.name.to_s.upcase.gsub('-', '_')}"
                     end
        request.get_header(header_name)
      end

      def parse_request_body(request, input)
        body = request.body.read
        request.body.rewind
        
        return nil if body.empty?

        content_type = request.content_type&.downcase
        format = input.options[:format] || detect_format_from_content_type(content_type)

        case format
        when :json
          JSON.parse(body)
        when :form
          Rack::Utils.parse_nested_query(body)
        else
          body
        end
      rescue JSON::ParserError => e
        raise Core::EnhancedEndpoint::ValidationError, "Invalid JSON in request body: #{e.message}"
      end

      def detect_format_from_content_type(content_type)
        case content_type
        when /application\/json/
          :json
        when /application\/x-www-form-urlencoded/, /multipart\/form-data/
          :form
        else
          :text
        end
      end

      def serialize_validated_response(result, endpoint)
        # Find the appropriate output definition
        json_output = endpoint.outputs.find { |o| o.kind == :json }
        text_output = endpoint.outputs.find { |o| o.kind == :text }
        status_output = endpoint.outputs.find { |o| o.kind == :status }
        
        output = json_output || text_output || endpoint.outputs.first
        status_code = status_output&.type || determine_default_status(endpoint.method)
        
        if output
          # Validate the response
          validation_result = output.validate(result)
          unless validation_result[:valid]
            errors = validation_result[:errors].join(', ')
            raise StandardError, "Response validation failed: #{errors}"
          end
          
          serialized = output.serialize(result)
          content_type = determine_content_type(output)
          
          [status_code, { 'Content-Type' => content_type }, [serialized]]
        else
          # Default response
          [status_code, { 'Content-Type' => 'application/json' }, [JSON.generate(result)]]
        end
      end

      def determine_content_type(output)
        case output.kind
        when :json
          'application/json'
        when :text
          'text/plain'
        else
          'application/json'
        end
      end

      def determine_default_status(method)
        case method
        when :post
          201
        when :delete
          204
        else
          200
        end
      end

      def convert_to_enhanced(endpoint)
        # Convert a regular endpoint to an enhanced endpoint
        Core::EnhancedEndpoint.new(
          method: endpoint.method,
          path: endpoint.path,
          inputs: endpoint.inputs,
          outputs: endpoint.outputs,
          errors: endpoint.errors,
          metadata: endpoint.metadata
        )
      end

      def handle_custom_error(error)
        handler = @error_handlers[error.class] || @error_handlers[StandardError]
        return nil unless handler
        
        begin
          result = handler.call(error)
          [500, { 'Content-Type' => 'application/json' }, [JSON.generate(result)]]
        rescue => handler_error
          # If custom error handler fails, fall back to default
          nil
        end
      end

      # Error response helpers
      def not_found_response
        error_data = {
          error: 'Not Found',
          message: 'The requested endpoint was not found',
          code: 404
        }
        [404, { 'Content-Type' => 'application/json' }, [JSON.generate(error_data)]]
      end

      def validation_error_response(error)
        error_data = {
          error: 'Validation Error',
          message: error.message,
          code: 400
        }
        [400, { 'Content-Type' => 'application/json' }, [JSON.generate(error_data)]]
      end

      def type_validation_error_response(error)
        error_data = {
          error: 'Type Validation Error',
          message: error.message,
          type: error.type.to_s,
          value: error.value,
          errors: error.errors,
          code: 400
        }
        [400, { 'Content-Type' => 'application/json' }, [JSON.generate(error_data)]]
      end

      def coercion_error_response(error)
        error_data = {
          error: 'Type Coercion Error',
          message: error.message,
          type: error.type.to_s,
          value: error.value,
          reason: error.reason,
          code: 400
        }
        [400, { 'Content-Type' => 'application/json' }, [JSON.generate(error_data)]]
      end

      def error_response(error)
        error_data = {
          error: error.class.name,
          message: error.message,
          code: 500
        }
        
        [500, { 'Content-Type' => 'application/json' }, [JSON.generate(error_data)]]
      end
    end
  end
end
