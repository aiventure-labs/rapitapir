# RapiTapir Sinatra Extension - Before vs After

This document demonstrates the dramatic reduction in boilerplate code when using the RapiTapir Sinatra Extension compared to manual implementation.

## 📊 Code Comparison

### Manual Implementation (Before)
**File: `enterprise_rapitapir_api.rb` - 660 lines**

```ruby
# frozen_string_literal: true

require 'sinatra/base'
require 'json'
require_relative '../lib/rapitapir'
require_relative '../lib/rapitapir/server/sinatra_adapter'

# 50+ lines of database setup...
class UserDatabase
  # ...
end

class TaskDatabase
  # ...
end

# 100+ lines of schema definitions...
module TaskAPI
  TASK_SCHEMA = RapiTapir::Types.hash({
    # ...
  })
  
  def self.endpoints
    @endpoints ||= [
      # Manually define every single endpoint...
      RapiTapir.get('/health')
        .summary('Health check')
        .description('Returns the health status of the API')
        .ok(HEALTH_SCHEMA)
        .build,
        
      RapiTapir.get('/api/v1/tasks')
        .summary('List all tasks')
        .description('Retrieve a list of all tasks in the system. Requires read permission.')
        .query(:status, RapiTapir::Types.optional(RapiTapir::Types.string), description: 'Filter by task status')
        # ... more configuration
        .build,
        
      # Repeat for every endpoint (8 total)...
    ]
  end
  
  # 50+ lines of OpenAPI generation...
  def self.openapi_spec
    # Manual OpenAPI configuration
  end
end

# Main application - 200+ lines
class EnterpriseTaskAPI < Sinatra::Base
  def initialize
    super
    
    # Manual middleware setup...
    use RapiTapir::Auth::Middleware::SecurityHeadersMiddleware
    use RapiTapir::Auth::Middleware::CorsMiddleware, {
      # Manual CORS configuration...
    }
    use RapiTapir::Auth::Middleware::RateLimitingMiddleware, {
      # Manual rate limiting configuration...
    }
    
    # Manual authentication setup...
    bearer_auth = RapiTapir::Auth.bearer_token(:bearer, {
      # Manual auth configuration...
    })
    
    # Manual adapter setup...
    setup_rapitapir_endpoints
  end
  
  # Many helper methods...
  def json_response(status, data)
    # ...
  end
  
  def require_scope(scope)
    # ...
  end
  
  # Manual endpoint registration...
  def setup_rapitapir_endpoints
    adapter = RapiTapir::Server::SinatraAdapter.new(self)
    TaskAPI.endpoints.each do |endpoint|
      adapter.register_endpoint(endpoint, get_endpoint_handler(endpoint))
    end
  end
  
  # 150+ lines of manual endpoint handlers...
  def get_endpoint_handler(endpoint)
    case endpoint.path
    when '/health'
      proc do |inputs|
        # Manual implementation...
      end
    when '/api/v1/tasks'
      if endpoint.method == :get
        proc do |inputs|
          require_authenticated
          require_scope('read')
          # Manual filtering, pagination, formatting...
        end
      else # POST
        proc do |inputs|
          # Manual validation, creation...
        end
      end
    # Repeat for every endpoint...
    end
  end
  
  # Manual documentation endpoints...
  get '/openapi.json' do
    # ...
  end
  
  get '/docs' do
    # 50+ lines of HTML generation...
  end
end
```

### Extension Implementation (After)
**File: `enterprise_extension_demo.rb` - 280 lines**

```ruby
# frozen_string_literal: true

require 'sinatra/base'
require 'json'
require_relative '../lib/rapitapir'
require_relative '../lib/rapitapir/sinatra/extension'

# Same database classes (50 lines)...
class UserDatabase
  # ... (unchanged)
end

class TaskDatabase
  # ... (unchanged)
end

# Simple schema definitions (20 lines)...
TASK_SCHEMA = RapiTapir::Types.hash({
  "id" => RapiTapir::Types.integer,
  "title" => RapiTapir::Types.string,
  "description" => RapiTapir::Types.string,
  "status" => RapiTapir::Types.string,
  "assignee_id" => RapiTapir::Types.integer,
  "created_at" => RapiTapir::Types.string,
  "updated_at" => RapiTapir::Types.optional(RapiTapir::Types.string)
})

USER_SCHEMA = RapiTapir::Types.hash({
  "id" => RapiTapir::Types.integer,
  "name" => RapiTapir::Types.string,
  "email" => RapiTapir::Types.string,
  "role" => RapiTapir::Types.string,
  "scopes" => RapiTapir::Types.array(RapiTapir::Types.string)
})

# Main application - dramatically simplified!
class EnterpriseTaskAPI < Sinatra::Base
  register RapiTapir::Sinatra::Extension

  # ONE configuration block for everything!
  rapitapir do
    info(
      title: 'Enterprise Task Management API',
      description: 'A production-ready task management API built with RapiTapir Sinatra Extension',
      version: '2.0.0',
      contact: { name: 'API Support', email: 'api-support@example.com' }
    )

    server(url: 'http://localhost:4567', description: 'Development server')
    server(url: 'https://api.example.com', description: 'Production server')

    bearer_auth(:bearer, {
      realm: 'Enterprise Task Management API',
      token_validator: proc do |token|
        user = UserDatabase.find_by_token(token)
        next nil unless user
        { user: user, scopes: user[:scopes] }
      end
    })

    development_defaults!  # ONE LINE for all middleware!
    enable_docs(path: '/docs', openapi_path: '/openapi.json')
  end

  # Simple health check
  endpoint(
    RapiTapir.get('/health')
      .summary('Health check')
      .ok(RapiTapir::Types.hash({
        "status" => RapiTapir::Types.string,
        "timestamp" => RapiTapir::Types.string,
        "version" => RapiTapir::Types.string,
        "features" => RapiTapir::Types.array(RapiTapir::Types.string)
      }))
      .build
  ) do |inputs|
    {
      status: 'healthy',
      timestamp: Time.now.iso8601,
      version: '2.0.0',
      features: ['RapiTapir Sinatra Extension', 'Auto-generated OpenAPI', 'Zero Boilerplate']
    }
  end

  # ENTIRE RESTful resource in one block!
  api_resource '/api/v1/tasks', schema: TASK_SCHEMA do
    crud do
      index do |inputs|
        tasks = TaskDatabase.all
        # Apply filters if provided
        if inputs[:status]
          tasks = tasks.select { |task| task[:status] == inputs[:status] }
        end
        # Apply pagination and format...
        tasks.map { |task| format_task(task) }
      end

      show { |inputs| /* ... */ }
      create { |inputs| /* ... */ }
      update { |inputs| /* ... */ }
      destroy(scopes: ['admin']) { |inputs| /* ... */ }
    end

    # Custom endpoint in one line!
    custom(:get, 'by-status/:status', /* config */) { |inputs| /* handler */ }
  end

  # Simple profile endpoint
  endpoint(/* profile endpoint */) { require_authentication!; current_user }

  # Simple admin endpoint
  endpoint(/* admin endpoint */) { require_scope!('admin'); UserDatabase.all_users }
end
```

