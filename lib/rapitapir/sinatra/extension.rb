# frozen_string_literal: true

require 'sinatra/base'
require_relative '../server/sinatra_adapter'
require_relative '../auth'
require_relative '../openapi/schema_generator'
require_relative 'configuration'
require_relative 'resource_builder'
require_relative 'swagger_ui_generator'
require_relative 'oauth2_helpers'
require_relative '../dsl/http_verbs'

module RapiTapir
  module Sinatra
    # Main Sinatra Extension for RapiTapir integration
    # Provides a seamless, ergonomic experience for building enterprise-grade APIs
    module Extension
      # Extension registration hook
      def self.registered(app)
        app.helpers Helpers
        app.extend ClassMethods
        app.extend DSL::HTTPVerbs # Automatically include enhanced HTTP verb DSL
        app.extend OAuth2Helpers # Include OAuth2 authentication helpers
        app.set :rapitapir_config, Configuration.new
        app.set :rapitapir_endpoints, []
        app.set :rapitapir_adapter, nil
      end

      # Class methods added to the Sinatra application
      module ClassMethods
        # Configure RapiTapir integration
        def rapitapir(&block)
          config = settings.rapitapir_config
          config.instance_eval(&block) if block_given?
          setup_rapitapir_integration
        end

        # Register an endpoint with automatic route creation
        def endpoint(definition, &handler)
          endpoint_obj = case definition
                         when RapiTapir::Core::Endpoint, RapiTapir::Core::EnhancedEndpoint
                           definition
                         when Proc
                           definition.call
                         else
                           raise ArgumentError, 'Invalid endpoint definition'
                         end

          # Store the endpoint
          settings.rapitapir_endpoints << { endpoint: endpoint_obj, handler: handler }

          # Register with adapter if available
          settings.rapitapir_adapter&.register_endpoint(endpoint_obj, handler)

          endpoint_obj
        end

        # DSL for common endpoint patterns
        def api_resource(path, schema:, **options, &block)
          ResourceBuilder.new(self, path, schema, **options).instance_eval(&block)
        end

        # Authentication configuration
        def auth_scheme(name, type, **config)
          settings.rapitapir_config.add_auth_scheme(name, type, **config)
        end

        # Middleware configuration
        def use_rapitapir_middleware(*middleware_types)
          middleware_types.each { |type| settings.rapitapir_config.enable_middleware(type) }
        end

        # OpenAPI documentation endpoints
        def enable_docs(path: '/docs', openapi_path: '/openapi.json')
          settings.rapitapir_config.docs_path = path
          settings.rapitapir_config.openapi_path = openapi_path
        end

        private

        def setup_rapitapir_integration
          return if settings.rapitapir_adapter

          config = settings.rapitapir_config

          # Create and configure adapter
          adapter = RapiTapir::Server::SinatraAdapter.new(self)
          set :rapitapir_adapter, adapter

          # Register existing endpoints
          settings.rapitapir_endpoints.each do |ep_data|
            adapter.register_endpoint(ep_data[:endpoint], ep_data[:handler])
          end

          # Setup documentation endpoints
          setup_documentation_endpoints(config) if config.docs_enabled?

          # Setup health check endpoint automatically
          setup_health_check_endpoint(config) if config.health_check_enabled?
        end

        def setup_documentation_endpoints(config)
          openapi_path = config.openapi_path
          docs_path = config.docs_path

          # OpenAPI spec endpoint
          get openapi_path do
            content_type :json
            JSON.pretty_generate(generate_openapi_spec)
          end

          # Swagger UI endpoint
          get docs_path do
            generate_swagger_ui(openapi_path, config.api_info)
          end
        end

        def setup_health_check_endpoint(config)
          health_path = config.health_check_path
          health_endpoint = build_health_check_endpoint(health_path)
          health_handler = build_health_check_handler(config)

          # Register the health check endpoint
          settings.rapitapir_endpoints << { endpoint: health_endpoint, handler: health_handler }

          # Register with adapter
          settings.rapitapir_adapter&.register_endpoint(health_endpoint, health_handler)
        end

        def build_health_check_endpoint(health_path)
          RapiTapir.get(health_path)
                   .summary('Health check')
                   .description('Returns the health status of the API')
                   .tags('Health')
                   .ok(build_health_check_schema)
                   .build
        end

        def build_health_check_schema
          RapiTapir::Types.hash({
                                  'status' => RapiTapir::Types.string,
                                  'timestamp' => RapiTapir::Types.string,
                                  'version' => RapiTapir::Types.optional(RapiTapir::Types.string)
                                })
        end

        def build_health_check_handler(config)
          proc do |_inputs|
            {
              status: 'healthy',
              timestamp: Time.now.iso8601,
              version: config.api_info[:version]
            }
          end
        end
      end

      # Instance methods added to the Sinatra application
      module Helpers
        # Generate OpenAPI specification from registered endpoints
        def generate_openapi_spec
          config = settings.rapitapir_config
          endpoints = settings.rapitapir_endpoints.map { |ep| ep[:endpoint] }

          generator = RapiTapir::OpenAPI::SchemaGenerator.new(
            endpoints: endpoints,
            info: config.api_info,
            servers: config.servers
          )

          generator.generate
        end

        # Generate Swagger UI HTML
        def generate_swagger_ui(openapi_path, api_info)
          SwaggerUIGenerator.new(openapi_path, api_info).generate
        end

        # Authentication helpers
        def current_user
          @current_user
        end

        def authenticated?
          !current_user.nil?
        end

        def scope?(scope)
          return false unless authenticated?

          user_scopes = current_user.is_a?(Hash) ? current_user[:scopes] || [] : []
          user_scopes.include?(scope.to_s)
        end
        alias has_scope? scope?

        def require_authentication!
          halt 401, { error: 'Authentication required' }.to_json unless authenticated?
        end

        def require_scope!(scope)
          require_authentication!
          halt 403, { error: "#{scope.capitalize} permission required" }.to_json unless has_scope?(scope)
        end

        private

        # Simple placeholder for future security scheme building
        def build_security_schemes(_config)
          {}
        end
      end
    end
  end
end
