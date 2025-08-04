# Enterprise RapiTapir API - Auto-Generated OpenAPI Implementation

This is the improved version of the Enterprise Sinatra API that demonstrates RapiTapir's capability to automatically generate OpenAPI 3.0 specifications from endpoint definitions at runtime.

## 🎯 Key Improvements

### ✅ **Fixed Issues from Original Version**

1. **Auto-Generated OpenAPI**: The OpenAPI specification is now generated automatically from RapiTapir endpoint definitions at runtime, not manually written
2. **Working Run Script**: Fixed the `run_enterprise_api.rb` script to properly load dependencies with `bundle exec`
3. **Proper RapiTapir DSL Usage**: All endpoints are now defined using RapiTapir's fluent DSL with proper type definitions
4. **Runtime Reflection**: The API documentation reflects the actual endpoint implementations

### 🚀 **Enterprise Features**

- **8 Fully-Typed Endpoints** defined with RapiTapir DSL
- **Auto-Generated OpenAPI 3.0** specification from endpoint definitions
- **Bearer Token Authentication** with scope-based authorization
- **Production Middleware Stack**: CORS, Rate Limiting, Security Headers
- **Interactive Documentation** with Swagger UI
- **Type-Safe Request/Response** schemas using RapiTapir Types

## 📋 API Endpoints (Auto-Generated from RapiTapir Definitions)

All endpoints are defined using RapiTapir's fluent DSL and automatically generate OpenAPI documentation:

### System Endpoints
- **GET /health** - Health check (public)
- **GET /docs** - Interactive Swagger UI documentation  
- **GET /openapi.json** - Auto-generated OpenAPI 3.0 specification

### Task Management Endpoints (Authenticated)
- **GET /api/v1/tasks** - List all tasks (requires `read` scope)
- **GET /api/v1/tasks/:id** - Get specific task (requires `read` scope)
- **POST /api/v1/tasks** - Create new task (requires `write` scope)
- **PUT /api/v1/tasks/:id** - Update task (requires `write` scope)
- **DELETE /api/v1/tasks/:id** - Delete task (requires `admin` scope)

### User Endpoints (Authenticated)
- **GET /api/v1/profile** - Get current user profile with assigned tasks
- **GET /api/v1/admin/users** - List all users (requires `admin` scope)

## 🔑 Authentication

Three test Bearer tokens are provided:

```bash
# Regular user (read, write permissions)
Authorization: Bearer user-token-123

# Admin user (read, write, admin, delete permissions) 
Authorization: Bearer admin-token-456

# Read-only user (read permission only)
Authorization: Bearer readonly-token-789
```

## 🏃‍♂️ **Running the API**

### Start the Server
```bash
cd /Users/riccardo/git/github/riccardomerolla/rapitapir
bundle exec ruby examples/run_enterprise_api.rb
```

### Access Documentation
- **Interactive Docs**: http://localhost:4567/docs
- **OpenAPI Spec**: http://localhost:4567/openapi.json  
- **Health Check**: http://localhost:4567/health

## 📖 **Example API Calls**

### Health Check (Public)
```bash
curl http://localhost:4567/health
```

### List Tasks (Authenticated)
```bash
curl -H "Authorization: Bearer user-token-123" \
     http://localhost:4567/api/v1/tasks
```

### Create Task (Authenticated)
```bash
curl -X POST \
     -H "Authorization: Bearer user-token-123" \
     -H "Content-Type: application/json" \
     -d '{"title":"New Task","description":"Test task","assignee_id":1}' \
     http://localhost:4567/api/v1/tasks
```

### Get User Profile (Authenticated)
```bash
curl -H "Authorization: Bearer user-token-123" \
     http://localhost:4567/api/v1/profile
```

### Admin: List All Users (Admin Only)
```bash
curl -H "Authorization: Bearer admin-token-456" \
     http://localhost:4567/api/v1/admin/users
```

## 🎯 **RapiTapir DSL Example**

The endpoints are defined using RapiTapir's fluent DSL with full type safety:

```ruby
# Task creation endpoint with full type validation
RapiTapir.post('/api/v1/tasks')
  .summary('Create a new task')
  .description('Create a new task in the system. Requires write permission.')
  .json_body(TASK_CREATE_SCHEMA)  # RapiTapir type schema
  .created(TASK_SCHEMA)           # Response type validation
  .error_response(400, ERROR_SCHEMA, description: 'Validation error')
  .error_response(401, ERROR_SCHEMA, description: 'Authentication required')
  .error_response(403, ERROR_SCHEMA, description: 'Insufficient permissions')
  .build
```

## 🔧 **Auto-Generated OpenAPI Features**

The OpenAPI specification is generated automatically from the RapiTapir endpoint definitions:

- **Path Parameters**: Automatically extracted from `:id` patterns
- **Query Parameters**: Type-safe with validation rules
- **Request Bodies**: JSON schema validation from RapiTapir types
- **Response Schemas**: Type-safe response definitions
- **Error Responses**: Comprehensive error documentation
- **Security Schemes**: Bearer token authentication documented
- **Operation Metadata**: Summaries, descriptions, and tags

## 🏗️ **Architecture Highlights**

### Type-Safe Schema Definitions
```ruby
TASK_SCHEMA = RapiTapir::Types.hash({
  "id" => RapiTapir::Types.integer,
  "title" => RapiTapir::Types.string,
  "description" => RapiTapir::Types.string,
  "status" => RapiTapir::Types.string,
  "assignee_id" => RapiTapir::Types.integer,
  "created_at" => RapiTapir::Types.string,
  "updated_at" => RapiTapir::Types.optional(RapiTapir::Types.string)
})
```

### Auto-Generated OpenAPI
```ruby
def self.openapi_spec
  @openapi_spec ||= begin
    generator = RapiTapir::OpenAPI::SchemaGenerator.new(
      endpoints: endpoints,
      info: { title: 'Enterprise Task Management API', version: '1.0.0' }
    )
    generator.generate
  end
end
```

### Sinatra Integration
```ruby
# OpenAPI endpoint auto-generated at runtime
get '/openapi.json' do
  content_type :json
  JSON.pretty_generate(TaskAPI.openapi_spec)
end
```

## ✨ **Production Features**

- **Security Headers**: XSS protection, content type options
- **CORS Support**: Configurable origins and methods
- **Rate Limiting**: 100 requests/minute, 2000/hour
- **Request Validation**: Type-safe input validation
- **Error Handling**: Structured error responses
- **Authentication Middleware**: Bearer token validation
- **Authorization**: Scope-based permission checking

## 🧪 **Testing**

Run the comprehensive test suite:

```bash
# Test RapiTapir endpoint definitions
ruby examples/test_rapitapir_endpoints.rb

# Test the full enterprise API (requires server to be running)
ruby examples/test_enterprise_api.rb
```

## 🎉 **Benefits of This Approach**

1. **Single Source of Truth**: API endpoints defined once in RapiTapir DSL
2. **Auto-Generated Documentation**: OpenAPI spec reflects actual implementation
3. **Type Safety**: Request/response validation with RapiTapir types  
4. **Developer Experience**: Interactive Swagger UI for testing
5. **Production Ready**: Comprehensive middleware and security
6. **Maintainable**: No manual OpenAPI spec maintenance required

This implementation demonstrates the power of RapiTapir's DSL and auto-generation capabilities in creating production-ready APIs with comprehensive documentation.
