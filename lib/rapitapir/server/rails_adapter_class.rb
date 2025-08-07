# frozen_string_literal: true

module RapiTapir
  module Server
    module Rails
      # Rails adapter for automatic route generation
      class RailsAdapter
        attr_reader :endpoints

        def initialize
          @endpoints = []
        end

        # Register an endpoint and generate Rails routes
        def register_endpoint(endpoint, controller_class, action_name)
          raise ArgumentError, 'Endpoint must be a RapiTapir::Core::Endpoint' unless endpoint.is_a?(RapiTapir::Core::Endpoint)

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
