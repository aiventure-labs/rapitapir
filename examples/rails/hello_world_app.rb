# frozen_string_literal: true

# Minimal Rails Application for Hello World RapiTapir Demo
# This creates a minimal Rails app to demonstrate the Hello World controller

require 'rails'
require 'action_controller/railtie'
require 'json'

# Minimal Rails application
class HelloWorldRailsApp < Rails::Application
  config.load_defaults Rails::VERSION::STRING.to_f
  config.api_only = true
  config.eager_load = false
  config.cache_classes = false
  config.secret_key_base = 'dummy_secret_for_demo'
  
  # Disable unnecessary middleware for demo
  config.middleware.delete ActionDispatch::Cookies
  config.middleware.delete ActionDispatch::Session::CookieStore
  config.middleware.delete ActionDispatch::Flash
  
  # CORS for development (optional)
  config.middleware.insert_before 0, Rack::Cors do
    allow do
      origins '*'
      resource '*', headers: :any, methods: [:get, :post, :put, :patch, :delete, :options, :head]
    end
  end if defined?(Rack::Cors)
end

# Initialize the Rails application
HelloWorldRailsApp.initialize!

# Load our controller
require_relative 'hello_world_controller'

# Load routes helper and include it in Rails routes
require_relative '../../lib/rapitapir/server/rails/routes'
require_relative '../../lib/rapitapir/server/rails/documentation_helpers'
ActionDispatch::Routing::Mapper.include(RapiTapir::Server::Rails::Routes)
ActionDispatch::Routing::Mapper.include(RapiTapir::Server::Rails::DocumentationHelpers)

# Define routes
HelloWorldRailsApp.routes.draw do
  # Auto-generate routes from RapiTapir endpoints
  rapitapir_routes_for HelloWorldController
  
  # Documentation endpoints
  add_documentation_routes(
    HelloWorldController, 
    {
      docs_path: '/docs',
      openapi_path: '/openapi.json',
      info: {
        title: 'Hello World Rails API',
        version: '1.0.0',
        description: 'A beautiful Rails API built with RapiTapir - same elegant syntax as Sinatra!'
      },
      servers: [
        {
          url: 'http://localhost:9292',
          description: 'Development server (Rails + RapiTapir)'
        }
      ]
    }
  )
  
  # Welcome page
  root 'hello_world#welcome'
  
  # Manual health check (for demo purposes)
  get '/manual-health', to: proc { |env|
    [200, {'Content-Type' => 'application/json'}, 
     [{ status: 'healthy', message: 'Manual route working!' }.to_json]]
  }
end

# If running this file directly
if __FILE__ == $PROGRAM_NAME
  require 'rack'
  
  puts "\n🌟 Hello World Rails API with RapiTapir"
  puts "🚀 Clean syntax: class HelloWorldController < RapiTapir::Server::Rails::ControllerBase"
  puts "🔗 Enhanced Rails integration with Sinatra-like elegance"
  puts ""
  puts "📋 Available endpoints:"
  puts "   GET  /                      - Welcome message"
  puts "   GET  /hello?name=YourName   - Personalized greeting" 
  puts "   GET  /greet/:language       - Multilingual greetings"
  puts "   POST /greetings             - Create custom greeting"
  puts "   GET  /health                - Health check"
  puts "   GET  /docs                  - 📖 Interactive API Documentation (Swagger UI)"
  puts "   GET  /openapi.json          - 🔧 OpenAPI 3.0 Specification"
  puts ""
  puts "🌐 Starting server on http://localhost:9292"
  puts "❤️  Try: curl http://localhost:9292/hello?name=Developer"
  puts "🌍 Try: curl http://localhost:9292/greet/spanish"
  puts ""
  puts "✨ Beautiful, type-safe Rails API with RapiTapir integration!"
  puts ""
  puts "🌐 Starting server on http://localhost:9292"
  puts "📖 Try these endpoints:"
  puts "   curl 'http://localhost:9292/hello?name=Developer'"
  puts "   curl 'http://localhost:9292/greet/spanish'"
  puts "   curl -X POST 'http://localhost:9292/greetings' -H 'Content-Type: application/json' -d '{\"name\":\"Rails\"}'"
  puts "   open http://localhost:9292/docs  # 📖 Interactive API Documentation!"
  puts ""
  
  # Start server using Rackup (modern Rack)
  require 'rackup/handler/webrick'
  
  puts "🚀 Starting server with Rackup..."
  
  Rackup::Handler::WEBrick.run(HelloWorldRailsApp, Port: 9292, Host: 'localhost')
end
