#!/usr/bin/env ruby
# frozen_string_literal: true

# Test the Rails server startup

puts "🧪 Testing Rails Server Startup (Final)..."
puts "=" * 45

begin
  puts "\n1. Loading Rails app..."
  require_relative 'hello_world_app'
  puts "✅ App loaded successfully"
  
  puts "\n2. Testing direct app call..."
  env = {
    'REQUEST_METHOD' => 'GET',
    'PATH_INFO' => '/hello',
    'QUERY_STRING' => 'name=Test',
    'HTTP_HOST' => 'localhost:9292',
    'rack.url_scheme' => 'http',
    'rack.input' => StringIO.new(''),
    'rack.errors' => $stderr,
    'rack.version' => [1, 3],
    'rack.multithread' => true,
    'rack.multiprocess' => false,
    'rack.run_once' => false
  }
  
  require 'stringio'
  env['rack.input'] = StringIO.new('')
  
  status, headers, body = HelloWorldRailsApp.call(env)
  puts "✅ App responds: status=#{status}"
  
  puts "\n3. Testing WEBrick server creation..."
  require 'webrick'
  server = WEBrick::HTTPServer.new(
    Port: 9293,  # Different port for testing
    Host: 'localhost'
  )
  puts "✅ WEBrick server created"
  
  puts "\n🎉 Rails server setup is ready!"
  puts "\n🚀 The server should start successfully."
  puts "📝 Run: ruby examples/rails/hello_world_app.rb"
  
rescue => e
  puts "❌ Error: #{e.message}"
  puts e.backtrace[0..3].join("\n")
end
