# frozen_string_literal: true

# Add the lib directory to the load path
lib_path = File.expand_path('../lib', __dir__)
$LOAD_PATH.unshift(lib_path) unless $LOAD_PATH.include?(lib_path)

require 'rapitapir'

# Include DSL to use helper methods
include RapiTapir::DSL

# Define endpoints for CLI usage
[
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
