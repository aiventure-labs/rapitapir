# frozen_string_literal: true

# Minimal runnable Rails application demonstrating RapiTapir integration
# This shows the traditional Rails app structure in a single file for easy testing

require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'
  gem 'rails', '~> 8.0'
  gem 'sqlite3'
  gem 'puma'
end

require 'rails/all'
require_relative '../../../lib/rapitapir'

# Simulate ActiveRecord models for the demo
class User < ActiveRecord::Base
  validates :email, presence: true, uniqueness: true
  validates :name, presence: true
end

class Post < ActiveRecord::Base
  belongs_to :user
  validates :title, presence: true
  validates :content, presence: true
end

# Rails Application Setup
class TraditionalApp < Rails::Application
  config.load_defaults 8.0
  config.api_only = true
  config.eager_load = false
  config.logger = Logger.new(STDOUT)
  config.log_level = :info
  config.secret_key_base = 'demo_secret_key_base_for_traditional_app_example'
  
  # Rails 8 specific configurations
  config.autoload_lib(ignore: %w[assets tasks])
end

Rails.application.initialize!

# Database setup
ActiveRecord::Base.establish_connection(
  adapter: 'sqlite3',
  database: ':memory:'
)

# Create tables
ActiveRecord::Schema.define do
  create_table :users do |t|
    t.string :name, null: false
    t.string :email, null: false
    t.text :bio
    t.timestamps
  end
  
  create_table :posts do |t|
    t.references :user, null: false, foreign_key: true
    t.string :title, null: false
    t.text :content, null: false
    t.boolean :published, default: false
    t.timestamps
  end
  
  add_index :users, :email, unique: true
end

# Seed some data
user1 = User.create!(name: "Alice Johnson", email: "alice@example.com", bio: "Tech blogger")
user2 = User.create!(name: "Bob Smith", email: "bob@example.com", bio: "Developer")

Post.create!(
  user: user1,
  title: "Getting Started with RapiTapir",
  content: "RapiTapir makes API development in Ruby a breeze...",
  published: true
)

Post.create!(
  user: user2,
  title: "Rails + RapiTapir Best Practices",
  content: "Here are some patterns I've learned...",
  published: true
)

# ApplicationController - Base controller with health check
class ApplicationController < RapiTapir::Server::Rails::ControllerBase
  # Global configuration for all controllers
  rapitapir do
    # Enable development features (automatic docs, etc.)
    development_defaults!
    
    # Global error handling
    error_out(json_body(error: T.string, details: T.string.optional), 500)
    error_out(json_body(error: T.string), 401)
    error_out(json_body(error: T.string), 403)
    error_out(json_body(error: T.string), 404)
    error_out(json_body(error: T.string, errors: T.array(T.string).optional), 422)
    
    # Health check endpoint - no separate controller needed!
    GET('/health')
      .out(json_body(
        status: T.string,
        timestamp: T.string,
        version: T.string,
        environment: T.string,
        database: T.string,
        services: T.hash(redis: T.string)
      ))
      .summary("Health check")
      .description("Check API and service health")
      .tag("System")
  end
  
  def health_check
    {
      status: 'ok',
      timestamp: Time.current.iso8601,
      version: '1.0.0',
      environment: Rails.env,
      database: database_status,
      services: {
        redis: redis_status
      }
    }
  end
  
  protected
  
  # Helper method for standardized error responses
  def render_error(message, status, details: nil, errors: nil)
    payload = { error: message }
    payload[:details] = details if details
    payload[:errors] = errors if errors
    
    render json: payload, status: status
  end
  
  # Helper for pagination metadata
  def pagination_metadata(collection, page, per_page)
    total = collection.respond_to?(:count) ? collection.count : collection.size
    {
      page: page,
      per_page: per_page,
      total: total,
      total_pages: (total.to_f / per_page).ceil,
      has_next: page < (total.to_f / per_page).ceil,
      has_prev: page > 1
    }
  end
  
  private
  
  def database_status
    ActiveRecord::Base.connection.execute('SELECT 1')
    'connected'
  rescue => e
    Rails.logger.error "Database check failed: #{e.message}"
    'disconnected'
  end
  
  def redis_status
    'not_configured'
  rescue => e
    Rails.logger.error "Redis check failed: #{e.message}"
    'disconnected'
  end
end

