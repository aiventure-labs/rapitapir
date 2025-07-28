require_relative 'lib/rapitapir'
include RapiTapir::DSL

# Simple API endpoints for Phase 4 demonstration
user_list = RapiTapir.get('/users')
  .out(json_body([{ id: :integer, name: :string, email: :string }]))
  .summary('List all users')
  .description('Retrieve a paginated list of all users in the system')

create_user = RapiTapir.post('/users')
  .in(body({ name: :string, email: :string }))
  .out(json_body({ id: :integer, name: :string, email: :string }))
  .summary('Create new user')
  .description('Create a new user account with the provided information')
