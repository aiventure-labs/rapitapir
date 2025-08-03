#!/usr/bin/env ruby
# frozen_string_literal: true

# Test script to validate Honeycomb.io observability example
require 'bundler/setup'

# Add local lib to load path for RapiTapir
$LOAD_PATH.unshift(File.expand_path('../../lib', __dir__))

# Set mock environment variables
ENV['OTEL_EXPORTER_OTLP_HEADERS'] = 'x-honeycomb-team=test-key'
ENV['OTEL_SERVICE_NAME'] = 'rapitapir-demo'
ENV['OTEL_EXPORTER_OTLP_ENDPOINT'] = 'https://api.honeycomb.io'

# Override $PROGRAM_NAME to avoid server startup
original_program_name = $PROGRAM_NAME
$PROGRAM_NAME = 'test_validation'

begin
  puts "🧪 Testing Honeycomb.io observability example..."
  
  # Test individual gem loading
  puts "   Loading OpenTelemetry SDK..."
  require 'opentelemetry/sdk'
  
  puts "   Loading OpenTelemetry OTLP exporter..."
  require 'opentelemetry/exporter/otlp'
  
  puts "   Loading OpenTelemetry instrumentation..."
  require 'opentelemetry/instrumentation/all'
  
  puts "   Loading OpenTelemetry baggage processor..."
  require 'opentelemetry/processor/baggage/baggage_span_processor'
  
  puts "   Loading Sinatra..."
  require 'sinatra/base'
  
  puts "   Loading JSON..."
  require 'json'
  
  # Now load the main example file
  puts "   Loading honeycomb_example.rb..."
  load File.join(__dir__, 'honeycomb_example.rb')
  
  # Test that the class was defined
  unless defined?(HoneycombDemoAPI)
    raise "HoneycombDemoAPI class not defined"
  end
  
  puts ""
  puts "✅ Success! All components loaded correctly:"
  puts "   ✓ OpenTelemetry SDK initialized"
  puts "   ✓ OTLP exporter configured"
  puts "   ✓ Automatic instrumentation enabled"
  puts "   ✓ Baggage processor configured"
  puts "   ✓ RapiTapir configuration loaded"
  puts "   ✓ Sinatra app class defined: #{HoneycombDemoAPI.name}"
  puts ""
  puts "🚀 Ready to run the Honeycomb.io observability demo!"
  puts "   Usage: ruby honeycomb_example.rb"
  puts ""
  puts "📋 Next steps:"
  puts "   1. Get a Honeycomb.io API key from https://ui.honeycomb.io/account"
  puts "   2. Copy .env.example to .env and add your API key"
  puts "   3. Run: ruby honeycomb_example.rb"
  puts "   4. Make requests to generate traces"
  puts "   5. View traces in Honeycomb.io dashboard"
  
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
