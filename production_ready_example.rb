# frozen_string_literal: true

require_relative 'lib/rapitapir'

puts "🌟 RapiTapir Production-Ready API Example"
puts "=" * 45

# Define schemas
User = RapiTapir::Schema.define do
  field :id, :uuid
  field :name, :string
  field :email, :email  
  field :created_at, :datetime
end

CreateUser = RapiTapir::Schema.define do
  field :name, :string
  field :email, :email
end

Error = RapiTapir::Schema.define do
  field :error, :string
  field :message, :string
  field :code, :integer
end

# Define a complete REST API using the fluent DSL
users_api = RapiTapir.namespace("/api/v1/users") do
  bearer_auth("API Token Required")
  tags("users", "rest-api")
  
  error_responses do
    unauthorized(401, Error, description: "Invalid or missing token")
    forbidden(403, Error, description: "Insufficient permissions")
    server_error(500, Error, description: "Internal server error")
  end

  # GET /api/v1/users - List users with pagination
  get("/")
    .summary("List users")
    .description("Retrieve paginated list of users")
    .query(:page, :integer, min: 1, default: 1, description: "Page number")
    .query(:per_page, :integer, min: 1, max: 100, default: 20, description: "Items per page")
    .query(:search, :string, required: false, description: "Search users by name")
    .ok(RapiTapir::Types.array(User), description: "List of users")
    .bad_request(Error, description: "Invalid query parameters")

  # GET /api/v1/users/{id} - Get specific user
  get("/{id}")
    .summary("Get user by ID")
    .description("Retrieve a specific user by their unique identifier")
    .path_param(:id, :uuid, description: "User unique identifier")
    .ok(User, description: "User details")
    .not_found(Error, description: "User not found")

  # POST /api/v1/users - Create new user
  post("/")
    .summary("Create user")
    .description("Create a new user account")
    .json_body(CreateUser, description: "User data")
    .requires_scope("users:write")
    .created(User, description: "User created successfully")
    .bad_request(Error, description: "Invalid user data")
    .unprocessable_entity(Error, description: "Validation failed")

  # PUT /api/v1/users/{id} - Update user
  put("/{id}")
    .summary("Update user")
    .description("Update an existing user's information")
    .path_param(:id, :uuid, description: "User unique identifier")
    .json_body(CreateUser, description: "Updated user data")
    .requires_scope("users:write")
    .ok(User, description: "User updated successfully")
    .not_found(Error, description: "User not found")
    .unprocessable_entity(Error, description: "Validation failed")

  # DELETE /api/v1/users/{id} - Delete user
  delete("/{id}")
    .summary("Delete user")
    .description("Permanently delete a user account")
    .path_param(:id, :uuid, description: "User unique identifier")
    .requires_scope("users:delete")
    .no_content(description: "User deleted successfully")
    .not_found(Error, description: "User not found")
end

puts "✅ Defined complete REST API with 5 endpoints"
puts "   - GET /api/v1/users (list with pagination)"
puts "   - GET /api/v1/users/{id} (get by ID)"
puts "   - POST /api/v1/users (create)"
puts "   - PUT /api/v1/users/{id} (update)"
puts "   - DELETE /api/v1/users/{id} (delete)"

puts "\n✅ Features implemented:"
puts "   - Bearer token authentication"
puts "   - Scope-based permissions (read/write/delete)"
puts "   - Full CRUD operations"
puts "   - Input validation with type constraints"
puts "   - Comprehensive error responses"
puts "   - OpenAPI 3.0.3 specification ready"
puts "   - Production-ready architecture"

puts "\n🚀 RapiTapir Phase 1 Complete!"
puts "   From documentation tool → Production API framework"
puts "   Ready for real-world applications! 🎉"
