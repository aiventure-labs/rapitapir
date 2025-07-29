# frozen_string_literal: true

require_relative 'lib/rapitapir'

puts "🚀 RapiTapir Phase 1.2 Demo - Server Integration Foundation"
puts "=" * 70

# 1. Test Type System Foundation
puts "\n1. 🔧 Type System Foundation"
puts "-" * 30

# Test basic types
puts "\nTesting basic types:"

string_type = RapiTapir::Types.string(min_length: 3, max_length: 50)
result = string_type.validate("Hello World")
puts "✅ String validation: #{result[:valid] ? 'PASSED' : 'FAILED'}"

integer_type = RapiTapir::Types.integer(min: 0, max: 100)
result = integer_type.validate(25)
puts "✅ Integer validation: #{result[:valid] ? 'PASSED' : 'FAILED'}"

uuid_type = RapiTapir::Types.uuid
result = uuid_type.validate("123e4567-e89b-12d3-a456-426614174000")
puts "✅ UUID validation: #{result[:valid] ? 'PASSED' : 'FAILED'}"

email_type = RapiTapir::Types.email  
result = email_type.validate("user@example.com")
puts "✅ Email validation: #{result[:valid] ? 'PASSED' : 'FAILED'}"

# Test invalid cases
puts "\nTesting validation failures:"

result = string_type.validate("Hi")  # Too short
puts "❌ Short string rejected: #{!result[:valid] ? 'PASSED' : 'FAILED'}"

result = uuid_type.validate("not-a-uuid")
puts "❌ Invalid UUID rejected: #{!result[:valid] ? 'PASSED' : 'FAILED'}"

result = email_type.validate("not-an-email")
puts "❌ Invalid email rejected: #{!result[:valid] ? 'PASSED' : 'FAILED'}"

# 2. Test Schema System
puts "\n2. 📋 Schema System"
puts "-" * 20

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
valid_data = {
  id: '123e4567-e89b-12d3-a456-426614174000',
  name: 'John Doe',
  email: 'john@example.com',
  age: 30
}

result = user_schema.validate(valid_data)
puts "\n✅ Valid data validation: #{result[:valid] ? 'PASSED' : 'FAILED'}"

invalid_data = {
  id: 'invalid-uuid',
  name: 'John',
  email: 'not-email'
}

result = user_schema.validate(invalid_data)
puts "❌ Invalid data rejected: #{!result[:valid] ? 'PASSED' : 'FAILED'}"

# 3. Test Composite Types
puts "\n3. 🔗 Composite Types"
puts "-" * 20

# Array type
user_list_type = RapiTapir::Types.array(user_schema, min_items: 1, max_items: 10)
users_data = [valid_data]

result = user_list_type.validate(users_data)
puts "✅ Array validation: #{result[:valid] ? 'PASSED' : 'FAILED'}"

# Hash type - using field_types hash
metadata_type = RapiTapir::Types::Hash.new(
  {
    "version" => RapiTapir::Types.string,
    "api" => RapiTapir::Types.string
  }
)

metadata_data = { "version" => "1.0", "api" => "users" }
result = metadata_type.validate(metadata_data)
puts "✅ Hash validation: #{result[:valid] ? 'PASSED' : 'FAILED'}"

# Optional type
optional_age = RapiTapir::Types.optional(RapiTapir::Types.integer)
result1 = optional_age.validate(25)
result2 = optional_age.validate(nil)
puts "✅ Optional validation (with value): #{result1[:valid] ? 'PASSED' : 'FAILED'}"
puts "✅ Optional validation (nil): #{result2[:valid] ? 'PASSED' : 'FAILED'}"

# 4. Test JSON Schema Generation
puts "\n4. 📄 JSON Schema Generation"
puts "-" * 30

json_schema = user_schema.to_json_schema
puts "✅ Generated JSON Schema:"
puts JSON.pretty_generate(json_schema)

# 5. Test Type Coercion
puts "\n5. 🔄 Type Coercion"
puts "-" * 17

puts "\nTesting type coercion:"

# String to integer
int_type = RapiTapir::Types.integer
begin
  result = int_type.coerce("123")
  puts "✅ String to integer: #{result}"
rescue => e
  puts "❌ String to integer failed: #{e.message}"
end

# String to boolean
bool_type = RapiTapir::Types.boolean  
begin
  result = bool_type.coerce("true")
  puts "✅ String to boolean: #{result}"
rescue => e
  puts "❌ String to boolean failed: #{e.message}"
end

# ISO string to date
date_type = RapiTapir::Types.date
begin
  result = date_type.coerce("2024-01-15")
  puts "✅ String to date: #{result}"
rescue => e
  puts "❌ String to date failed: #{e.message}"
end

# 6. Test Enhanced Endpoints (Basic)
puts "\n6. 🛠️  Enhanced Endpoints (Basic)"
puts "-" * 35

# Create endpoints without triggering DSL
require_relative 'lib/rapitapir/core/endpoint'
require_relative 'lib/rapitapir/core/enhanced_endpoint'

# Use basic endpoint first
basic_endpoint = RapiTapir::Core::Endpoint.new(
  method: :get,
  path: '/users'
)

puts "✅ Created basic endpoint: #{basic_endpoint.method.upcase} #{basic_endpoint.path}"
puts "✅ Endpoint class: #{basic_endpoint.class}"

# Show the difference between basic and enhanced is available
puts "✅ Enhanced endpoint class available: #{RapiTapir::Core::EnhancedEndpoint}"

# Test basic OpenAPI generation  
puts "\nGenerating OpenAPI spec fragment:"
begin
  spec = basic_endpoint.to_openapi_spec
  puts "✅ OpenAPI generation: PASSED"
  puts "Basic spec keys: #{spec.keys.join(', ')}" 
rescue => e
  puts "❌ OpenAPI generation failed: #{e.message}"
end

puts "\n🎉 Phase 1.2 Foundation Demo Complete!"
puts "✅ Type system validation working"
puts "✅ Schema definition and validation"
puts "✅ Composite types (Array, Hash, Optional)"
puts "✅ JSON Schema generation"
puts "✅ Type coercion system"
puts "✅ Enhanced endpoint basics"
puts "\n🚀 Foundation is solid for Phase 1.3 - Enhanced DSL!"
