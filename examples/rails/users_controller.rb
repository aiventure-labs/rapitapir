# frozen_string_literal: true

# Example Rails controller using RapiTapir
#
# To use this in a Rails app:
# 1. Add this file to app/controllers/
# 2. Include RapiTapir::Server::Rails::Controller
# 3. Define endpoints using rapitapir_endpoint
# 4. Call process_rapitapir_endpoint in your action methods

require_relative '../../lib/rapitapir'
require_relative '../../lib/rapitapir/server/rails_adapter'

class UsersController < ApplicationController
  include RapiTapir::Server::Rails::Controller

  before_action :setup_users_data

  # Define RapiTapir endpoints
  rapitapir_endpoint :index, RapiTapir.get('/users')
                                      .summary('List all users')
                                      .description('Returns a list of all users in the system')
                                      .out(RapiTapir::Core::Output.new(kind: :json, type: { users: Array })) do |_inputs|
    { users: @users.values }
  end

  rapitapir_endpoint :show, RapiTapir.get('/users/:id')
                                     .summary('Get user by ID')
                                     .description('Returns a single user by their ID')
                                     .in(RapiTapir::Core::Input.new(kind: :path, name: :id, type: :integer))
                                     .out(RapiTapir::Core::Output.new(kind: :json, type: { id: :integer, name: :string, email: :string })) do |inputs|
    user_id = inputs[:id]
    user = @users[user_id]

    raise ArgumentError, 'User not found' unless user

    user
  end

  rapitapir_endpoint :create, RapiTapir.post('/users')
                                       .summary('Create a new user')
                                       .description('Creates a new user with the provided data')
                                       .in(RapiTapir::Core::Input.new(kind: :body, name: :user_data, type: Hash))
                                       .out(RapiTapir::Core::Output.new(kind: :json, type: { id: :integer, name: :string, email: :string })) do |inputs|
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

  rapitapir_endpoint :update, RapiTapir.put('/users/:id')
                                       .summary('Update an existing user')
                                       .description('Updates an existing user with the provided data')
                                       .in(RapiTapir::Core::Input.new(kind: :path, name: :id, type: :integer))
                                       .in(RapiTapir::Core::Input.new(kind: :body, name: :user_data, type: Hash))
                                       .out(RapiTapir::Core::Output.new(kind: :json, type: { id: :integer, name: :string, email: :string })) do |inputs|
    user_id = inputs[:id]
    user_data = inputs[:user_data]

    raise ArgumentError, 'User not found' unless @users[user_id]

    @users[user_id].merge!(
      name: user_data['name'] || @users[user_id][:name],
      email: user_data['email'] || @users[user_id][:email]
    )

    @users[user_id]
  end

  rapitapir_endpoint :destroy, RapiTapir.delete('/users/:id')
                                        .summary('Delete a user')
                                        .description('Deletes a user by their ID')
                                        .in(RapiTapir::Core::Input.new(kind: :path, name: :id, type: :integer))
                                        .out(RapiTapir::Core::Output.new(kind: :json, type: { message: :string })) do |inputs|
    user_id = inputs[:id]

    raise ArgumentError, 'User not found' unless @users[user_id]

    @users.delete(user_id)
    { message: "User #{user_id} deleted successfully" }
  end

  # Controller actions
  def index
    process_rapitapir_endpoint
  end

  def show
    process_rapitapir_endpoint
  end

  def create
    process_rapitapir_endpoint
  end

  def update
    process_rapitapir_endpoint
  end

  def destroy
    process_rapitapir_endpoint
  end

  private

  def setup_users_data
    @users = {
      1 => { id: 1, name: 'John Doe', email: 'john@example.com' },
      2 => { id: 2, name: 'Jane Smith', email: 'jane@example.com' }
    }
  end
end

# Example config/routes.rb content:
#
# Rails.application.routes.draw do
#   resources :users, only: [:index, :show, :create, :update, :destroy]
# end
#
# Or using the RailsAdapter for automatic route generation:
#
# adapter = RapiTapir::Server::Rails::RailsAdapter.new
# adapter.register_endpoint(list_endpoint, UsersController, :index)
# adapter.register_endpoint(show_endpoint, UsersController, :show)
# # ... etc
# adapter.generate_routes(Rails.application.routes)
