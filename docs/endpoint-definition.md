# RapiTapir Endpoint Definition Guide

This comprehensive guide covers the RapiTapir DSL for defining HTTP API endpoints with type safety, validation, and automatic documentation generation.

## Table of Contents

- [Overview](#overview)
- [HTTP Verb Methods](#http-verb-methods)
- [Input Definitions](#input-definitions)
- [Output Definitions](#output-definitions)
- [Metadata and Documentation](#metadata-and-documentation)
- [Advanced Features](#advanced-features)
- [Type System Integration](#type-system-integration)
- [Complete Examples](#complete-examples)

## Overview

RapiTapir provides a fluent, chainable DSL for defining HTTP endpoints. The modern DSL uses HTTP verb methods (`GET()`, `POST()`, etc.) combined with the global `T` shortcut for clean, readable endpoint definitions.

### Basic Structure

```ruby
endpoint(
  HTTP_VERB('/path')
    .input_definitions()     # Query params, path params, headers, body
    .output_definitions()    # Success and error responses
    .metadata()             # Summary, description, tags, etc.
    .build
) do |inputs|
  # Your endpoint implementation
end
```

## HTTP Verb Methods

All standard HTTP methods are available as chainable builders:

```ruby
# All HTTP verbs supported
GET('/users')          # Retrieve resources
POST('/users')         # Create resources  
PUT('/users/:id')      # Update/replace resources
PATCH('/users/:id')    # Partial updates
DELETE('/users/:id')   # Delete resources
OPTIONS('/users')      # CORS preflight
HEAD('/users')         # Headers only
```

### Path Parameters

Define path parameters directly in the URL pattern:

```ruby
GET('/users/:id')              # Single parameter
GET('/users/:id/posts/:post_id') # Multiple parameters
GET('/files/*path')            # Splat parameters
```

## Input Definitions

### Query Parameters

```ruby
GET('/search')
  .query(:q, T.string(min_length: 1), description: 'Search query')
  .query(:limit, T.optional(T.integer(minimum: 1, maximum: 100)), description: 'Results limit')
  .query(:sort, T.optional(T.string(enum: %w[name date relevance])), description: 'Sort order')
  .query(:tags, T.optional(T.array(T.string)), description: 'Filter tags')
```

### Path Parameters

```ruby
GET('/users/:id')
  .path_param(:id, T.integer(minimum: 1), description: 'User ID')

GET('/files/:category/:filename')
  .path_param(:category, T.string(enum: %w[images documents videos]), description: 'File category')
  .path_param(:filename, T.string(pattern: /^[\w\-_.]+$/), description: 'Filename')
```

### Request Headers

```ruby
POST('/upload')
  .header('Content-Type', T.string, description: 'MIME type of uploaded content')
  .header('X-Request-ID', T.optional(T.string), description: 'Request tracking ID')
  .header('Authorization', T.string, description: 'Bearer token')
```

### Request Body

```ruby
# JSON body with schema
POST('/users')
  .body(T.hash({
    "name" => T.string(min_length: 1, max_length: 100),
    "email" => T.email,
    "age" => T.optional(T.integer(minimum: 18, maximum: 120)),
    "preferences" => T.optional(T.hash({
      "theme" => T.string(enum: %w[light dark]),
      "notifications" => T.boolean
    }))
  }), description: 'User data to create')

# File upload
POST('/files')
  .body(T.string, content_type: 'multipart/form-data', description: 'File content')

# Raw binary data
POST('/images')
  .body(T.string, content_type: 'image/jpeg', description: 'JPEG image data')
```

## Output Definitions

### Success Responses

```ruby
GET('/users')
  .ok(T.array(USER_SCHEMA), description: 'List of users')

POST('/users')
  .created(USER_SCHEMA, description: 'Created user')

PUT('/users/:id')  
  .ok(USER_SCHEMA, description: 'Updated user')

DELETE('/users/:id')
  .no_content(description: 'User deleted successfully')
```

### Error Responses

```ruby
GET('/users/:id')
  .ok(USER_SCHEMA)
  .error_response(404, T.hash({
    "error" => T.string,
    "user_id" => T.integer
  }), description: 'User not found')
  .error_response(500, T.hash({
    "error" => T.string,
    "trace_id" => T.string
  }), description: 'Internal server error')

POST('/users')
  .created(USER_SCHEMA)
  .error_response(400, T.hash({
    "error" => T.string,
    "validation_errors" => T.array(T.hash({
      "field" => T.string,
      "message" => T.string,
      "code" => T.string
    }))
  }), description: 'Validation failed')
  .error_response(409, T.hash({
    "error" => T.string,
    "existing_user_id" => T.integer
  }), description: 'User already exists')
```

### Multiple Response Types

```ruby
GET('/content/:id')
  .path_param(:id, T.integer)
  .query(:format, T.optional(T.string(enum: %w[json xml])), description: 'Response format')
  .ok(CONTENT_SCHEMA, content_type: 'application/json', description: 'JSON response')
  .ok(T.string, content_type: 'application/xml', description: 'XML response')
  .error_response(404, ERROR_SCHEMA)
```

## Metadata and Documentation

### Basic Metadata

```ruby
GET('/users')
  .summary('List all users')
  .description('Retrieves a paginated list of all users in the system with optional filtering')
  .tags('Users', 'CRUD')
  .deprecated(false)
```

### Rich Documentation

```ruby
POST('/users')
  .summary('Create a new user')
  .description('''
    Creates a new user account with the provided information.
    
    The email address must be unique across the system.
    Password requirements:
    - Minimum 8 characters
    - At least one uppercase letter
    - At least one number
    - At least one special character
  ''')
  .tags('Users', 'Registration')
  .external_docs(
    description: 'User Management Guide',
    url: 'https://docs.example.com/users'
  )
```

### OpenAPI Extensions

```ruby
GET('/users')
  .openapi_extensions({
    'x-rate-limit' => '100/minute',
    'x-permissions' => ['users:read'],
    'x-cache-ttl' => 300
  })
```

## Advanced Features

### Authentication Requirements

```ruby
GET('/profile')
  .bearer_auth(scopes: ['profile:read'])
  .ok(USER_SCHEMA)

DELETE('/admin/users/:id')
  .bearer_auth(scopes: ['admin', 'users:delete'])
  .no_content()
```

### AI Integration

```ruby
GET('/search/semantic')
  .query(:query, T.string, description: 'Natural language search query')
  .enable_rag(
    retrieval_backend: :memory,
    llm_provider: :openai,
    context_window: 4000
  )
  .enable_mcp # Export for AI agents
  .enable_llm_instructions(purpose: :completion)
  .ok(T.hash({
    "results" => T.array(SEARCH_RESULT_SCHEMA),
    "reasoning" => T.string,
    "confidence" => T.float
  }))
```

### Observability

```ruby
GET('/users/:id')
  .path_param(:id, T.integer)
  .with_metrics('user_requests', labels: { operation: 'get_by_id' })
  .with_tracing('fetch_user')
  .ok(USER_SCHEMA)
```

### Caching

```ruby
GET('/users/:id')
  .cache(ttl: 300, vary: ['Authorization'])
  .ok(USER_SCHEMA)
```

## Type System Integration

### Using the T Shortcut

The global `T` constant provides clean access to all RapiTapir types:

```ruby
# Primitive types
T.string                    # String type
T.integer                   # Integer type
T.float                     # Float type
T.boolean                   # Boolean type
T.date                      # Date type
T.datetime                  # DateTime type

# Constrained types
T.string(min_length: 1, max_length: 100)
T.integer(minimum: 0, maximum: 999)
T.float(minimum: 0.0)

# Special types
T.email                     # Email validation
T.uuid                      # UUID format
T.url                       # URL format

# Collections
T.array(T.string)           # Array of strings
T.hash({ "key" => T.value }) # Object schema

# Optional types
T.optional(T.string)        # Nullable string
```

### Auto-Derivation

Generate schemas from existing data:

```ruby
# From hash
USER_SCHEMA = T.from_hash({
  id: 1,
  name: "John Doe",
  active: true,
  tags: ["admin"]
})

# From JSON Schema
API_SCHEMA = T.from_json_schema(json_schema_object)

# From OpenStruct
CONFIG_SCHEMA = T.from_open_struct(config_object)
```

### Schema Composition

```ruby
# Base schemas
ADDRESS_SCHEMA = T.hash({
  "street" => T.string,
  "city" => T.string,
  "country" => T.string,
  "postal_code" => T.string
})

# Composed schemas
USER_SCHEMA = T.hash({
  "id" => T.integer,
  "name" => T.string,
  "email" => T.email,
  "address" => T.optional(ADDRESS_SCHEMA),
  "billing_address" => T.optional(ADDRESS_SCHEMA)
})
```

## Complete Examples

### Simple CRUD Endpoint

```ruby
class UserAPI < SinatraRapiTapir
  USER_SCHEMA = T.hash({
    "id" => T.integer,
    "name" => T.string(min_length: 1, max_length: 100),
    "email" => T.email,
    "active" => T.boolean,
    "created_at" => T.datetime
  })

  # List users
  endpoint(
    GET('/users')
      .summary('List users')
      .query(:active, T.optional(T.boolean), description: 'Filter by active status')
      .query(:limit, T.optional(T.integer(minimum: 1, maximum: 100)), description: 'Page size')
      .query(:offset, T.optional(T.integer(minimum: 0)), description: 'Page offset')
      .tags('Users')
      .ok(T.hash({
        "users" => T.array(USER_SCHEMA),
        "total" => T.integer,
        "limit" => T.integer,
        "offset" => T.integer
      }))
      .build
  ) do |inputs|
    users = User.all
    users = users.where(active: inputs[:active]) if inputs[:active]
    
    limit = inputs[:limit] || 50
    offset = inputs[:offset] || 0
    
    paginated_users = users.limit(limit).offset(offset)
    
    {
      users: paginated_users.map(&:to_h),
      total: users.count,
      limit: limit,
      offset: offset
    }
  end

  # Get user by ID
  endpoint(
    GET('/users/:id')
      .summary('Get user by ID')
      .path_param(:id, T.integer(minimum: 1), description: 'User ID')
      .tags('Users')
      .ok(USER_SCHEMA, description: 'User details')
      .error_response(404, T.hash({
        "error" => T.string,
        "user_id" => T.integer
      }), description: 'User not found')
      .build
  ) do |inputs|
    user = User.find(inputs[:id])
    halt 404, { error: 'User not found', user_id: inputs[:id] }.to_json unless user
    user.to_h
  end

  # Create user
  endpoint(
    POST('/users')
      .summary('Create a new user')
      .body(T.hash({
        "name" => T.string(min_length: 1, max_length: 100),
        "email" => T.email,
        "active" => T.optional(T.boolean)
      }), description: 'User data')
      .tags('Users')
      .created(USER_SCHEMA, description: 'Created user')
      .error_response(400, T.hash({
        "error" => T.string,
        "validation_errors" => T.array(T.string)
      }), description: 'Validation failed')
      .error_response(409, T.hash({
        "error" => T.string,
        "existing_email" => T.string
      }), description: 'Email already exists')
      .build
  ) do |inputs|
    begin
      user = User.create!(inputs[:body])
      status 201
      user.to_h
    rescue ValidationError => e
      halt 400, {
        error: 'Validation failed',
        validation_errors: e.messages
      }.to_json
    rescue UniqueConstraintError => e
      halt 409, {
        error: 'Email already exists',
        existing_email: inputs[:body]['email']
      }.to_json
    end
  end
end
```

### Advanced API with Authentication and AI

```ruby
class AdvancedAPI < SinatraRapiTapir
  rapitapir do
    info(title: 'Advanced API', version: '2.0.0')
    
    oauth2_auth0 :auth0,
      domain: ENV['AUTH0_DOMAIN'],
      audience: ENV['AUTH0_AUDIENCE']
    
    production_defaults!
  end

  # AI-powered search endpoint
  endpoint(
    GET('/search/intelligent')
      .summary('AI-powered intelligent search')
      .description('Uses machine learning to understand natural language queries and return relevant results')
      .query(:q, T.string(min_length: 1), description: 'Natural language search query')
      .query(:limit, T.optional(T.integer(minimum: 1, maximum: 50)), description: 'Maximum results')
      .query(:include_reasoning, T.optional(T.boolean), description: 'Include AI reasoning in response')
      .bearer_auth(scopes: ['search:enhanced'])
      .tags('Search', 'AI')
      .ok(T.hash({
        "results" => T.array(T.hash({
          "id" => T.string,
          "title" => T.string,
          "content" => T.string,
          "relevance_score" => T.float(minimum: 0, maximum: 1),
          "metadata" => T.hash({})
        })),
        "query_analysis" => T.hash({
          "intent" => T.string,
          "entities" => T.array(T.string),
          "confidence" => T.float(minimum: 0, maximum: 1)
        }),
        "reasoning" => T.optional(T.string),
        "total_results" => T.integer,
        "processing_time_ms" => T.float
      }))
      .error_response(400, T.hash({
        "error" => T.string,
        "suggestion" => T.string
      }), description: 'Invalid query')
      .error_response(401, T.hash({ "error" => T.string }), description: 'Authentication required')
      .error_response(403, T.hash({ "error" => T.string }), description: 'Insufficient permissions')
      .enable_rag(
        retrieval_backend: :elasticsearch,
        llm_provider: :openai,
        context_window: 8000
      )
      .enable_llm_instructions(purpose: :analysis)
      .with_metrics('ai_search_requests', labels: { model: 'gpt-4' })
      .with_tracing('intelligent_search')
      .build
  ) do |inputs|
    start_time = Time.now
    
    begin
      # Verify enhanced search permissions
      require_scope!('search:enhanced')
      
      # Perform AI-enhanced search
      search_results = AISearchService.intelligent_search(
        query: inputs[:q],
        limit: inputs[:limit] || 20,
        user_context: current_auth_context[:user_info],
        rag_context: rag_context
      )
      
      response = {
        results: search_results[:items],
        query_analysis: search_results[:analysis],
        total_results: search_results[:total],
        processing_time_ms: ((Time.now - start_time) * 1000).round(2)
      }
      
      # Include reasoning if requested
      if inputs[:include_reasoning]
        response[:reasoning] = search_results[:reasoning]
      end
      
      response
      
    rescue InvalidQueryError => e
      halt 400, {
        error: e.message,
        suggestion: e.suggestion
      }.to_json
    end
  end
end
```

## Best Practices

### 1. Schema Organization
```ruby
# Define schemas as constants for reuse
USER_SCHEMA = T.hash({
  "id" => T.integer,
  "name" => T.string,
  "email" => T.email
})

# Use schema composition
FULL_USER_SCHEMA = T.hash({
  **USER_SCHEMA.definition,
  "profile" => T.optional(PROFILE_SCHEMA),
  "preferences" => T.optional(PREFERENCES_SCHEMA)
})
```

### 2. Error Handling
```ruby
# Define consistent error schemas
ERROR_SCHEMA = T.hash({
  "error" => T.string,
  "code" => T.string,
  "details" => T.optional(T.hash({}))
})

# Use specific error responses
.error_response(400, VALIDATION_ERROR_SCHEMA, description: 'Validation failed')
.error_response(404, NOT_FOUND_ERROR_SCHEMA, description: 'Resource not found')
.error_response(500, INTERNAL_ERROR_SCHEMA, description: 'Internal server error')
```

### 3. Documentation
```ruby
# Always provide clear summaries and descriptions
.summary('Create user account')
.description('Creates a new user account with email verification')

# Use meaningful parameter descriptions
.query(:filter, T.optional(T.string), description: 'Filter users by name or email')

# Tag endpoints for logical grouping
.tags('Users', 'Account Management')
```

### 4. Type Safety
```ruby
# Use specific constraints
T.string(min_length: 1, max_length: 255)
T.integer(minimum: 1)
T.array(T.string, min_items: 1)

# Prefer enums for known values
T.string(enum: %w[active inactive pending])

# Use optional for nullable fields
T.optional(T.string)
```

### 5. Performance
```ruby
# Add caching for expensive operations
.cache(ttl: 300, vary: ['Authorization'])

# Use metrics for monitoring
.with_metrics('endpoint_requests', labels: { operation: 'list' })

# Add tracing for debugging
.with_tracing('database_query')
```

---

This guide covers the comprehensive RapiTapir endpoint definition DSL. For more examples, see the [examples directory](../examples/) and the [Sinatra extension guide](SINATRA_EXTENSION.md).
