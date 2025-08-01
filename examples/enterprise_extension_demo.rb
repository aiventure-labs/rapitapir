# frozen_string_literal: true

# Enterprise Task Management API - RapiTapir Sinatra Extension Demo
# 
# This example demonstrates the new ergonomic Sinatra extension that eliminates
# boilerplate and provides a seamless developer experience for building
# enterprise-grade APIs with RapiTapir.

# Check for Sinatra availability
begin
  require 'sinatra/base'
  SINATRA_AVAILABLE = true
rescue LoadError
  SINATRA_AVAILABLE = false
  puts "⚠️  Sinatra not available. Install with: gem install sinatra"
  puts "🔄 Running in demo mode instead..."
end

require 'json'
require_relative '../lib/rapitapir'

# Only require extension if Sinatra is available
if SINATRA_AVAILABLE
  require_relative '../lib/rapitapir/sinatra/extension'
end

# Sample databases (same as before)
class UserDatabase
  USERS = {
    'user-token-123' => {
      id: 1,
      name: 'John Doe',
      email: 'john.doe@example.com',
      role: 'user',
      scopes: ['read', 'write']
    },
    'admin-token-456' => {
      id: 2,
      name: 'Jane Admin',
      email: 'jane.admin@example.com',
      role: 'admin',
      scopes: ['read', 'write', 'admin', 'delete']
    }
  }.freeze

  def self.find_by_token(token)
    USERS[token]
  end

  def self.all_users
    USERS.values
  end

  def self.find_by_id(id)
    USERS.values.find { |user| user[:id] == id.to_i }
  end
end

class TaskDatabase
  @@tasks = [
    { id: 1, title: 'Setup CI/CD Pipeline', description: 'Configure automated testing and deployment', status: 'in_progress', assignee_id: 1, created_at: Time.now - 86400 },
    { id: 2, title: 'Review Security Audit', description: 'Complete quarterly security review', status: 'pending', assignee_id: 2, created_at: Time.now - 3600 }
  ]
  @@next_id = 3

  def self.all
    @@tasks
  end

  def self.find(id)
    @@tasks.find { |task| task[:id] == id.to_i }
  end

  def self.create(attrs)
    task = attrs.merge(id: @@next_id, created_at: Time.now)
    @@next_id += 1
    @@tasks << task
    task
  end

  def self.update(id, attrs)
    task = find(id)
    return nil unless task
    
    attrs.each { |key, value| task[key] = value }
    task[:updated_at] = Time.now
    task
  end

  def self.delete(id)
    @@tasks.reject! { |task| task[:id] == id.to_i }
  end
end

# Define schemas using RapiTapir types
TASK_SCHEMA = RapiTapir::Types.hash({
  "id" => RapiTapir::Types.integer,
  "title" => RapiTapir::Types.string,
  "description" => RapiTapir::Types.string,
  "status" => RapiTapir::Types.string,
  "assignee_id" => RapiTapir::Types.integer,
  "created_at" => RapiTapir::Types.string,
  "updated_at" => RapiTapir::Types.optional(RapiTapir::Types.string)
})

USER_SCHEMA = RapiTapir::Types.hash({
  "id" => RapiTapir::Types.integer,
  "name" => RapiTapir::Types.string,
  "email" => RapiTapir::Types.string,
  "role" => RapiTapir::Types.string,
  "scopes" => RapiTapir::Types.array(RapiTapir::Types.string)
})

