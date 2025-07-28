# frozen_string_literal: true

require_relative '../../lib/rapitapir'
require_relative '../../lib/rapitapir/openapi/schema_generator'

# Example script to demonstrate OpenAPI schema generation
class OpenAPIExample
  def initialize
    @endpoints = setup_user_endpoints
  end

  def generate_schema
    generator = RapiTapir::OpenAPI::SchemaGenerator.new(
      endpoints: @endpoints,
      info: {
        title: 'User Management API',
        version: '1.0.0',
        description: 'A simple user management API built with RapiTapir'
      },
      servers: [
        {
          url: 'http://localhost:4567',
          description: 'Development server (Sinatra)'
        },
        {
          url: 'http://localhost:9292',
          description: 'Development server (Rack)'
        }
      ]
    )
    
    generator.generate
  end

  def save_schema(format: :json, pretty: true)
    schema = generate_schema
    
    case format
    when :json
      content = pretty ? JSON.pretty_generate(schema) : JSON.generate(schema)
      filename = 'user_api_schema.json'
    when :yaml
      require 'yaml'
      content = YAML.dump(schema)
      filename = 'user_api_schema.yaml'
    else
      raise ArgumentError, "Unsupported format: #{format}"
    end
    
    File.write(filename, content)
    puts "OpenAPI schema saved to #{filename}"
    puts "Schema preview:"
    puts content[0..500] + (content.length > 500 ? '...' : '')
  end

  private

  def setup_user_endpoints
    endpoints = []

    # List users endpoint
    list_endpoint = RapiTapir.get('/users')
      .summary('List all users')
      .description('Returns a list of all users in the system')
      .out(RapiTapir::Core::Output.new(kind: :json, type: { users: [{ id: :integer, name: :string, email: :string }] }))
    endpoints << list_endpoint

    # Get user by ID endpoint
    get_endpoint = RapiTapir.get('/users/:id')
      .summary('Get user by ID')
      .description('Returns a single user by their ID')
      .in(RapiTapir::Core::Input.new(kind: :path, name: :id, type: :integer))
      .out(RapiTapir::Core::Output.new(kind: :json, type: { id: :integer, name: :string, email: :string }))
    endpoints << get_endpoint

    # Create user endpoint
    create_endpoint = RapiTapir.post('/users')
      .summary('Create a new user')
      .description('Creates a new user with the provided data')
      .in(RapiTapir::Core::Input.new(kind: :body, name: :user_data, type: { name: :string, email: :string }))
      .out(RapiTapir::Core::Output.new(kind: :json, type: { id: :integer, name: :string, email: :string }))
    endpoints << create_endpoint

    # Update user endpoint
    update_endpoint = RapiTapir.put('/users/:id')
      .summary('Update an existing user')
      .description('Updates an existing user with the provided data')
      .in(RapiTapir::Core::Input.new(kind: :path, name: :id, type: :integer))
      .in(RapiTapir::Core::Input.new(kind: :body, name: :user_data, type: { name: :string, email: :string }))
      .out(RapiTapir::Core::Output.new(kind: :json, type: { id: :integer, name: :string, email: :string }))
    endpoints << update_endpoint

    # Delete user endpoint
    delete_endpoint = RapiTapir.delete('/users/:id')
      .summary('Delete a user')
      .description('Deletes a user by their ID')
      .in(RapiTapir::Core::Input.new(kind: :path, name: :id, type: :integer))
      .out(RapiTapir::Core::Output.new(kind: :json, type: { message: :string }))
    endpoints << delete_endpoint

    endpoints
  end
end

# Run the example if this file is executed directly
if __FILE__ == $0
  example = OpenAPIExample.new
  
  puts "Generating OpenAPI schema for User Management API..."
  
  # Generate and save JSON schema
  example.save_schema(format: :json, pretty: true)
  
  puts "\n" + "="*50
  
  # Generate and save YAML schema  
  example.save_schema(format: :yaml)
end
