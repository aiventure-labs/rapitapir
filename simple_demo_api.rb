require_relative 'lib/rapitapir'
include RapiTapir::DSL

# Simple API endpoints for demonstration
user_list = RapiTapir.get('/users')
  .out(json_body([{ id: :integer, name: :string, email: :string }]))
  .summary('List all users')
  .description('Retrieve a paginated list of all users in the system')

create_user = RapiTapir.post('/users')
  .in(body({ name: :string, email: :string, password: :string }))
  .out(status_code(201), json_body({ id: :integer, name: :string, email: :string }))
  .error_out(400, json_body({ error: :string, validation_errors: [:string] }))
  .error_out(422, json_body({ error: :string, message: :string }))
  .summary('Create new user')
  .description('Create a new user account with the provided information')
