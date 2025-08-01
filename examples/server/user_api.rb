# frozen_string_literal: true

require_relative '../../lib/rapitapir'

# Example demonstrating RapiTapir server functionality
class UserAPI
  def initialize
    @adapter = RapiTapir::Server::RackAdapter.new
    @users = {
      1 => { id: 1, name: 'John Doe', email: 'john@example.com' },
      2 => { id: 2, name: 'Jane Smith', email: 'jane@example.com' }
    }

    setup_middleware
    setup_endpoints
  end

  def app
    @adapter
  end

  private

  def setup_middleware
    # Add CORS middleware
    @adapter.use(RapiTapir::Server::Middleware::CORS, {
                   allow_origin: '*',
                   allow_methods: %w[GET POST PUT DELETE OPTIONS],
                   allow_headers: %w[Content-Type Authorization]
                 })

    # Add logging middleware
    @adapter.use(RapiTapir::Server::Middleware::Logger)
  end

  def setup_endpoints
    setup_list_users
    setup_get_user
    setup_create_user
    setup_update_user
    setup_delete_user
  end

  def setup_list_users
    endpoint = RapiTapir.get('/users')
                        .summary('List all users')
                        .description('Returns a list of all users in the system')
                        .out(RapiTapir::Core::Output.new(kind: :json,
                                                         type: { users: [{
                                                           id: :integer, name: :string, email: :string
                                                         }] }))

    @adapter.register_endpoint(endpoint, method(:list_users))
  end

  def setup_get_user
    endpoint = RapiTapir.get('/users/:id')
                        .summary('Get user by ID')
                        .description('Returns a single user by their ID')
                        .in(RapiTapir::Core::Input.new(kind: :path, name: :id, type: :integer))
                        .out(RapiTapir::Core::Output.new(kind: :json,
                                                         type: {
                                                           id: :integer, name: :string, email: :string
                                                         }))

    @adapter.register_endpoint(endpoint, method(:get_user))
  end

  def setup_create_user
    endpoint = RapiTapir.post('/users')
                        .summary('Create a new user')
                        .description('Creates a new user with the provided data')
                        .in(RapiTapir::Core::Input.new(kind: :body, name: :user_data, type: Hash))
                        .out(RapiTapir::Core::Output.new(kind: :json,
                                                         type: {
                                                           id: :integer, name: :string, email: :string
                                                         }))

    @adapter.register_endpoint(endpoint, method(:create_user))
  end

  def setup_update_user
    endpoint = RapiTapir.put('/users/:id')
                        .summary('Update an existing user')
                        .description('Updates an existing user with the provided data')
                        .in(RapiTapir::Core::Input.new(kind: :path, name: :id, type: :integer))
                        .in(RapiTapir::Core::Input.new(kind: :body, name: :user_data, type: Hash))
                        .out(RapiTapir::Core::Output.new(kind: :json,
                                                         type: {
                                                           id: :integer, name: :string, email: :string
                                                         }))

    @adapter.register_endpoint(endpoint, method(:update_user))
  end

  def setup_delete_user
    endpoint = RapiTapir.delete('/users/:id')
                        .summary('Delete a user')
                        .description('Deletes a user by their ID')
                        .in(RapiTapir::Core::Input.new(kind: :path, name: :id, type: :integer))
                        .out(RapiTapir::Core::Output.new(kind: :json, type: { message: :string }))

    @adapter.register_endpoint(endpoint, method(:delete_user))
  end

  # Handler methods
  def list_users(_inputs)
    { users: @users.values }
  end

  def get_user(inputs)
    user_id = inputs[:id]
    user = @users[user_id]

    raise ArgumentError, 'User not found' unless user

    user
  end

  def create_user(inputs)
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

  def update_user(inputs)
    user_id = inputs[:id]
    user_data = inputs[:user_data]

    raise ArgumentError, 'User not found' unless @users[user_id]

    @users[user_id].merge!(
      name: user_data['name'] || @users[user_id][:name],
      email: user_data['email'] || @users[user_id][:email]
    )

    @users[user_id]
  end

  def delete_user(inputs)
    user_id = inputs[:id]

    raise ArgumentError, 'User not found' unless @users[user_id]

    @users.delete(user_id)
    { message: "User #{user_id} deleted successfully" }
  end
end

# Example usage:
if __FILE__ == $PROGRAM_NAME
  require 'rack'

  user_api = UserAPI.new

  puts 'Starting RapiTapir User API server on http://localhost:9292'
  puts 'Available endpoints:'
  puts '  GET    /users       - List all users'
  puts '  GET    /users/:id   - Get user by ID'
  puts '  POST   /users       - Create new user'
  puts '  PUT    /users/:id   - Update user'
  puts '  DELETE /users/:id   - Delete user'
  puts ''
  puts 'Example requests:'
  puts '  curl http://localhost:9292/users'
  puts '  curl http://localhost:9292/users/1'
  puts "  curl -X POST http://localhost:9292/users -H 'Content-Type: application/json' " \
       "-d '{\"name\":\"Bob\",\"email\":\"bob@example.com\"}'"

  Rack::Handler::WEBrick.run(user_api.app, Port: 9292)
end
