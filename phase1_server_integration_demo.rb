# frozen_string_literal: true

require_relative 'lib/rapitapir'
require_relative 'lib/rapitapir/core/enhanced_endpoint'
require_relative 'lib/rapitapir/server/enhanced_rack_adapter'
require_relative 'lib/rapitapir/server/sinatra_integration'

puts "🚀 RapiTapir Phase 1.2 Demo - Server Integration Foundation"
puts "=" * 70

# 1. Create enhanced endpoints with the new type system
puts "\n1. 📝 Creating Enhanced Endpoints"
puts "-" * 35

# User schema for our API
user_schema = RapiTapir::Schema.define do
  field :id, :uuid
  field :name, :string
  field :email, :email
  field :age, :integer, required: false
end

create_user_schema = RapiTapir::Schema.define do
  field :name, :string
  field :email, :email
  field :age, :integer, required: false
end

error_schema = RapiTapir::Schema.define do
  field :error, :string
  field :message, :string
  field :code, :integer
end

# Create enhanced endpoints with proper DSL usage
get_users_endpoint = RapiTapir::Core::EnhancedEndpoint.new(method: :get, path: '/users')
get_users_endpoint = get_users_endpoint.query(:limit, RapiTapir::Types.integer(min: 1, max: 100), required: false, description: "Maximum number of users to return")
get_users_endpoint = get_users_endpoint.query(:offset, RapiTapir::Types.integer(min: 0), required: false, description: "Number of users to skip")
get_users_endpoint = get_users_endpoint.json_response(200, RapiTapir::Types.array(user_schema))
get_users_endpoint.summary = "List all users"
get_users_endpoint.description = "Retrieve a paginated list of users"

get_user_endpoint = RapiTapir::Core::EnhancedEndpoint.new(method: :get, path: '/users/{id}')
get_user_endpoint = get_user_endpoint.path_param(:id, RapiTapir::Types.uuid, description: "User ID")
get_user_endpoint = get_user_endpoint.json_response(200, user_schema)
get_user_endpoint = get_user_endpoint.error_response(404, error_schema, description: "User not found")
get_user_endpoint.summary = "Get user by ID"
get_user_endpoint.description = "Retrieve a specific user by their ID"

create_user_endpoint = RapiTapir::Core::EnhancedEndpoint.new(method: :post, path: '/users')
create_user_endpoint = create_user_endpoint.json_body(create_user_schema)
create_user_endpoint = create_user_endpoint.json_response(201, user_schema)
create_user_endpoint = create_user_endpoint.error_response(400, error_schema, description: "Invalid input")
create_user_endpoint.summary = "Create a new user"
create_user_endpoint.description = "Create a new user with the provided data"

# Endpoint with authentication  
protected_endpoint = RapiTapir::Core::EnhancedEndpoint.new(method: :get, path: '/users/me')
protected_endpoint = protected_endpoint.bearer_auth("Bearer token required")
protected_endpoint = protected_endpoint.json_response(200, user_schema)
protected_endpoint = protected_endpoint.error_response(401, error_schema, description: "Unauthorized")
protected_endpoint.summary = "Get current user"
protected_endpoint.description = "Get the currently authenticated user's profile"

puts "✅ Created 4 enhanced endpoints with type validation"
puts "   - GET /users (with pagination)"
puts "   - GET /users/{id} (with UUID validation)"
puts "   - POST /users (with request body validation)"
puts "   - GET /users/me (with authentication)"

# 2. Set up the enhanced Rack adapter
puts "\n2. 🔧 Setting Up Enhanced Rack Adapter"
puts "-" * 40

adapter = RapiTapir::Server::EnhancedRackAdapter.new

# Mock data store
users_db = [
  {
    id: '123e4567-e89b-12d3-a456-426614174000',
    name: 'John Doe',
    email: 'john@example.com',
    age: 30
  },
  {
    id: '987fcdeb-51a2-4567-8901-abcdef123456',
    name: 'Jane Smith',
    email: 'jane@example.com',
    age: 25
  }
]

# Mount the endpoints with handlers
adapter.mount(get_users_endpoint) do |params|
  limit = params[:limit] || 10
  offset = params[:offset] || 0
  
  users_db.slice(offset, limit)
end

adapter.mount(get_user_endpoint) do |params|
  user = users_db.find { |u| u[:id] == params[:id] }
  
  if user
    user
  else
    # This will trigger a 404 error response
    raise StandardError, "User not found"
  end
