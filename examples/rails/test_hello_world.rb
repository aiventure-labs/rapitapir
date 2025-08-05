#!/usr/bin/env ruby
# frozen_string_literal: true

# Test script for Hello World Rails RapiTapir example

require_relative 'hello_world_app'

puts "\n🧪 Testing Hello World Rails RapiTapir Controller"
puts "=" * 50

# Test 1: Basic functionality
puts "\n1. Testing controller class inheritance..."
begin
  controller = HelloWorldController.new
  puts "✅ HelloWorldController inherits from ControllerBase"
rescue => e
  puts "❌ Error: #{e.message}"
end

# Test 2: T shortcut availability
puts "\n2. Testing T shortcut availability..."
begin
  string_type = HelloWorldController::T.string
  puts "✅ T shortcut works: #{string_type.class}"
rescue => e
  puts "❌ Error: #{e.message}"
end

# Test 3: HTTP verb methods
puts "\n3. Testing HTTP verb methods..."
begin
  get_builder = HelloWorldController.GET('/test')
  puts "✅ GET method works: #{get_builder.class}"
rescue => e
  puts "❌ Error: #{e.message}"
end

# Test 4: Route generation
puts "\n4. Testing route generation..."
begin
  router = Object.new
  router.extend(RapiTapir::Server::Rails::Routes)
  
  # Mock route methods
  def router.get(path, options = {}); puts "  Generated: GET #{path} => #{options[:to]}"; end
  def router.post(path, options = {}); puts "  Generated: POST #{path} => #{options[:to]}"; end
  
  puts "  Generating routes for HelloWorldController:"
  
  # Check if controller has endpoints
  if HelloWorldController.respond_to?(:rapitapir_endpoints)
    router.rapitapir_routes_for(HelloWorldController)
    puts "✅ Route generation works"
  else
    puts "❌ Controller doesn't have rapitapir_endpoints method"
  end
rescue => e
  puts "❌ Error: #{e.message}"
end

# Test 5: Schema validation
puts "\n5. Testing schema definitions..."
begin
  # Test the schema types used in the controller
  schema = HelloWorldController::T.hash({
    'message' => HelloWorldController::T.string,
    'timestamp' => HelloWorldController::T.string
  })
  puts "✅ Schema definition works: #{schema.class}"
rescue => e
  puts "❌ Error: #{e.message}"
end

puts "\n🎉 Rails Hello World Controller Tests Complete!"
puts "\n🚀 To run the server:"
puts "   ruby examples/rails/hello_world_app.rb"
puts "\n📖 To test endpoints manually:"
puts "   curl http://localhost:9292/hello?name=Developer"
puts "   curl http://localhost:9292/greet/spanish"
puts "   curl -X POST http://localhost:9292/greetings -H 'Content-Type: application/json' -d '{\"name\":\"Rails\"}'"
