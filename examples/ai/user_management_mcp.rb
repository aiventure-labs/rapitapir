# frozen_string_literal: true

require_relative '../../lib/rapitapir'
require_relative '../../lib/rapitapir/endpoint_registry'

# Example: User Management API with MCP Export
# This demonstrates how to mark endpoints for MCP export for AI/LLM consumption

class UserManagementAPI
  include RapiTapir::DSL

  # User schema for consistent typing
  USER_SCHEMA = {
    id: :integer,
    name: :string,
    email: :string,
    created_at: :datetime
  }.freeze

  # Endpoint 1: Get user by ID - marked for MCP export
  GET_USER = RapiTapir.get('/users/{id}')
    .in(path_param(:id, :integer))
    .out(json_body(USER_SCHEMA))
    .summary('Retrieve a user by ID')
    .description('Fetches a single user record by their unique identifier')
    .mcp_export  # Mark for MCP export

  # Endpoint 2: Create new user - marked for MCP export  
  CREATE_USER = RapiTapir.post('/users')
    .in(json_body({
      name: :string,
      email: :string
    }))
    .out(status_code(201))
    .out(json_body(USER_SCHEMA))
    .summary('Create a new user')
    .description('Creates a new user account with name and email')
    .mcp_export  # Mark for MCP export

  # Endpoint 3: Update user - NOT marked for MCP export
  UPDATE_USER = RapiTapir.put('/users/{id}')
    .in(path_param(:id, :integer))
    .in(json_body({
      name: :string,
      email: :string
    }))
    .out(json_body(USER_SCHEMA))
    .summary('Update an existing user')
    .description('Updates user information')
    # No .mcp_export - this endpoint won't be included in MCP context

  # Endpoint 4: List users with pagination - marked for MCP export
  LIST_USERS = RapiTapir.get('/users')
    .in(query(:page, :integer, required: false))
    .in(query(:limit, :integer, required: false))
    .out(json_body({
      users: [:array, USER_SCHEMA],
      total: :integer,
      page: :integer,
      limit: :integer
    }))
    .summary('List all users')
    .description('Retrieves a paginated list of all users')
    .mcp_export  # Mark for MCP export

  # Store endpoints for export
  ALL_ENDPOINTS = [GET_USER, CREATE_USER, UPDATE_USER, LIST_USERS].freeze

  # Register endpoints in global registry
  RapiTapir::EndpointRegistry.register_all(ALL_ENDPOINTS)
end

# Usage demonstration
if __FILE__ == $PROGRAM_NAME
  puts "User Management API Example"
  puts "==========================="
  
  # Show which endpoints are marked for MCP export
  mcp_endpoints = UserManagementAPI::ALL_ENDPOINTS.select(&:mcp_export?)
  puts "\nEndpoints marked for MCP export:"
  mcp_endpoints.each do |ep|
    puts "- #{ep.method.upcase} #{ep.path} (#{ep.metadata[:summary]})"
  end
  
  # Generate MCP context
  require_relative '../../lib/rapitapir/ai/mcp'
  exporter = RapiTapir::AI::MCP::Exporter.new(UserManagementAPI::ALL_ENDPOINTS)
  mcp_context = exporter.as_mcp_context
  
  puts "\nGenerated MCP Context:"
  puts JSON.pretty_generate(mcp_context)
end
