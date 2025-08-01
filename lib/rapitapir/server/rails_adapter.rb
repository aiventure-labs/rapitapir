# frozen_string_literal: true

module RapiTapir
  module Server
    module Rails
      # Rails controller concern for RapiTapir integration
      module Controller
        extend ActiveSupport::Concern

        included do
          class_attribute :rapitapir_endpoints, default: {}
        end

        class_methods do
          # Register an endpoint for this controller
          def rapitapir_endpoint(action_name, endpoint, &handler)
            unless endpoint.is_a?(RapiTapir::Core::Endpoint)
              raise ArgumentError, 'Endpoint must be a RapiTapir::Core::Endpoint'
            end

            endpoint.validate!

            self.rapitapir_endpoints = rapitapir_endpoints.merge(
              action_name.to_sym => {
                endpoint: endpoint,
                handler: handler
              }
            )
          end
        end

        private

        # Process a RapiTapir endpoint within a Rails action
        def process_rapitapir_endpoint(action_name = nil)
          action_name ||= params[:action]&.to_sym || :index
          endpoint_config = self.class.rapitapir_endpoints[action_name.to_sym]

          unless endpoint_config
            render json: { error: 'Endpoint not configured' }, status: 500
            return
          end

          endpoint = endpoint_config[:endpoint]
          handler = endpoint_config[:handler]

          begin
            # Extract inputs from Rails request
            processed_inputs = extract_rails_inputs(request, endpoint)

            # Call the handler in the context of the controller
            result = instance_exec(processed_inputs, &handler)

            # Render the response
            render_rapitapir_response(result, endpoint)
          rescue ArgumentError => e
            render json: { error: e.message }, status: 400
          rescue StandardError => e
            render json: { error: 'Internal Server Error', message: e.message }, status: 500
          end
        end

        def extract_rails_inputs(request, endpoint)
          inputs = {}

          endpoint.inputs.each do |input|
            value = case input.kind
                    when :query
                      request.query_parameters[input.name.to_s] || params[input.name.to_s]
                    when :header
                      request.headers[input.name.to_s] || request.headers["HTTP_#{input.name.to_s.upcase}"]
                    when :path
                      params[input.name.to_s]
                    when :body
                      parse_rails_body(request, input)
                    end

            # Validate and coerce the value
            raise ArgumentError, "Required input '#{input.name}' is missing" if value.nil? && input.required?

            inputs[input.name] = input.coerce(value) if value || !input.required?
          end

          inputs
        end

        def parse_rails_body(request, input)
          # Rails typically parses JSON automatically into params
          if input.type == Hash || input.type.is_a?(Hash)
            # Try to get from parsed params first
            request.request_parameters.presence ||
              # Fall back to parsing raw body
              begin
                JSON.parse(request.raw_post)
              rescue JSON::ParserError
                raise ArgumentError, 'Invalid JSON in request body'
              end
          else
            request.raw_post
          end
        end

        def render_rapitapir_response(result, endpoint)
          output = endpoint.outputs.find { |o| o.kind == :json } || endpoint.outputs.first
          status_code = determine_rails_status_code(endpoint)

          if output&.kind == :xml
            render xml: result, status: status_code
          else
            # Default to JSON for nil output, :json kind, or unknown kinds
            render json: result, status: status_code
          end
        end

        def determine_rails_status_code(endpoint)
          status_output = endpoint.outputs.find { |o| o.kind == :status }
          status_output ? status_output.type : 200
        end
      end

      # Rails adapter for automatic route generation
      class RailsAdapter
        attr_reader :endpoints

        def initialize
          @endpoints = []
        end

        # Register an endpoint and generate Rails routes
        def register_endpoint(endpoint, controller_class, action_name)
          unless endpoint.is_a?(RapiTapir::Core::Endpoint)
            raise ArgumentError, 'Endpoint must be a RapiTapir::Core::Endpoint'
          end

          endpoint.validate!

          @endpoints << {
            endpoint: endpoint,
            controller: controller_class,
            action: action_name
          }
        end

        # Generate Rails routes for registered endpoints
        def generate_routes(rails_routes)
          @endpoints.each do |endpoint_config|
            endpoint = endpoint_config[:endpoint]
            controller = endpoint_config[:controller]
            action = endpoint_config[:action]

            method_name = endpoint.method.to_s.downcase
            path_pattern = convert_path_to_rails(endpoint.path)
            controller_name = controller.name.underscore.sub(/_controller$/, '')

            rails_routes.send(method_name, path_pattern, to: "#{controller_name}##{action}")
          end
        end

        private

        def convert_path_to_rails(path)
          # Convert "/users/:id" to "/users/:id" (Rails format is the same)
          path
        end
      end
    end
  end
end
