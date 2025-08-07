# RapiTapir Auto-Derivation Feature

## Overview

RapiTapir's Auto-Derivation feature automatically generates type schemas from structured data sources with explicit type information. This feature accelerates API development by reducing manual schema definition while maintaining type safety.

## Supported Data Sources

### 1. JSON Schema (API Contracts)
Perfect for external API integration and OpenAPI specifications.

```ruby
# Example: GitHub API user schema
github_user_schema = {
  "type" => "object",
  "properties" => {
    "id" => { "type" => "integer" },
    "login" => { "type" => "string" },
    "avatar_url" => { "type" => "string", "format" => "uri" },
    "email" => { "type" => "string", "format" => "email" },
    "created_at" => { "type" => "string", "format" => "date-time" },
    "public_repos" => { "type" => "integer" },
    "followers" => { "type" => "integer" },
    "following" => { "type" => "integer" }
  },
  "required" => ["id", "login", "avatar_url"]
}

# Auto-derive RapiTapir schema using T shortcut
GITHUB_USER_SCHEMA = T.from_json_schema(github_user_schema)
```

### 2. Hash Structures (Sample Data)
Generate schemas from existing hash data with type inference.

```ruby
# Sample user data
sample_user = {
  id: 123,
  name: "John Doe", 
  email: "john@example.com",
  active: true,
  created_at: Time.now,
  tags: ["admin", "premium"],
  profile: {
    bio: "Software developer",
    age: 30,
    location: "San Francisco"
  }
}

# Auto-derive schema with intelligent type inference
USER_SCHEMA = T.from_hash(sample_user)
```

### 3. OpenStruct (Configuration Objects)
Ideal for configuration schemas and dynamic data structures.

```ruby
require 'ostruct'

# Configuration object
api_config = OpenStruct.new(
  host: "api.example.com",
  port: 443,
  ssl: true,
  timeout: 30.5,
  max_retries: 3,
  features: ["auth", "logging", "metrics"],
  database: OpenStruct.new(
    host: "db.example.com",
    port: 5432,
    ssl: true
  )
)

# Auto-derive nested schema
CONFIG_SCHEMA = T.from_open_struct(api_config)
```

### 4. ActiveRecord Models (Rails Integration)
Extract schemas from existing model definitions.

```ruby
# Derive schema from ActiveRecord model
class User < ActiveRecord::Base
  # has attributes: id, name, email, created_at, updated_at
end

# Auto-derive from model
USER_SCHEMA = T.from_activerecord(User)

# With field filtering
PUBLIC_USER_SCHEMA = T.from_activerecord(User, only: [:id, :name, :email])
```

### 5. Protobuf Messages (gRPC Integration)
Generate schemas from Protocol Buffer definitions.

```ruby
# Requires google-protobuf gem
require 'google/protobuf'

# Auto-derive from protobuf message
USER_SCHEMA = T.from_protobuf(UserProto)
SEARCH_REQUEST_SCHEMA = T.from_protobuf(SearchRequestProto)
```

## Advanced Features

### Field Filtering

Control which fields are included in the derived schema:

```ruby
# Include only specific fields
user_schema = T.from_json_schema(github_user_schema, only: [:id, :login, :email])

# Exclude specific fields (useful for sensitive data)
public_user_schema = T.from_hash(user_data, except: [:password_hash, :api_keys])

# Complex filtering with nested paths
filtered_schema = T.from_hash(complex_data, 
  only: ['user.id', 'user.profile.name', 'metadata.version']
)
```

### Type Enhancement

Enhance auto-derived schemas with additional constraints:

```ruby
# Basic auto-derivation
base_schema = T.from_hash({
  name: "John",
  age: 30,
  email: "john@example.com"
})

# Enhance with constraints
enhanced_schema = T.enhance(base_schema) do |schema|
  schema.field(:name).min_length(1).max_length(100)
  schema.field(:age).minimum(0).maximum(150)
  schema.field(:email).format(:email)
end
```

### Smart Type Inference

RapiTapir uses intelligent type inference for common patterns:

```ruby
# Recognizes common patterns
sample_data = {
  id: "550e8400-e29b-41d4-a716-446655440000",  # → T.uuid
  email: "user@example.com",                    # → T.email  
  url: "https://example.com",                   # → T.url
  created_at: "2024-01-15T10:30:00Z",          # → T.datetime
  price: "19.99",                               # → T.decimal
  phone: "+1-555-123-4567",                     # → T.phone
  tags: ["admin", "premium"]                    # → T.array(T.string)
}

SMART_SCHEMA = T.from_hash(sample_data, smart_inference: true)
```

## AI-Enhanced Auto-Derivation

### LLM-Powered Schema Generation

Use AI to generate schemas from natural language descriptions:

