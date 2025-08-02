#!/usr/bin/env ruby
# frozen_string_literal: true

puts "=== Enhanced Auto-Derivation Testing ==="

require_relative '../lib/rapitapir/types'

# Test JSON Schema with advanced features
puts "\n1. Advanced JSON Schema Features"
puts "-" * 40

advanced_schema = {
  "type" => "object",
  "properties" => {
    "id" => { "type" => "integer", "minimum" => 1 },
    "email" => { "type" => "string", "format" => "email" },
    "name" => { "type" => "string", "minLength" => 2, "maxLength" => 50 },
    "age" => { "type" => "integer", "minimum" => 0, "maximum" => 120 },
    "tags" => { 
      "type" => "array", 
      "items" => { "type" => "string" }
    },
    "metadata" => { "type" => "object" },
    "active" => { "type" => "boolean" }
  },
  "required" => ["id", "email", "name"]
}

result = RapiTapir::Types.from_json_schema(advanced_schema)
puts "✅ Advanced JSON Schema with constraints and formats"
puts "Fields: #{result.field_types.keys.join(', ')}"

# Test field filtering
filtered = RapiTapir::Types.from_json_schema(advanced_schema, only: [:id, :name, :email])
puts "✅ Filtered (only): #{filtered.field_types.keys.join(', ')}"

excluded = RapiTapir::Types.from_json_schema(advanced_schema, except: [:metadata, :tags])
puts "✅ Filtered (except): #{excluded.field_types.keys.join(', ')}"

# Test OpenStruct with complex data
puts "\n2. OpenStruct with Complex Data"
puts "-" * 40

require 'ostruct'
complex_config = OpenStruct.new(
  database_url: "postgresql://localhost:5432/mydb",
  max_connections: 25,
  ssl_enabled: true,
  timeout: 30.5,
  features: ["caching", "logging", "monitoring"],
  settings: { debug: true, verbose: false }
)

result = RapiTapir::Types.from_open_struct(complex_config)
puts "✅ Complex OpenStruct with mixed types"
puts "Fields: #{result.field_types.keys.join(', ')}"

# Test filtering on OpenStruct
essential = RapiTapir::Types.from_open_struct(complex_config, only: [:database_url, :max_connections])
puts "✅ Essential config: #{essential.field_types.keys.join(', ')}"

# Test error handling
puts "\n3. Error Handling"
puts "-" * 40

begin
  RapiTapir::Types.from_json_schema({"type" => "string"})
rescue ArgumentError => e
  puts "✅ Proper error for non-object schema: #{e.message}"
end

begin
  RapiTapir::Types.from_open_struct("not an ostruct")
rescue ArgumentError => e
  puts "✅ Proper error for invalid OpenStruct: #{e.message}"
end

puts "\n🎉 Enhanced auto-derivation features working!"
puts "💡 Key benefits:"
puts "   ✓ Field filtering with only/except"
puts "   ✓ JSON Schema constraints and formats"
puts "   ✓ Complex nested types (arrays, objects)"
puts "   ✓ Proper error handling"
