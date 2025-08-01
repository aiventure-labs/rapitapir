# frozen_string_literal: true

require 'sinatra/base'
require_relative '../server/sinatra_adapter'
require_relative '../auth'
require_relative '../openapi/schema_generator'
require_relative 'configuration'
require_relative 'resource_builder'
require_relative 'swagger_ui_generator'

module RapiTapir
  module Sinatra
    # Main Sinatra Extension for RapiTapir integration
    # Provides a seamless, ergonomic experience for building enterprise-grade APIs
    module Extension
      # Extension registration hook
      def self.registered(app)
        app.helpers Helpers
        app.extend ClassMethods
        app.set :rapitapir_config, Configuration.new
        app.set :rapitapir_endpoints, []
        app.set :rapitapir_adapter, nil
        
        # Auto-setup when the app is ready
        app.configure do
          setup_rapitapir_integration unless app.settings.rapitapir_adapter
        end
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
                          raise ArgumentError, "Invalid endpoint definition"
                        end

          # Store the endpoint
          settings.rapitapir_endpoints << { endpoint: endpoint_obj, handler: handler }
          
          # Register with adapter if available
          if settings.rapitapir_adapter
            settings.rapitapir_adapter.register_endpoint(endpoint_obj, handler)
          end
          
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
          config = settings.rapitapir_config
          
          # Setup authentication middleware
          setup_authentication_middleware(config)
          
          # Setup other middleware
          setup_additional_middleware(config)
          
          # Create and configure adapter
          adapter = RapiTapir::Server::SinatraAdapter.new(self)
          set :rapitapir_adapter, adapter
          
          # Register existing endpoints
          settings.rapitapir_endpoints.each do |ep_data|
            adapter.register_endpoint(ep_data[:endpoint], ep_data[:handler])
          end
          
          # Setup documentation endpoints
          setup_documentation_endpoints(config) if config.docs_enabled?
        end

        def setup_authentication_middleware(config)
          return unless config.auth_schemes.any?

          # Convert auth scheme configurations to actual auth objects
          auth_schemes = {}
          config.auth_schemes.each do |name, scheme_config|
            auth_schemes[name] = create_auth_scheme(scheme_config)
          end

          use RapiTapir::Auth::Middleware::AuthenticationMiddleware, auth_schemes
        end

        def setup_additional_middleware(config)
          config.middleware_stack.each do |middleware_type, middleware_config|
            case middleware_type
            when :cors
              use RapiTapir::Auth::Middleware::CorsMiddleware, middleware_config
            when :rate_limiting
              use RapiTapir::Auth::Middleware::RateLimitingMiddleware, middleware_config
            when :security_headers
              use RapiTapir::Auth::Middleware::SecurityHeadersMiddleware, middleware_config
            end
          end
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

        def create_auth_scheme(scheme_config)
          case scheme_config[:type]
          when :bearer_token
            RapiTapir::Auth.bearer_token(
              scheme_config[:name],
              scheme_config[:config]
            )
          when :api_key
            RapiTapir::Auth.api_key(
              scheme_config[:name],
              scheme_config[:config]
            )
          else
            raise ArgumentError, "Unknown auth scheme type: #{scheme_config[:type]}"
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
          
          spec = generator.generate
          
          # Add security schemes if configured
          if config.auth_schemes.any?
            spec[:components] ||= {}
            spec[:components][:securitySchemes] = build_security_schemes(config)
            apply_security_requirements(spec, config)
          end
          
          spec
        end

        # Generate Swagger UI HTML
        def generate_swagger_ui(openapi_path, api_info)
          SwaggerUIGenerator.new(openapi_path, api_info).generate
        end

        # Authentication helpers
        def current_user
          RapiTapir::Auth.current_user
        end

        def authenticated?
          RapiTapir::Auth.authenticated?
        end

        def has_scope?(scope)
          RapiTapir::Auth.has_scope?(scope)
        end

        def require_authentication!
          halt 401, { error: 'Authentication required' }.to_json unless authenticated?
        end

        def require_scope!(scope)
          require_authentication!
          halt 403, { error: "#{scope.capitalize} permission required" }.to_json unless has_scope?(scope)
        end

        private

        def build_security_schemes(config)
          schemes = {}
          config.auth_schemes.each do |name, scheme_config|
            schemes[name] = build_openapi_security_scheme(scheme_config)
          end
          schemes
        end

        def build_openapi_security_scheme(scheme_config)
          case scheme_config[:type]
          when :bearer_token
            {
              type: 'http',
              scheme: 'bearer',
              bearerFormat: scheme_config[:config][:format] || 'Token',
              description: scheme_config[:config][:description]
            }
          when :api_key
            {
              type: 'apiKey',
              in: scheme_config[:config][:location] || 'header',
              name: scheme_config[:config][:name] || 'X-API-Key',
              description: scheme_config[:config][:description]
            }
          end
        end

        def apply_security_requirements(spec, config)
          return unless config.default_security_scheme

          spec[:paths].each do |path, methods|
            next if config.public_paths.include?(path)
            
            methods.each do |method, operation|
              operation[:security] = [{ config.default_security_scheme => [] }]
            end
          end
        end
      end
    end
  end
end
