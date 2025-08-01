# RapiTapir Sinatra Extension

**Zero-boilerplate, enterprise-grade API development with RapiTapir and Sinatra**

The RapiTapir Sinatra Extension provides a seamless, ergonomic experience for building production-ready APIs by eliminating repetitive configuration and following SOLID principles.

## 🚀 Quick Start

```ruby
require 'sinatra/base'
require 'rapitapir'
require 'rapitapir/sinatra/extension'

class MyAPI < Sinatra::Base
  register RapiTapir::Sinatra::Extension

  rapitapir do
    info title: 'My API', version: '1.0.0'
    development_defaults!
  end

  # Define a simple endpoint
  endpoint(
    RapiTapir.get('/hello')
      .ok(RapiTapir::Types.hash({ "message" => RapiTapir::Types.string }))
      .build
  ) { { message: 'Hello, World!' } }
end
```

## 📋 Table of Contents

- [Features](#features)
- [Installation](#installation)
- [Configuration](#configuration)
- [Endpoint Definition](#endpoint-definition)
- [RESTful Resources](#restful-resources)
- [Authentication](#authentication)
- [Middleware](#middleware)
- [Documentation](#documentation)
- [Examples](#examples)
- [Architecture](#architecture)

## ✨ Features

### Zero Boilerplate
- **One-line configuration**: Set up authentication, middleware, and documentation with minimal code
- **Smart defaults**: Production and development presets that just work
- **Automatic registration**: Endpoints are automatically registered with proper validation

### Enterprise-Ready
- **Built-in authentication**: Bearer token, API key, and custom schemes
- **Production middleware**: CORS, rate limiting, security headers
- **Auto-generated OpenAPI**: Beautiful Swagger UI documentation
- **Type-safe validation**: Automatic request/response validation

### Developer Experience
- **RESTful resource builder**: Create full CRUD APIs with a single block
- **Helpful error messages**: Clear validation and authentication errors
- **Hot reloading**: Development-friendly configuration
- **Extensive examples**: Get started quickly with working code

## 🔧 Installation

Add to your Gemfile:

```ruby
gem 'rapitapir'
```

Or install directly:

```bash
gem install rapitapir
```

## ⚙️ Configuration

### Basic Configuration

```ruby
class MyAPI < Sinatra::Base
  register RapiTapir::Sinatra::Extension

  rapitapir do
    # API metadata
    info(
      title: 'My API',
      description: 'A fantastic API',
      version: '1.0.0',
      contact: { email: 'support@example.com' }
    )

    # Server configuration
    server url: 'http://localhost:4567', description: 'Development'
    server url: 'https://api.example.com', description: 'Production'

    # Enable documentation
    enable_docs path: '/docs', openapi_path: '/openapi.json'
  end
end
```

### Environment-Specific Defaults

```ruby
rapitapir do
  if development?
    development_defaults!  # Permissive CORS, high rate limits
  else
    production_defaults!   # Secure defaults for production
  end
end
```

## 🛡️ Authentication

### Bearer Token Authentication

```ruby
rapitapir do
  bearer_auth :bearer, {
    realm: 'My API',
    token_validator: proc do |token|
      user = User.find_by_token(token)
      next nil unless user

      {
        user: user,
        scopes: user.scopes
      }
    end
  }
end
```

### API Key Authentication

```ruby
rapitapir do
  api_key_auth :api_key, {
    location: 'header',
    name: 'X-API-Key',
    key_validator: proc do |key|
      # Validate API key
    end
  }
end
```

### Public Endpoints

```ruby
rapitapir do
  public_paths '/health', '/docs', '/openapi.json'
end
```

## 📡 Endpoint Definition

### Simple Endpoints

```ruby
endpoint(
  RapiTapir.get('/users')
    .summary('List users')
    .ok(RapiTapir::Types.array(USER_SCHEMA))
    .build
) do |inputs|
  User.all
end
```

### With Authentication Requirements

```ruby
endpoint(
  RapiTapir.post('/admin/users')
    .summary('Create user (admin only)')
    .json_body(USER_CREATE_SCHEMA)
    .created(USER_SCHEMA)
    .build
) do |inputs|
  require_scope!('admin')
  User.create(inputs[:body])
end
```

## 🏗️ RESTful Resources

The resource builder creates full CRUD APIs with minimal code:

```ruby
api_resource '/api/v1/tasks', schema: TASK_SCHEMA do
  # Enable all CRUD operations
  crud do
    index { Task.all }
    show { |inputs| Task.find(inputs[:id]) }
    create { |inputs| Task.create(inputs[:body]) }
    update { |inputs| Task.update(inputs[:id], inputs[:body]) }
    destroy { |inputs| Task.delete(inputs[:id]) }
  end
end
```

### Selective Operations

```ruby
api_resource '/books', schema: BOOK_SCHEMA do
  crud(except: [:destroy]) do  # All operations except delete
    index { Book.published }
    show { |inputs| Book.find(inputs[:id]) }
    create { |inputs| Book.create(inputs[:body]) }
    update { |inputs| Book.update(inputs[:id], inputs[:body]) }
  end
end
```

### Custom Endpoints

```ruby
api_resource '/tasks', schema: TASK_SCHEMA do
  crud { /* ... */ }

  # Custom endpoint: /tasks/by-status/:status
  custom(:get, 'by-status/:status',
    summary: 'Get tasks by status',
    configure: ->(endpoint) {
      endpoint
        .path_param(:status, RapiTapir::Types.string)
        .ok(RapiTapir::Types.array(TASK_SCHEMA))
    }
  ) do |inputs|
    Task.where(status: inputs[:status])
  end
end
```

### Different Scopes for Operations

```ruby
api_resource '/users', schema: USER_SCHEMA do
  crud do
    index(scopes: ['read']) { User.all }
    show(scopes: ['read']) { |inputs| User.find(inputs[:id]) }
    create(scopes: ['write']) { |inputs| User.create(inputs[:body]) }
    update(scopes: ['write']) { |inputs| User.update(inputs[:id], inputs[:body]) }
    destroy(scopes: ['admin']) { |inputs| User.delete(inputs[:id]) }
  end
end
```

## 🔐 Authentication Helpers

```ruby
endpoint(...) do |inputs|
  # Check if user is authenticated
  require_authentication!

  # Check specific scope
  require_scope!('admin')

  # Get current user
  user = current_user

  # Check if authenticated (non-throwing)
  if authenticated?
    # User is logged in
  end

  # Check scope (non-throwing)
  if has_scope?('write')
    # User has write permission
  end
end
```

## 🛠️ Middleware Configuration

### CORS

```ruby
rapitapir do
  cors(
    allowed_origins: ['https://myapp.com'],
    allowed_methods: ['GET', 'POST', 'PUT', 'DELETE'],
    allowed_headers: ['Authorization', 'Content-Type'],
    allow_credentials: true
  )
end
```

### Rate Limiting

```ruby
rapitapir do
  rate_limiting(
    requests_per_minute: 60,
    requests_per_hour: 1000
  )
end
```

### Security Headers

```ruby
rapitapir do
  security_headers(
    csp: "default-src 'self'",
    hsts: true
  )
end
```

## 📚 Documentation

### Automatic OpenAPI Generation

The extension automatically generates OpenAPI 3.0 specifications from your endpoint definitions:

- **Swagger UI**: Beautiful, interactive documentation
- **Type validation**: Schemas automatically derived from RapiTapir types
- **Authentication schemes**: Security requirements automatically added
- **Request/response examples**: Generated from your schemas

### Custom Documentation

```ruby
rapitapir do
  info(
    title: 'My API',
    description: 'Comprehensive API documentation',
    version: '1.0.0',
    contact: {
      name: 'Support Team',
      email: 'support@example.com',
      url: 'https://example.com/support'
    },
    license: {
      name: 'MIT',
      url: 'https://opensource.org/licenses/MIT'
    }
  )
end
```

## 🎯 Complete Examples

### Minimal Bookstore API

```ruby
require 'sinatra/base'
require 'rapitapir/sinatra/extension'

class BookstoreAPI < Sinatra::Base
  register RapiTapir::Sinatra::Extension

  rapitapir do
    info title: 'Bookstore API', version: '1.0.0'
    development_defaults!
    public_paths '/books'
  end

  BOOK_SCHEMA = RapiTapir::Types.hash({
    "id" => RapiTapir::Types.integer,
    "title" => RapiTapir::Types.string,
    "author" => RapiTapir::Types.string
  })

  api_resource '/books', schema: BOOK_SCHEMA do
    crud do
      index { Book.all }
      show { |inputs| Book.find(inputs[:id]) }
      create { |inputs| Book.create(inputs[:body]) }
      update { |inputs| Book.update(inputs[:id], inputs[:body]) }
    end
  end
end
```

### Enterprise Task Management API

See `examples/enterprise_extension_demo.rb` for a comprehensive example with:
- Bearer token authentication
- Multiple resources
- Custom endpoints
- Admin-only operations
- Full middleware stack

## 🏛️ Architecture

The RapiTapir Sinatra Extension follows SOLID principles:

### Single Responsibility Principle
- **Extension**: Manages Sinatra integration only
- **Configuration**: Handles API configuration only
- **ResourceBuilder**: Creates RESTful endpoints only
- **SwaggerUIGenerator**: Generates documentation UI only

### Open/Closed Principle
- **Extensible**: Add new authentication schemes without modifying core
- **Pluggable**: Custom middleware can be added
- **Customizable**: Resource builder supports custom endpoints

### Liskov Substitution Principle
- **Endpoint compatibility**: Works with any RapiTapir endpoint
- **Authentication schemes**: All auth schemes follow same interface

### Interface Segregation Principle
- **Focused interfaces**: Each component has a specific, minimal interface
- **Optional features**: Documentation, authentication, middleware are optional

### Dependency Inversion Principle
- **Abstractions**: Depends on RapiTapir abstractions, not concrete implementations
- **Injection**: Authentication and validation logic is injected via procs

## 🔄 Migration from Manual Implementation

Migrating from manual Sinatra routes to the extension:

### Before (Manual)
```ruby
class MyAPI < Sinatra::Base
  use SomeMiddleware
  use SomeOtherMiddleware
  
  get '/tasks' do
    # Manual authentication
    # Manual validation
    # Manual response formatting
  end
  
  post '/tasks' do
    # Repeat authentication, validation, etc.
  end
  
  # Repeat for every endpoint...
end
```

### After (Extension)
```ruby
class MyAPI < Sinatra::Base
  register RapiTapir::Sinatra::Extension
  
  rapitapir do
    bearer_auth { /* config */ }
    development_defaults!
  end
  
  api_resource '/tasks', schema: TASK_SCHEMA do
    crud { /* handlers */ }
  end
end
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Add tests for your changes
4. Ensure all tests pass
5. Submit a pull request

## 📄 License

MIT License - see LICENSE file for details.
