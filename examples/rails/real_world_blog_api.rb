# frozen_string_literal: true

# Real-world Rails API example demonstrating RapiTapir integration
# This simulates a blog API with users, posts, and comments

require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'
  gem 'rails', '~> 7.0'
  gem 'sqlite3'
  gem 'puma'
end

require 'rails/all'
require_relative '../../lib/rapitapir'

# Simulate ActiveRecord models
class User < ActiveRecord::Base
  has_many :posts, dependent: :destroy
  has_many :comments, dependent: :destroy
  
  validates :email, presence: true, uniqueness: true
  validates :name, presence: true
end

class Post < ActiveRecord::Base
  belongs_to :user
  has_many :comments, dependent: :destroy
  
  validates :title, presence: true
  validates :content, presence: true
end

class Comment < ActiveRecord::Base
  belongs_to :user
  belongs_to :post
  
  validates :content, presence: true
end

# Rails Application Setup
class BlogApiApp < Rails::Application
  config.api_only = true
  config.eager_load = false
  config.logger = Logger.new(STDOUT)
  config.log_level = :info
  
  # Database setup
  config.active_record.database_selector = { reading: :primary }
  config.active_record.database_resolver = ActiveRecord::Middleware::DatabaseSelector::Resolver
  config.active_record.database_resolver_context = ActiveRecord::Middleware::DatabaseSelector::Resolver::Session
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
  
  create_table :comments do |t|
    t.references :user, null: false, foreign_key: true
    t.references :post, null: false, foreign_key: true
    t.text :content, null: false
    t.timestamps
  end
  
  add_index :users, :email, unique: true
end

# Seed some data
user1 = User.create!(name: "Alice Johnson", email: "alice@example.com", bio: "Tech blogger")
user2 = User.create!(name: "Bob Smith", email: "bob@example.com", bio: "Developer")

post1 = Post.create!(
  user: user1,
  title: "Getting Started with RapiTapir",
  content: "RapiTapir makes API development in Ruby a breeze...",
  published: true
)

post2 = Post.create!(
  user: user1,
  title: "Advanced API Patterns",
  content: "Let's explore some advanced patterns...",
  published: false
)

Comment.create!(
  user: user2,
  post: post1,
  content: "Great article! Very helpful."
)

