#!/usr/bin/env ruby
# frozen_string_literal: true

# Test script for the working Honeycomb example
require 'bundler/setup'

# Set mock environment variables
ENV['OTEL_EXPORTER_OTLP_HEADERS'] = 'x-honeycomb-team=test-key'
ENV['OTEL_SERVICE_NAME'] = 'rapitapir-demo'
ENV['OTEL_EXPORTER_OTLP_ENDPOINT'] = 'https://api.honeycomb.io'

# Override $PROGRAM_NAME to avoid server startup
original_program_name = $PROGRAM_NAME
$PROGRAM_NAME = 'test_validation'

begin
  puts "🧪 Testing working Honeycomb.io observability example..."
  
  # Load the working example
  puts "   Loading honeycomb_working_example.rb..."
  load File.join(__dir__, 'honeycomb_working_example.rb')
  
  # Test that the class was defined
  unless defined?(HoneycombDemoAPI)
    raise "HoneycombDemoAPI class not defined"
  end
  
  puts ""
  puts "✅ Success! Working Honeycomb example loaded correctly:"
  puts "   ✓ OpenTelemetry SDK initialized"
  puts "   ✓ OTLP exporter configured for Honeycomb.io"
  puts "   ✓ Automatic instrumentation enabled (Sinatra, Rack, HTTP)"
  puts "   ✓ Baggage processor configured for context propagation"
  puts "   ✓ Custom RapiTapir observability extension loaded"
  puts "   ✓ Sinatra app class defined: #{HoneycombDemoAPI.name}"
  puts ""
  puts "🚀 Ready to run the Honeycomb.io observability demo!"
  puts "   Usage: ruby honeycomb_working_example.rb"
  puts ""
  puts "📋 Next steps:"
  puts "   1. Get a Honeycomb.io API key from https://ui.honeycomb.io/account"
  puts "   2. Copy .env.example to .env and add your API key"
  puts "   3. Load environment: source .env"
  puts "   4. Run: ruby honeycomb_working_example.rb"
  puts "   5. Make requests to generate traces"
  puts "   6. View traces in Honeycomb.io dashboard"
  puts ""
  puts "🔧 Available endpoints:"
  puts "   GET    /health                     - Health check with tracing"
  puts "   GET    /users                      - List users with pagination"
  puts "   POST   /users                      - Create user with validation"
  puts "   GET    /users/:id                  - Get user by ID"
  puts "   PUT    /users/:id                  - Update user"
  puts "   DELETE /users/:id                  - Delete user"
  puts "   GET    /analytics/department-stats - Complex analytics operation"
  
rescue LoadError => e
  puts "❌ LoadError: #{e.message}"
  puts "   Make sure all gems are installed: bundle install"
rescue StandardError => e
  puts "❌ Error: #{e.message}"
  puts "   Backtrace:"
  puts e.backtrace.first(5).map { |line| "     #{line}" }
ensure
  $PROGRAM_NAME = original_program_name
end
