# frozen_string_literal: true

require_relative 'enhanced_rack_adapter'

module RapiTapir
  module Server
    # Sinatra integration for enhanced endpoints
    module SinatraIntegration
      def self.included(base)
        base.extend(ClassMethods)
        base.class_eval do
          @rapitapir_adapter = EnhancedRackAdapter.new
        end
      end

      # Class methods for Sinatra integration
      #
      # Provides methods to define RapiTapir endpoints and generate documentation
      # within Sinatra applications.
      module ClassMethods
        def rapitapir_adapter
          @rapitapir_adapter ||= EnhancedRackAdapter.new
        end

        # Mount an endpoint in Sinatra
        def mount_endpoint(endpoint, &handler)
          rapitapir_adapter.mount(endpoint, &handler)

          # Register the route with Sinatra
          method_name = endpoint.method.to_s.downcase
          path_pattern = convert_path_to_sinatra(endpoint.path)

          send(method_name, path_pattern) do
            # Delegate to RapiTapir adapter
            rapitapir_adapter.call(env)
          end
        end

        # Use middleware with RapiTapir
        def rapitapir_use(middleware_class, ...)
          rapitapir_adapter.use(middleware_class, ...)
        end

        # Register error handlers
        def rapitapir_error(error_class, &handler)
          rapitapir_adapter.on_error(error_class, &handler)
        end

        # Generate OpenAPI spec for all mounted endpoints
        def to_openapi_spec(info = {})
          spec = {
            openapi: '3.0.3',
            info: {
              title: info[:title] || 'API',
              version: info[:version] || '1.0.0',
              description: info[:description]
            }.compact,
            paths: {}
          }

          rapitapir_adapter.endpoints.each do |endpoint_data|
            endpoint = endpoint_data[:endpoint]
            path = endpoint.path
            method = endpoint.method.to_s.downcase

            spec[:paths][path] ||= {}
            spec[:paths][path][method] = endpoint.to_openapi_spec
          end

          spec
        end

        private

        def convert_path_to_sinatra(path)
          # Convert RapiTapir path format to Sinatra path format
          # e.g., "/users/{id}" -> "/users/:id"
          path.gsub(/\{([^}]+)\}/, ':\1')
        end
      end
    end
  end
end
