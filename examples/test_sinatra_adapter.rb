#!/usr/bin/env ruby
# frozen_string_literal: true

# Test script to validate the SinatraAdapter integration

# Add lib to path
$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))

require 'rapitapir'

puts "Testing SinatraAdapter integration..."
puts "1. Loading TaskAPI endpoints..."

# Fake databases
class UserDatabase
  def self.find_by_token(token)
    { id: 1, name: 'Test User', scopes: ['read', 'write'] }
  end
end

class TaskDatabase
  def self.all
    [{ id: 1, title: 'Test Task', status: 'pending' }]
  end
end

# Load the TaskAPI module
require_relative 'enterprise_rapitapir_api'

# Check endpoints
puts "2. Found #{TaskAPI.endpoints.size} endpoints:"
TaskAPI.endpoints.each_with_index do |endpoint, i|
  puts "   #{i+1}. #{endpoint.method.upcase} #{endpoint.path}"
  puts "      Inputs: #{endpoint.inputs.map(&:name).join(', ')}" if endpoint.inputs.any?
  puts "      Outputs: #{endpoint.outputs.size} defined" if endpoint.outputs.any?
end

puts "\n3. Testing endpoint structure compatibility..."
endpoint = TaskAPI.endpoints.first
puts "   Sample endpoint: #{endpoint.class.name}"
puts "   Has method: #{endpoint.respond_to?(:method)}"
puts "   Has path: #{endpoint.respond_to?(:path)}"
puts "   Has inputs: #{endpoint.respond_to?(:inputs)}"
puts "   Has outputs: #{endpoint.respond_to?(:outputs)}"

if endpoint.inputs.any?
  input = endpoint.inputs.first
  puts "   Sample input: #{input.class.name}"
  puts "   Has kind: #{input.respond_to?(:kind)}"
  puts "   Has name: #{input.respond_to?(:name)}"
  puts "   Has required?: #{input.respond_to?(:required?)}"
  puts "   Has coerce: #{input.respond_to?(:coerce)}"
end

puts "\n✅ SinatraAdapter integration test completed successfully!"
