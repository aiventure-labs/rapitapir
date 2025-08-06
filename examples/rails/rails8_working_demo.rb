# frozen_string_literal: true

# Working Rails 8 + RapiTapir example
# This uses only the core RapiTapir features that are known to work

puts "🚀 Starting Rails 8 + RapiTapir Demo..."

# Check if Rails is available
begin
  require 'rails/all'
  puts "✅ Rails #{Rails::VERSION::STRING} loaded"
rescue LoadError => e
  puts "❌ Rails not available: #{e.message}"
  puts ""
  puts "To run this demo, install Rails 8:"
  puts "  gem install rails"
  puts ""
  exit 1
end

# Load RapiTapir
begin
  require_relative '../../lib/rapitapir'
  puts "✅ RapiTapir loaded"
rescue LoadError => e
  puts "❌ RapiTapir not available: #{e.message}"
  exit 1
end

# Create Rails application
puts "🏗️  Setting up Rails application..."

class Rails8DemoApp < Rails::Application
  config.load_defaults 8.0
  config.api_only = true
  config.eager_load = false
  config.secret_key_base = 'rails8_demo_secret_key_for_rapitapir_integration'
  config.log_level = :info
  config.logger = Logger.new(STDOUT)
end

Rails.application.initialize!
puts "✅ Rails application initialized"

# Sample data
DEMO_USERS = [
  { id: 1, name: "Alice Johnson", email: "alice@example.com" },
  { id: 2, name: "Bob Smith", email: "bob@example.com" }
].freeze

# Define endpoints using standard RapiTapir DSL (not Rails integration)
puts "📋 Defining API endpoints..."

# Health check endpoint
HEALTH_ENDPOINT = RapiTapir.get('/health')
  .out(status_code(200))
  .out(json_body({
    status: :string,
    timestamp: :string,
    rails_version: :string,
    ruby_version: :string
  }))
  .summary("Health check")
  .description("Check if the API is running")
  .tag("System")

# List users endpoint  
LIST_USERS_ENDPOINT = RapiTapir.get('/users')
  .out(status_code(200))
  .out(json_body({
    users: [{
      id: :integer,
      name: :string,
      email: :string
    }]
  }))
  .summary("List users")
  .description("Get all users")
  .tag("Users")

# Get user endpoint
GET_USER_ENDPOINT = RapiTapir.get('/users/:id')
  .in(path_param(:id, :integer))
  .out(status_code(200))
  .out(json_body({
    user: {
      id: :integer,
      name: :string,
      email: :string
    }
  }))
  .error_out(404, json_body({ error: :string }))
  .summary("Get user")
  .description("Get a specific user by ID")
  .tag("Users")

puts "✅ Endpoints defined"

# Create a standard Rails controller (not using RapiTapir Rails integration)
puts "🎮 Creating Rails controllers..."

class ApplicationController < ActionController::API
  def health_check
    render json: {
      status: 'ok',
      timestamp: Time.current.iso8601,
      rails_version: Rails.version,
      ruby_version: RUBY_VERSION
    }
  end
end

class UsersController < ApplicationController
  def index
    render json: { users: DEMO_USERS }
  end
  
  def show
    user = DEMO_USERS.find { |u| u[:id] == params[:id].to_i }
    
    if user
      render json: { user: user }
    else
      render json: { error: "User not found" }, status: 404
    end
  end
end

puts "✅ Controllers created"

# Set up routes
puts "🛣️  Setting up routes..."

