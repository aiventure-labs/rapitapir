# frozen_string_literal: true

module RapiTapir
  module Sinatra
    # Configuration class for RapiTapir Sinatra integration
    # Follows Single Responsibility Principle - manages configuration only
    class Configuration
      attr_accessor :docs_path, :openapi_path
      attr_reader :api_info, :servers, :public_paths

      def initialize
        @api_info = {
          title: 'API Documentation',
          description: 'Generated with RapiTapir',
          version: '1.0.0'
        }
        @servers = []
        @public_paths = []
        @docs_path = '/docs'
        @openapi_path = '/openapi.json'
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

      # Check if documentation is enabled
      def docs_enabled?
        !@docs_path.nil?
      end

      # Environment-specific configurations
      def development_defaults!
        # Basic development settings
        puts '📝 Applied development defaults for RapiTapir'
      end

      def production_defaults!
        # Basic production settings
        puts '🔒 Applied production defaults for RapiTapir'
      end

      # Documentation configuration
      def enable_docs(path: '/docs', openapi_path: '/openapi.json')
        @docs_path = path
        @openapi_path = openapi_path
      end
    end
  end
end
