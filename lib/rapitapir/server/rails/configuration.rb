# frozen_string_literal: true

module RapiTapir
  module Server
    module Rails
      # Simple configuration class for Rails integration
      # Provides basic configuration options needed for Rails controllers
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

        # Enable development defaults (docs endpoints, etc.)
        def development_defaults!
          # This would set up automatic documentation endpoints
          # For now, just enable health checks
          @health_check_enabled = true

          # Enable docs
          enable_docs
        end

        # Enable documentation endpoints
        def enable_docs(path: '/docs', openapi_path: '/openapi.json')
          @docs_path = path
          @openapi_path = openapi_path
        end

        # Check if docs are enabled
        def docs_enabled?
          !@docs_path.nil?
        end
      end
    end
  end
end
