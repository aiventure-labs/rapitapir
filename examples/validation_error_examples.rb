# frozen_string_literal: true

# RapiTapir Validation Error Examples
#
# This file demonstrates the improved validation error messages in RapiTapir v2.0
# Run this script to see the enhanced developer experience for API validation.

require_relative '../lib/rapitapir'

puts "🔍 RapiTapir v2.0 - Enhanced Validation Error Messages"
puts "=" * 60

# Define a realistic API schema
USER_SCHEMA = RapiTapir::Types.hash({
  'name' => RapiTapir::Types.string(min_length: 2, max_length: 50),
  'email' => RapiTapir::Types.email,
  'age' => RapiTapir::Types.integer(minimum: 18, maximum: 120),
  'profile' => RapiTapir::Types.hash({
    'bio' => RapiTapir::Types.string(max_length: 200),
    'website' => RapiTapir::Types.string(format: :uri),
    'newsletter' => RapiTapir::Types.boolean
  })
})

def show_validation_example(title, data, schema = USER_SCHEMA)
  puts "\n#{title}"
  puts "-" * 40
  puts "📥 Input: #{data.inspect}"
  
  begin
    # First try coercion (type conversion + missing field checks)
    coerced = schema.coerce(data)
    
    # Then validate the coerced data (constraint checks)
    validation_result = schema.validate(coerced)
    
    if validation_result[:valid]
      puts "✅ Success: #{coerced.inspect}"
    else
      puts "❌ Validation Failed: #{validation_result[:errors].first}"
      puts "📋 All errors: #{validation_result[:errors].join(', ')}"
    end
    
  rescue RapiTapir::Types::CoercionError => e
    puts "❌ Coercion Error: #{e.message}"
    puts "🎯 Field: #{extract_field_from_error(e)}" if extract_field_from_error(e)
    puts "📋 Expected: #{e.type}"
    puts "💭 Received: #{e.value.inspect}"
  end
end

def extract_field_from_error(error)
  if error.reason =~ /Field '([^']+)':/
    $1
  elsif error.reason =~ /Required field '([^']+)'/
    $1
  else
    nil
  end
end

# Example 1: Missing required field
show_validation_example(
  "1️⃣  Missing Required Field",
  {
    'name' => 'John Doe',
    'age' => 25,
    'profile' => {
      'bio' => 'Software developer',
      'newsletter' => true
    }
    # Missing 'email' field
  }
)

# Example 2: Invalid email format
show_validation_example(
  "2️⃣  Invalid Email Format",
  {
    'name' => 'John Doe',
    'email' => 'not-an-email',
    'age' => 25,
    'profile' => {
      'bio' => 'Software developer',
      'website' => 'https://example.com',
      'newsletter' => true
    }
  }
)

# Example 3: Age constraint violation
show_validation_example(
  "3️⃣  Age Constraint Violation",
  {
    'name' => 'John Doe',
    'email' => 'john@example.com',
    'age' => 16, # Under 18
    'profile' => {
      'bio' => 'High school student',
      'website' => 'https://example.com',
      'newsletter' => false
    }
  }
)

# Example 4: Invalid nested field
show_validation_example(
  "4️⃣  Invalid Nested Field",
  {
    'name' => 'John Doe',
    'email' => 'john@example.com',
    'age' => 25,
    'profile' => {
      'bio' => 'Software developer',
      'website' => 'not-a-valid-url',
      'newsletter' => 'yes' # Should be boolean
    }
  }
)

# Example 5: Missing nested required field
show_validation_example(
  "5️⃣  Missing Nested Required Field",
  {
    'name' => 'John Doe',
    'email' => 'john@example.com',
    'age' => 25,
    'profile' => {
      'bio' => 'Software developer',
      'website' => 'https://example.com'
      # Missing 'newsletter' field
    }
  }
)

# Example 6: String length validation
show_validation_example(
  "6️⃣  String Length Validation",
  {
    'name' => 'J', # Too short (min 2 chars)
    'email' => 'john@example.com',
    'age' => 25,
    'profile' => {
      'bio' => 'A' * 250, # Too long (max 200 chars)
      'website' => 'https://example.com',
      'newsletter' => true
    }
  }
)

# Example 7: Successful validation
show_validation_example(
  "7️⃣  Successful Validation ✨",
  {
    'name' => 'John Doe',
    'email' => 'john@example.com',
    'age' => 25,
    'profile' => {
      'bio' => 'Software developer passionate about APIs',
      'website' => 'https://johndoe.dev',
      'newsletter' => true
    }
  }
)

puts "\n🎉 Enhanced Error Messages Summary:"
puts "   ✅ Specific field names in error messages"
puts "   ✅ Clear indication of missing vs invalid fields"
puts "   ✅ Expected vs received value information"
puts "   ✅ Nested object validation with field context"
puts "   ✅ Constraint violation details (length, format, etc.)"
puts "   ✅ Maintains backward compatibility"
puts "\n💡 This improves the developer experience by providing actionable feedback!"