# Api::V1::UsersController - Example API controller
class Api::V1::UsersController < ApplicationController
  rapitapir do
    # User type definitions
    user_type = T.hash(
      id: T.integer,
      email: T.string,
      name: T.string,
      bio: T.string.optional,
      created_at: T.string,
      updated_at: T.string
    )
    
    # List users with pagination
    GET('/api/v1/users')
      .in(query(:page, T.integer.default(1)))
      .in(query(:per_page, T.integer.default(10)))
      .out(json_body(
        users: T.array(user_type),
        pagination: T.hash(
          page: T.integer,
          per_page: T.integer,
          total: T.integer,
          total_pages: T.integer
        )
      ))
      .summary("List users")
      .description("Get a paginated list of all users")
      .tag("Users")
    
    # Get specific user
    GET('/api/v1/users/:id')
      .in(path(:id, T.integer))
      .out(json_body(user: user_type))
      .error_out(json_body(error: T.string), 404)
      .summary("Get user by ID")
      .tag("Users")
    
    # Create new user
    POST('/api/v1/users')
      .in(json_body(
        name: T.string,
        email: T.string,
        bio: T.string.optional
      ))
      .out(json_body(user: user_type), 201)
      .error_out(json_body(errors: T.array(T.string)), 422)
      .summary("Create a new user")
      .tag("Users")
  end
  
  def list_users
    page = inputs[:page]
    per_page = [inputs[:per_page], 50].min # Cap at 50
    
    users_scope = User.all
    total = users_scope.count
    users = users_scope.offset((page - 1) * per_page).limit(per_page)
    
    {
      users: users.map(&method(:serialize_user)),
      pagination: pagination_metadata(users_scope, page, per_page)
    }
  end
  
  def get_user
    user = User.find_by(id: inputs[:id])
    return render_error("User not found", 404) unless user
    
    { user: serialize_user(user) }
  end
  
  def create_user
    user = User.new(user_params)
    
    if user.save
      render json: { user: serialize_user(user) }, status: 201
    else
      render_error("Validation failed", 422, errors: user.errors.full_messages)
    end
  end
  
  private
  
  def user_params
    inputs.slice(:name, :email, :bio).compact
  end
  
  def serialize_user(user)
    {
      id: user.id,
      name: user.name,
      email: user.email,
      bio: user.bio,
      created_at: user.created_at.iso8601,
      updated_at: user.updated_at.iso8601
    }
  end
end

# Api::V1::PostsController - Posts API
class Api::V1::PostsController < ApplicationController
  rapitapir do
    # Post schema
    post_type = T.hash(
      id: T.integer,
      title: T.string,
      content: T.string,
      published: T.boolean,
      user: T.hash(
        id: T.integer,
        name: T.string,
        email: T.string
      ),
      created_at: T.string,
      updated_at: T.string
    )
    
    # List posts
    GET('/api/v1/posts')
      .in(query(:published, T.boolean.optional))
      .in(query(:page, T.integer.default(1)))
      .out(json_body(
        posts: T.array(post_type),
        pagination: T.hash(
          page: T.integer,
          total: T.integer,
          total_pages: T.integer
        )
      ))
      .summary("List posts")
      .tag("Posts")
    
    # Get specific post
    GET('/api/v1/posts/:id')
      .in(path(:id, T.integer))
      .out(json_body(post: post_type))
      .error_out(json_body(error: T.string), 404)
      .summary("Get post by ID")
      .tag("Posts")
  end
  
  def list_posts
    posts_scope = Post.includes(:user)
    
    # Apply filters
    posts_scope = posts_scope.where(published: inputs[:published]) if inputs.key?(:published)
    
    # Pagination
    page = inputs[:page]
    per_page = 10
    total = posts_scope.count
    posts = posts_scope.offset((page - 1) * per_page).limit(per_page)
    
    {
      posts: posts.map(&method(:serialize_post)),
      pagination: pagination_metadata(posts_scope, page, per_page)
    }
  end
  
  def get_post
    post = Post.includes(:user).find_by(id: inputs[:id])
    return render_error("Post not found", 404) unless post
    
    { post: serialize_post(post) }
  end
  
  private
  
  def serialize_post(post)
    {
      id: post.id,
      title: post.title,
      content: post.content,
      published: post.published,
      user: {
        id: post.user.id,
        name: post.user.name,
        email: post.user.email
      },
      created_at: post.created_at.iso8601,
      updated_at: post.updated_at.iso8601
    }
  end
end

# Application routing
Rails.application.routes.draw do
  # Health check (from ApplicationController)
  rapitapir_routes_for ApplicationController
  
  # API v1 routes - RapiTapir auto-generates routes from endpoint definitions
  namespace :api do
    namespace :v1 do
      rapitapir_routes_for Api::V1::UsersController
      rapitapir_routes_for Api::V1::PostsController
    end
  end
  
  # Documentation routes (automatically added by development_defaults!)
  # Available at:
  # - GET /docs          -> Swagger UI
  # - GET /openapi.json  -> OpenAPI 3.0 specification
  
  # Catch-all for unmatched routes
  match '*path', to: proc { |env|
    [404, { 'Content-Type' => 'application/json' }, [{ error: 'Route not found' }.to_json]]
  }, via: :all
end

# Start the server
if __FILE__ == $0
  puts "🚀 Starting Traditional Rails App with RapiTapir on http://localhost:3000"
  puts "📚 API Documentation: http://localhost:3000/docs"
  puts "📋 OpenAPI Spec: http://localhost:3000/openapi.json"
  puts "🏥 Health Check: http://localhost:3000/health"
  puts ""
  puts "📋 Available Endpoints:"
  puts "  GET    /health              - System health check"
  puts "  GET    /api/v1/users        - List users"
  puts "  GET    /api/v1/users/1      - Get specific user"
  puts "  POST   /api/v1/users        - Create new user"
  puts "  GET    /api/v1/posts        - List posts"
  puts "  GET    /api/v1/posts/1      - Get specific post"
  puts ""
  puts "🧪 Test Examples:"
  puts "  curl http://localhost:3000/health"
  puts "  curl http://localhost:3000/api/v1/users"
  puts "  curl http://localhost:3000/api/v1/posts?published=true"
  puts ""
  
  require 'rack'
  Rack::Handler::WEBrick.run(Rails.application, Port: 3000)
end
