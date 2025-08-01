# frozen_string_literal: true

require 'date'
require_relative '../lib/rapitapir'

# Example: User Management API
module UserAPI
  extend RapiTapir::DSL

  # GET /users - List all users
  LIST_USERS = RapiTapir.get('/users')
                        .in(query(:page, :integer, optional: true))
                        .in(query(:limit, :integer, optional: true))
                        .in(query(:search, :string, optional: true))
                        .in(header(:authorization, :string))
                        .out(status_code(200))
                        .out(json_body({
                                         users: [{ id: :integer, name: :string, email: :string }],
                                         total: :integer,
                                         page: :integer,
                                         limit: :integer
                                       }))
                        .error_out(401, json_body({ error: :string }))
                        .error_out(500, json_body({ error: :string }))
                        .description('Retrieve a paginated list of users')
                        .summary('List users')
                        .tag('users')

  # GET /users/:id - Get specific user
  GET_USER = RapiTapir.get('/users/:id')
                      .in(path_param(:id, :integer))
                      .in(header(:authorization, :string))
                      .out(status_code(200))
                      .out(json_body({ id: :integer, name: :string, email: :string, created_at: :datetime }))
                      .error_out(401, json_body({ error: :string }))
                      .error_out(404, json_body({ error: :string }))
                      .error_out(500, json_body({ error: :string }))
                      .description('Retrieve a specific user by ID')
                      .summary('Get user')
                      .tag('users')

  # POST /users - Create new user
  CREATE_USER = RapiTapir.post('/users')
                         .in(header(:authorization, :string))
                         .in(header(:'content-type', :string))
                         .in(body({ name: :string, email: :string, password: :string }))
                         .out(status_code(201))
                         .out(json_body({ id: :integer, name: :string, email: :string, created_at: :datetime }))
                         .error_out(400, json_body({ error: :string, details: :string }))
                         .error_out(401, json_body({ error: :string }))
                         .error_out(422, json_body({ error: :string,
                                                     validation_errors: [{ field: :string, message: :string }] }))
                         .error_out(500, json_body({ error: :string }))
                         .description('Create a new user account')
                         .summary('Create user')
                         .tag('users')

  # PUT /users/:id - Update user
  UPDATE_USER = RapiTapir.put('/users/:id')
                         .in(path_param(:id, :integer))
                         .in(header(:authorization, :string))
                         .in(header(:'content-type', :string))
                         .in(body({ name: :string, email: :string }))
                         .out(status_code(200))
                         .out(json_body({ id: :integer, name: :string, email: :string, updated_at: :datetime }))
                         .error_out(400, json_body({ error: :string, details: :string }))
                         .error_out(401, json_body({ error: :string }))
                         .error_out(404, json_body({ error: :string }))
                         .error_out(422, json_body({ error: :string,
                                                     validation_errors: [{ field: :string, message: :string }] }))
                         .error_out(500, json_body({ error: :string }))
                         .description('Update an existing user')
                         .summary('Update user')
                         .tag('users')

  # DELETE /users/:id - Delete user
  DELETE_USER = RapiTapir.delete('/users/:id')
                         .in(path_param(:id, :integer))
                         .in(header(:authorization, :string))
                         .out(status_code(204))
                         .error_out(401, json_body({ error: :string }))
                         .error_out(404, json_body({ error: :string }))
                         .error_out(500, json_body({ error: :string }))
                         .description('Delete a user account')
                         .summary('Delete user')
                         .tag('users')

  # POST /users/login - User authentication
  LOGIN_USER = RapiTapir.post('/users/login')
                        .in(header(:'content-type', :string))
                        .in(body({ email: :string, password: :string }))
                        .out(status_code(200))
                        .out(json_body({
                                         user: { id: :integer, name: :string, email: :string },
                                         token: :string,
                                         expires_at: :datetime
                                       }))
                        .error_out(400, json_body({ error: :string }))
                        .error_out(401, json_body({ error: :string }))
                        .error_out(500, json_body({ error: :string }))
                        .description('Authenticate user and return access token')
                        .summary('User login')
                        .tag('authentication')

  # Example usage and validation
  def self.demo
    puts '=== RapiTapir User API Demo ==='
    puts

    # Example 1: Valid user creation
    puts '1. Valid user creation:'
    input_data = {
      body: { name: 'John Doe', email: 'john@example.com', password: 'secret123' }
    }
    output_data = {
      id: 1,
      name: 'John Doe',
      email: 'john@example.com',
      created_at: DateTime.now
    }

    begin
      CREATE_USER.validate!(input_data, output_data)
      puts '✓ Validation passed'
    rescue StandardError => e
      puts "✗ Validation failed: #{e.message}"
    end
    puts

    # Example 2: Invalid user creation (missing required field)
    puts '2. Invalid user creation (missing password):'
    invalid_input = {
      body: { name: 'John Doe', email: 'john@example.com' }
    }

    begin
      CREATE_USER.validate!(invalid_input, output_data)
      puts '✓ Validation passed'
    rescue StandardError => e
      puts "✗ Validation failed: #{e.message}"
    end
    puts

    # Example 3: Valid user listing
    puts '3. Valid user listing:'
    list_input = {}
    list_output = {
      users: [
        { id: 1, name: 'John Doe', email: 'john@example.com' },
        { id: 2, name: 'Jane Smith', email: 'jane@example.com' }
      ],
      total: 2,
      page: 1,
      limit: 10
    }

    begin
      LIST_USERS.validate!(list_input, list_output)
      puts '✓ Validation passed'
    rescue StandardError => e
      puts "✗ Validation failed: #{e.message}"
    end
    puts

    # Example 4: Endpoint metadata
    puts '4. Endpoint metadata:'
    puts 'GET /users:'
    puts "  Description: #{GET_USER.metadata[:description]}"
    puts "  Summary: #{GET_USER.metadata[:summary]}"
    puts "  Tag: #{GET_USER.metadata[:tag]}"
    puts "  Inputs: #{GET_USER.inputs.length}"
    puts "  Outputs: #{GET_USER.outputs.length}"
    puts "  Error responses: #{GET_USER.errors.length}"
    puts

    # Example 5: Serialization
    puts '5. Output serialization:'
    json_output = CREATE_USER.outputs.find { |o| o.kind == :json }
    if json_output
      serialized = json_output.serialize(output_data)
      puts "JSON: #{serialized}"
    end
    puts

    puts '=== Demo Complete ==='
  end
end

# Run the demo if this file is executed directly
UserAPI.demo if __FILE__ == $PROGRAM_NAME
