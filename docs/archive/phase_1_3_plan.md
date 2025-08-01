# Phase 1.3 - Enhanced Endpoint DSL Implementation Plan

## 🎯 Objectives

Transform RapiTapir into a production-ready API framework with a fluent, chainable DSL that makes endpoint definition elegant and intuitive.

## 🏗️ Core Components to Implement

### 1. Fluent DSL Builder Pattern
- **Chainable methods** for input/output specification
- **Method return optimization** for fluent chaining
- **Type-safe builder** with compile-time validation
- **DSL state management** for consistent building

### 2. Enhanced Input/Output DSL
- **Simplified input methods**: `.query()`, `.path_param()`, `.header()`, `.body()`
- **Output specification**: `.responds_with()`, `.json_response()`, `.error_response()`
- **Status code handling**: `.status()`, `.created()`, `.no_content()`
- **Content-type specification**: automatic and manual

### 3. Advanced Authentication DSL
- **Multiple auth schemes**: Bearer, API Key, Basic, OAuth2
- **Scope-based permissions**: `.requires_scope()`, `.requires_permission()`
- **Optional authentication**: `.optional_auth()`
- **Custom auth handlers**: `.custom_auth()`

### 4. Path Composition & Routing
- **Path variables**: automatic extraction and validation
- **Path prefixes**: `.prefix()`, `.namespace()`
- **Route grouping**: logical endpoint organization
- **Path parameter constraints**: type and format validation

### 5. Error Handling Enhancement
- **oneOf responses**: multiple possible response types
- **Error mapping**: automatic validation error to HTTP error conversion
- **Custom error schemas**: domain-specific error formats
- **Error composition**: reusable error definitions

### 6. Middleware Integration
- **Request middleware**: preprocessing and validation
- **Response middleware**: post-processing and formatting
- **Error middleware**: custom error handling
- **Conditional middleware**: apply based on conditions

## 📝 Example Target DSL

```ruby
# Goal: This is what we want to achieve
user_api = RapiTapir.namespace("/api/v1/users")
  .bearer_auth("User management API")
  .middleware(AuthenticationMiddleware)
  .error_responses do
    unauthorized(401, "Authentication required")
    forbidden(403, "Insufficient permissions") 
    server_error(500, "Internal server error")
  end

get_users = user_api.get("/")
  .summary("List users")
  .description("Retrieve a paginated list of users")
  .query(:limit, :integer, min: 1, max: 100, default: 10, description: "Number of users to return")
  .query(:offset, :integer, min: 0, default: 0, description: "Number of users to skip")
  .query(:search, :string, required: false, description: "Search term for user names")
  .requires_scope("users:read")
  .responds_with(200, json: UserListSchema, description: "Successful response")
  .responds_with(400, json: ValidationErrorSchema, description: "Invalid parameters")

get_user = user_api.get("/{id}")
  .summary("Get user by ID")
  .path_param(:id, :uuid, description: "User ID")
  .requires_scope("users:read")
  .responds_with(200, json: UserSchema)
  .responds_with(404, json: ErrorSchema, description: "User not found")

create_user = user_api.post("/")
  .summary("Create new user")
  .json_body(CreateUserSchema, description: "User data")
  .requires_scope("users:write")
  .responds_with(201, json: UserSchema, description: "User created successfully")
  .responds_with(400, json: ValidationErrorSchema, description: "Invalid user data")
  .responds_with(409, json: ErrorSchema, description: "User already exists")

update_user = user_api.put("/{id}")
  .summary("Update user")
  .path_param(:id, :uuid)
  .json_body(UpdateUserSchema)
  .requires_scope("users:write")
  .responds_with(200, json: UserSchema, description: "User updated")
  .responds_with(404, json: ErrorSchema, description: "User not found")
  .responds_with(400, json: ValidationErrorSchema, description: "Invalid update data")
```

## 🔧 Implementation Strategy

### Phase 1.3.1: Core DSL Builder
1. Create `FluentEndpointBuilder` class
2. Implement chainable method pattern
3. Add state management and validation
4. Test basic chaining functionality

### Phase 1.3.2: Input/Output DSL
1. Enhanced input specification methods
2. Response specification with status codes
3. Content-type and format handling
4. Validation integration

### Phase 1.3.3: Authentication & Security
1. Multiple authentication scheme support
2. Scope and permission management
3. Security requirement composition
4. Custom authentication handlers

### Phase 1.3.4: Advanced Features
1. Path composition and namespacing
2. Error handling enhancement
3. Middleware integration
4. Route grouping and organization

### Phase 1.3.5: Integration & Testing
1. Server adapter integration
2. Comprehensive test suite
3. Real-world usage examples
4. Performance optimization

## 🎯 Success Criteria

- ✅ Fluent, chainable DSL for endpoint definition
- ✅ Type-safe input/output specification
- ✅ Multiple authentication schemes
- ✅ Advanced error handling
- ✅ Middleware integration
- ✅ Path composition and routing
- ✅ Comprehensive test coverage
- ✅ Production-ready performance

Let's start implementing! 🚀
