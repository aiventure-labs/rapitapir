# RapiTapir 🦙

A Ruby library for defining HTTP API endpoints declaratively with type safety, automatic validation, and excellent developer experience.

[![Tests](https://img.shields.io/badge/tests-88%20passing-brightgreen)](spec/)
[![Coverage](https://img.shields.io/badge/coverage-85.67%25-green)](coverage/)
[![Ruby](https://img.shields.io/badge/ruby-3.2%2B-red)](Gemfile)

## 🎯 Goals

- **Type-safe HTTP APIs**: Define endpoints with strong typing for inputs and outputs
- **Declarative DSL**: Readable, composable endpoint definitions
- **Runtime Validation**: Automatic type checking and validation
- **Framework Agnostic**: Works with any Ruby web framework
- **Developer Joy**: Excellent error messages and IDE support

## 🚀 Quick Start

```ruby
require 'rapitapir'

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
