#!/usr/bin/env ruby
# frozen_string_literal: true

# Detailed Rails integration test

puts "🧪 Testing Rails Integration in Detail..."
puts "=" * 50

begin
  puts "\n1. Loading Rails app..."
  require_relative 'hello_world_app'
  puts "✅ App loaded: #{HelloWorldRailsApp.class}"
  
  puts "\n2. Checking controller endpoints..."
  if HelloWorldController.respond_to?(:rapitapir_endpoints)
    endpoints = HelloWorldController.rapitapir_endpoints
    puts "✅ Found #{endpoints.count} endpoints:"
    endpoints.each do |action, config|
      endpoint = config[:endpoint]
      puts "   #{endpoint.method} #{endpoint.path} => #{action}"
    end
  else
    puts "❌ No rapitapir_endpoints found"
  end
  
  puts "\n3. Checking routes..."
  routes = HelloWorldRailsApp.routes.routes
  puts "✅ Found #{routes.count} routes:"
  routes.each do |route|
    puts "   #{route.verb} #{route.path.spec} => #{route.defaults[:controller]}##{route.defaults[:action]}"
  end
  
  puts "\n4. Testing controller instantiation..."
  controller = HelloWorldController.new
  puts "✅ Controller instantiated: #{controller.class}"
  
  puts "\n5. Testing Rails engine..."
  app = HelloWorldRailsApp
  puts "✅ Rails app ready: #{app}"
  
  puts "\n🎉 Rails integration appears to be working!"
  
rescue => e
  puts "❌ Error: #{e.message}"
  puts e.backtrace[0..5].join("\n")
end
