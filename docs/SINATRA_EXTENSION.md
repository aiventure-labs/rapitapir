# RapiTapir Sinatra Integration

**Zero-boilerplate, enterprise-grade API development with RapiTapir and Sinatra**

RapiTapir provides two elegant ways to integrate with Sinatra: the recommended **SinatraRapiTapir base class** for maximum simplicity, and the **manual extension registration** for advanced customization.

## 🚀 Quick Start (Recommended)

### Option 1: SinatraRapiTapir Base Class

The simplest and cleanest way to create APIs:

```ruby
require 'rapitapir'

class MyAPI < SinatraRapiTapir
  rapitapir do
    info(title: 'My API', version: '2.0.0')
    development_defaults! # Auto CORS, docs, health checks
  end

  # T shortcut and HTTP verbs automatically available
  endpoint(
    GET('/hello')
      .query(:name, T.string, description: 'Your name')
      .ok(T.hash({ "message" => T.string }))
      .build
  ) { |inputs| { message: "Hello, #{inputs[:name]}!" } }

  run! if __FILE__ == $0
end
```

### Option 2: Manual Extension Registration

For advanced customization and existing Sinatra applications:

```ruby
require 'sinatra/base'
require 'rapitapir/sinatra/extension'

class MyAPI < Sinatra::Base
  register RapiTapir::Sinatra::Extension

  rapitapir do
    info(title: 'My API', version: '2.0.0')
    development_defaults!
  end

  endpoint(
    GET('/hello')
      .query(:name, T.string)
      .ok(T.hash({ "message" => T.string }))
      .build
  ) { |inputs| { message: "Hello, #{inputs[:name]}!" } }
end
```

## 📋 Key Features

### ✨ Zero Configuration
- **SinatraRapiTapir base class**: Inherit and start building APIs immediately
- **T shortcut**: Use `T.string` instead of `RapiTapir::Types.string` everywhere
- **HTTP verbs**: `GET()`, `POST()`, `PUT()`, `DELETE()` methods built-in
- **Smart defaults**: Production and development presets that just work

### 🏭 Enterprise Ready
- **Built-in authentication**: OAuth2, Bearer token, API key, and custom schemes
- **Production middleware**: CORS, rate limiting, security headers, request validation
- **Auto-generated documentation**: Interactive Swagger UI with try-it-out functionality
- **Type-safe validation**: Automatic request/response validation with helpful errors

### 🤖 AI Integration
- **LLM instruction generation**: Auto-generate AI prompts for your endpoints
- **RAG pipelines**: Retrieval-augmented generation for enhanced responses
- **MCP export**: Model Context Protocol for AI agent consumption
- **CLI toolkit**: Complete command-line development workflow

## 📖 Configuration Options

### API Information
```ruby
rapitapir do
  info(
    title: 'My API',
    description: 'A comprehensive API for my application',
    version: '2.0.0',
    contact: { 
      name: 'API Team', 
      email: 'api@example.com',
      url: 'https://example.com/support'
    },
    license: {
      name: 'MIT',
      url: 'https://opensource.org/licenses/MIT'
    }
  )
  
  # Server environments
  server(url: 'http://localhost:4567', description: 'Development')
  server(url: 'https://staging-api.example.com', description: 'Staging')
  server(url: 'https://api.example.com', description: 'Production')
end
```

### Development vs Production Defaults

```ruby
# Development mode (automatic CORS, docs, health checks)
rapitapir do
  development_defaults!
end

# Production mode (security headers, rate limiting, metrics)
rapitapir do
  production_defaults!
end

# Custom configuration
rapitapir do
  enable_docs(path: '/documentation', openapi_path: '/spec.json')
  enable_cors(origins: ['https://myapp.com'], methods: %w[GET POST])
  enable_health_checks(path: '/health')
  enable_metrics(path: '/metrics')
end
```

## 🏗️ Endpoint Definition

### Modern HTTP Verb DSL