```ruby
class AIEnhancedAPI < SinatraRapiTapir
  rapitapir do
    enable_llm_schema_generation(
      provider: :openai,
      model: 'gpt-4',
      confidence_threshold: 0.8
    )
  end

  # Generate schema from description
  USER_PROFILE_SCHEMA = T.from_description(
    "A user profile with name, email, bio (optional), age (18-100), 
     preferences object with theme and notifications settings, 
     and an array of skill tags"
  )

  # Use in endpoints
  endpoint(
    PUT('/profile')
      .summary('Update user profile with AI-derived schema')
      .body(USER_PROFILE_SCHEMA, description: 'User profile data')
      .tags('Users', 'AI')
      .ok(USER_PROFILE_SCHEMA)
      .build
  ) do |inputs|
    # Handle profile update
    current_user.update!(inputs[:body])
    current_user.to_h
  end
end
```

### Schema Validation with AI

Validate and improve schemas using AI analysis:

```ruby
# AI-enhanced schema validation
validated_schema = T.validate_with_ai(base_schema,
  context: "REST API for e-commerce user management",
  suggestions: true,
  security_check: true
)

# AI suggests improvements:
# - Add email format validation
# - Include password strength requirements  
# - Add rate limiting fields
# - Suggest security headers
```

## Practical Examples

### External API Integration

```ruby
class GitHubIntegrationAPI < SinatraRapiTapir
  # Fetch and cache GitHub API schema
  GITHUB_USER_SCHEMA = T.from_url(
    'https://api.github.com/users/octocat',
    cache_ttl: 3600
  )

  endpoint(
    GET('/users/:username/github')
      .path_param(:username, T.string, description: 'GitHub username')
      .summary('Get GitHub user profile')
      .tags('Integration', 'GitHub')
      .ok(GITHUB_USER_SCHEMA)
      .error_response(404, T.hash({
        "error" => T.string,
        "username" => T.string
      }))
      .build
  ) do |inputs|
    username = inputs[:username]
    
    response = HTTP.get("https://api.github.com/users/#{username}")
    
    if response.status.success?
      JSON.parse(response.body)
    else
      halt 404, { 
        error: "GitHub user not found", 
        username: username 
      }.to_json
    end
  end
end
```

### Configuration Management API

```ruby
class ConfigAPI < SinatraRapiTapir
  # Auto-derive from default configuration
  DEFAULT_CONFIG = {
    database: {
      host: 'localhost',
      port: 5432,
      ssl: true,
      pool_size: 10,
      timeout: 30
    },
    redis: {
      host: 'localhost', 
      port: 6379,
      db: 0
    },
    features: {
      rate_limiting: true,
      caching: true,
      metrics: true
    },
    api: {
      version: '1.0.0',
      rate_limit: 1000,
      timeout: 60
    }
  }

  CONFIG_SCHEMA = T.from_hash(DEFAULT_CONFIG)

  endpoint(
    PUT('/config')
      .summary('Update application configuration')
      .body(CONFIG_SCHEMA, description: 'Configuration updates')
      .tags('Configuration')
      .ok(T.hash({
        "updated_config" => CONFIG_SCHEMA,
        "restart_required" => T.boolean,
        "updated_at" => T.datetime
      }))
      .build
  ) do |inputs|
    new_config = inputs[:body]
    
    # Validate configuration
    validator = ConfigValidator.new(new_config)
    halt 422, validator.errors.to_json unless validator.valid?
    
    # Apply configuration
    ConfigManager.update!(new_config)
    
    {
      updated_config: ConfigManager.current_config,
      restart_required: ConfigManager.restart_required?,
      updated_at: Time.now
    }
  end
end
```

### Multi-Source Schema Composition

```ruby
class CompositeAPI < SinatraRapiTapir
  # Combine schemas from multiple sources
  BASE_USER_SCHEMA = T.from_hash({
    id: 1,
    name: "John Doe",
    email: "john@example.com"
  })

  EXTERNAL_PROFILE_SCHEMA = T.from_json_schema({
    "type" => "object",
    "properties" => {
      "bio" => { "type" => "string" },
      "website" => { "type" => "string", "format" => "uri" },
      "location" => { "type" => "string" }
    }
  })

  PREFERENCES_SCHEMA = T.from_open_struct(OpenStruct.new(
    theme: 'dark',
    notifications: true,
    language: 'en'
  ))

  # Compose complete user schema
  COMPLETE_USER_SCHEMA = T.compose(
    BASE_USER_SCHEMA,
    profile: EXTERNAL_PROFILE_SCHEMA,
    preferences: PREFERENCES_SCHEMA
  )

  endpoint(
    GET('/users/:id/complete')
      .path_param(:id, T.integer, description: 'User ID')
      .summary('Get complete user profile')
      .tags('Users')
      .ok(COMPLETE_USER_SCHEMA)
      .build
  ) do |inputs|
    user = User.find(inputs[:id])
    profile = ProfileService.get(user.id)
    preferences = PreferencesService.get(user.id)
    
    {
      **user.to_h,
      profile: profile,
      preferences: preferences
    }
  end
end
```

## Type Mappings Reference

### JSON Schema → RapiTapir Types

