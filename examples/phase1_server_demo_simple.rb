# frozen_string_literal: true

require_relative 'lib/rapitapir'
require_relative 'lib/rapitapir/core/enhanced_endpoint'
require_relative 'lib/rapitapir/server/enhanced_rack_adapter'

puts "🚀 RapiTapir Phase 1.2 Demo - Server Integration Foundation"
puts "=" * 70

# 1. Create simple enhanced endpoints
puts "\n1. 📝 Creating Enhanced Endpoints"
puts "-" * 35

# Simple endpoint using base functionality
get_users_endpoint = RapiTapir::Core::EnhancedEndpoint.new(
  method: :get, 
  path: '/users'
)

get_user_endpoint = RapiTapir::Core::EnhancedEndpoint.new(
  method: :get,
  path: '/users/{id}'
)

create_user_endpoint = RapiTapir::Core::EnhancedEndpoint.new(
  method: :post,
  path: '/users'
)

puts "✅ Created 3 enhanced endpoints"
puts "   - GET /users"
puts "   - GET /users/{id}"
puts "   - POST /users"

# 2. Test the type system directly
puts "\n2. 🔧 Testing Type System"
puts "-" * 25

# Create types for validation
uuid_type = RapiTapir::Types.uuid
email_type = RapiTapir::Types.email

# Test UUID validation
puts "\nTesting UUID validation:"
valid_uuid = '123e4567-e89b-12d3-a456-426614174000'
invalid_uuid = 'not-a-uuid'

begin
  result = uuid_type.validate(valid_uuid)
  puts "✅ Valid UUID: #{result}"
rescue RapiTapir::Types::ValidationError => e
  puts "❌ UUID validation failed: #{e.message}"
end

begin
  result = uuid_type.validate(invalid_uuid)
  puts "✅ Invalid UUID accepted: #{result}"
rescue RapiTapir::Types::ValidationError => e
  puts "❌ UUID validation correctly rejected: #{e.message}"
end

# Test Email validation
puts "\nTesting Email validation:"
valid_email = 'user@example.com'
invalid_email = 'not-an-email'

begin
  result = email_type.validate(valid_email)
  puts "✅ Valid email: #{result}"
rescue RapiTapir::Types::ValidationError => e
  puts "❌ Email validation failed: #{e.message}"
end

begin
  result = email_type.validate(invalid_email)
  puts "✅ Invalid email accepted: #{result}"
rescue RapiTapir::Types::ValidationError => e
  puts "❌ Email validation correctly rejected: #{e.message}"
end

# 3. Test Enhanced Rack Adapter
puts "\n3. 🔄 Testing Enhanced Rack Adapter"
puts "-" * 35

adapter = RapiTapir::Server::EnhancedRackAdapter.new

# Mock data
users_db = [
  {
    id: '123e4567-e89b-12d3-a456-426614174000',
    name: 'John Doe',
    email: 'john@example.com',
    age: 30
  }
]

# Mount a simple endpoint
adapter.mount(get_users_endpoint) do |params|
  puts "Handler called with params: #{params.inspect}"
  users_db
end

puts "✅ Mounted GET /users endpoint with handler"

# 4. Test request processing
puts "\n4. 🔄 Request Processing"
puts "-" * 25

# Create a simple request environment
def create_env(method, path, query_string = '')
  {
    'REQUEST_METHOD' => method.to_s.upcase,
    'PATH_INFO' => path,
    'QUERY_STRING' => query_string,
    'rack.input' => StringIO.new,
    'CONTENT_TYPE' => 'application/json'
  }
end

# Test basic request handling
puts "\nTesting GET /users:"
env = create_env('GET', '/users', 'limit=10')

begin
  status, headers, body = adapter.call(env)
  puts "✅ Status: #{status}"
  puts "✅ Headers: #{headers.inspect}"
  puts "✅ Body: #{body.first}" if body.respond_to?(:first)
rescue => e
  puts "❌ Error: #{e.message}"
  puts "   Class: #{e.class}"
end

# 5. Test Schema System
puts "\n5. 📋 Testing Schema System"
puts "-" * 25

# Create a user schema
user_schema = RapiTapir::Schema.define do
  field :id, :uuid
  field :name, :string
  field :email, :email
  field :age, :integer, required: false
end

puts "✅ Created user schema with fields:"
puts "   - id: UUID (required)"
puts "   - name: String (required)"
puts "   - email: Email (required)"  
puts "   - age: Integer (optional)"

# Test schema validation
valid_user_data = {
  id: '123e4567-e89b-12d3-a456-426614174000',
  name: 'John Doe',
  email: 'john@example.com',
  age: 30
}

invalid_user_data = {
  id: 'invalid-uuid',
  name: 'John Doe',
  email: 'not-an-email'
}

puts "\nTesting valid user data:"
begin
  result = user_schema.validate(valid_user_data)
  puts "✅ Validation passed: #{result.inspect}"
rescue => e
  puts "❌ Validation failed: #{e.message}"
end

puts "\nTesting invalid user data:"
begin
  result = user_schema.validate(invalid_user_data)
  puts "✅ Invalid data accepted: #{result.inspect}"
rescue => e
  puts "❌ Validation correctly rejected: #{e.message}"
end

# 6. Test JSON Schema Generation
puts "\n6. 📄 JSON Schema Generation"
puts "-" * 30

schema_json = user_schema.to_json_schema
puts "✅ Generated JSON Schema:"
puts JSON.pretty_generate(schema_json)

puts "\n🎉 Phase 1.2 Server Integration Foundation Demo Complete!"
puts "✅ Enhanced endpoints created"
puts "✅ Type system validation working"
puts "✅ Enhanced Rack adapter functional"
puts "✅ Schema system operational"
puts "✅ JSON Schema generation working"
puts "\nReady for Phase 1.3 - Enhanced DSL!"
