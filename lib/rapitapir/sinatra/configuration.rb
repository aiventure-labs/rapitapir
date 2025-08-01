# frozen_string_literal: true

module RapiTapir
  module Sinatra
    # Configuration class for RapiTapir Sinatra integration
    # Follows Single Responsibility Principle - manages configuration only
    class Configuration
      attr_accessor :docs_path, :openapi_path, :default_security_scheme
      attr_reader :api_info, :servers, :auth_schemes, :middleware_stack, :public_paths

      def initialize
        @api_info = {
          title: 'API Documentation',
          description: 'Generated with RapiTapir',
          version: '1.0.0'
        }
        @servers = []
        @auth_schemes = {}
        @middleware_stack = {}
        @public_paths = []
        @docs_path = '/docs'
        @openapi_path = '/openapi.json'
        @default_security_scheme = nil
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

      # Authentication scheme configuration
      def add_auth_scheme(name, type, **config)
        @auth_schemes[name] = {
          name: name,
          type: type,
          config: config
        }
      end

      # Bearer token authentication (most common)
      def bearer_auth(name = :bearer, **config)
        add_auth_scheme(name, :bearer_token, **config)
        @default_security_scheme = name unless @default_security_scheme
      end

      # API Key authentication
      def api_key_auth(name = :api_key, **config)
        add_auth_scheme(name, :api_key, **config)
        @default_security_scheme = name unless @default_security_scheme
      end

      # Middleware configuration
      def enable_middleware(type, **config)
        @middleware_stack[type] = config
      end

      # CORS configuration
      def cors(**config)
        enable_middleware(:cors, **config)
      end

      # Rate limiting configuration
      def rate_limiting(**config)
        enable_middleware(:rate_limiting, **config)
      end

      # Security headers configuration
      def security_headers(**config)
        enable_middleware(:security_headers, **config)
      end

      # Public paths (no authentication required)
      def public_path(path)
        @public_paths << path
      end

      def public_paths(*paths)
        @public_paths.concat(paths)
      end

      # Check if documentation is enabled
      def docs_enabled?
        @docs_path && @openapi_path
      end

      # Production-ready defaults
      def production_defaults!
        # Enable security middleware
        security_headers
        
        # Enable CORS with secure defaults
        cors(
          allowed_origins: [],
          allowed_methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH'],
          allowed_headers: ['Authorization', 'Content-Type', 'Accept'],
          allow_credentials: false
        )
        
        # Enable rate limiting
        rate_limiting(
          requests_per_minute: 60,
          requests_per_hour: 1000
        )
        
        # Common public paths
        public_paths('/health', '/docs', '/openapi.json')
      end

      # Development-friendly defaults
      def development_defaults!
        # Relaxed CORS for development
        cors(
          allowed_origins: ['http://localhost:3000', 'http://localhost:4567'],
          allowed_methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
          allowed_headers: ['Authorization', 'Content-Type', 'Accept'],
          allow_credentials: true
        )
        
        # Generous rate limiting for development
        rate_limiting(
          requests_per_minute: 1000,
          requests_per_hour: 10000
        )
        
        # Common public paths
        public_paths('/health', '/docs', '/openapi.json')
      end
    end
  end
end
