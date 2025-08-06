# frozen_string_literal: true

# Test script to verify Rails integration loads properly with correct order

# First, simulate Rails being loaded (this is what Rails apps do)
require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'
  gem 'rails', '~> 8.0'
  gem 'activesupport'
end

# Load Rails and ActiveSupport first (this is crucial!)
require 'rails/all'

# NOW load RapiTapir (this is the correct order)
require_relative '../../lib/rapitapir'

puts "Testing RapiTapir Rails integration loading..."

begin
  # Try to access the ControllerBase class
  controller_base = RapiTapir::Server::Rails::ControllerBase
  puts "✅ RapiTapir::Server::Rails::ControllerBase loaded successfully"
  
  # Test that it's a class
  if controller_base.is_a?(Class)
    puts "✅ ControllerBase is a proper class"
  else
    puts "❌ ControllerBase is not a class: #{controller_base.class}"
  end
  
  # Test other components
  config = RapiTapir::Server::Rails::Configuration
  puts "✅ RapiTapir::Server::Rails::Configuration loaded"
  
  routes = RapiTapir::Server::Rails::Routes
  puts "✅ RapiTapir::Server::Rails::Routes loaded"
  
  puts "\n🎉 All Rails integration components loaded successfully!"
  
rescue NameError => e
  puts "❌ Error loading Rails integration: #{e.message}"
  puts "   This means there's still an issue with the loading order"
  exit 1
rescue => e
  puts "❌ Unexpected error: #{e.message}"
  puts "   #{e.backtrace.first(3).join("\n   ")}"
  exit 1
end

puts "\n✅ Rails integration test passed!"
puts "✅ The correct loading order is: Rails first, then RapiTapir"