end

adapter.mount(create_user_endpoint) do |params|
  new_user = {
    id: SecureRandom.uuid,
    name: params[:name],
    email: params[:email],
    age: params[:age]
  }
  
  users_db << new_user
  new_user
end

adapter.mount(protected_endpoint) do |params|
  # In a real app, you'd validate the token
  # For demo, we'll just return the first user
  users_db.first
end

# Add custom error handling
adapter.on_error(StandardError) do |error|
  case error.message
  when "User not found"
    {
      error: "Not Found",
      message: "The requested user was not found",
      code: 404
    }
  else
    {
      error: error.class.name,
      message: error.message,
      code: 500
    }
  end
end

puts "✅ Mounted all endpoints with handlers"
puts "✅ Added custom error handling"

# 3. Demonstrate request processing
puts "\n3. 🔄 Request Processing with Type Validation"
puts "-" * 45

# Simulate request processing (without actually starting a server)
def simulate_request(adapter, method, path, params = {}, headers = {}, body = nil)
  env = {
    'REQUEST_METHOD' => method.to_s.upcase,
    'PATH_INFO' => path,
    'QUERY_STRING' => params.map { |k, v| "#{k}=#{v}" }.join('&'),
    'rack.input' => StringIO.new(body.to_s),
    'CONTENT_TYPE' => 'application/json'
  }
  
  headers.each do |key, value|
    env["HTTP_#{key.to_s.upcase.gsub('-', '_')}"] = value
  end
  
  begin
    status, response_headers, response_body = adapter.call(env)
    {
      status: status,
      headers: response_headers,
      body: response_body.first
    }
  rescue => e
    {
      error: e.message,
      class: e.class.name
    }
  end
end

# Test 1: Valid GET request with query parameters
puts "\nTest 1: GET /users?limit=1&offset=0"
response = simulate_request(adapter, :get, '/users', { limit: 1, offset: 0 })
puts "✅ Status: #{response[:status]}"
puts "✅ Response: #{response[:body]}"

# Test 2: Valid GET request with path parameter
puts "\nTest 2: GET /users/{valid-uuid}"
valid_uuid = '123e4567-e89b-12d3-a456-426614174000'
response = simulate_request(adapter, :get, "/users/#{valid_uuid}")
puts "✅ Status: #{response[:status]}"
puts "✅ Response: #{response[:body]}"

# Test 3: Invalid UUID format
puts "\nTest 3: GET /users/{invalid-uuid}"
response = simulate_request(adapter, :get, '/users/invalid-uuid')
puts "❌ Status: #{response[:status] || 'Error'}"
puts "❌ Error: #{response[:error] || response[:body]}"

# Test 4: Valid POST request
puts "\nTest 4: POST /users with valid data"
valid_user_data = {
  name: 'Bob Wilson',
  email: 'bob@example.com',
  age: 35
}.to_json

response = simulate_request(adapter, :post, '/users', {}, {}, valid_user_data)
puts "✅ Status: #{response[:status]}"
puts "✅ Response: #{response[:body]}"

# Test 5: Invalid POST request (bad email)
puts "\nTest 5: POST /users with invalid email"
invalid_user_data = {
  name: 'Bad User',
  email: 'not-an-email',
  age: 25
}.to_json

response = simulate_request(adapter, :post, '/users', {}, {}, invalid_user_data)
puts "❌ Status: #{response[:status] || 'Error'}"
puts "❌ Error: #{response[:error] || response[:body]}"

# 4. OpenAPI spec generation
puts "\n4. 📄 OpenAPI Specification Generation"
puts "-" * 38

# Generate OpenAPI spec for one endpoint as an example
openapi_spec = get_user_endpoint.to_openapi_spec
puts "✅ Generated OpenAPI spec for GET /users/{id}:"
puts JSON.pretty_generate(openapi_spec)

puts "\n🎉 Phase 1.2 Complete!"
puts "✅ Enhanced Rack adapter with type integration"
puts "✅ Full request/response validation"
puts "✅ Detailed error handling and reporting"
puts "✅ Type coercion and validation"
puts "✅ Authentication integration points"
puts "✅ OpenAPI specification generation"
puts "✅ Custom error handlers"
puts "\nNext: Phase 1.3 - Enhanced Endpoint DSL!"
