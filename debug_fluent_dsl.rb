# frozen_string_literal: true

require_relative 'lib/rapitapir'

puts "🔧 Testing Fluent DSL Access"
puts "=" * 30

# Test what RapiTapir.get returns
puts "Testing RapiTapir.get('/test'):"
result = RapiTapir.get('/test')
puts "Class: #{result.class}"
puts "Methods available: #{result.methods.grep(/query|summary|description/).join(', ')}"

# Test if we can access FluentEndpointBuilder directly
puts "\nTesting FluentEndpointBuilder directly:"
builder = RapiTapir::DSL::FluentEndpointBuilder.new(:get, '/test')
puts "Class: #{builder.class}"
puts "Methods available: #{builder.methods.grep(/query|summary|description/).join(', ')}"

# Test method call
puts "\nTesting method call:"
begin
  builder_with_query = builder.query(:test, :string)
  puts "Success! Result class: #{builder_with_query.class}"
rescue => e
  puts "Error: #{e.message}"
end
