# frozen_string_literal: true

require 'sinatra'
require 'json'
require_relative '../../lib/rapitapir'
require_relative '../../lib/rapitapir/server/sinatra_adapter'

# Example Sinatra app using RapiTapir
class UserSinatraApp < Sinatra::Base
  def initialize
    super
    @users = {
      1 => { id: 1, name: 'John Doe', email: 'john@example.com' },
      2 => { id: 2, name: 'Jane Smith', email: 'jane@example.com' }
    }

    setup_rapitapir_endpoints
  end

  private

  def setup_rapitapir_endpoints
    adapter = RapiTapir::Server::SinatraAdapter.new(self)

    # List users endpoint
    list_endpoint = RapiTapir.get('/users')
                             .summary('List all users')
                             .out(RapiTapir::Core::Output.new(kind: :json, type: { users: Array }))

    adapter.register_endpoint(list_endpoint) do |_inputs|
      { users: @users.values }
    end

    # Get user by ID endpoint
    get_endpoint = RapiTapir.get('/users/:id')
                            .summary('Get user by ID')
                            .in(RapiTapir::Core::Input.new(kind: :path, name: :id, type: :integer))
                            .out(RapiTapir::Core::Output.new(kind: :json,
                                                             type: {
                                                               id: :integer, name: :string, email: :string
                                                             }))

    adapter.register_endpoint(get_endpoint) do |inputs|
      user_id = inputs[:id]
      user = @users[user_id]

      raise ArgumentError, 'User not found' unless user

      user
    end

    # Create user endpoint
    create_endpoint = RapiTapir.post('/users')
                               .summary('Create a new user')
                               .in(RapiTapir::Core::Input.new(kind: :body, name: :user_data, type: Hash))
                               .out(RapiTapir::Core::Output.new(kind: :json,
                                                                type: {
                                                                  id: :integer, name: :string, email: :string
                                                                }))

    adapter.register_endpoint(create_endpoint) do |inputs|
      user_data = inputs[:user_data]
      new_id = (@users.keys.max || 0) + 1

      new_user = {
        id: new_id,
        name: user_data['name'],
        email: user_data['email']
      }

      @users[new_id] = new_user
      new_user
    end

    # Update user endpoint
    update_endpoint = RapiTapir.put('/users/:id')
                               .summary('Update an existing user')
                               .in(RapiTapir::Core::Input.new(kind: :path, name: :id, type: :integer))
                               .in(RapiTapir::Core::Input.new(kind: :body, name: :user_data, type: Hash))
                               .out(RapiTapir::Core::Output.new(kind: :json,
                                                                type: {
                                                                  id: :integer, name: :string, email: :string
                                                                }))

    adapter.register_endpoint(update_endpoint) do |inputs|
      user_id = inputs[:id]
      user_data = inputs[:user_data]

      raise ArgumentError, 'User not found' unless @users[user_id]

      @users[user_id].merge!(
        name: user_data['name'] || @users[user_id][:name],
        email: user_data['email'] || @users[user_id][:email]
      )

      @users[user_id]
    end

    # Delete user endpoint
    delete_endpoint = RapiTapir.delete('/users/:id')
                               .summary('Delete a user')
                               .in(RapiTapir::Core::Input.new(kind: :path, name: :id, type: :integer))
                               .out(RapiTapir::Core::Output.new(kind: :json, type: { message: :string }))

    adapter.register_endpoint(delete_endpoint) do |inputs|
      user_id = inputs[:id]

      raise ArgumentError, 'User not found' unless @users[user_id]

      @users.delete(user_id)
      { message: "User #{user_id} deleted successfully" }
    end
  end
end

# Run the app if this file is executed directly
if __FILE__ == $PROGRAM_NAME
  puts 'Starting RapiTapir Sinatra User API server on http://localhost:4567'
  puts 'Available endpoints:'
  puts '  GET    /users       - List all users'
  puts '  GET    /users/:id   - Get user by ID'
  puts '  POST   /users       - Create new user'
  puts '  PUT    /users/:id   - Update user'
  puts '  DELETE /users/:id   - Delete user'

  UserSinatraApp.run!
end
