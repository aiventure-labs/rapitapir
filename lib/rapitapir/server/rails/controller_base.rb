# frozen_string_literal: true

require_relative '../rails_controller'
require_relative '../../dsl/http_verbs'
require_relative '../../types'
require_relative 'resource_builder'
require_relative 'configuration'

module RapiTapir
  module Server
    module Rails
      # Enhanced Rails controller base class providing Sinatra-like experience
      #
      # This class bridges the gap between Sinatra's elegant DSL and Rails conventions,
      # offering the same clean syntax that Sinatra developers enjoy.
      #
      # @example Basic usage
      #   class UsersController < RapiTapir::Server::Rails::ControllerBase
      #     rapitapir do
      #       info(title: 'Users API', version: '1.0.0')
      #       development_defaults!
      #     end
      #
      #     USER_SCHEMA = T.hash({
      #       "id" => T.integer,
      #       "name" => T.string,
      #       "email" => T.email
      #     })
      #
      #     endpoint(
      #       GET('/users')
      #         .summary('List users')
      #         .ok(T.array(USER_SCHEMA))
      #         .build
      #     ) { User.all.map(&:attributes) }
      #   end
      class ControllerBase < ActionController::Base
        include RapiTapir::Server::Rails::Controller
        extend RapiTapir::DSL::HTTPVerbs

        # Make T shortcut available in Rails controllers
        T = RapiTapir::Types

        class << self
          # Configure RapiTapir for this controller
          # Similar to Sinatra's rapitapir block
          #
          # @param block [Proc] Configuration block
          # @example
          #   rapitapir do
          #     info(title: 'My API', version: '1.0.0')
          #     development_defaults!
          #   end
          def rapitapir(&)
            @rapitapir_config = Configuration.new
            @rapitapir_config.instance_eval(&) if block_given?
            setup_default_features
          end

          # Define an endpoint with automatic action generation
          # This method creates both the endpoint definition and the corresponding Rails action
          #
          # @param endpoint_definition [RapiTapir::Core::Endpoint] The endpoint definition
          # @param block [Proc] The endpoint handler
          # @example
          #   endpoint(
          #     GET('/users/:id')
          #       .summary('Get user')
          #       .path_param(:id, T.integer)
          #       .ok(USER_SCHEMA)
          #       .build
          #   ) do |inputs|
          #     User.find(inputs[:id]).attributes
          #   end
          def endpoint(endpoint_definition, &)
            action_name = derive_action_name(endpoint_definition.path, endpoint_definition.method)

            # Register endpoint with the Rails controller mixin
            rapitapir_endpoint(action_name, endpoint_definition, &)

            # Auto-generate Rails controller action that passes the correct action name
            define_method(action_name) do
              process_rapitapir_endpoint(action_name)
            end
          end

          # Create RESTful resource endpoints with CRUD operations
          # Mirrors Sinatra's api_resource functionality for Rails
          #
          # @param path [String] Base path for the resource
          # @param schema [Object] Schema for the resource
          # @param block [Proc] Resource configuration block
          # @example
          #   api_resource '/users', schema: USER_SCHEMA do
          #     crud do
          #       index { User.all.map(&:attributes) }
          #       show { |inputs| User.find(inputs[:id]).attributes }
          #       create { |inputs| User.create!(inputs[:body]).attributes }
          #     end
          #   end
          def api_resource(path, schema:, &block)
            resource_builder = ResourceBuilder.new(self, path, schema)
            resource_builder.instance_eval(&block)

            # Generate all CRUD endpoints and actions automatically
            resource_builder.endpoints.each do |endpoint_def, handler|
              endpoint(endpoint_def, &handler)
            end
          end

          # Enhanced HTTP verb methods that return FluentEndpointBuilder
          # These override the mixin methods to ensure proper scoping
          #
          # @param path [String] The endpoint path
          # @return [RapiTapir::DSL::FluentEndpointBuilder] Builder for method chaining
          def GET(path)
            RapiTapir.get(path)
          end

          def POST(path)
            RapiTapir.post(path)
          end

          def PUT(path)
            RapiTapir.put(path)
          end

          def PATCH(path)
            RapiTapir.patch(path)
          end

          def DELETE(path)
            RapiTapir.delete(path)
          end

          def HEAD(path)
            RapiTapir.head(path)
          end

          def OPTIONS(path)
            RapiTapir.options(path)
          end

          private

          # Set up default features similar to Sinatra extension
          def setup_default_features
            # Future: Auto-setup CORS, docs, health checks like Sinatra
            # For now, we'll focus on the core functionality
          end

          # Derive Rails action name from HTTP method and path
          # Follows Rails conventions for RESTful routes
          #
          # @param path [String] The endpoint path
          # @param method [Symbol] The HTTP method
          # @return [Symbol] The Rails action name
          def derive_action_name(path, method)
            # For custom endpoints, always derive from path to avoid conflicts
            path_segments = path.split('/').reject(&:empty?)

            return method.to_s.downcase.to_sym if path_segments.empty?

            # Get the main path segment (not parameters)
            main_segment = nil
            path_segments.each do |segment|
              unless segment.start_with?(':') || segment.start_with?('{')
                main_segment = segment
                break
              end
            end

            if main_segment
              # Create action name from method + segment to ensure uniqueness
              :"#{method.to_s.downcase}_#{main_segment}"
            else
              # Fallback to method name
              method.to_s.downcase.to_sym
            end
          end
        end
      end
    end
  end
end
