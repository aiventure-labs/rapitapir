# frozen_string_literal: true

require 'dotenv'
Dotenv.load

puts "🍯 Simple Server Test"
puts "===================="

# Just try to start the server directly and see what happens
puts "📡 Starting server directly..."

require_relative 'honeycomb_working_example'

puts "✅ Server started successfully!"