```ruby
class BookAPI < SinatraRapiTapir
  # Basic endpoint
  endpoint(
    GET('/books')
      .summary('List all books')
      .query(:limit, T.optional(T.integer(minimum: 1, maximum: 100)), description: 'Number of books to return')
      .query(:genre, T.optional(T.string), description: 'Filter by genre')
      .ok(T.array(T.hash({
        "id" => T.integer,
        "title" => T.string,
        "author" => T.string,
        "genre" => T.string
      })))
      .build
  ) do |inputs|
    books = Book.all
    books = books.where(genre: inputs[:genre]) if inputs[:genre]
    books = books.limit(inputs[:limit] || 50)
    books.map(&:to_h)
  end

  # POST with body validation
  endpoint(
    POST('/books')
      .summary('Create a new book')
      .body(T.hash({
        "title" => T.string(min_length: 1, max_length: 500),
        "author" => T.string(min_length: 1),
        "genre" => T.string,
        "isbn" => T.optional(T.string(pattern: /^\d{13}$/)),
        "pages" => T.optional(T.integer(minimum: 1))
      }), description: 'Book data')
      .ok(T.hash({
        "id" => T.integer,
        "title" => T.string,
        "author" => T.string,
        "created_at" => T.datetime
      }), description: 'Created book')
      .error_response(400, T.hash({ "error" => T.string, "details" => T.array(T.string) }))
      .build
  ) do |inputs|
    begin
      book = Book.create!(inputs[:body])
      status 201
      {
        id: book.id,
        title: book.title,
        author: book.author,
        created_at: book.created_at
      }
    rescue ValidationError => e
      halt 400, {
        error: 'Validation failed',
        details: e.messages
      }.to_json
    end
  end
end
```

### RESTful Resource Builder

Create complete CRUD APIs with minimal code:

```ruby
class UserAPI < SinatraRapiTapir
  USER_SCHEMA = T.hash({
    "id" => T.integer,
    "name" => T.string(min_length: 1, max_length: 100),
    "email" => T.email,
    "active" => T.boolean,
    "created_at" => T.datetime,
    "updated_at" => T.datetime
  })

  api_resource '/users', schema: USER_SCHEMA do
    crud do
      index do |inputs|
        users = User.all
        users = users.where(active: true) if inputs[:active] == 'true'
        users.limit(inputs[:limit] || 50).map(&:to_h)
      end
      
      show { |inputs| User.find(inputs[:id])&.to_h || halt(404) }
      
      create do |inputs|
        user = User.create!(inputs[:body])
        status 201
        user.to_h
      end
      
      update do |inputs|
        user = User.find(inputs[:id]) || halt(404)
        user.update!(inputs[:body])
        user.to_h
      end
      
      destroy do |inputs|
        user = User.find(inputs[:id]) || halt(404)
        user.destroy!
        status 204
      end
    end
    
    # Custom endpoints
    custom :post, ':id/activate' do |inputs|
      user = User.find(inputs[:id]) || halt(404)
      user.update!(active: true)
      { message: 'User activated', user: user.to_h }
    end
  end
end
```

## 🔐 Authentication

### OAuth2 + Auth0 Integration

```ruby
class SecureAPI < SinatraRapiTapir
  rapitapir do
    info(title: 'Secure API', version: '2.0.0')
    
    # Configure Auth0 OAuth2
    oauth2_auth0 :auth0,
      domain: ENV['AUTH0_DOMAIN'],
      audience: ENV['AUTH0_AUDIENCE'],
      realm: 'API Access'
    
    production_defaults!
  end

  # Protected endpoint with scopes
  endpoint(
    GET('/profile')
      .summary('Get user profile')
      .bearer_auth(scopes: ['read:profile'])
      .ok(T.hash({
        "user" => T.hash({
          "id" => T.string,
          "email" => T.string,
          "name" => T.string
        })
      }))
      .build
  ) do
    user_info = current_auth_context[:user_info]
    {
      user: {
        id: user_info['sub'],
        email: user_info['email'],
        name: user_info['name']
      }
    }
  end

  # Scope-based protection for multiple endpoints
  protect_with_oauth2 scopes: ['api:read'] do
    endpoint(GET('/protected').ok(T.hash({})).build) { { data: 'protected' } }
    endpoint(GET('/also-protected').ok(T.hash({})).build) { { data: 'also protected' } }
  end
end
```

### Bearer Token Authentication

```ruby
class TokenAPI < SinatraRapiTapir
  rapitapir do
    bearer_auth :api_key, realm: 'API'
    production_defaults!
  end

  endpoint(
    GET('/secure-data')
      .bearer_auth
      .ok(T.array(T.hash({})))
      .build
  ) do
    # current_auth_context available here
    SecureData.for_user(current_auth_context[:user_id])
  end
end
```

## 🤖 AI Integration

### LLM Instructions and RAG

