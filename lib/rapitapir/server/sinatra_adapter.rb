# frozen_string_literal: true

require 'json'

module RapiTapir
  module Server
    # Sinatra integration adapter for RapiTapir
    # Provides seamless integration with Sinatra applications
    class SinatraAdapter
      attr_reader :app, :endpoints

      def initialize(sinatra_app)
        @app = sinatra_app
        @endpoints = []

        # Store adapter reference in the app for access in route handlers
        @app.instance_variable_set(:@rapitapir_adapter, self)

        # Define a helper method on the app to access the adapter
        @app.define_singleton_method(:rapitapir_adapter) do
          @rapitapir_adapter
        end
      end

      # Register an endpoint with automatic Sinatra route creation
      def register_endpoint(endpoint, handler = nil, &block)
        raise ArgumentError, 'Endpoint must be a RapiTapir::Core::Endpoint' unless endpoint.is_a?(RapiTapir::Core::Endpoint)

        endpoint.validate!

        # Use provided handler or block
        endpoint_handler = handler || block
        raise ArgumentError, 'Handler must be provided' unless endpoint_handler

        endpoint_info = { endpoint: endpoint, handler: endpoint_handler, id: @endpoints.length }
        @endpoints << endpoint_info

        # Register route with Sinatra
        register_sinatra_route(endpoint_info)
      end

      private

      def register_sinatra_route(endpoint_info)
        method_name = endpoint_info[:endpoint].method.to_s.downcase.to_sym
        path_pattern = convert_path_to_sinatra(endpoint_info[:endpoint].path)
        endpoint_id = endpoint_info[:id]
        adapter = self

        @app.send(method_name, path_pattern) do
          result = adapter.handle_sinatra_request(endpoint_id, request, params)
          if result.is_a?(Array) && result.length == 3
            status result[0]
            headers result[1]
            body result[2]
          else
            result
          end
        end
      end

      public

      def handle_sinatra_request(endpoint_id, request, params)
        endpoint_data = @endpoints[endpoint_id]

        begin
          processed_inputs = extract_sinatra_inputs(request, params, endpoint_data[:endpoint])
          result = @app.instance_exec(processed_inputs, &endpoint_data[:handler])
          send_successful_response(endpoint_data, result)
        rescue ArgumentError => e
          error_response(400, e.message)
        rescue StandardError => e
          error_response(500, 'Internal Server Error', e.message)
        end
      end

      def error_response(status_code, error, message = nil)
        error_data = { error: error }
        error_data[:message] = message if message
        [status_code, { 'Content-Type' => 'application/json' }, [error_data.to_json]]
      end

      def execute_endpoint_handler(endpoint_data, processed_inputs)
        case endpoint_data[:handler]
        when Proc
          instance_exec(processed_inputs, &endpoint_data[:handler])
        else
          call_handler_method(endpoint_data[:handler], processed_inputs)
        end
      end

      def call_handler_method(handler, processed_inputs)
        if handler.respond_to?(:call)
          handler.call(processed_inputs)
        else
          instance_exec(processed_inputs, &handler)
        end
      end

      def send_successful_response(endpoint_data, result)
        endpoint = endpoint_data[:endpoint]

        # Find status code from outputs
        status_output = endpoint.outputs.find { |o| o.kind == :status }
        status_code = status_output ? status_output.type : 200

        # Default headers
        headers = { 'Content-Type' => 'application/json' }

        # Add any additional headers from outputs if they exist
        # Note: This is for future compatibility when header outputs are supported

        [status_code, headers, [result.to_json]]
      end

      def convert_path_to_sinatra(path)
        # Convert "/users/:id" to "/users/:id" (Sinatra format is the same)
        path
      end

      def extract_sinatra_inputs(request, params, endpoint)
        inputs = {}

        endpoint.inputs.each do |input|
          value = extract_input_value(request, params, input)
          validate_and_add_input(inputs, input, value)
        end

        inputs
      end

      private

      def extract_input_value(request, params, input)
        case input.kind
        when :query, :path
          # Both query and path parameters are available in params
          params[input.name.to_s] || params[input.name.to_sym]
        when :header
          request.env["HTTP_#{input.name.to_s.upcase}"]
        when :body
          parse_sinatra_body(request, input)
        end
      end

      def validate_and_add_input(inputs, input, value)
        # Validate and coerce the value
        raise ArgumentError, "Required input '#{input.name}' is missing" if value.nil? && input.required?

        inputs[input.name] = input.coerce(value) if value || !input.required?
      end

      def parse_sinatra_body(request, input)
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
        output = endpoint.outputs.find { |o| o.kind == :json } || endpoint.outputs.first

        if output
          output.serialize(result)
        else
          result.to_json
        end
      end

      def determine_content_type(endpoint)
        output = endpoint.outputs.find { |o| o.kind == :json } || endpoint.outputs.first

        case output&.kind
        when :xml
          'application/xml'
        else # Default to JSON for :json and unknown formats
          'application/json'
        end
      end

      def determine_status_code(endpoint)
        status_output = endpoint.outputs.find { |o| o.kind == :status }
        status_output ? status_output.type : 200
      end
    end
  end
end
