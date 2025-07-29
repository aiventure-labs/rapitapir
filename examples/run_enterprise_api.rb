# frozen_string_literal: true

# Test script to start the Enterprise RapiTapir API
# Usage: bundle exec ruby examples/run_enterprise_api.rb

require 'bundler/setup'
require_relative '../lib/rapitapir'
require_relative 'enterprise_rapitapir_api'

# Set Sinatra environment
ENV['RACK_ENV'] ||= 'development'

puts "\n" + "="*60
puts "🚀 STARTING ENTERPRISE TASK MANAGEMENT API"
puts "🎯 Powered by RapiTapir with Auto-generated OpenAPI"
puts "="*60

# Run the application
EnterpriseTaskAPI.run!
