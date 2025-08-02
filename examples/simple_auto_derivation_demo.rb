#!/usr/bin/env ruby
# frozen_string_literal: true

puts "=== RapiTapir Auto-Derivation Examples ==="

require_relative '../lib/rapitapir/types'

# 1. JSON Schema Example
puts "\n1. JSON Schema Auto-Derivation"
puts "-" * 30

user_schema = {
  "type" => "object",
  "properties" => {
    "name" => { "type" => "string" },
    "age" => { "type" => "integer" },
    "active" => { "type" => "boolean" }
  }
}

result = RapiTapir::Types.from_json_schema(user_schema)
puts "✅ Derived schema from JSON Schema"
puts "Fields: #{result.field_types.keys.join(', ')}"

# 2. OpenStruct Example  
puts "\n2. OpenStruct Auto-Derivation"
puts "-" * 30

require 'ostruct'
config = OpenStruct.new(
  host: "api.example.com",
  port: 443,
  ssl: true
)

result = RapiTapir::Types.from_open_struct(config)
puts "✅ Derived schema from OpenStruct"
puts "Fields: #{result.field_types.keys.join(', ')}"

puts "\n🎉 Auto-derivation working for structured data sources!"
puts "💡 Focus on sources with explicit type information:"
puts "   - JSON Schema (API contracts)"
puts "   - OpenStruct (configuration objects)"
puts "   - Protobuf (when available)"
