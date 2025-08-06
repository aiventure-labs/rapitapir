# RapiTapir

[![Tests](https://img.shields.io/badge/tests-620%20passing-brightgreen)](spec/)
[![Coverage](https://img.shields.io/badge/coverage-68.68%25-green)](coverage/)
[![Ruby](https://img.shields.io/badge/ruby-3.1%2B-red)](Gemfile)
[![License](https://img.shields.io/badge/license-MIT-blue)](LICENSE)

**RapiTapir 🦙** combines the expressiveness of Ruby with the safety of strong typing to create APIs that are both powerful and reliable. Define your endpoints once with our fluent DSL, and get automatic validation, documentation, and client generation.

## 🆕 What's New

- **✨ Clean Base Class**: `class MyAPI < SinatraRapiTapir` - the simplest way to create APIs
- **🎯 Enhanced HTTP DSL**: Built-in GET, POST, PUT, DELETE methods with fluent chaining  
- **🔧 Zero Boilerplate**: Automatic extension registration and feature setup
- **� Type Shortcuts**: Use `T.string` instead of `RapiTapir::Types.string` for cleaner code
- **�📚 GitHub Pages Ready**: Modern documentation deployment with GitHub Actions
- **🧪 Comprehensive Tests**: 620 tests passing with 68.68% coverage

## ✨ Why RapiTapir?

- **🔒 Type Safety**: Strong typing for inputs and outputs with runtime validation
- **📖 Auto Documentation**: OpenAPI 3.0 specs generated automatically from your code
- **🚀 Framework Agnostic**: Works with Sinatra, Rails, and any Rack-based framework  
- **🛡️ Production Ready**: Built-in security, observability, and authentication features
- **💎 Ruby Native**: Designed specifically for Ruby developers who love clean, readable code
- **🔧 Zero Config**: Get started in minutes with sensible defaults
- **✨ Clean Syntax**: Elegant base class: `class MyAPI < SinatraRapiTapir`
- **🎯 Enhanced DSL**: Built-in HTTP verb methods (GET, POST, PUT, etc.)
- **� Type Shortcuts**: Clean type syntax with `T.string`, `T.integer`, etc.
- **�🔄 GitHub Pages**: Modern documentation deployment with GitHub Actions

## 🚀 Quick Start

### Installation

Add to your Gemfile:

```ruby
gem 'rapitapir'
```

### Basic Sinatra Example

```ruby
require 'rapitapir' # Only one require needed!

class BookAPI < SinatraRapiTapir
  # Configure API information
  rapitapir do
    info(
      title: 'Book API',
      description: 'A simple book management API',
      version: '1.0.0'
    )
    development_defaults! # Auto CORS, docs, health checks
  end

  # Define your data schema with T shortcut (globally available!)
  BOOK_SCHEMA = T.hash({
    "id" => T.integer,
    "title" => T.string(min_length: 1, max_length: 255),
    "author" => T.string(min_length: 1),
    "published" => T.boolean,
    "isbn" => T.optional(T.string),
    "pages" => T.optional(T.integer(minimum: 1))
  })

  # Define endpoints with the elegant resource DSL and enhanced HTTP verbs
  api_resource '/books', schema: BOOK_SCHEMA do
    crud do
      index { Book.all }
      
      show do |inputs|
        Book.find(inputs[:id]) || halt(404, { error: 'Book not found' }.to_json)
      end
      
      create do |inputs|
        Book.create(inputs[:body])
      end
    end
    
    # Custom endpoint using enhanced DSL
    custom :get, 'featured' do
      Book.where(featured: true)
    end
  end

  # Alternative endpoint definition using enhanced HTTP verb DSL
  endpoint(
    GET('/books/search')
      .query(:q, T.string(min_length: 1), description: 'Search query')
      .query(:limit, T.optional(T.integer(minimum: 1, maximum: 100)), description: 'Results limit')
      .summary('Search books')
      .description('Search books by title or author')
      .tags('Search')
      .ok(T.array(BOOK_SCHEMA))
      .bad_request(T.hash({ "error" => T.string }), description: 'Invalid search parameters')
      .build
  ) do |inputs|
    query = inputs[:q]
    limit = inputs[:limit] || 20
    
    books = Book.search(query).limit(limit)
    books.map(&:to_h)
  end

  run! if __FILE__ == $0
end
```

Start your server and visit:
- **📖 Interactive Documentation**: `http://localhost:4567/docs`
- **📋 OpenAPI Specification**: `http://localhost:4567/openapi.json`

That's it! You now have a fully documented, type-safe API with interactive documentation.

## 🏗️ Core Features

### Clean Base Class Syntax

Create APIs with the cleanest possible syntax:

```ruby
require 'rapitapir'

class MyAPI < SinatraRapiTapir
  rapitapir do
    info(title: 'My API', version: '1.0.0')
    development_defaults! # Auto CORS, docs, health checks
  end

  # Enhanced HTTP verb DSL automatically available + T shortcut for types
  endpoint(
    GET('/books')
      .summary('List all books')
      .ok(T.array(BOOK_SCHEMA))
      .error_response(500, T.hash({ "error" => T.string }))
      .build
  ) { Book.all }
end
```

### Type-Safe API Design

Define your data schemas once and use them everywhere:

```ruby
# T shortcut is automatically available - no setup needed!
USER_SCHEMA = T.hash({
  "id" => T.integer,
  "name" => T.string(min_length: 1, max_length: 100),
  "email" => T.email,
  "age" => T.optional(T.integer(min: 0, max: 150)),
  "profile" => T.optional(T.hash({
    "bio" => T.string(max_length: 500),
    "avatar_url" => T.string(format: :url)
  }))
})
```

### Fluent Endpoint Definition

Create endpoints with a clean, readable DSL:

```ruby
# Using the enhanced HTTP verb DSL with T shortcut
endpoint(
  GET('/users/:id')
    .summary('Get user by ID')
    .path_param(:id, T.integer(minimum: 1))
    .query(:include, T.optional(T.array(T.string)), description: 'Related data to include')
    .ok(USER_SCHEMA)
    .error_response(404, T.hash({ "error" => T.string }), description: 'User not found')
    .error_response(422, T.hash({ 
      "error" => T.string,
      "details" => T.array(T.hash({
        "field" => T.string,
        "message" => T.string
      }))
    }))
    .build
) do |inputs|
  user = User.find(inputs[:id])
  halt 404, { error: 'User not found' }.to_json unless user
  
  # Handle optional includes
  if inputs[:include]&.include?('profile')
    user = user.with_profile
  end
  
  user.to_h
end
```

### RESTful Resource Builder

Build complete CRUD APIs with minimal code:

```ruby
# Enhanced resource builder with custom validations and relationships
api_resource '/users', schema: USER_SCHEMA do
  crud do
    index do
      # Automatic pagination and filtering
      users = User.all
      users = users.where(active: true) if params[:active] == 'true'
      users.limit(params[:limit] || 50)
    end
    
    show { |inputs| User.find(inputs[:id]) }
    
    create do |inputs|
      user = User.create(inputs[:body])
      status 201
      user.to_h
    end
    
    update { |inputs| User.update(inputs[:id], inputs[:body]) }
    destroy { |inputs| User.delete(inputs[:id]); status 204 }
  end
  
  # Add custom endpoints with full type safety
  custom :get, 'active' do
    User.where(active: true).map(&:to_h)
  end
  
  custom :post, ':id/avatar' do |inputs|
    user = User.find(inputs[:id])
    user.update_avatar(inputs[:body][:avatar_data])
    { success: true }
  end
end
```

### Automatic OpenAPI Documentation

Your API documentation is always up-to-date because it's generated from your actual code:

- **Interactive Swagger UI** with try-it-out functionality
- **Complete OpenAPI 3.0 specification** with schemas, examples, and security
- **TypeScript client generation** for frontend teams
- **Markdown documentation** for wikis and READMEs

## 🔧 Framework Integration

### Sinatra (Recommended)

**Option 1: Clean Base Class (Recommended)**
```ruby
require 'rapitapir'

class MyAPI < SinatraRapiTapir
  rapitapir do
    info(title: 'My API', version: '1.0.0')
    development_defaults!
  end
  # Enhanced HTTP verb DSL automatically available
end
```

**Option 2: Manual Extension Registration**
```ruby
require 'rapitapir/sinatra/extension'

class MyAPI < Sinatra::Base
  register RapiTapir::Sinatra::Extension
  # Use the full DSL...
end
```

### Rack Applications

```ruby
require 'rapitapir/server/rack_adapter'

class MyRackApp
  def call(env)
    # Manual integration with Rack
  end
end
```

### Rails Support

```ruby
# In your Rails controller
include RapiTapir::Rails::Controller
```

## 🛡️ Production Features

### Authentication & Authorization

```ruby
# Bearer token authentication with enhanced syntax
class SecureAPI < SinatraRapiTapir
  rapitapir do
    info(title: 'Secure API', version: '1.0.0')
    bearer_auth :api_key, realm: 'API'
    production_defaults!
  end

  # Protected endpoint with scope-based authorization
  endpoint(
    GET('/admin/users')
      .summary('List all users (admin only)')
      .bearer_auth(scopes: ['admin'])
      .query(:page, T.optional(T.integer(minimum: 1)), description: 'Page number')
      .query(:per_page, T.optional(T.integer(minimum: 1, maximum: 100)), description: 'Items per page')
      .ok(T.hash({
        "users" => T.array(USER_SCHEMA),
        "pagination" => T.hash({
          "page" => T.integer,
          "per_page" => T.integer,
          "total" => T.integer,
          "pages" => T.integer
        })
      }))
      .error_response(401, T.hash({ "error" => T.string }), description: 'Unauthorized')
      .error_response(403, T.hash({ "error" => T.string }), description: 'Insufficient permissions')
      .build
  ) do |inputs|
    require_scope!('admin')
    
    page = inputs[:page] || 1
    per_page = inputs[:per_page] || 20
    
    users = User.paginate(page: page, per_page: per_page)
    
    {
      users: users.map(&:to_h),
      pagination: {
        page: page,
        per_page: per_page,
        total: users.total_count,
        pages: users.total_pages
      }
    }
  end
end
```

### Observability

```ruby
class MonitoredAPI < SinatraRapiTapir
  rapitapir do
    info(title: 'Monitored API', version: '1.0.0')
    enable_health_checks path: '/health'
    enable_metrics
    production_defaults!
  end

  # Endpoint with metrics and tracing
  endpoint(
    GET('/api/data')
      .summary('Get data with monitoring')
      .with_metrics('api_data_requests')
      .with_tracing('fetch_api_data')
      .query(:filter, T.optional(T.string), description: 'Data filter')
      .ok(T.hash({
        "data" => T.array(T.hash({
          "id" => T.integer,
          "value" => T.string,
          "timestamp" => T.datetime
        })),
        "metadata" => T.hash({
          "total" => T.integer,
          "filtered" => T.boolean
        })
      }))
      .build
  ) do |inputs|
    # Your endpoint code with automatic metrics collection
    data = DataService.fetch(filter: inputs[:filter])
    
    {
      data: data.map(&:to_h),
      metadata: {
        total: data.count,
        filtered: inputs[:filter].present?
      }
    }
  end
end
```

### Security Middleware

```ruby
# Built-in security features
use RapiTapir::Server::Middleware::CORS
use RapiTapir::Server::Middleware::RateLimit, requests_per_minute: 100
use RapiTapir::Server::Middleware::SecurityHeaders
```

## 🎨 Examples

Explore our comprehensive examples:

- **[Hello World](examples/hello_world.rb)** - Minimal API with SinatraRapiTapir base class  
- **[Getting Started](examples/getting_started_extension.rb)** - Complete bookstore API with CRUD operations
- **[Enterprise API](examples/enterprise_rapitapir_api.rb)** - Production-ready example with auth
- **[Authentication](examples/authentication_example.rb)** - Bearer token and scope-based auth
- **[Observability](examples/observability/)** - Health checks, metrics, and tracing

## 📚 Documentation

- **[API Reference](docs/endpoint-definition.md)** - Complete endpoint definition guide
- **[SinatraRapiTapir Base Class](docs/sinatra_rapitapir.md)** - Clean inheritance syntax guide
- **[Sinatra Extension](docs/SINATRA_EXTENSION.md)** - Detailed Sinatra integration
- **[Type System](docs/types.md)** - All available types and validations (use `T.` shortcut!)
- **[Authentication](docs/authentication.md)** - Security and auth patterns
- **[Observability](docs/observability.md)** - Monitoring and health checks
- **[GitHub Pages Setup](docs/github_pages_setup.md)** - Documentation deployment guide

## 🧪 Testing

RapiTapir includes comprehensive testing utilities:

```ruby
# Validate your endpoint definitions
RapiTapir::CLI::Validator.new(endpoints).validate

# Generate test fixtures
RapiTapir::Testing.generate_fixtures(USER_SCHEMA)
```

Run the test suite:

```bash
bundle exec rspec
```

## 🤝 Contributing

We love contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

### Development Setup

```bash
git clone https://github.com/riccardomerolla/rapitapir.git
cd ruby-tapir
bundle install
bundle exec rspec
```

### Roadmap

- **Phase 4**: Advanced client generation (Python, Go, etc.)
- **Phase 5**: GraphQL integration
- **Phase 6**: gRPC support
- **Community**: Plugin ecosystem

## � License

RapiTapir is released under the [MIT License](LICENSE).

## 🙋‍♂️ Support

- **🐛 Bug Reports**: [GitHub Issues](https://github.com/riccardomerolla/rapitapir/issues)
- **💡 Feature Requests**: [GitHub Discussions](https://github.com/riccardomerolla/rapitapir/discussions)
- **📧 Email**: riccardo.merolla@gmail.com

---

**Built with ❤️ for the Ruby and Sinatra community**


## 🙏 Acknowledgments

Inspired by:
- [Scala Tapir](https://github.com/softwaremill/tapir) - Type-safe endpoints

---

**RapiTapir** - APIs so fast and clean, they practically run wild! 🦙⚡