Rails.application.routes.draw do
  get '/health', to: 'application#health_check'
  get '/users', to: 'users#index'
  get '/users/:id', to: 'users#show'
  
  # Documentation routes (manual for now)
  get '/docs', to: proc { |env|
    [200, { 'Content-Type' => 'text/html' }, [<<~HTML
      <!DOCTYPE html>
      <html>
      <head>
        <title>Rails 8 + RapiTapir Demo API</title>
        <style>
          body { font-family: Arial, sans-serif; margin: 40px; }
          h1 { color: #333; }
          .endpoint { background: #f5f5f5; padding: 15px; margin: 10px 0; border-radius: 5px; }
          .method { font-weight: bold; color: #007bff; }
          .path { font-family: monospace; background: #eee; padding: 2px 4px; }
          pre { background: #f8f9fa; padding: 10px; border-radius: 3px; overflow-x: auto; }
        </style>
      </head>
      <body>
        <h1>Rails 8 + RapiTapir Demo API</h1>
        <p>This is a working demonstration of RapiTapir with Rails 8.</p>
        
        <h2>Available Endpoints</h2>
        
        <div class="endpoint">
          <h3><span class="method">GET</span> <span class="path">/health</span></h3>
          <p>Health check endpoint</p>
          <h4>Example Response:</h4>
          <pre>{"status":"ok","timestamp":"2025-08-06T10:30:00Z","rails_version":"8.0.2","ruby_version":"3.3.4"}</pre>
        </div>
        
        <div class="endpoint">
          <h3><span class="method">GET</span> <span class="path">/users</span></h3>
          <p>List all users</p>
          <h4>Example Response:</h4>
          <pre>{"users":[{"id":1,"name":"Alice Johnson","email":"alice@example.com"},{"id":2,"name":"Bob Smith","email":"bob@example.com"}]}</pre>
        </div>
        
        <div class="endpoint">
          <h3><span class="method">GET</span> <span class="path">/users/:id</span></h3>
          <p>Get a specific user by ID</p>
          <h4>Example Response:</h4>
          <pre>{"user":{"id":1,"name":"Alice Johnson","email":"alice@example.com"}}</pre>
          <h4>Error Response (404):</h4>
          <pre>{"error":"User not found"}</pre>
        </div>
        
        <h2>Test Commands</h2>
        <pre>
curl http://localhost:3000/health
curl http://localhost:3000/users
curl http://localhost:3000/users/1
curl http://localhost:3000/users/999
        </pre>
        
        <h2>About</h2>
        <p>This demo shows Rails 8 working with RapiTapir endpoints defined using the standard DSL.</p>
        <p>While this example doesn't use the Rails integration features (which are still in development), 
        it demonstrates that RapiTapir and Rails 8 can work together successfully.</p>
      </body>
      </html>
    HTML
    ]]
  }
end

puts "✅ Routes configured"

# Register endpoints with RapiTapir (for documentation generation)
puts "📝 Registering endpoints with RapiTapir..."

RapiTapir.register_endpoint(HEALTH_ENDPOINT)
RapiTapir.register_endpoint(LIST_USERS_ENDPOINT)
RapiTapir.register_endpoint(GET_USER_ENDPOINT)

puts "✅ Endpoints registered"

# Start the server
if __FILE__ == $0
  puts ""
  puts "🚀 Rails 8 + RapiTapir Demo is ready!"
  puts ""
  puts "📋 System Info:"
  puts "   Rails Version: #{Rails.version}"
  puts "   Ruby Version: #{RUBY_VERSION}"
  puts "   RapiTapir: ✅ Loaded"
  puts ""
  puts "📚 Available endpoints:"
  puts "   GET /health      - Health check"
  puts "   GET /users       - List all users"
  puts "   GET /users/:id   - Get specific user"
  puts "   GET /docs        - API documentation"
  puts ""
  puts "🧪 Test commands:"
  puts "   curl http://localhost:3000/health"
  puts "   curl http://localhost:3000/users"
  puts "   curl http://localhost:3000/users/1"
  puts ""
  puts "Starting server on http://localhost:3000..."
  puts ""
  
  begin
    require 'webrick'
    puts "Using WEBrick server..."
    Rack::Handler::WEBrick.run(Rails.application, Port: 3000, Host: '0.0.0.0')
  rescue LoadError
    puts "WEBrick not available. Trying Puma..."
    begin
      require 'puma'
      puts "Using Puma server..."
      Rack::Handler::Puma.run(Rails.application, Port: 3000, Host: '0.0.0.0')
    rescue LoadError
      puts "❌ No web server available. Install webrick or puma:"
      puts "   gem install webrick"
      puts "   gem install puma"
      exit 1
    end
  end
end