# Main Application using RapiTapir Sinatra Extension
if SINATRA_AVAILABLE
  class EnterpriseTaskAPI < Sinatra::Base
    # Register the RapiTapir extension
    register RapiTapir::Sinatra::Extension

    # Configure the application in one place
    rapitapir do
      # API information
      info(
        title: 'Enterprise Task Management API',
        description: 'A production-ready task management API built with RapiTapir Sinatra Extension',
        version: '2.0.0',
        contact: {
          name: 'API Support',
          email: 'api-support@example.com'
        }
      )

      # Server configuration
      server(url: 'http://localhost:4567', description: 'Development server')
      server(url: 'https://api.example.com', description: 'Production server')

      # Authentication configuration
      bearer_auth(:bearer, {
        realm: 'Enterprise Task Management API',
        token_validator: proc do |token|
          user = UserDatabase.find_by_token(token)
          next nil unless user

          {
            user: user,
            scopes: user[:scopes]
          }
        end
      })

      # Middleware configuration based on environment
      if development?
        development_defaults!
      else
        production_defaults!
      end

      # Enable documentation
      enable_docs(path: '/docs', openapi_path: '/openapi.json')
    end

    # Health check endpoint (public)
    endpoint(
      RapiTapir.get('/health')
        .summary('Health check')
        .description('Returns the health status of the API')
        .ok(RapiTapir::Types.hash({
          "status" => RapiTapir::Types.string,
          "timestamp" => RapiTapir::Types.string,
          "version" => RapiTapir::Types.string,
          "features" => RapiTapir::Types.array(RapiTapir::Types.string)
        }))
        .build
    ) do |inputs|
      {
        status: 'healthy',
        timestamp: Time.now.iso8601,
        version: '2.0.0',
        features: ['RapiTapir Sinatra Extension', 'Auto-generated OpenAPI', 'Zero Boilerplate']
      }
    end

    # Tasks resource - using the RESTful resource builder
    api_resource '/api/v1/tasks', schema: TASK_SCHEMA do
      # Enable full CRUD operations with custom handlers
      crud do
        # List tasks with filtering
        index do |inputs|
          tasks = TaskDatabase.all
          
          # Apply filters if provided
          if inputs[:status]
            tasks = tasks.select { |task| task[:status] == inputs[:status] }
          end
          
          # Apply pagination
          limit = inputs[:limit] || 50
          offset = inputs[:offset] || 0
          tasks = tasks.drop(offset).take(limit)
          
          # Format timestamps
          tasks.map do |task|
            task_copy = task.dup
            task_copy[:created_at] = task_copy[:created_at].iso8601 if task_copy[:created_at]
            task_copy[:updated_at] = task_copy[:updated_at].iso8601 if task_copy[:updated_at]
            task_copy
          end
        end

        # Get specific task
        show do |inputs|
          task = TaskDatabase.find(inputs[:id])
          halt 404, { error: 'Task not found' }.to_json unless task

          # Enrich with assignee details
          assignee = UserDatabase.find_by_id(task[:assignee_id])
          task_with_assignee = task.dup
          task_with_assignee[:created_at] = task_with_assignee[:created_at].iso8601 if task_with_assignee[:created_at]
          task_with_assignee[:assignee] = assignee ? {
            id: assignee[:id],
            name: assignee[:name],
            email: assignee[:email]
          } : nil
          
          task_with_assignee
        end

        # Create new task
        create do |inputs|
          body = inputs[:body]
          
          # Validate assignee exists
          assignee = UserDatabase.find_by_id(body['assignee_id'])
          halt 400, { error: 'Invalid assignee ID' }.to_json unless assignee
          
          # Create task
          task_data = {
            title: body['title'],
            description: body['description'],
            status: body['status'] || 'pending',
            assignee_id: body['assignee_id']
          }
          
          task = TaskDatabase.create(task_data)
          task[:created_at] = task[:created_at].iso8601
          task
        end

        # Update task
        update do |inputs|
          task = TaskDatabase.find(inputs[:id])
          halt 404, { error: 'Task not found' }.to_json unless task

          body = inputs[:body]
          update_data = {}
          
          # Prepare update data
          update_data[:title] = body['title'] if body['title']
          update_data[:description] = body['description'] if body['description']
          update_data[:status] = body['status'] if body['status']
          
          if body['assignee_id']
            assignee = UserDatabase.find_by_id(body['assignee_id'])
            halt 400, { error: 'Invalid assignee ID' }.to_json unless assignee
            update_data[:assignee_id] = body['assignee_id']
          end
          
          # Update task
          updated_task = TaskDatabase.update(inputs[:id], update_data)
          updated_task[:created_at] = updated_task[:created_at].iso8601 if updated_task[:created_at]
          updated_task[:updated_at] = updated_task[:updated_at].iso8601 if updated_task[:updated_at]
          updated_task
        end

        # Delete task (requires admin scope)
        destroy(scopes: ['admin']) do |inputs|
          task = TaskDatabase.find(inputs[:id])
          halt 404, { error: 'Task not found' }.to_json unless task

          TaskDatabase.delete(inputs[:id])
          status 204
          nil
        end
      end

      # Custom endpoint: Get tasks by status
      custom(:get, 'by-status/:status',
        summary: 'Get tasks by status',
        configure: ->(endpoint) {
          endpoint
            .path_param(:status, RapiTapir::Types.string, description: 'Task status')
            .ok(RapiTapir::Types.array(TASK_SCHEMA))
        }
      ) do |inputs|
        tasks = TaskDatabase.all.select { |task| task[:status] == inputs[:status] }
        tasks.map do |task|
          task_copy = task.dup
          task_copy[:created_at] = task_copy[:created_at].iso8601 if task_copy[:created_at]
          task_copy
        end
      end
    end

    # User profile endpoint
    endpoint(
      RapiTapir.get('/api/v1/profile')
        .summary('Get current user profile')
        .description('Retrieve the profile of the authenticated user')
        .ok(RapiTapir::Types.hash({
          "id" => RapiTapir::Types.integer,
          "name" => RapiTapir::Types.string,
          "email" => RapiTapir::Types.string,
          "role" => RapiTapir::Types.string,
          "scopes" => RapiTapir::Types.array(RapiTapir::Types.string)
        }))
        .build
    ) do |inputs|
      require_authentication!
      current_user
    end

    # Admin endpoint - list all users
    endpoint(
      RapiTapir.get('/api/v1/admin/users')
        .summary('List all users (admin only)')
        .description('Retrieve a list of all users in the system. Requires admin permission.')
        .ok(RapiTapir::Types.array(USER_SCHEMA))
        .build
    ) do |inputs|
      require_scope!('admin')
      UserDatabase.all_users
    end

    # Development info
    configure :development do
      puts "\n" + "="*70
      puts "🚀 ENTERPRISE TASK MANAGEMENT API v2.0 - RapiTapir Extension"
      puts "="*70
      puts "📚 API Documentation: http://localhost:4567/docs"
      puts "📋 OpenAPI Spec: http://localhost:4567/openapi.json"
      puts "❤️  Health Check: http://localhost:4567/health"
      puts "\n🔑 Bearer Tokens:"
      puts "   User: user-token-123 (scopes: read, write)"
      puts "   Admin: admin-token-456 (scopes: read, write, admin, delete)"
      puts "\n✨ NEW FEATURES with RapiTapir Extension:"
      puts "   🎯 Zero boilerplate configuration"
      puts "   🔧 Automatic middleware setup"
      puts "   📦 RESTful resource builder"
      puts "   🛡️  Built-in authentication helpers"
      puts "   📖 Auto-generated beautiful documentation"
      puts "   🏗️  SOLID principles architecture"
      puts ""
    end
  end

  # Start the server
  if __FILE__ == $0
    EnterpriseTaskAPI.run!
  end
