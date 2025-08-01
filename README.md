# RapiTapir 🦙

**A modern Ruby library for building type-safe HTTP APIs with automatic OpenAPI documentation**

[![Tests](https://img.shields.io/badge/tests-189%20passing-brightgreen)](spec/)
[![Coverage](https://img.shields.io/badge/coverage-54.39%25-yellow)](coverage/)
[![Ruby](https://img.shields.io/badge/ruby-3.0%2B-red)](Gemfile)
[![License](https://img.shields.io/badge/license-MIT-blue)](LICENSE)

RapiTapir combines the expressiveness of Ruby with the safety of strong typing to create APIs that are both powerful and reliable. Define your endpoints once with our fluent DSL, and get automatic validation, documentation, and client generation.

## ✨ Why RapiTapir?

- **🔒 Type Safety**: Strong typing for inputs and outputs with runtime validation
- **📖 Auto Documentation**: OpenAPI 3.0 specs generated automatically from your code
- **🚀 Framework Agnostic**: Works with Sinatra, Rails, and any Rack-based framework  
- **🛡️ Production Ready**: Built-in security, observability, and authentication features
- **💎 Ruby Native**: Designed specifically for Ruby developers who love clean, readable code
- **🔧 Zero Config**: Get started in minutes with sensible defaults

## 🚀 Quick Start

### Installation

Add to your Gemfile:

```ruby
gem 'rapitapir'
```

### Basic Sinatra Example

```ruby
require 'sinatra/base'
require 'rapitapir'
require 'rapitapir/sinatra/extension'

class BookAPI < Sinatra::Base
  register RapiTapir::Sinatra::Extension

  # Configure API information
  configure_api do |config|
    config.info(
      title: 'Book API',
      description: 'A simple book management API',
      version: '1.0.0'
    )
  end

  # Define your data schema
  BOOK_SCHEMA = RapiTapir::Types.hash({
    "id" => RapiTapir::Types.integer,
    "title" => RapiTapir::Types.string,
    "author" => RapiTapir::Types.string,
    "published" => RapiTapir::Types.boolean
  })

  # Define endpoints with the elegant resource DSL
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
  end

  run! if __FILE__ == $0
end
```

Start your server and visit:
- **📖 Interactive Documentation**: `http://localhost:4567/docs`
- **📋 OpenAPI Specification**: `http://localhost:4567/openapi.json`

That's it! You now have a fully documented, type-safe API with interactive documentation.

## 🏗️ Core Features

### Type-Safe API Design

Define your data schemas once and use them everywhere:

```ruby
USER_SCHEMA = RapiTapir::Types.hash({
  "id" => RapiTapir::Types.integer,
  "name" => RapiTapir::Types.string(min_length: 1, max_length: 100),
  "email" => RapiTapir::Types.email,
  "age" => RapiTapir::Types.optional(RapiTapir::Types.integer(min: 0, max: 150))
})
```

### Fluent Endpoint Definition

Create endpoints with a clean, readable DSL:

```ruby
# Simple endpoint
endpoint(
  RapiTapir.get('/users/:id')
    .summary('Get user by ID')
    .path_param(:id, RapiTapir::Types.integer)
    .ok(USER_SCHEMA)
    .error_response(404, ERROR_SCHEMA, description: 'User not found')
    .build
) do |inputs|
  user = User.find(inputs[:id])
  halt 404 unless user
  user.to_h
end
```

### RESTful Resource Builder

Build complete CRUD APIs with minimal code:

```ruby
api_resource '/users', schema: USER_SCHEMA do
  crud do
    index { User.all }
    show { |inputs| User.find(inputs[:id]) }
    create { |inputs| User.create(inputs[:body]) }
    update { |inputs| User.update(inputs[:id], inputs[:body]) }
    destroy { |inputs| User.delete(inputs[:id]); status 204 }
  end
  
  # Add custom endpoints
  custom(:get, 'active') do
    User.where(active: true)
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
# Bearer token authentication
configure_api do |config|
  config.bearer_auth :api_key, realm: 'API'
end

# Scope-based authorization
endpoint(
  RapiTapir.get('/admin/users')
    .summary('List all users (admin only)')
    .bearer_auth(scopes: ['admin'])
    .ok(RapiTapir::Types.array(USER_SCHEMA))
    .build
) do |inputs|
  require_scope('admin')
  User.all
end
```

### Observability

```ruby
# Health checks
RapiTapir::Observability.configure do |config|
  config.enable_health_checks
  config.health_endpoint '/health'
end

# Metrics and tracing
endpoint(
  RapiTapir.get('/api/data')
    .with_metrics('api_data_requests')
    .with_tracing('fetch_api_data')
    .build
) do
  # Your endpoint code
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

- **[Getting Started](examples/getting_started_extension.rb)** - Basic Sinatra integration
- **[Enterprise API](examples/enterprise_rapitapir_api.rb)** - Production-ready example with auth
- **[Authentication](examples/authentication_example.rb)** - Bearer token and scope-based auth
- **[Observability](examples/observability/)** - Health checks, metrics, and tracing

## 📚 Documentation

- **[API Reference](docs/endpoint-definition.md)** - Complete endpoint definition guide
- **[Sinatra Extension](docs/SINATRA_EXTENSION.md)** - Detailed Sinatra integration
- **[Type System](docs/types.md)** - All available types and validations
- **[Authentication](docs/authentication.md)** - Security and auth patterns
- **[Observability](docs/observability.md)** - Monitoring and health checks

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
git clone https://github.com/riccardomerolla/ruby-tapir.git
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

- **🐛 Bug Reports**: [GitHub Issues](https://github.com/riccardomerolla/ruby-tapir/issues)
- **💡 Feature Requests**: [GitHub Discussions](https://github.com/riccardomerolla/ruby-tapir/discussions)
- **📧 Email**: riccardo.merolla@example.com
- **💬 Community**: Join our [Discord](https://discord.gg/rapitapir)

---

**Built with ❤️ for the Ruby and Sinatra community**

# Define an endpoint
endpoint = RapiTapir.post('/users')
  .in(RapiTapir.body({ name: :string, email: :string }))
  .out(RapiTapir.status_code(201))
  .out(RapiTapir.json_body({ id: :integer, name: :string, email: :string }))
  .error_out(422, RapiTapir.json_body({ error: :string }))
  .description('Create a new user')
  .tag('users')

# Validate request/response
input = { body: { name: 'John', email: 'john@example.com' } }
output = { id: 1, name: 'John', email: 'john@example.com' }

endpoint.validate!(input, output) # ✓ Passes

# Invalid data raises TypeError with detailed message
endpoint.validate!({ body: { name: 123 } }, output)
# => TypeError: Invalid type for input 'body': expected Hash, got Integer
```

## 📋 Features

### ✅ **Declarative Endpoint DSL**
Define HTTP endpoints using a fluent, chainable API:

```ruby
RapiTapir.get('/users/:id')
  .in(RapiTapir.path_param(:id, :integer))
  .in(RapiTapir.query(:include, :string, optional: true))
  .in(RapiTapir.header(:authorization, :string))
  .out(RapiTapir.status_code(200))
  .out(RapiTapir.json_body({ id: :integer, name: :string, email: :string }))
  .error_out(404, RapiTapir.json_body({ error: :string }))
  .description('Get user by ID')
  .tag('users')
```

### ✅ **Type-Safe Inputs & Outputs**
Strong typing with runtime validation:

- **Primitive types**: `:string`, `:integer`, `:float`, `:boolean`, `:date`, `:datetime`
- **Hash schemas**: `{ name: :string, age: :integer }`
- **Custom classes**: `User`, `MyCustomType`
- **Optional fields**: `optional: true`

### ✅ **Comprehensive Validation**
Automatic validation with detailed error messages:

```ruby
endpoint.validate!(
  { name: 'John', age: 30 },      # Input
  { id: 1, name: 'John' }         # Output
)
# Returns true or raises TypeError with context
```

### ✅ **Rich Metadata Support**
Document your API with built-in metadata:

```ruby
endpoint
  .description('Create a new user account')
  .summary('User creation')
  .tag('users')
  .example({ name: 'John', email: 'john@example.com' })
  .deprecated(false)
```

### ✅ **Immutable Design**
All operations return new instances, ensuring thread safety:

```ruby
base = RapiTapir.get('/users')
with_auth = base.in(RapiTapir.header(:auth, :string))
# base and with_auth are different objects
```

## 🛠️ Installation

Add to your Gemfile:

```ruby
gem 'rapitapir'
```

Or install directly:

```bash
gem install rapitapir
```

## 📖 Documentation

- [Endpoint Definition Guide](docs/endpoint-definition.md) - Complete DSL reference
- [Implementation Plan](docs/blueprint.md) - Architecture and roadmap
- [Examples](examples/) - Practical usage examples

## 🧪 Testing

RapiTapir has comprehensive test coverage:

```bash
bundle install
bundle exec rspec
```

**Test Results:**
- 88 tests passing
- 85.67% code coverage
- All core functionality tested

## 📝 Examples

### Basic CRUD API

```ruby
require 'rapitapir'

# List users
list_users = RapiTapir.get('/users')
  .in(RapiTapir.query(:page, :integer, optional: true))
  .in(RapiTapir.query(:limit, :integer, optional: true))
  .out(RapiTapir.json_body({
    users: [{ id: :integer, name: :string }],
    total: :integer
  }))

# Get user by ID  
get_user = RapiTapir.get('/users/:id')
  .in(RapiTapir.path_param(:id, :integer))
  .out(RapiTapir.json_body({ id: :integer, name: :string, email: :string }))
  .error_out(404, RapiTapir.json_body({ error: :string }))

# Create user
create_user = RapiTapir.post('/users')
  .in(RapiTapir.body({ name: :string, email: :string }))
  .out(RapiTapir.status_code(201))
  .out(RapiTapir.json_body({ id: :integer, name: :string, email: :string }))
  .error_out(422, RapiTapir.json_body({ 
    error: :string, 
    details: [{ field: :string, message: :string }]
  }))

# Update user
update_user = RapiTapir.put('/users/:id')
  .in(RapiTapir.path_param(:id, :integer))
  .in(RapiTapir.body({ name: :string, email: :string }))
  .out(RapiTapir.json_body({ id: :integer, name: :string, email: :string }))
  .error_out(404, RapiTapir.json_body({ error: :string }))
  .error_out(422, RapiTapir.json_body({ error: :string }))

# Delete user
delete_user = RapiTapir.delete('/users/:id')
  .in(RapiTapir.path_param(:id, :integer))
  .out(RapiTapir.status_code(204))
  .error_out(404, RapiTapir.json_body({ error: :string }))
```

### Advanced Features

```ruby
# Complex endpoint with metadata
complex_endpoint = RapiTapir.post('/orders')
  .in(RapiTapir.header(:authorization, :string))
  .in(RapiTapir.body({
    items: [{ product_id: :integer, quantity: :integer }],
    shipping_address: {
      street: :string,
      city: :string,
      country: :string,
      postal_code: :string
    },
    payment: { method: :string, amount: :float }
  }))
  .out(RapiTapir.status_code(201))
  .out(RapiTapir.json_body({
    id: :string,
    status: :string,
    total: :float,
    created_at: :datetime
  }))
  .error_out(400, RapiTapir.json_body({ error: :string }))
  .error_out(401, RapiTapir.json_body({ error: :string }))
  .error_out(422, RapiTapir.json_body({ 
    error: :string,
    validation_errors: [{ field: :string, message: :string }]
  }))
  .description('Create a new order with items and payment')
  .summary('Create order')
  .tag('orders')
  .example({
    items: [{ product_id: 1, quantity: 2 }],
    shipping_address: {
      street: '123 Main St',
      city: 'New York',
      country: 'US',
      postal_code: '10001'
    },
    payment: { method: 'credit_card', amount: 99.99 }
  })
```

## 🗂️ Project Structure

```
lib/
├── rapitapir/
│   ├── core/
│   │   ├── endpoint.rb      # Core endpoint definition
│   │   ├── input.rb         # Input type handling  
│   │   ├── output.rb        # Output type handling
│   │   ├── request.rb       # HTTP request wrapper
│   │   └── response.rb      # HTTP response wrapper
│   └── dsl/
│       └── endpoint_dsl.rb  # DSL helper methods
└── rapitapir.rb             # Main entry point

spec/                        # Comprehensive test suite
examples/                    # Usage examples
docs/                        # Documentation
```

## 🚧 Current Status

**Phase 1: Core Foundation** ✅ **COMPLETE**
- [x] Core type system and endpoint definitions
- [x] Basic DSL with fluent API
- [x] Runtime type validation
- [x] Comprehensive test suite (88 tests, 85.67% coverage)
- [x] Immutable design patterns
- [x] Rich error messages

**Phase 2: Server Integration** 🚧 **PLANNED**
- [ ] Rack adapter for framework integration
- [ ] Sinatra/Rails/Hanami adapters
- [ ] Request/response processing pipeline

**Phase 3: Advanced Features** 🚧 **PLANNED**
- [ ] OpenAPI 3.x documentation generation
- [ ] HTTP client generation
- [ ] Observability hooks (metrics, tracing)
- [ ] Custom type systems

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Ensure all tests pass: `bundle exec rspec`
5. Submit a pull request

### Development Guidelines

- Follow Ruby Style Guide
- Write comprehensive tests (aim for >90% coverage)
- Use 2-space indentation
- Add `# frozen_string_literal: true` to all files
- Document public APIs

## 📊 Roadmap

### Version 1.0 (Q3 2025)
- Complete core DSL and validation
- Server framework adapters
- OpenAPI documentation generation
- Production-ready performance

### Version 1.1 (Q4 2025)
- HTTP client generation
- Advanced observability
- Performance optimizations

### Version 2.0 (2026)
- Cross-language client generation
- Advanced type system features
- Plugin architecture

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

Inspired by:
- [Scala Tapir](https://github.com/softwaremill/tapir) - Type-safe endpoints
- [Haskell Servant](https://github.com/haskell-servant/servant) - Type-level web APIs
- [tRPC](https://trpc.io/) - End-to-end typesafe APIs

---

**RapiTapir** - APIs so fast and clean, they practically run wild! 🦙⚡
