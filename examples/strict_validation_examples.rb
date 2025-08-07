#!/usr/bin/env ruby
# frozen_string_literal: true

# RapiTapir Strict Validation Examples
#
# This file demonstrates the strict validation behavior in RapiTapir v2.0
# By default, hash schemas now reject unexpected fields for better security.

require_relative '../lib/rapitapir'

puts "🔒 RapiTapir v2.0 - Strict Validation by Default"
puts "=" * 55

# Define strict schema (default behavior)
STRICT_USER_SCHEMA = RapiTapir::Types.hash({
  'name' => RapiTapir::Types.string,
  'email' => RapiTapir::Types.email,
  'age' => RapiTapir::Types.integer
})

# Define open schema (allows additional properties)
OPEN_USER_SCHEMA = RapiTapir::Types.open_hash({
  'name' => RapiTapir::Types.string,
  'email' => RapiTapir::Types.email,
  'age' => RapiTapir::Types.integer
})

def test_validation(title, data, schema)
  puts "\n#{title}"
  puts "-" * 40
  puts "📥 Input: #{data.inspect}"
  
  begin
    result = schema.coerce(data)
    puts "✅ Success: #{result.inspect}"
  rescue RapiTapir::Types::CoercionError => e
    puts "❌ Error: #{e.message}"
    if e.reason =~ /Unexpected fields/
      puts "🔒 Security: Rejecting unexpected data"
    end
  end
end

# Test data with extra field
test_data_with_extra = {
  'name' => 'John Doe',
  'email' => 'john@example.com',
  'age' => 25,
  'extra_field' => 'unexpected_value',
  'another_field' => 42
}

# Test data without extra fields
test_data_clean = {
  'name' => 'Jane Smith',
  'email' => 'jane@example.com',
  'age' => 30
}

puts "\n📋 1. STRICT VALIDATION (Default Behavior)"
puts "   🔒 Rejects unexpected fields for security"

test_validation(
  "1️⃣  Strict Schema with Extra Fields",
  test_data_with_extra,
  STRICT_USER_SCHEMA
)

test_validation(
  "2️⃣  Strict Schema with Clean Data",
  test_data_clean,
  STRICT_USER_SCHEMA
)

puts "\n📋 2. OPEN VALIDATION (Explicit opt-in)"
puts "   🌐 Allows additional properties when needed"

test_validation(
  "3️⃣  Open Schema with Extra Fields",
  test_data_with_extra,
  OPEN_USER_SCHEMA
)

test_validation(
  "4️⃣  Open Schema with Clean Data",
  test_data_clean,
  OPEN_USER_SCHEMA
)

puts "\n🎉 Strict Validation Benefits:"
puts "   ✅ Enhanced security by rejecting unexpected data"
puts "   ✅ Clear error messages showing allowed fields"
puts "   ✅ Prevents data leakage and injection attacks"
puts "   ✅ Enforces API contract compliance"
puts "   ✅ Explicit opt-in for flexible schemas when needed"

puts "\n💡 Usage Guidelines:"
puts "   • Use RapiTapir::Types.hash() for strict validation (default)"
puts "   • Use RapiTapir::Types.open_hash() when you need flexibility"
puts "   • Most production APIs should use strict validation"
puts "   • Consider open validation only for specific use cases like:"
puts "     - Webhook payloads with variable structures"
puts "     - Configuration objects with user-defined fields"
puts "     - Migration endpoints that need backward compatibility"
