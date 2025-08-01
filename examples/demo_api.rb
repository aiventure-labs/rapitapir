# frozen_string_literal: true

require_relative 'lib/rapitapir'
include RapiTapir::DSL

# Sample API endpoints for demonstration
RapiTapir.get('/users')
         .out(json_body([{ id: :integer, name: :string, email: :string }]))
         .summary('List all users')
         .description('Retrieve a paginated list of all users in the system')

RapiTapir.get('/users/:id')
         .in(path_param(:id, :integer))
         .out(json_body({ id: :integer, name: :string, email: :string, created_at: :string }))
         .error_out(404, json_body({ error: :string, message: :string }))
         .summary('Get user by ID')
         .description('Retrieve detailed information about a specific user')

RapiTapir.post('/users')
         .in(json_body({ name: :string, email: :string, password: :string }))
         .out(status_code(201), json_body({ id: :integer, name: :string, email: :string }))
         .error_out(400, json_body({ error: :string, validation_errors: [:string] }))
         .error_out(422, json_body({ error: :string, message: :string }))
         .summary('Create new user')
         .description('Create a new user account with the provided information')

RapiTapir.put('/users/:id')
         .in(path_param(:id, :integer))
         .in(json_body({ name: :string, email: :string }))
         .out(json_body({ id: :integer, name: :string, email: :string, updated_at: :string }))
         .error_out(404, json_body({ error: :string, message: :string }))
         .error_out(400, json_body({ error: :string, validation_errors: [:string] }))
         .summary('Update user')
         .description('Update an existing user with new information')

RapiTapir.delete('/users/:id')
         .in(path_param(:id, :integer))
         .out(status_code(204))
         .error_out(404, json_body({ error: :string, message: :string }))
         .summary('Delete user')
         .description('Permanently delete a user account')
