# frozen_string_literal: true

require_relative '../../openapi/schema_generator'
require_relative '../../sinatra/swagger_ui_generator'

module RapiTapir
  module Server
    module Rails
      # Documentation helpers for Rails controllers
      module DocumentationHelpers
        # Generate OpenAPI specification from Rails controller endpoints
        def generate_openapi_spec_for_controller(controller_class, config = {})
          endpoints = []
          
          if controller_class.respond_to?(:rapitapir_endpoints)
            endpoints = controller_class.rapitapir_endpoints.values.map { |ep_config| ep_config[:endpoint] }
          end
          
          info = {
            title: 'API Documentation',
            version: '1.0.0',
            description: 'Generated with RapiTapir for Rails'
          }.merge(config[:info] || {})
          
          servers = config[:servers] || [
            {
              url: 'http://localhost:9292',
              description: 'Development server (Rails)'
            }
          ]
          
          generator = RapiTapir::OpenAPI::SchemaGenerator.new(
            endpoints: endpoints,
            info: info,
            servers: servers
          )
          
          generator.generate
        end
        
        # Generate Swagger UI HTML for Rails
        def generate_swagger_ui_html(openapi_path, api_info)
          RapiTapir::Sinatra::SwaggerUIGenerator.new(openapi_path, api_info).generate
        end
        
        # Create documentation routes for a Rails controller
        def add_documentation_routes(controller_class, config = {})
          docs_path = config[:docs_path] || '/docs'
          openapi_path = config[:openapi_path] || '/openapi.json'
          
          # OpenAPI JSON endpoint
          get openapi_path, to: proc { |env|
            spec = RapiTapir::Server::Rails::DocumentationHelpers.generate_openapi_spec_for_controller(controller_class, config)
            [
              200, 
              { 'Content-Type' => 'application/json' },
              [JSON.pretty_generate(spec)]
            ]
          }
          
          # Swagger UI endpoint
          get docs_path, to: proc { |env|
            api_info = config.dig(:info) || { title: 'API Documentation' }
            html = RapiTapir::Server::Rails::DocumentationHelpers.generate_swagger_ui_html(openapi_path, api_info)
            [
              200,
              { 'Content-Type' => 'text/html' },
              [html]
            ]
          }
        end
        
        # Module methods for static access
        module_function :generate_openapi_spec_for_controller, :generate_swagger_ui_html
      end
    end
  end
end
