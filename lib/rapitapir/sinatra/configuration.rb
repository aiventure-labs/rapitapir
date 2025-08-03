# frozen_string_literal: true

module RapiTapir
  module Sinatra
    # Configuration class for RapiTapir Sinatra integration
    # Follows Single Responsibility Principle - manages configuration only
    class Configuration
      attr_accessor :docs_path, :openapi_path, :health_check_enabled, :health_check_path
      attr_reader :api_info, :servers, :public_paths, :auth_schemes

      def initialize
        @api_info = {
          title: 'API Documentation',
          description: 'Generated with RapiTapir',
          version: '1.0.0'
        }
        @servers = []
        @public_paths = []
        @auth_schemes = {}
        @docs_path = '/docs'
        @openapi_path = '/openapi.json'
        @health_check_enabled = false
        @health_check_path = '/health'
      end

      # API Information configuration
      def info(title: nil, description: nil, version: nil, **options)
        @api_info[:title] = title if title
        @api_info[:description] = description if description
        @api_info[:version] = version if version
        @api_info.merge!(options)
      end

      # Server configuration
      def server(url:, description: nil)
        @servers << { url: url, description: description }.compact
      end

      # Add paths that don't require authentication
      def add_public_paths(*paths)
        @public_paths.concat(paths.flatten.map(&:to_s))
      end

      # Authentication scheme management
      def add_auth_scheme(name, scheme)
        @auth_schemes[name] = scheme
      end

      def get_auth_scheme(name)
        @auth_schemes[name]
      end

      # Check if documentation is enabled
      def docs_enabled?
        !@docs_path.nil?
      end

      # Environment-specific configurations
      def development_defaults!
        # Enable health check endpoint
        enable_health_check
        # Enable docs by default in development
        enable_docs unless @docs_path.nil? && @openapi_path.nil?
        # Add health check to public paths (no auth required)
        add_public_paths(@health_check_path)
        puts '📝 Applied development defaults for RapiTapir (includes health check at /health)'
      end

      def production_defaults!
        # Basic production settings
        puts '🔒 Applied production defaults for RapiTapir'
      end

      # Health check configuration
      def enable_health_check(path: '/health')
        @health_check_enabled = true
        @health_check_path = path
      end

      def health_check_enabled?
        @health_check_enabled
      end

      # Documentation configuration
      def enable_docs(path: '/docs', openapi_path: '/openapi.json')
        @docs_path = path
        @openapi_path = openapi_path
      end
    end
  end
end
