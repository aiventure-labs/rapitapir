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
        unless endpoint.is_a?(RapiTapir::Core::Endpoint)
          raise ArgumentError, 'Endpoint must be a RapiTapir::Core::Endpoint'
        end

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
          handle_sinatra_request(adapter, endpoint_id, request, params)
        end
      end

      def handle_sinatra_request(adapter, endpoint_id, request, params)
        endpoint_data = adapter.endpoints[endpoint_id]

        begin
          processed_inputs = adapter.extract_sinatra_inputs(request, params, endpoint_data[:endpoint])
          result = execute_endpoint_handler(endpoint_data, processed_inputs)
          send_successful_response(adapter, endpoint_data, result)
        rescue ArgumentError => e
          halt 400, { error: e.message }.to_json
        rescue StandardError => e
          halt 500, { error: 'Internal Server Error', message: e.message }.to_json
        end
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

      def send_successful_response(adapter, endpoint_data, result)
        content_type adapter.determine_content_type(endpoint_data[:endpoint])
        status adapter.determine_status_code(endpoint_data[:endpoint])
        adapter.serialize_response(result, endpoint_data[:endpoint])
      end

      public

      def convert_path_to_sinatra(path)
        # Convert "/users/:id" to "/users/:id" (Sinatra format is the same)
        path
      end

      def extract_sinatra_inputs(request, params, endpoint)
        inputs = {}

        endpoint.inputs.each do |input|
          value = case input.kind
                  when :query, :path
                    # Both query and path parameters are available in params
                    params[input.name.to_s] || params[input.name.to_sym]
                  when :header
                    request.env["HTTP_#{input.name.to_s.upcase}"]
                  when :body
                    parse_sinatra_body(request, input)
                  end

          # Validate and coerce the value
          raise ArgumentError, "Required input '#{input.name}' is missing" if value.nil? && input.required?

          inputs[input.name] = input.coerce(value) if value || !input.required?
        end

        inputs
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
