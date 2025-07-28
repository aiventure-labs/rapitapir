#!/usr/bin/env ruby

require_relative 'lib/rapitapir'
require_relative 'spec/spec_helper'

include RapiTapir::DSL

# Test the actual endpoints from the test
endpoints = [
  RapiTapir.get('/users')
    .out(json_body([{ id: :integer, name: :string, email: :string }]))
    .summary('Get all users')
    .description('Retrieve a list of all users'),

  RapiTapir.post('/users')
    .in(body({ name: :string, email: :string }))
    .out(json_body({ id: :integer, name: :string, email: :string, created_at: :datetime }))
    .summary('Create user')
    .description('Create a new user'),

  RapiTapir.get('/users/:id')
    .in(path(:id, :integer))
    .out(json_body({ id: :integer, name: :string, email: :string }))
    .summary('Get user by ID')
    .description('Get a specific user by their ID')
]

puts "Created #{endpoints.length} endpoints"
endpoints.each_with_index do |endpoint, i|
  puts "#{i+1}: #{endpoint.class} - #{endpoint.method} #{endpoint.path}"
end

# Test OpenAPI generation
generator = RapiTapir::OpenAPI::SchemaGenerator.new(endpoints: endpoints)
schema = generator.generate

puts "\nSchema paths:"
if schema[:paths]
  schema[:paths].each do |path, methods|
    puts "  #{path}: #{methods.keys.join(', ')}"
  end
else
  puts "  No paths found"
end
