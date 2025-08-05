# frozen_string_literal: true

# Enhanced Rails controller example using RapiTapir's new base class
# This demonstrates the improved developer experience that matches Sinatra's elegance
#
# Usage in a Rails app:
# 1. Add this file to app/controllers/
# 2. Add routes using the automatic route generator
# 3. That's it! No boilerplate needed.

require_relative '../../lib/rapitapir'
require_relative '../../lib/rapitapir/server/rails/controller_base'

class EnhancedUsersController < RapiTapir::Server::Rails::ControllerBase
  # Configure RapiTapir - same clean syntax as Sinatra
  rapitapir do
    info(
      title: 'Enhanced Users API',
      description: 'A clean, type-safe user management API built with RapiTapir for Rails',
      version: '1.0.0'
    )
    # Future: development_defaults! will auto-setup CORS, docs, health checks
  end

  # Define schema using T shortcut (automatically available!)
  USER_SCHEMA = T.hash({
    "id" => T.integer,
    "name" => T.string(min_length: 1, max_length: 100),
    "email" => T.email,
    "active" => T.boolean,
    "created_at" => T.datetime,
    "updated_at" => T.datetime
  })

  USER_CREATE_SCHEMA = T.hash({
    "name" => T.string(min_length: 1, max_length: 100),
    "email" => T.email,
    "active" => T.optional(T.boolean)
  })

  USER_UPDATE_SCHEMA = T.hash({
    "name" => T.optional(T.string(min_length: 1, max_length: 100)),
    "email" => T.optional(T.email),
    "active" => T.optional(T.boolean)
  })

  before_action :setup_users_data

  # Option 1: Use the enhanced api_resource DSL (recommended for CRUD)
  api_resource '/users', schema: USER_SCHEMA do
    crud do
      index do
        # Access Rails helpers and instance variables naturally
        users = @users.values
        
        # Apply optional filtering (Rails-style)
        users = users.select { |u| u[:active] } if params[:active] == 'true'
        
        # Simple pagination
        limit = params[:limit]&.to_i || 20
        offset = params[:offset]&.to_i || 0
        
        users[offset, limit] || []
      end
      
      show do |inputs|
        user = @users[inputs[:id]]
        
        # Rails-style error handling
        if user.nil?
          render json: { error: 'User not found' }, status: :not_found
          return
        end
        
        user
      end
      
      create do |inputs|
        new_id = (@users.keys.max || 0) + 1
        
        new_user = {
          id: new_id,
          name: inputs[:body]['name'],
          email: inputs[:body]['email'],
          active: inputs[:body]['active'] || true,
          created_at: Time.now.iso8601,
          updated_at: Time.now.iso8601
        }
        
        @users[new_id] = new_user
        
        # Rails-style status setting
        response.status = 201
        new_user
      end
      
      update do |inputs|
        user = @users[inputs[:id]]
        
        if user.nil?
          render json: { error: 'User not found' }, status: :not_found
          return
        end
        
        # Update fields
        update_data = inputs[:body]
        user[:name] = update_data['name'] if update_data['name']
        user[:email] = update_data['email'] if update_data['email']
        user[:active] = update_data['active'] if update_data.key?('active')
        user[:updated_at] = Time.now.iso8601
        
        @users[inputs[:id]] = user
        user
      end
      
      destroy do |inputs|
        user = @users[inputs[:id]]
        
        if user.nil?
          render json: { error: 'User not found' }, status: :not_found
          return
        end
        
        @users.delete(inputs[:id])
        
        # Rails-style head response
        head :no_content
      end
    end
  end

  # Option 2: Individual endpoint definitions with enhanced HTTP verb DSL
  endpoint(
    GET('/users/active')
      .summary('Get active users')
      .description('Retrieve a list of all active users in the system')
      .tags('Users')
      .query(:limit, T.optional(T.integer(minimum: 1, maximum: 100)), description: 'Maximum number of results')
      .ok(T.array(USER_SCHEMA))
      .build
  ) do |inputs|
    active_users = @users.values.select { |u| u[:active] }
    limit = inputs[:limit] || 20
    active_users.first(limit)
  end

  endpoint(
    POST('/users/bulk')
      .summary('Create multiple users')
      .description('Create multiple users in a single request')
      .tags('Users')
      .json_body(T.array(USER_CREATE_SCHEMA))
      .created(T.array(USER_SCHEMA))
      .bad_request(T.hash({
        "error" => T.string,
        "failed_users" => T.array(T.hash({
          "index" => T.integer,
          "errors" => T.array(T.string)
        }))
      }))
      .build
  ) do |inputs|
    created_users = []
    failed_users = []
    
    inputs[:body].each_with_index do |user_data, index|
      # Simple validation
      errors = []
      errors << 'Name is required' if user_data['name'].nil? || user_data['name'].empty?
      errors << 'Email is required' if user_data['email'].nil? || user_data['email'].empty?
      errors << 'Email already exists' if @users.values.any? { |u| u[:email] == user_data['email'] }
      
      if errors.any?
        failed_users << { index: index, errors: errors }
        next
      end
      
      new_id = (@users.keys.max || 0) + 1
      new_user = {
        id: new_id,
        name: user_data['name'],
        email: user_data['email'],
        active: user_data['active'] || true,
        created_at: Time.now.iso8601,
        updated_at: Time.now.iso8601
      }
      
      @users[new_id] = new_user
      created_users << new_user
    end
    
    if failed_users.any?
      render json: {
        error: 'Some users could not be created',
        failed_users: failed_users
      }, status: :bad_request
      return
    end
    
    response.status = 201
    created_users
  end

  endpoint(
    GET('/users/search')
      .summary('Search users')
      .description('Search users by name or email')
      .tags('Users', 'Search')
      .query(:q, T.string(min_length: 1), description: 'Search query')
      .query(:fields, T.optional(T.array(T.string(enum: %w[name email]))), description: 'Fields to search in')
      .query(:limit, T.optional(T.integer(minimum: 1, maximum: 100)), description: 'Maximum number of results')
      .ok(T.array(USER_SCHEMA))
      .bad_request(T.hash({ "error" => T.string }))
      .build
  ) do |inputs|
    query = inputs[:q].downcase
    fields = inputs[:fields] || %w[name email]
    limit = inputs[:limit] || 20
    
    results = @users.values.select do |user|
      fields.any? do |field|
        user[field.to_sym]&.downcase&.include?(query)
      end
    end
    
    results.first(limit)
  end

  private

  def setup_users_data
    @users = {
      1 => {
        id: 1,
        name: 'John Doe',
        email: 'john@example.com',
        active: true,
        created_at: 1.week.ago.iso8601,
        updated_at: 1.week.ago.iso8601
      },
      2 => {
        id: 2,
        name: 'Jane Smith',
        email: 'jane@example.com',
        active: true,
        created_at: 3.days.ago.iso8601,
        updated_at: 3.days.ago.iso8601
      },
      3 => {
        id: 3,
        name: 'Bob Wilson',
        email: 'bob@example.com',
        active: false,
        created_at: 1.day.ago.iso8601,
        updated_at: 1.day.ago.iso8601
      }
    }
  end
end

# Example routes configuration for config/routes.rb:
#
# Rails.application.routes.draw do
#   # Option 1: Automatic route generation for specific controller
#   rapitapir_routes_for EnhancedUsersController
#   
#   # Option 2: Auto-discover all RapiTapir controllers
#   rapitapir_auto_routes
#   
#   # Option 3: Manual routes (still works)
#   resources :enhanced_users, only: [:index, :show, :create, :update, :destroy] do
#     collection do
#       get :active
#       post :bulk
#       get :search
#     end
#   end
# end
