# frozen_string_literal: true

require 'rapitapir'
require 'rapitapir/sinatra/extension'
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
    docs_enabled!
  end

  # Configure OAuth2 with token introspection
  # Environment variables:
  # OAUTH2_INTROSPECTION_ENDPOINT=https://your-oauth-server/introspect
  # OAUTH2_CLIENT_ID=your-client-id
  # OAUTH2_CLIENT_SECRET=your-client-secret
  oauth2_introspection(
    introspection_endpoint: ENV['OAUTH2_INTROSPECTION_ENDPOINT'],
    client_id: ENV['OAUTH2_CLIENT_ID'],
    client_secret: ENV['OAUTH2_CLIENT_SECRET'],
    cache_tokens: true,
    token_cache_ttl: 300 # 5 minutes
  )

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
      .tag('tasks')
      .build
  ) do
    TASKS.to_json
  end

  # Protected endpoints with different scope requirements
  endpoint(
    POST('/tasks')
      .summary('Create task')
      .description('Create a new task (requires write scope)')
      .with_oauth2_auth(scopes: ['write'])
      .body(CREATE_TASK_SCHEMA)
      .created(TASK_SCHEMA)
      .error_response(401, ERROR_SCHEMA)
      .error_response(403, ERROR_SCHEMA)
      .tag('tasks')
      .build
  ) do |inputs|
    authorize_oauth2!(required_scopes: ['write'])
    
    new_task = {
      id: TASKS.map { |t| t[:id] }.max + 1,
      title: inputs[:title],
      completed: inputs[:completed] || false
    }
    
    status 201
    new_task.to_json
  end

  endpoint(
    PUT('/tasks/:id')
      .summary('Update task')
      .description('Update a task (requires write scope)')
      .with_oauth2_auth(scopes: ['write'])
      .path_param(:id, T.integer(minimum: 1))
      .body(CREATE_TASK_SCHEMA)
      .ok(TASK_SCHEMA)
      .error_response(401, ERROR_SCHEMA)
      .error_response(403, ERROR_SCHEMA)
      .error_response(404, ERROR_SCHEMA)
      .tag('tasks')
      .build
  ) do |inputs|
    authorize_oauth2!(required_scopes: ['write'])
    
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
      .with_oauth2_auth(scopes: ['admin'])
      .path_param(:id, T.integer(minimum: 1))
      .ok(TASK_SCHEMA)
      .error_response(401, ERROR_SCHEMA)
      .error_response(403, ERROR_SCHEMA)
      .error_response(404, ERROR_SCHEMA)
      .tag('tasks')
      .build
  ) do |inputs|
    authorize_oauth2!(required_scopes: ['admin'])
    
    task = TASKS.find { |t| t[:id] == inputs[:id] }
    halt 404, { error: 'not_found' }.to_json unless task
    
    task.to_json
  end

  # User info endpoint
  endpoint(
    GET('/me')
      .summary('Get user info')
      .description('Get current user information')
      .with_oauth2_auth
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
      .tag('user')
      .build
  ) do
    context = authorize_oauth2!
    
    {
      user: context.user,
      scopes: context.scopes,
      client_id: context.metadata[:client_id]
    }.to_json
  end

  # Health check with authentication status
  get '/health' do
    content_type :json
    
    auth_status = if authenticated?
                    {
                      authenticated: true,
                      user_id: current_user[:id],
                      scopes: current_auth_context.scopes
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
