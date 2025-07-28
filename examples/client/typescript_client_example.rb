# frozen_string_literal: true

require_relative '../../lib/rapitapir'

# Include DSL to use helper methods
include RapiTapir::DSL

# Define the same User API as before
user_api = [
  # Get all users
  RapiTapir.get('/users')
    .out(json_body([{ id: :integer, name: :string, email: :string }]))
    .summary('Get all users')
    .description('Retrieve a list of all users'),

  # Get user by ID
  RapiTapir.get('/users/:id')
    .in(path_param(:id, :integer))
    .out(json_body({ id: :integer, name: :string, email: :string }))
    .summary('Get user by ID')
    .description('Retrieve a specific user by their ID'),

  # Create new user
  RapiTapir.post('/users')
    .in(body({ name: :string, email: :string }))
    .out(json_body({ id: :integer, name: :string, email: :string }))
    .summary('Create new user')
    .description('Create a new user with the provided information'),

  # Update user
  RapiTapir.put('/users/:id')
    .in(path_param(:id, :integer))
    .in(body({ name: :string, email: :string }))
    .out(json_body({ id: :integer, name: :string, email: :string }))
    .summary('Update user')
    .description('Update an existing user'),

  # Delete user
  RapiTapir.delete('/users/:id')
    .in(path_param(:id, :integer))
    .out(json_body({ success: :boolean }))
    .summary('Delete user')
    .description('Delete a user by their ID'),

  # Search users
  RapiTapir.get('/users/search')
    .in(query(:q, :string))
    .in(query(:limit, :integer, optional: true))
    .out(json_body([{ id: :integer, name: :string, email: :string }]))
    .summary('Search users')
    .description('Search for users by name or email')
]

# Generate TypeScript client
puts "Generating TypeScript client..."

generator = RapiTapir::Client::TypescriptGenerator.new(
  endpoints: user_api,
  config: {
    base_url: 'https://api.example.com',
    client_name: 'UserApiClient',
    package_name: '@mycompany/user-api-client',
    version: '1.2.0'
  }
)

# Save to file
output_file = File.join(__dir__, 'user-api-client.ts')
generator.save_to_file(output_file)

puts "\nTypeScript client generated successfully!"
puts "File: #{output_file}"
puts "\nTo use the client in your TypeScript project:"
puts "1. Copy the generated file to your project"
puts "2. Install dependencies: npm install"
puts "3. Import and use the client:"
puts ""
puts "```typescript"
puts "import UserApiClient from './user-api-client';"
puts ""
puts "const client = new UserApiClient({"
puts "  baseUrl: 'https://api.example.com',"
puts "  headers: { 'Authorization': 'Bearer your-token' }"
puts "});"
puts ""
puts "// Get all users"
puts "const users = await client.getUsers();"
puts ""
puts "// Get user by ID"
puts "const user = await client.getUsersById({ id: 123 });"
puts ""
puts "// Create new user"
puts "const newUser = await client.createUsers({"
puts "  body: { name: 'John Doe', email: 'john@example.com' }"
puts "});"
puts ""
puts "// Search users"
puts "const searchResults = await client.getUsersSearch({"
puts "  q: 'john',"
puts "  limit: 10"
puts "});"
puts "```"
