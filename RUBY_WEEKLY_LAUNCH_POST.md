# 🦙 Introducing RapiTapir: Type-Safe HTTP APIs for Ruby

**TL;DR**: RapiTapir brings Scala Tapir's elegance to Ruby with type-safe API development, automatic OpenAPI docs, and a clean DSL that makes building production APIs a joy.

## The Problem: Ruby API Development Pain Points

Ruby developers love the language's expressiveness, but API development often involves:

- **Manual documentation** that gets out of sync with code
- **Runtime errors** from type mismatches that could be caught earlier  
- **Boilerplate code** for validation, serialization, and error handling
- **Inconsistent patterns** across different teams and projects

What if we could have the type safety of languages like Scala while keeping Ruby's elegance?

## Enter RapiTapir 🦙

RapiTapir is inspired by [Scala's Tapir](https://github.com/softwaremill/tapir) library, bringing **declarative, type-safe API development** to Ruby. Define your endpoints once with strong typing, and get automatic validation, documentation, and client generation.

### The Magic: Clean Base Class Syntax

```ruby
require 'rapitapir'

class BookAPI < SinatraRapiTapir
  # 🎯 Configure once, get everything
  rapitapir do
    info(title: 'Book API', version: '1.0.0')
    development_defaults! # Auto CORS, docs, health checks
  end

  # 📏 T shortcut available globally - no imports needed!
  BOOK_SCHEMA = T.hash({
    "id" => T.integer,
    "title" => T.string(min_length: 1, max_length: 255),
    "author" => T.string(min_length: 1),
    "published" => T.boolean,
    "isbn" => T.optional(T.string),
    "pages" => T.optional(T.integer(minimum: 1))
  })

  # 🚀 Fluent endpoint definition with automatic validation
  endpoint(
    GET('/books')
      .query(:limit, T.optional(T.integer(min: 1, max: 100)))
      .query(:genre, T.optional(T.string))
      .summary('List books with filtering')
      .ok(T.array(BOOK_SCHEMA))
      .build
  ) do |inputs|
    # inputs are already validated and type-coerced!
    Book.where(genre: inputs[:genre])
        .limit(inputs[:limit] || 20)
        .map(&:to_h)
  end

  run! if __FILE__ == $0
end
```

Start the server and visit `http://localhost:4567/docs` for **interactive Swagger documentation** that's always in sync with your code.

## Why RapiTapir Feels Like Ruby Magic ✨

### 1. **Zero Boilerplate Setup**
```ruby
# One line to get a complete API server
class MyAPI < SinatraRapiTapir
  # Enhanced HTTP verbs automatically available
  # T shortcut for types works everywhere
  # Health checks, CORS, docs - all included
end
```

### 2. **Type Safety Without Ceremony**
```ruby
# Define once, use everywhere
USER_SCHEMA = T.hash({
  "email" => T.email,  # Built-in email validation
  "age" => T.optional(T.integer(min: 0, max: 150)),
  "preferences" => T.hash({
    "newsletter" => T.boolean,
    "theme" => T.enum(['light', 'dark'])
  })
})

# Automatic validation + coercion
endpoint(POST('/users').json_body(USER_SCHEMA).build) do |inputs|
  # inputs[:body] is guaranteed to match USER_SCHEMA
  User.create(inputs[:body])
end
```

### 3. **RESTful Resources Made Simple**
```ruby
# Complete CRUD API in ~10 lines
api_resource '/books', schema: BOOK_SCHEMA do
  crud do
    index { Book.all }
    show { |inputs| Book.find(inputs[:id]) }
    create { |inputs| Book.create(inputs[:body]) }
    update { |inputs| Book.update(inputs[:id], inputs[:body]) }
    destroy { |inputs| Book.destroy(inputs[:id]); status 204 }
  end
  
  # Add custom endpoints with full type safety
  custom :get, 'featured' do
    Book.where(featured: true)
  end
end
```

## Production-Ready Features 🛡️

### Built-in Security & Auth
```ruby
class SecureAPI < SinatraRapiTapir
  rapitapir do
    bearer_auth :api_key
    production_defaults! # Security headers, rate limiting, etc.
  end

  endpoint(
    GET('/admin/users')
      .bearer_auth(scopes: ['admin'])  # Scope-based authorization
      .ok(T.array(USER_SCHEMA))
      .build
  ) do
    require_scope!('admin')
    User.all
  end
end
```

### Observability Out of the Box
```ruby
rapitapir do
  enable_health_checks    # GET /health
  enable_metrics         # Prometheus metrics at /metrics  
  enable_tracing         # OpenTelemetry integration
end
```

## Real-World Benefits

**🚀 Development Speed**: Define endpoints declaratively, get validation + docs for free

**🐛 Fewer Bugs**: Type checking catches issues at definition time, not runtime

**📖 Always-Current Docs**: Swagger UI generated from your actual code

**🔧 Better DX**: Enhanced error messages, auto-completion, consistent patterns

**⚡ Easy Testing**: Validate schemas independently, generate test fixtures

## Framework Integration

Works with your existing Ruby stack:

```ruby
# Sinatra (recommended) - clean inheritance
class API < SinatraRapiTapir; end

# Sinatra extension 
register RapiTapir::Sinatra::Extension

# Plain Rack
use RapiTapir::Server::RackAdapter

# Rails controllers (coming soon)
include RapiTapir::Rails::Controller
```

## The Ruby Community Connection

RapiTapir builds on Ruby's strengths:

- **Sinatra's simplicity** with enhanced capabilities
- **Rack's composability** for middleware and deployment  
- **Ruby's expressiveness** with added type safety
- **Community gems** for auth, testing, deployment

It's not about replacing your stack - it's about making it better.

## Getting Started

```bash
gem install rapitapir
```

Or add to your Gemfile:
```ruby
gem 'rapitapir'
```

Check out the [comprehensive examples](https://github.com/riccardomerolla/rapitapir/tree/main/examples) and [documentation](https://riccardomerolla.github.io/rapitapir).

## What's Next?

- 🎯 **Rails integration** for seamless adoption in existing apps
- 🌐 **Multi-language client generation** (TypeScript, Python, Go)
- 📊 **Enhanced observability** with distributed tracing
- 🔌 **Plugin ecosystem** for community extensions

## Try It Today

RapiTapir is **production-ready** with comprehensive tests, clear documentation, and real-world examples. Whether you're building a new API or enhancing an existing one, RapiTapir helps you write better Ruby code.

**Links:**
- 📦 **Gem**: [rubygems.org/gems/rapitapir](https://rubygems.org/gems/rapitapir)  
- 🏠 **Homepage**: [riccardomerolla.github.io/rapitapir](https://riccardomerolla.github.io/rapitapir)
- 💻 **Source**: [github.com/riccardomerolla/rapitapir](https://github.com/riccardomerolla/rapitapir)
- 📖 **Docs**: [Examples and guides](https://github.com/riccardomerolla/rapitapir/tree/main/examples)

---

*Built with ❤️ for the Ruby community. Questions? Feedback? Open an issue or discussion on GitHub!*

**RapiTapir** - APIs so clean and fast, they practically run wild! 🦙⚡