## 📈 Metrics Comparison

| Metric | Manual Implementation | Extension Implementation | Improvement |
|--------|----------------------|-------------------------|-------------|
| **Total Lines** | 660 | 280 | **-58%** |
| **Configuration Lines** | ~150 | ~25 | **-83%** |
| **Endpoint Definition** | ~200 | ~50 | **-75%** |
| **Middleware Setup** | ~30 | 1 | **-97%** |
| **Documentation Setup** | ~50 | 1 | **-98%** |
| **Boilerplate Code** | ~300 | ~30 | **-90%** |

## 🎯 Key Benefits

### 1. **Dramatic Code Reduction**
- **58% fewer lines** overall
- **90% less boilerplate** code
- Focus on business logic, not infrastructure

### 2. **Zero Configuration Overhead**
- **One line** for all middleware setup
- **Automatic** OpenAPI generation
- **Smart defaults** for development and production

### 3. **RESTful Resource Builder**
- **Full CRUD** operations in one block
- **Automatic** authentication and validation
- **Custom endpoints** with minimal code

### 4. **Enterprise Features Out-of-the-Box**
- **Authentication** and **authorization** helpers
- **CORS**, **rate limiting**, **security headers**
- **Beautiful documentation** UI
- **Type-safe** request/response validation

### 5. **Developer Experience**
- **Intuitive** DSL that reads like documentation
- **Helpful error messages** for authentication and validation
- **Hot reloading** friendly configuration
- **Extensive examples** and documentation

## 🔧 Feature Comparison

| Feature | Manual | Extension | Extension Advantage |
|---------|--------|-----------|-------------------|
| **Middleware Setup** | Manual configuration for each | `development_defaults!` | One-line setup |
| **Authentication** | Manual auth scheme creation | `bearer_auth` helper | Built-in helpers |
| **CRUD Operations** | Individual endpoint definitions | `api_resource` + `crud` | Resource builder |
| **Documentation** | Manual HTML generation | Auto-generated | Zero maintenance |
| **Error Handling** | Manual error responses | Built-in helpers | Consistent errors |
| **Type Validation** | Manual validation logic | Automatic from schemas | Type safety |
| **OpenAPI Generation** | Manual spec building | Automatic from endpoints | Always up-to-date |

## 🚀 Migration Guide

### Step 1: Add Extension
```ruby
# Add to your Sinatra app
register RapiTapir::Sinatra::Extension
```

### Step 2: Replace Configuration
```ruby
# Replace manual middleware setup with:
rapitapir do
  development_defaults!  # or production_defaults!
end
```

### Step 3: Convert Endpoints
```ruby
# Replace manual endpoint definitions with:
api_resource '/api/v1/tasks', schema: TASK_SCHEMA do
  crud { /* handlers */ }
end
```

### Step 4: Simplify Authentication
```ruby
# Replace manual auth helpers with:
endpoint(...) do |inputs|
  require_authentication!
  require_scope!('admin')
  # business logic
end
```

## 💡 Best Practices with Extension

### 1. **Use Resource Builder for RESTful APIs**
```ruby
api_resource '/users', schema: USER_SCHEMA do
  crud(except: [:destroy]) { /* handlers */ }
end
```

### 2. **Leverage Configuration Presets**
```ruby
rapitapir do
  if production?
    production_defaults!
  else
    development_defaults!
  end
end
```

### 3. **Custom Endpoints for Special Cases**
```ruby
api_resource '/tasks', schema: TASK_SCHEMA do
  crud { /* ... */ }
  
  custom(:get, 'statistics', 
    summary: 'Task statistics'
  ) { TaskStatistics.generate }
end
```

### 4. **Authentication Helpers**
```ruby
endpoint(...) do |inputs|
  # Use built-in helpers instead of manual checks
  require_scope!('admin')
  current_user.create_task(inputs[:body])
end
```

## 🎉 Conclusion

The RapiTapir Sinatra Extension transforms enterprise API development by:

- **Eliminating 90% of boilerplate code**
- **Providing enterprise features out-of-the-box**
- **Maintaining full flexibility and customization**
- **Following SOLID principles for maintainable architecture**
- **Delivering exceptional developer experience**

The result is **cleaner**, **more maintainable**, and **more secure** APIs with significantly less code to write and maintain.