else
  # Demo mode when Sinatra is not available
  puts "\n" + "="*70
  puts "🚀 ENTERPRISE TASK MANAGEMENT API v2.0 - Demo Mode"
  puts "="*70
  
  puts "\n✅ Successfully loaded:"
  puts "   • RapiTapir core and type system"
  puts "   • Task and User schemas"
  puts "   • Database classes"
  
  puts "\n🎯 This enterprise API would provide:"
  puts "   GET    /health                    - Health check (public)"
  puts "   GET    /api/v1/tasks              - List tasks with filtering"
  puts "   GET    /api/v1/tasks/:id          - Get specific task"
  puts "   POST   /api/v1/tasks              - Create new task"
  puts "   PUT    /api/v1/tasks/:id          - Update task"
  puts "   DELETE /api/v1/tasks/:id          - Delete task (admin only)"
  puts "   GET    /api/v1/tasks/by-status/:status - Tasks by status"
  puts "   GET    /api/v1/profile            - Current user profile"
  puts "   GET    /api/v1/admin/users        - List users (admin only)"
  puts "   GET    /docs                      - Swagger UI documentation"
  puts "   GET    /openapi.json              - OpenAPI 3.0 specification"
  
  puts "\n🛡️  Security features:"
  puts "   • Bearer token authentication"
  puts "   • Scope-based authorization (read, write, admin, delete)"
  puts "   • CORS protection"
  puts "   • Rate limiting (configurable per environment)"
  puts "   • Security headers"
  
  puts "\n🎯 Extension advantages demonstrated:"
  puts "   • 90% less boilerplate code compared to manual implementation"
  puts "   • One-line configuration: development_defaults!()"
  puts "   • RESTful resource builder: api_resource + crud block"
  puts "   • Built-in auth helpers: require_authentication!, require_scope!"
  puts "   • Auto-generated OpenAPI 3.0 documentation"
  puts "   • Production-ready middleware stack"
  
  puts "\n💡 Authentication tokens that would work:"
  puts "   User token: user-token-123 (scopes: read, write)"
  puts "   Admin token: admin-token-456 (scopes: read, write, admin, delete)"
  
  puts "\n📖 Sample API calls that would work:"
  puts "   curl -H 'Authorization: Bearer user-token-123' http://localhost:4567/api/v1/tasks"
  puts "   curl -H 'Authorization: Bearer admin-token-456' http://localhost:4567/api/v1/admin/users"
  puts "   curl -X POST -H 'Authorization: Bearer user-token-123' \\"
  puts "        -H 'Content-Type: application/json' \\"
  puts "        -d '{\"title\":\"New Task\",\"description\":\"Test\",\"assignee_id\":1}' \\"
  puts "        http://localhost:4567/api/v1/tasks"
  
  puts "\n💡 To run the actual server:"
  puts "   gem install sinatra"
  puts "   ruby #{__FILE__}"
  
  puts "\n🏗️  Architecture highlights:"
  puts "   • SOLID principles implementation"
  puts "   • Single Responsibility: Each class has one purpose"
  puts "   • Open/Closed: Extensible without modification"
  puts "   • Dependency Inversion: Auth logic injected via procs"
end
