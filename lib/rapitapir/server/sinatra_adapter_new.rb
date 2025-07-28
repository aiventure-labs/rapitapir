# frozen_string_literal: true

require 'json'

module RapiTapir
  module Server
    class SinatraAdapter
      attr_reader :app, :endpoints

      def initialize(sinatra_app)
        @app = sinatra_app
        @endpoints = []
      end

      # Register an endpoint with automatic Sinatra route creation
      def register_endpoint(endpoint, handler = nil, &block)
        raise ArgumentError, 'Endpoint must be a RapiTapir::Core::Endpoint' unless endpoint.is_a?(RapiTapir::Core::Endpoint)
        
        endpoint.validate!
        
        # Use provided handler or block
        endpoint_handler = handler || block
        raise ArgumentError, 'Handler must be provided' unless endpoint_handler
        
        @endpoints << { endpoint: endpoint, handler: endpoint_handler }
        
        # Register route with Sinatra using a simpler approach
        register_sinatra_route(endpoint, endpoint_handler)
      end

      private

      def register_sinatra_route(endpoint, handler)
        method_name = endpoint.method.to_s.downcase
        path_pattern = convert_path_to_sinatra(endpoint.path)
        
        # Store references for the block
        adapter = self
        endpoint_ref = endpoint
        handler_ref = handler
        
        # Use define_method to create a proper method on the Sinatra app
        route_method_name = "rapitapir_route_#{@endpoints.length}"
        
        @app.define_singleton_method(route_method_name) do
          begin
            # Extract inputs from Sinatra request
            processed_inputs = adapter.extract_sinatra_inputs(request, endpoint_ref)
            
            # Call the handler in the app context with access to instance variables
            result = case handler_ref
                     when Proc
                       instance_exec(processed_inputs, &handler_ref)
                     else
                       handler_ref.respond_to?(:call) ? handler_ref.call(processed_inputs) : instance_exec(processed_inputs, &handler_ref)
                     end
            
            # Set content type and return response
            content_type adapter.determine_content_type(endpoint_ref)
            status adapter.determine_status_code(endpoint_ref)
            
            adapter.serialize_response(result, endpoint_ref)
          rescue ArgumentError => e
            halt 400, { error: e.message }.to_json
          rescue StandardError => e
            halt 500, { error: 'Internal Server Error', message: e.message }.to_json
          end
        end
        
        # Register the route with the method
        @app.send(method_name, path_pattern, &@app.method(route_method_name))
      end

      public

      def convert_path_to_sinatra(path)
        # Convert "/users/:id" to "/users/:id" (Sinatra format is the same)
        path
      end

      def extract_sinatra_inputs(request, endpoint)
        inputs = {}
        
        endpoint.inputs.each do |input|
          value = case input.kind
                  when :query
                    request.params[input.name.to_s]
                  when :header
                    request.env["HTTP_#{input.name.to_s.upcase}"]
                  when :path
                    request.params[input.name.to_s]
                  when :body
                    parse_sinatra_body(request, input)
                  else
                    nil
                  end

          # Validate and coerce the value
          if value.nil? && input.required?
            raise ArgumentError, "Required input '#{input.name}' is missing"
          end

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
        raise ArgumentError, "Invalid JSON in request body"
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
        when :json
          'application/json'
        when :xml
          'application/xml'
        else
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
