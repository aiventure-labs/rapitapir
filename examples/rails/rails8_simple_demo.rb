# frozen_string_literal: true

# Simple Rails 8 + RapiTapir example using system Rails
# Note: Requires Rails 8 to be installed: gem install rails

puts "🚀 Loading Rails and RapiTapir..."

# Load Rails first (this is crucial!)
require 'rails/all'

# Now load RapiTapir (this will work because Rails is loaded)
require_relative '../../lib/rapitapir'

puts "✅ Libraries loaded successfully"

# Rails 8 Application Setup
class Rails8Demo < Rails::Application
  config.load_defaults 8.0
  config.api_only = true
  config.eager_load = false
  config.logger = Logger.new(STDOUT)
  config.log_level = :info
  config.secret_key_base = 'rails8_demo_secret_key'
end

puts "🏗️  Initializing Rails application..."
Rails.application.initialize!
puts "✅ Rails application initialized"

# Simple in-memory data for demo
USERS = [
  { id: 1, name: "Alice Johnson", email: "alice@example.com" },
  { id: 2, name: "Bob Smith", email: "bob@example.com" }
].freeze

# ApplicationController with RapiTapir
class ApplicationController < RapiTapir::Server::Rails::ControllerBase
  rapitapir do
    development_defaults!
    
    # Health endpoint
    GET('/health')
      .out(json_body(
        status: T.string,
        timestamp: T.string,
        rails_version: T.string,
        ruby_version: T.string
      ))
      .summary("System health check")
      .tag("System")
  end
  
  def health_check
    render json: {
      status: 'ok',
      timestamp: Time.current.iso8601,
      rails_version: Rails.version,
      ruby_version: RUBY_VERSION
    }
  end
end

puts "✅ ApplicationController defined"

# Users API Controller
class UsersController < ApplicationController
  rapitapir do
    user_type = T.hash(
      id: T.integer,
      name: T.string,
      email: T.string
    )
    
    GET('/users')
      .out(json_body(users: T.array(user_type)))
      .summary("List all users")
      .description("Get a list of all users in the system")
      .tag("Users")
    
    GET('/users/:id')
      .in(path(:id, T.integer))
      .out(json_body(user: user_type))
      .error_out(json_body(error: T.string), 404)
      .summary("Get user by ID")
      .tag("Users")
  end
  
  def list_users
    render json: { users: USERS }
  end
  
  def get_user
    user = USERS.find { |u| u[:id] == params[:id].to_i }
    
    if user
      render json: { user: user }
    else
      render json: { error: "User not found" }, status: 404
    end
  end
end

puts "✅ UsersController defined"

# Routes
Rails.application.routes.draw do
  rapitapir_routes_for ApplicationController
  rapitapir_routes_for UsersController
end

puts "✅ Routes configured"

# Start server
if __FILE__ == $0
  puts ""
  puts "🚀 Rails 8 + RapiTapir Demo starting on http://localhost:3000"
  puts "📋 Rails Version: #{Rails.version}"
  puts "📋 Ruby Version: #{RUBY_VERSION}"
  puts ""
  puts "📚 Available endpoints:"
  puts "  GET /health      - Health check"
  puts "  GET /users       - List users"
  puts "  GET /users/1     - Get specific user"
  puts "  GET /docs        - Swagger UI documentation"
  puts "  GET /openapi.json - OpenAPI specification"
  puts ""
  puts "🧪 Test commands:"
  puts "  curl http://localhost:3000/health"
  puts "  curl http://localhost:3000/users"
  puts "  curl http://localhost:3000/users/1"
  puts ""
  
  begin
    require 'webrick'
    Rack::Handler::WEBrick.run(Rails.application, Port: 3000)
  rescue LoadError
    puts "❌ WEBrick not available. Install with: gem install webrick"
    puts "Or use another server like Puma"
  end
end
