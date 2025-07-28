# frozen_string_literal: true

require_relative 'lib/rapitapir'

puts "🎉 RapiTapir Phase 1.1 Demo - Advanced Type System & Validation"
puts "=" * 70

# 1. Basic primitive types with constraints
puts "\n1. 📝 Primitive Types with Constraints"
puts "-" * 40

name_type = RapiTapir::Types.string(min_length: 2, max_length: 50)
age_type = RapiTapir::Types.integer(minimum: 0, maximum: 150)
email_type = RapiTapir::Types.email

puts "✅ Valid name: #{name_type.validate('John')[:valid]}"
puts "❌ Invalid name (too short): #{name_type.validate('J')[:valid]}"
puts "✅ Valid age: #{age_type.validate(25)[:valid]}"
puts "❌ Invalid age (negative): #{age_type.validate(-5)[:valid]}"
puts "✅ Valid email: #{email_type.validate('user@example.com')[:valid]}"
puts "❌ Invalid email: #{email_type.validate('not-an-email')[:valid]}"

# 2. Semantic types
puts "\n2. 🔍 Semantic Types"
puts "-" * 25

uuid_type = RapiTapir::Types.uuid
valid_uuid = '123e4567-e89b-12d3-a456-426614174000'
invalid_uuid = 'not-a-uuid'

puts "✅ Valid UUID: #{uuid_type.validate(valid_uuid)[:valid]}"
puts "❌ Invalid UUID: #{uuid_type.validate(invalid_uuid)[:valid]}"

# 3. Composite types - Arrays
puts "\n3. 📋 Array Types"
puts "-" * 20

tags_type = RapiTapir::Types.array(
  RapiTapir::Types.string(min_length: 1),
  min_items: 1,
  max_items: 5,
  unique_items: true
)

puts "✅ Valid tags: #{tags_type.validate(['ruby', 'api', 'web'])[:valid]}"
puts "❌ Empty array: #{tags_type.validate([])[:valid]}"
puts "❌ Duplicate items: #{tags_type.validate(['ruby', 'ruby'])[:valid]}"

# 4. Complex object schemas
puts "\n4. 🏗️  Complex Object Schemas"
puts "-" * 32

user_schema = RapiTapir::Types.object do
  field :id, RapiTapir::Types.uuid
  field :name, RapiTapir::Types.string(min_length: 2, max_length: 100)
  field :email, RapiTapir::Types.email
  field :age, RapiTapir::Types.integer(minimum: 18, maximum: 120), required: false
  field :tags, RapiTapir::Types.array(RapiTapir::Types.string), required: false
end

valid_user = {
  id: '123e4567-e89b-12d3-a456-426614174000',
  name: 'John Doe',
  email: 'john@example.com',
  age: 30,
  tags: ['developer', 'ruby']
}

invalid_user = {
  id: 'invalid-uuid',
  name: 'J',  # too short
  email: 'not-an-email',
  age: 15     # too young
}

valid_result = user_schema.validate(valid_user)
invalid_result = user_schema.validate(invalid_user)

puts "✅ Valid user data: #{valid_result[:valid]}"
puts "❌ Invalid user data: #{invalid_result[:valid]}"
if !invalid_result[:valid]
  puts "   Errors:"
  invalid_result[:errors].each { |error| puts "   - #{error}" }
end

# 5. Schema definition with RapiTapir::Schema
puts "\n5. 🏭 Schema Builder API"
puts "-" * 25

article_schema = RapiTapir::Schema.define do
  field :id, :uuid
  field :title, :string
  field :content, :string
  field :author, { 
    name: :string, 
    email: :email,
    bio: :string
  }
  field :tags, [:string], required: false
  field :published_at, :datetime, required: false
end

sample_article = {
  id: '987fcdeb-51a2-4567-8901-abcdef123456',
  title: 'Getting Started with RapiTapir',
  content: 'This is a comprehensive guide...',
  author: {
    name: 'Jane Smith',
    email: 'jane@example.com',
    bio: 'Senior Ruby Developer'
  },
  tags: ['tutorial', 'ruby', 'api'],
  published_at: '2024-01-15T10:30:00Z'
}

article_result = article_schema.validate(sample_article)
puts "✅ Article validation: #{article_result[:valid]}"

# 6. Type coercion
puts "\n6. 🔄 Type Coercion"
puts "-" * 20

puts "String coercion:"
puts "  123 → '#{RapiTapir::Types.string.coerce(123)}'"
puts "  :symbol → '#{RapiTapir::Types.string.coerce(:symbol)}'"

puts "Integer coercion:"
puts "  '42' → #{RapiTapir::Types.integer.coerce('42')}"
puts "  42.7 → #{RapiTapir::Types.integer.coerce(42.7)}"
puts "  true → #{RapiTapir::Types.integer.coerce(true)}"

puts "Boolean coercion:"
puts "  'true' → #{RapiTapir::Types.boolean.coerce('true')}"
puts "  'false' → #{RapiTapir::Types.boolean.coerce('false')}"
puts "  '1' → #{RapiTapir::Types.boolean.coerce('1')}"

# 7. JSON Schema generation
puts "\n7. 📄 JSON Schema Generation"
puts "-" * 30

user_json_schema = user_schema.to_json_schema
puts "Generated JSON Schema properties:"
user_json_schema[:properties].each do |field, schema|
  puts "  #{field}: #{schema[:type]}#{schema[:format] ? " (#{schema[:format]})" : ""}"
end
puts "Required fields: #{user_json_schema[:required]}"

# 8. Error handling and detailed feedback
puts "\n8. ⚠️  Detailed Error Reporting"
puts "-" * 32

error_demo_data = {
  id: 'invalid',
  name: '',
  email: 'bad-email',
  age: 200,
  tags: ['', 'duplicate', 'duplicate']
}

error_result = user_schema.validate(error_demo_data)
puts "Validation errors for problematic data:"
error_result[:errors].each_with_index do |error, i|
  puts "  #{i + 1}. #{error}"
end

# 9. Optional types
puts "\n9. ❓ Optional Types"
puts "-" * 20

profile_schema = RapiTapir::Types.object do
  field :name, RapiTapir::Types.string
  field :bio, RapiTapir::Types.optional(RapiTapir::Types.string)
  field :website, RapiTapir::Types.optional(RapiTapir::Types.string(format: :uri))
end

minimal_profile = { name: 'Alice' }
full_profile = { 
  name: 'Bob', 
  bio: 'Software engineer',
  website: 'https://bob.dev'
}

puts "✅ Minimal profile (optional fields missing): #{profile_schema.validate(minimal_profile)[:valid]}"
puts "✅ Full profile: #{profile_schema.validate(full_profile)[:valid]}"

puts "\n🚀 Phase 1.1 Complete!"
puts "✅ Advanced type system with constraints"
puts "✅ Semantic types (UUID, Email)"
puts "✅ Composite types (Array, Object, Optional)"
puts "✅ Schema builder DSL"
puts "✅ Type coercion"
puts "✅ JSON Schema generation"
puts "✅ Detailed error reporting"
puts "✅ Comprehensive validation"
puts "\nNext: Phase 1.2 - Server Integration Foundation!"
