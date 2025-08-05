#!/usr/bin/env ruby
# frozen_string_literal: true

# Test server startup without actually running it

puts "🧪 Testing Rails Server Startup..."
puts "=" * 40

begin
  puts "\n1. Loading Rails app..."
  require_relative 'hello_world_app'
  puts "✅ App loaded successfully"
  
  puts "\n2. Testing Rack compatibility..."
  require 'rack'
  puts "✅ Rack loaded: #{Rack::VERSION}"
  
  puts "\n3. Creating Rack::Server instance..."
  server = Rack::Server.new(
    app: HelloWorldRailsApp,
    Port: 9292,
    Host: 'localhost',
    environment: 'development'
  )
  puts "✅ Rack::Server created: #{server.class}"
  
  puts "\n4. Testing app call method..."
  env = {
    'REQUEST_METHOD' => 'GET',
    'PATH_INFO' => '/hello',
    'QUERY_STRING' => 'name=Test',
    'HTTP_HOST' => 'localhost:9292',
    'rack.url_scheme' => 'http'
  }
  
  response = HelloWorldRailsApp.call(env)
  puts "✅ App responds to requests: status=#{response[0]}"
  
  puts "\n🎉 Rails server setup appears to be working!"
  puts "\n🚀 To start the server manually:"
  puts "   ruby examples/rails/hello_world_app.rb"
  
rescue => e
  puts "❌ Error: #{e.message}"
  puts e.backtrace[0..3].join("\n")
end
