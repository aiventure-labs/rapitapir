# frozen_string_literal: true

require_relative 'fluent_endpoint_builder'
require_relative 'enhanced_structures'

module RapiTapir
  module DSL
    # Main DSL entry point for creating endpoints with fluent interface
    module FluentDSL
      # HTTP method builders
      def get(path)
        FluentEndpointBuilder.new(:get, path)
      end

      def post(path)
        FluentEndpointBuilder.new(:post, path)
      end

      def put(path)
        FluentEndpointBuilder.new(:put, path)
      end

      def patch(path)
        FluentEndpointBuilder.new(:patch, path)
      end

      def delete(path)
        FluentEndpointBuilder.new(:delete, path)
      end

      def head(path)
        FluentEndpointBuilder.new(:head, path)
      end

      def options(path)
        FluentEndpointBuilder.new(:options, path)
      end

      # Route grouping and namespacing
      def namespace(prefix, &block)
        NamespaceBuilder.new(prefix, &block)
      end

      def group(&block)
        GroupBuilder.new(&block)
      end

      # Global configuration
      def configure(&block)
        Configuration.instance_eval(&block)
      end
    end

    # Namespace builder for grouping related endpoints
    class NamespaceBuilder
      include FluentDSL

      attr_reader :prefix, :endpoints, :middleware_stack, :security_schemes, :error_responses

      def initialize(prefix, &block)
        @prefix = prefix.to_s
        @endpoints = []
        @middleware_stack = []
        @security_schemes = []
        @error_responses = {}
        @default_metadata = {}

        instance_eval(&block) if block_given?
      end

      # Override HTTP methods to include namespace prefix
      [:get, :post, :put, :patch, :delete, :head, :options].each do |method|
        define_method(method) do |path|
          full_path = File.join(@prefix, path).gsub(/\/+/, '/')
          builder = FluentEndpointBuilder.new(method, full_path)
          
          # Apply namespace-level configurations
          builder = apply_namespace_defaults(builder)
          @endpoints << builder
          builder
        end
      end

      # Namespace-level configuration
      def middleware(middleware_class, *args, &block)
        @middleware_stack << [middleware_class, args, block]
        self
      end

      def bearer_auth(description = "Bearer token authentication", **options)
        security = DSL::EnhancedSecurity.new(type: :bearer, description: description, **options)
        @security_schemes << security
        self
      end

      def api_key_auth(name, location = :header, description = "API key authentication", **options)
        security = DSL::EnhancedSecurity.new(type: :api_key, description: description, name: name, location: location, **options)
        @security_schemes << security
        self
      end

      def error_responses(&block)
        error_builder = ErrorResponseBuilder.new
        error_builder.instance_eval(&block)
        @error_responses.merge!(error_builder.errors)
        self
      end

      def default_metadata(**metadata)
        @default_metadata.merge!(metadata)
        self
      end

      def tags(*tag_list)
        @default_metadata[:tags] = (@default_metadata[:tags] || []) + tag_list.flatten
        self
      end

      def build_all
        @endpoints.map(&:build)
      end

      def to_openapi_spec(info = {})
        spec = {
          openapi: '3.0.3',
          info: {
            title: info[:title] || 'API',
            version: info[:version] || '1.0.0',
            description: info[:description]
          }.compact,
          paths: {},
          components: {
            securitySchemes: {}
          }
        }

        # Add security schemes
        @security_schemes.each_with_index do |security, index|
          scheme_name = security.type.to_s + (index > 0 ? "_#{index}" : "")
          spec[:components][:securitySchemes][scheme_name] = security.to_openapi_spec
        end

        # Add endpoints
        @endpoints.each do |endpoint_builder|
          endpoint = endpoint_builder.build
          path = endpoint.path
          method = endpoint.method.to_s.downcase
          
          spec[:paths][path] ||= {}
          spec[:paths][path][method] = endpoint.to_openapi_spec
        end

        spec
      end

      private

      def apply_namespace_defaults(builder)
        # Apply security schemes
        @security_schemes.each do |security|
          builder = builder.copy_with(security_schemes: builder.security_schemes + [security])
        end

        # Apply default metadata
        @default_metadata.each do |key, value|
          case key
          when :tags
            builder = builder.tags(*value)
          else
            builder = builder.copy_with(metadata: builder.metadata.merge(key => value))
          end
        end

        # Apply error responses
        @error_responses.each do |status_code, error_spec|
          builder = builder.error_response(status_code, error_spec[:type], **error_spec[:options])
        end

        builder
      end
    end

    # Group builder for organizing endpoints without path prefix
    class GroupBuilder
      include FluentDSL

      attr_reader :endpoints

      def initialize(&block)
        @endpoints = []
        instance_eval(&block) if block_given?
      end

      [:get, :post, :put, :patch, :delete, :head, :options].each do |method|
        define_method(method) do |path|
          builder = FluentEndpointBuilder.new(method, path)
          @endpoints << builder
          builder
        end
      end

      def build_all
        @endpoints.map(&:build)
      end
    end

    # Error response builder for defining reusable error responses
    class ErrorResponseBuilder
      attr_reader :errors

      def initialize
        @errors = {}
      end

      def unauthorized(status_code = 401, type_def = nil, **options)
        @errors[status_code] = { type: type_def, options: options }
      end

      def forbidden(status_code = 403, type_def = nil, **options)
        @errors[status_code] = { type: type_def, options: options }
      end

      def not_found(status_code = 404, type_def = nil, **options)
        @errors[status_code] = { type: type_def, options: options }
      end

      def validation_error(status_code = 422, type_def = nil, **options)
        @errors[status_code] = { type: type_def, options: options }
      end

      def server_error(status_code = 500, type_def = nil, **options)
        @errors[status_code] = { type: type_def, options: options }
      end

      def custom_error(status_code, type_def = nil, **options)
        @errors[status_code] = { type: type_def, options: options }
      end
    end

    # Global configuration singleton
    class Configuration
      class << self
        attr_accessor :default_auth, :default_middleware, :global_error_responses, :openapi_info

        def reset!
          @default_auth = nil
          @default_middleware = []
          @global_error_responses = {}
          @openapi_info = {}
        end

        def bearer_auth(description = "Bearer token authentication", **options)
          @default_auth = DSL::EnhancedSecurity.new(type: :bearer, description: description, **options)
        end

        def middleware(middleware_class, *args, &block)
          @default_middleware << [middleware_class, args, block]
        end

        def openapi(info = {})
          @openapi_info.merge!(info)
        end
      end

      # Initialize with defaults
      reset!
    end
  end
end

# Extend RapiTapir module with DSL methods
module RapiTapir
  extend DSL::FluentDSL
end
