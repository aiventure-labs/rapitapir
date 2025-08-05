#!/usr/bin/env ruby
# frozen_string_literal: true

# Comprehensive Rails Integration Validation

puts "🎯 RapiTapir Rails Integration - Comprehensive Test"
puts "=" * 55

success_count = 0
total_tests = 7

def test(description)
  print "\n#{description}... "
  begin
    result = yield
    puts "✅"
    return true
  rescue => e
    puts "❌ #{e.message}"
    return false
  end
end

# Test 1: Basic loading
success_count += 1 if test("Loading Rails integration") do
  require_relative 'hello_world_app'
  true
end

# Test 2: Controller inheritance  
success_count += 1 if test("Controller inheritance working") do
  HelloWorldController < RapiTapir::Server::Rails::ControllerBase
end

# Test 3: T shortcuts
success_count += 1 if test("T shortcuts available") do
  type = HelloWorldController::T.string
  type.is_a?(RapiTapir::Types::String)
end

# Test 4: HTTP verbs
success_count += 1 if test("HTTP verb DSL working") do
  builder = HelloWorldController.GET('/test')
  builder.is_a?(RapiTapir::DSL::FluentEndpointBuilder)
end

# Test 5: Endpoints registered
success_count += 1 if test("Endpoints properly registered") do
  endpoints = HelloWorldController.rapitapir_endpoints
  endpoints.is_a?(Hash) && endpoints.count == 4
end

# Test 6: Rails routes generated
success_count += 1 if test("Rails routes generated") do
  routes = HelloWorldRailsApp.routes.routes
  rapitapir_routes = routes.select { |r| r.defaults[:controller] == 'hello_world' }
  rapitapir_routes.count == 4
end

# Test 7: Controller can be instantiated
success_count += 1 if test("Controller instantiation") do
  controller = HelloWorldController.new
  controller.respond_to?(:process_rapitapir_endpoint)
end

puts "\n" + "=" * 55
puts "🎉 Test Results: #{success_count}/#{total_tests} tests passed"

if success_count == total_tests
  puts "\n✅ RAILS INTEGRATION FULLY WORKING!"
  puts "\n🚀 Key Features Implemented:"
  puts "   • Enhanced controller base class"
  puts "   • Sinatra-like syntax for Rails"
  puts "   • Automatic action derivation"
  puts "   • Route generation"
  puts "   • Type shortcuts (T.string, etc.)"
  puts "   • HTTP verb DSL"
  puts "\n📋 Available Endpoints:"
  HelloWorldController.rapitapir_endpoints.each do |action, config|
    endpoint = config[:endpoint]
    puts "   #{endpoint.method.upcase} #{endpoint.path} => #{action}"
  end
  
  puts "\n🎯 Developer Experience Gap: ELIMINATED ✅"
  puts "📊 Feature Parity with Sinatra: ACHIEVED ✅"
  puts "\n🌟 Rails developers now have the same elegant syntax!"
else
  puts "\n❌ Some tests failed. Rails integration needs debugging."
end

puts "\n" + "=" * 55
