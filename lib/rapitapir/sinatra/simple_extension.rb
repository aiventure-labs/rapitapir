# frozen_string_literal: true

require 'sinatra/base'
require_relative '../server/sinatra_adapter'

module RapiTapir
  module Sinatra
    # Simplified Extension for basic RapiTapir + Sinatra integration
    module Extension
      def self.registered(app)
        app.helpers Helpers
        app.extend ClassMethods
        
        # Initialize RapiTapir adapter when the app starts
        app.configure do
          app.set :rapitapir_adapter, RapiTapir::Server::SinatraAdapter.new(app)
        end
      end

      module ClassMethods
        # Simple endpoint registration
        def rapitapir_endpoint(definition, &handler)
          settings.rapitapir_adapter.register_endpoint(definition, handler)
        end

        # Basic DSL for configuration
        def rapitapir(&block)
          instance_eval(&block) if block_given?
        end

        # Simple development setup
        def development_defaults!
          puts "📝 RapiTapir development mode enabled"
        end

        def production_defaults!
          puts "🔒 RapiTapir production mode enabled"
        end

        # Public paths helper
        def public_paths(*paths)
          puts "🌐 Public paths: #{paths.join(', ')}"
        end

        # API info helper
        def info(title: nil, description: nil, version: nil, **options)
          puts "📖 API: #{title} v#{version}"
        end
      end

      module Helpers
        def rapitapir_adapter
          settings.rapitapir_adapter
        end
      end
    end
  end
end
