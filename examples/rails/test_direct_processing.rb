#!/usr/bin/env ruby
# frozen_string_literal: true

# Test endpoint processing directly

puts "🧪 Testing Direct Endpoint Processing..."
puts "=" * 42

begin
  require_relative 'hello_world_app'
  
  # Create a controller instance
  controller = HelloWorldController.new
  
  # Mock Rails request environment
  env = {
    'REQUEST_METHOD' => 'GET',
    'PATH_INFO' => '/hello',
    'QUERY_STRING' => 'name=Test',
    'rack.input' => StringIO.new(''),
    'rack.errors' => $stderr
  }
  
  # Create a mock request object
  require 'stringio'
  request = ActionDispatch::Request.new(env)
  
  # Allow the controller to access request
  controller.instance_variable_set(:@_request, request)
  
  puts "\n1️⃣ Testing process_rapitapir_endpoint for :get_hello..."
  
  # Call process_rapitapir_endpoint with the specific action
  result = controller.send(:process_rapitapir_endpoint, :get_hello)
  puts "✅ Success: #{result}"
  
rescue => e
  puts "❌ Error during processing: #{e.message}"
  puts "Backtrace:"
  puts e.backtrace[0..10].join("\n")
end
