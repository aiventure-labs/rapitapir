# frozen_string_literal: true

require 'sinatra'
require_relative '../../lib/rapitapir'
require 'dotenv/load'

# Example Sinatra API with generic OAuth2 token introspection
# Demonstrates OAuth2 integration without Auth0-specific features
class GenericOAuth2API < SinatraRapiTapir
  rapitapir do
    info(
      title: 'Generic OAuth2 API',
      version: '1.0.0',
      description: 'Example API using OAuth2 token introspection'
    )
    
    development_defaults!
    enable_docs
  end

  # Configure OAuth2 with Auth0 (preferred) or generic introspection
  # For Auth0 testing, set AUTH0_DOMAIN and AUTH0_AUDIENCE
  # For generic OAuth2, set OAUTH2_INTROSPECTION_ENDPOINT, OAUTH2_CLIENT_ID, OAUTH2_CLIENT_SECRET
  
  if ENV['AUTH0_DOMAIN'] && ENV['AUTH0_AUDIENCE']
    # Use Auth0 JWT validation
    auth0_oauth2(
      domain: ENV['AUTH0_DOMAIN'],
      audience: ENV['AUTH0_AUDIENCE']
    )
    puts "🔒 Configured Auth0 OAuth2: #{ENV['AUTH0_DOMAIN']}"
  elsif ENV['OAUTH2_INTROSPECTION_ENDPOINT']
    # Use generic OAuth2 introspection
    oauth2_introspection(
      introspection_endpoint: ENV['OAUTH2_INTROSPECTION_ENDPOINT'],
      client_id: ENV['OAUTH2_CLIENT_ID'],
      client_secret: ENV['OAUTH2_CLIENT_SECRET']
    )
    puts "🔒 Configured Generic OAuth2: #{ENV['OAUTH2_INTROSPECTION_ENDPOINT']}"
  else
    puts "⚠️ No OAuth2 configuration found. Set AUTH0_DOMAIN+AUTH0_AUDIENCE or OAUTH2_* environment variables."
  end

  # Manually include OAuth2 helper methods to ensure they're available
  helpers RapiTapir::Sinatra::OAuth2HelperMethods

  # Debug: Check what methods are available
  puts "🔍 Available methods: #{self.methods.grep(/oauth/).join(', ')}"

  # Protect only POST routes (before filters in Sinatra apply to all methods by default)
  before '/tasks' do
    if request.post?
      authorize_oauth2!(required_scopes: ['write:tasks'])
    end
  end

  # Simple data model
  TASKS = [
    { id: 1, title: 'Learn OAuth2', completed: false },
    { id: 2, title: 'Implement API', completed: true },
    { id: 3, title: 'Write tests', completed: false }
  ]

  # Schemas
  TASK_SCHEMA = T.hash({
    'id' => T.integer(minimum: 1),
    'title' => T.string(min_length: 1, max_length: 200),
    'completed' => T.boolean
  })

  CREATE_TASK_SCHEMA = T.hash({
    'title' => T.string(min_length: 1, max_length: 200),
    'completed' => T.optional(T.boolean)
  })

  ERROR_SCHEMA = T.hash({
    'error' => T.string,
    'error_description' => T.optional(T.string)
  })

  # Public endpoint
  endpoint(
    GET('/tasks')
      .summary('List tasks')
      .description('Get all tasks (public endpoint)')
      .ok(T.array(TASK_SCHEMA))
      .tags('tasks')
      .build
  ) do
    TASKS.to_json
  end

  # Protected endpoints with different scope requirements
  endpoint(
    POST('/tasks')
      .summary('Create task')
      .description('Create a new task (requires write scope)')
      .body(CREATE_TASK_SCHEMA)
      .created(TASK_SCHEMA)
      .error_response(401, ERROR_SCHEMA)
      .error_response(403, ERROR_SCHEMA)
      .tags('tasks')
      .build
  ) do |inputs|
    # Authentication handled by route protection above
    
    new_task = {
      id: TASKS.map { |t| t[:id] }.max + 1,
      title: inputs[:title],
      completed: inputs[:completed] || false
    }
    
    TASKS << new_task  # Add to our in-memory store
    new_task.to_json
  end

  endpoint(
    PUT('/tasks/:id')
      .summary('Update task')
      .description('Update a task (requires write scope)')
      .path_param(:id, T.integer(minimum: 1))
      .body(CREATE_TASK_SCHEMA)
      .ok(TASK_SCHEMA)
      .error_response(401, ERROR_SCHEMA)
      .error_response(403, ERROR_SCHEMA)
      .error_response(404, ERROR_SCHEMA)
      .tags('tasks')
      .build
  ) do |inputs|
    authorize_oauth2!(required_scopes: ['write:tasks'])
    
    task = TASKS.find { |t| t[:id] == inputs[:id] }
    halt 404, { error: 'not_found' }.to_json unless task
    
    task[:title] = inputs[:title] if inputs[:title]
    task[:completed] = inputs[:completed] unless inputs[:completed].nil?
    
    task.to_json
  end

  endpoint(
    DELETE('/tasks/:id')
      .summary('Delete task')
      .description('Delete a task (requires admin scope)')
      .path_param(:id, T.integer(minimum: 1))
      .ok(TASK_SCHEMA)
      .error_response(401, ERROR_SCHEMA)
      .error_response(403, ERROR_SCHEMA)
      .error_response(404, ERROR_SCHEMA)
      .tags('tasks')
      .build
  ) do |inputs|
    authorize_oauth2!(required_scopes: ['write:tasks'])
    
    # Check for admin scope for delete operations
    auth_context = request.env['rapitapir.auth.context']
    unless auth_context && auth_context.scopes.include?('admin:tasks')
      halt 403, {
        error: 'insufficient_scope',
        error_description: 'Admin scope required for delete operations'
      }.to_json
    end
    
    task = TASKS.find { |t| t[:id] == inputs[:id] }
    halt 404, { error: 'not_found' }.to_json unless task
    
    task.to_json
  end

  # User info endpoint
  endpoint(
    GET('/me')
      .summary('Get user info')
      .description('Get current user information')
      .ok(T.hash({
        'user' => T.hash({
          'id' => T.string,
          'username' => T.optional(T.string),
          'email' => T.optional(T.string)
        }),
        'scopes' => T.array(T.string),
        'client_id' => T.string
      }))
      .error_response(401, ERROR_SCHEMA)
      .tags('user')
      .build
  ) do
    context = authorize_oauth2!
    
    {
      user: context.user,
      scopes: context.scopes,
      client_id: context.metadata[:client_id] || 'unknown'
    }.to_json
  end

  # Health check with authentication status
  get '/health' do
    content_type :json
    
    auth_context = request.env['rapitapir.auth.context']
    auth_status = if auth_context
                    {
                      authenticated: true,
                      user_id: auth_context.user[:id],
                      scopes: auth_context.scopes
                    }
                  else
                    { authenticated: false }
                  end
    
    {
      status: 'healthy',
      timestamp: Time.now.iso8601,
      auth: auth_status
    }.to_json
  end
end

if __FILE__ == $0
  puts "🚀 Starting Generic OAuth2 API..."
  puts "📖 Documentation: http://localhost:4567/docs"
  puts "❤️ Health check: http://localhost:4567/health"
  
  GenericOAuth2API.run!
end