| JSON Schema | RapiTapir Type |
|-------------|----------------|
| `"type": "string"` | `T.string` |
| `"type": "string", "format": "email"` | `T.email` |
| `"type": "string", "format": "uuid"` | `T.uuid` |
| `"type": "string", "format": "uri"` | `T.url` |
| `"type": "string", "format": "date"` | `T.date` |
| `"type": "string", "format": "date-time"` | `T.datetime` |
| `"type": "integer"` | `T.integer` |
| `"type": "number"` | `T.float` |
| `"type": "boolean"` | `T.boolean` |
| `"type": "array"` | `T.array(item_type)` |
| `"type": "object"` | `T.hash({})` |

### Ruby Values → RapiTapir Types

| Ruby Type | RapiTapir Type |
|-----------|----------------|
| `String` | `T.string` |
| `Integer` | `T.integer` |
| `Float` | `T.float` |
| `TrueClass/FalseClass` | `T.boolean` |
| `Date` | `T.date` |
| `Time/DateTime` | `T.datetime` |
| `Array` | `T.array(inferred_type)` |
| `Hash` | `T.hash({})` |
| `NilClass` | `T.optional(inferred_type)` |

### Smart Pattern Recognition

| Pattern | Detected As |
|---------|-------------|
| UUID format strings | `T.uuid` |
| Email format strings | `T.email` |
| URL format strings | `T.url` |
| ISO date strings | `T.datetime` |
| Phone number strings | `T.phone` |
| Decimal strings | `T.decimal` |

## Performance Considerations

### Caching Auto-Derived Schemas

```ruby
# Cache expensive derivations
class SchemaCache
  @cache = {}
  
  def self.from_url(url, ttl: 3600)
    cache_key = "schema:#{url}"
    
    if cached = @cache[cache_key]
      return cached[:schema] if cached[:expires_at] > Time.now
    end
    
    schema = T.from_url(url)
    @cache[cache_key] = {
      schema: schema,
      expires_at: Time.now + ttl
    }
    
    schema
  end
end
```

### Lazy Schema Loading

```ruby
class LazyAPI < SinatraRapiTapir
  # Define schemas lazily to improve startup time
  def self.user_schema
    @user_schema ||= T.from_url('https://api.example.com/schema/user')
  end
  
  endpoint(
    GET('/users')
      .ok(T.array(user_schema))
      .build
  ) { User.all }
end
```

## Best Practices

### 1. Use Reliable Sources
```ruby
# ✅ Good - explicit type information
schema = T.from_json_schema(api_spec)

# ❌ Avoid - unreliable runtime inference
schema = T.from_object(random_object)
```

### 2. Apply Field Filtering
```ruby
# ✅ Filter sensitive fields
public_schema = T.from_hash(user_data, except: [:password, :tokens])

# ✅ Include only needed fields
minimal_schema = T.from_activerecord(User, only: [:id, :name, :email])
```

### 3. Enhance with Constraints
```ruby
# ✅ Add business rules after derivation
enhanced = T.enhance(base_schema) do |s|
  s.field(:age).minimum(18).maximum(100)
  s.field(:email).required
end
```

### 4. Cache Expensive Operations
```ruby
# ✅ Cache external schema fetches
EXTERNAL_SCHEMA = T.from_url(schema_url, cache: true)
```

### 5. Validate Auto-Derived Schemas
```ruby
# ✅ Test derived schemas
RSpec.describe 'Auto-derived schemas' do
  it 'validates expected structure' do
    schema = T.from_hash(sample_data)
    expect(schema.validate!(test_data)).to be_truthy
  end
end
```

## Error Handling

```ruby
begin
  schema = T.from_json_schema(external_schema)
rescue T::AutoDerivation::InvalidSchemaError => e
  logger.error("Schema derivation failed: #{e.message}")
  # Fall back to manual schema
  schema = fallback_schema
rescue T::AutoDerivation::NetworkError => e
  logger.warn("Network error fetching schema: #{e.message}")
  # Use cached version or default
  schema = cached_schema || default_schema
end
```

## Integration with AI Features

Auto-derivation works seamlessly with RapiTapir's AI features:

```ruby
class AIIntegratedAPI < SinatraRapiTapir
  # Auto-derive schema, then enhance with AI
  BASE_SCHEMA = T.from_hash(sample_data)
  
  endpoint(
    POST('/analyze')
      .body(BASE_SCHEMA)
      .enable_llm_instructions(purpose: :analysis)
      .enable_rag(retrieval_backend: :memory)
      .ok(T.hash({
        "analysis" => T.string,
        "confidence" => T.float,
        "suggestions" => T.array(T.string)
      }))
      .build
  ) do |inputs|
    # AI-powered analysis using auto-derived schema
    AIAnalysisService.analyze(inputs[:body], context: rag_context)
  end
end
```

---

Auto-derivation significantly accelerates API development while maintaining the type safety and validation benefits that make RapiTapir powerful. By leveraging structured data sources with explicit type information, you can build robust APIs with minimal manual schema definition.