# RapiTapir Controllers
class UsersController < RapiTapir::Server::Rails::ControllerBase
  rapitapir do
    development_defaults!
    
    # User schema for responses
    user_schema = T.hash(
      id: T.integer,
      name: T.string,
      email: T.string,
      bio: T.string.optional,
      created_at: T.string,
      updated_at: T.string
    )
    
    # User list with pagination
    GET('/users')
      .in(query(:page, T.integer.default(1)))
      .in(query(:per_page, T.integer.default(10)))
      .out(json_body(
        users: T.array(user_schema),
        pagination: T.hash(
          page: T.integer,
          per_page: T.integer,
          total: T.integer,
          total_pages: T.integer
        )
      ))
      .summary("List all users")
      .description("Get a paginated list of all users")
    
    # Get specific user
    GET('/users/:id')
      .in(path(:id, T.integer))
      .out(json_body(user: user_schema))
      .error_out(json_body(error: T.string), 404)
      .summary("Get user by ID")
    
    # Create new user
    POST('/users')
      .in(json_body(
        name: T.string,
        email: T.string,
        bio: T.string.optional
      ))
      .out(json_body(user: user_schema), 201)
      .error_out(json_body(errors: T.array(T.string)), 422)
      .summary("Create a new user")
    
    # Update user
    PUT('/users/:id')
      .in(path(:id, T.integer))
      .in(json_body(
        name: T.string.optional,
        email: T.string.optional,
        bio: T.string.optional
      ))
      .out(json_body(user: user_schema))
      .error_out(json_body(error: T.string), 404)
      .error_out(json_body(errors: T.array(T.string)), 422)
      .summary("Update user")
    
    # Delete user
    DELETE('/users/:id')
      .in(path(:id, T.integer))
      .out(json_body(message: T.string))
      .error_out(json_body(error: T.string), 404)
      .summary("Delete user")
  end
  
  def list_users
    page = inputs[:page]
    per_page = [inputs[:per_page], 50].min # Cap at 50
    
    users_scope = User.all
    total = users_scope.count
    users = users_scope.offset((page - 1) * per_page).limit(per_page)
    
    {
      users: users.map(&method(:serialize_user)),
      pagination: {
        page: page,
        per_page: per_page,
        total: total,
        total_pages: (total.to_f / per_page).ceil
      }
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
      render json: { errors: user.errors.full_messages }, status: 422
    end
  end
  
  def update_user
    user = User.find_by(id: inputs[:id])
    return render_error("User not found", 404) unless user
    
    if user.update(user_params)
      { user: serialize_user(user) }
    else
      render json: { errors: user.errors.full_messages }, status: 422
    end
  end
  
  def delete_user
    user = User.find_by(id: inputs[:id])
    return render_error("User not found", 404) unless user
    
    user.destroy
    { message: "User deleted successfully" }
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
  
  def render_error(message, status)
    render json: { error: message }, status: status
  end
end

class PostsController < RapiTapir::Server::Rails::ControllerBase
  rapitapir do
    development_defaults!
    
    # Post schema
    post_schema = T.hash(
      id: T.integer,
      title: T.string,
      content: T.string,
      published: T.boolean,
      user_id: T.integer,
      user: T.hash(
        id: T.integer,
        name: T.string,
        email: T.string
      ),
      created_at: T.string,
      updated_at: T.string
    )
    
    # List posts with filtering
    GET('/posts')
      .in(query(:published, T.boolean.optional))
      .in(query(:user_id, T.integer.optional))
      .in(query(:page, T.integer.default(1)))
      .out(json_body(
        posts: T.array(post_schema),
        pagination: T.hash(
          page: T.integer,
          total: T.integer,
          total_pages: T.integer
        )
      ))
      .summary("List posts")
      .description("Get posts with optional filtering by published status and user")
    
    # Get specific post
    GET('/posts/:id')
      .in(path(:id, T.integer))
      .out(json_body(post: post_schema))
      .error_out(json_body(error: T.string), 404)
      .summary("Get post by ID")
    
    # Create post
    POST('/posts')
      .in(json_body(
        title: T.string,
        content: T.string,
        published: T.boolean.default(false),
        user_id: T.integer
      ))
      .out(json_body(post: post_schema), 201)
      .error_out(json_body(errors: T.array(T.string)), 422)
      .summary("Create a new post")
    
    # Update post
    PUT('/posts/:id')
      .in(path(:id, T.integer))
      .in(json_body(
        title: T.string.optional,
        content: T.string.optional,
        published: T.boolean.optional
      ))
      .out(json_body(post: post_schema))
      .error_out(json_body(errors: T.array(T.string)), 422)
      .summary("Update post")
  end
  
  def list_posts
    posts_scope = Post.includes(:user)
    
    # Apply filters
    posts_scope = posts_scope.where(published: inputs[:published]) if inputs[:published]
    posts_scope = posts_scope.where(user_id: inputs[:user_id]) if inputs[:user_id]
    
    # Pagination
    page = inputs[:page]
    per_page = 10
    total = posts_scope.count
    posts = posts_scope.offset((page - 1) * per_page).limit(per_page)
    
    {
      posts: posts.map(&method(:serialize_post)),
      pagination: {
        page: page,
        total: total,
        total_pages: (total.to_f / per_page).ceil
      }
    }
  end
  
  def get_post
    post = Post.includes(:user).find_by(id: inputs[:id])
    return render_error("Post not found", 404) unless post
    
    { post: serialize_post(post) }
  end
  
  def create_post
    post = Post.new(post_params)
    
    if post.save
      render json: { post: serialize_post(post.reload) }, status: 201
    else
      render json: { errors: post.errors.full_messages }, status: 422
    end
  end
  
  def update_post
    post = Post.find_by(id: inputs[:id])
    return render_error("Post not found", 404) unless post
    
    if post.update(post_params.compact)
      { post: serialize_post(post.reload) }
    else
      render json: { errors: post.errors.full_messages }, status: 422
    end
  end
  
  private
  
  def post_params
    inputs.slice(:title, :content, :published, :user_id)
  end
  
  def serialize_post(post)
    {
      id: post.id,
      title: post.title,
      content: post.content,
      published: post.published,
      user_id: post.user_id,
      user: {
        id: post.user.id,
        name: post.user.name,
        email: post.user.email
      },
      created_at: post.created_at.iso8601,
      updated_at: post.updated_at.iso8601
    }
  end
  
  def render_error(message, status)
    render json: { error: message }, status: status
  end
end

# Application routing
Rails.application.routes.draw do
  # Mount RapiTapir controllers
  rapitapir_routes_for UsersController
  rapitapir_routes_for PostsController
  
  # Health check
  get '/health', to: proc { |env| [200, {}, ['OK']] }
  
  # API documentation
  get '/docs', to: proc { |env|
    [200, { 'Content-Type' => 'text/html' }, [generate_docs_html]]
  }
  
  get '/openapi.json', to: proc { |env|
    [200, { 'Content-Type' => 'application/json' }, [generate_openapi_spec]]
  }
end

def generate_docs_html
  <<~HTML
    <!DOCTYPE html>
    <html>
    <head>
      <title>Blog API Documentation</title>
      <link rel="stylesheet" type="text/css" href="https://unpkg.com/swagger-ui-dist@3.25.0/swagger-ui.css" />
    </head>
    <body>
      <div id="swagger-ui"></div>
      <script src="https://unpkg.com/swagger-ui-dist@3.25.0/swagger-ui-bundle.js"></script>
      <script>
        SwaggerUIBundle({
          url: '/openapi.json',
          dom_id: '#swagger-ui',
          presets: [
            SwaggerUIBundle.presets.apis,
            SwaggerUIBundle.presets.standalone
          ]
        });
      </script>
    </body>
    </html>
  HTML
end

def generate_openapi_spec
  require 'json'
  
  spec = {
    openapi: "3.0.0",
    info: {
      title: "Blog API",
      version: "1.0.0",
      description: "A real-world blog API built with RapiTapir and Rails"
    },
    servers: [
      { url: "http://localhost:3000", description: "Development server" }
    ],
    paths: {}
  }
  
  # Add endpoints from controllers
  [UsersController, PostsController].each do |controller|
    controller.endpoints.each do |endpoint|
      path_key = endpoint.path.gsub(/:(\w+)/, '{\1}')
      method = endpoint.method.downcase
      
      spec[:paths][path_key] ||= {}
      spec[:paths][path_key][method] = {
        summary: endpoint.summary || "#{method.upcase} #{path_key}",
        description: endpoint.description || "",
        responses: {
          "200" => { description: "Success" }
        }
      }
    end
  end
  
  JSON.pretty_generate(spec)
end

# Start the server
if __FILE__ == $0
  puts "🚀 Starting Blog API server on http://localhost:3000"
  puts "📚 API Documentation: http://localhost:3000/docs"
  puts "📋 OpenAPI Spec: http://localhost:3000/openapi.json"
  puts ""
  puts "Sample endpoints:"
  puts "  GET    /users              - List users"
  puts "  POST   /users              - Create user"
  puts "  GET    /users/1            - Get user"
  puts "  PUT    /users/1            - Update user"
  puts "  DELETE /users/1            - Delete user"
  puts "  GET    /posts              - List posts"
  puts "  GET    /posts?published=true&user_id=1"
  puts "  POST   /posts              - Create post"
  puts "  GET    /posts/1            - Get post"
  puts "  PUT    /posts/1            - Update post"
  puts ""
  
  require 'rack'
  Rack::Handler::WEBrick.run(Rails.application, Port: 3000)
end