```ruby
class AIEnhancedAPI < SinatraRapiTapir
  rapitapir do
    info(title: 'AI-Enhanced API', version: '2.0.0')
    development_defaults!
  end

  # AI-powered search with RAG
  endpoint(
    GET('/books/ai-search')
      .query(:query, T.string, description: 'Natural language search query')
      .summary('AI-powered semantic book search')
      .tags('AI', 'Search')
      .ok(T.hash({
        "books" => T.array(BOOK_SCHEMA),
        "reasoning" => T.string,
        "confidence" => T.float
      }))
      .enable_rag(
        retrieval_backend: :memory,
        llm_provider: :openai
      )
      .enable_mcp # Export for AI agents
      .build
  ) do |inputs|
    # RAG context automatically injected
    results = AIBookSearch.semantic_search(
      query: inputs[:query],
      context: rag_context
    )
    
    {
      books: results[:books],
      reasoning: results[:explanation],
      confidence: results[:confidence_score]
    }
  end

  # Generate LLM instructions for endpoints
  endpoint(
    GET('/ai/instructions/:endpoint_id')
      .path_param(:endpoint_id, T.string)
      .query(:purpose, T.string(enum: %w[validation transformation analysis documentation testing completion]))
      .summary('Generate LLM instructions for an endpoint')
      .ok(T.hash({
        "instructions" => T.string,
        "metadata" => T.hash({})
      }))
      .build
  ) do |inputs|
    generator = RapiTapir::AI::LLMInstruction::Generator.new
    endpoint = find_endpoint(inputs[:endpoint_id])
    
    instructions = generator.generate_instructions(
      endpoint: endpoint,
      purpose: inputs[:purpose].to_sym
    )
    
    {
      instructions: instructions,
      metadata: {
        endpoint_id: inputs[:endpoint_id],
        purpose: inputs[:purpose],
        generated_at: Time.now
      }
    }
  end
end
```

## 📊 Observability

### Comprehensive Monitoring

```ruby
class MonitoredAPI < SinatraRapiTapir
  rapitapir do
    info(title: 'Monitored API', version: '2.0.0')
    
    enable_observability do |config|
      # Health checks
      config.health_checks.enable(path: '/health')
      config.health_checks.add_check('database') { Database.healthy? }
      config.health_checks.add_check('redis') { Redis.current.ping == 'PONG' }
      
      # OpenTelemetry tracing
      config.tracing.enable_opentelemetry(
        service_name: 'my-api',
        exporters: [:honeycomb, :jaeger]
      )
      
      # Prometheus metrics
      config.metrics.enable_prometheus(namespace: 'my_api')
      
      # Structured logging
      config.logging.enable_structured(format: :json)
    end
    
    production_defaults!
  end

  # Endpoint with observability features
  endpoint(
    GET('/monitored-endpoint')
      .with_metrics('endpoint_requests', labels: { operation: 'get' })
      .with_tracing('fetch_data')
      .ok(T.hash({ "data" => T.string }))
      .build
  ) do
    # Automatic metrics and tracing
    { data: 'monitored response' }
  end
end
```

## 🧪 Testing

### Test Your Endpoints

```ruby
require 'rack/test'

RSpec.describe MyAPI do
  include Rack::Test::Methods

  def app
    MyAPI
  end

  it 'returns hello message' do
    get '/hello?name=World'
    
    expect(last_response).to be_ok
    expect(JSON.parse(last_response.body)).to eq({
      'message' => 'Hello, World!'
    })
  end

  it 'validates required parameters' do
    get '/hello'
    
    expect(last_response.status).to eq(400)
    expect(JSON.parse(last_response.body)).to include('error')
  end
end
```

### Validate Endpoint Definitions

```ruby
# Validate all endpoints
validator = RapiTapir::CLI::Validator.new(MyAPI.rapitapir_endpoints)
result = validator.validate

puts "Validation passed: #{result}"
puts "Errors: #{validator.errors}" unless result
```

## 🔗 Comparison: Base Class vs Extension

| Feature | SinatraRapiTapir | Manual Extension |
|---------|------------------|------------------|
| Setup complexity | Single inheritance | Manual registration |
| HTTP verb methods | ✅ Built-in | ✅ Available |
| T shortcut | ✅ Automatic | ✅ Available |
| Configuration | ✅ Simple | ✅ Full control |
| Sinatra features | ✅ All available | ✅ All available |
| Customization | Good | Excellent |
| Use case | New APIs, rapid prototyping | Existing apps, advanced needs |

## 📚 Examples

### Complete RESTful API
See [examples/working_simple_example.rb](../examples/working_simple_example.rb)

### Authentication with Auth0
See [examples/oauth2/](../examples/oauth2/)

### AI-Powered Features
See [examples/auto_derivation_ruby_friendly.rb](../examples/auto_derivation_ruby_friendly.rb)

### Production Observability
See [examples/observability/](../examples/observability/)

## 🎯 Best Practices

1. **Use SinatraRapiTapir** for new projects - it's the simplest approach
2. **Leverage T shortcuts** everywhere for cleaner type definitions
3. **Use resource builders** for RESTful APIs to reduce boilerplate
4. **Enable observability** for production deployments
5. **Implement proper error handling** with meaningful error responses
6. **Document with examples** using the built-in OpenAPI generation
7. **Test endpoint validation** to ensure type safety works correctly

---

RapiTapir + Sinatra = **APIs so fast and clean, they practically run wild!** 🦙⚡
