# Ruby Tapir - Type-Safe HTTP API Library

A Ruby library for describing, serving, consuming, and documenting HTTP APIs with type safety and developer experience in mind.

## Repository Structure

```
ruby-tapir/
├── lib/
│   ├── tapir/
│   │   ├── core/
│   │   │   ├── endpoint.rb
│   │   │   ├── schema.rb
│   │   │   ├── input.rb
│   │   │   ├── output.rb
│   │   │   ├── codec.rb
│   │   │   └── validation.rb
│   │   ├── dsl/
│   │   │   ├── endpoint_dsl.rb
│   │   │   ├── schema_dsl.rb
│   │   │   └── validation_dsl.rb
│   │   ├── server/
│   │   │   ├── rack_adapter.rb
│   │   │   ├── sinatra_adapter.rb
│   │   │   ├── rails_adapter.rb
│   │   │   ├── hanami_adapter.rb
│   │   │   └── roda_adapter.rb
│   │   ├── client/
│   │   │   ├── http_client.rb
│   │   │   ├── faraday_adapter.rb
│   │   │   └── net_http_adapter.rb
│   │   ├── docs/
│   │   │   ├── openapi.rb
│   │   │   ├── swagger_ui.rb
│   │   │   └── redoc.rb
│   │   ├── observability/
│   │   │   ├── metrics.rb
│   │   │   ├── tracing.rb
│   │   │   └── logging.rb
│   │   ├── types/
│   │   │   ├── string.rb
│   │   │   ├── integer.rb
│   │   │   ├── float.rb
│   │   │   ├── boolean.rb
│   │   │   ├── array.rb
│   │   │   ├── hash.rb
│   │   │   ├── date.rb
│   │   │   ├── datetime.rb
│   │   │   └── custom.rb
│   │   ├── integrations/
│   │   │   ├── dry_validation.rb
│   │   │   ├── dry_struct.rb
│   │   │   ├── virtus.rb
│   │   │   └── active_model.rb
│   │   └── version.rb
│   └── tapir.rb
├── docs/
│   ├── implementation-plan.md
│   ├── architecture.md
│   ├── getting-started.md
│   ├── endpoint-definition.md
│   ├── server-integration.md
│   ├── client-usage.md
│   ├── openapi-documentation.md
│   ├── observability.md
│   ├── type-system.md
│   ├── examples/
│   │   ├── basic-crud.md
│   │   ├── authentication.md
│   │   ├── file-upload.md
│   │   ├── websockets.md
│   │   └── microservices.md
│   └── api-reference/
├── examples/
│   ├── sinatra/
│   ├── rails/
│   ├── hanami/
│   ├── roda/
│   └── client/
├── spec/
│   ├── core/
│   ├── dsl/
│   ├── server/
│   ├── client/
│   ├── docs/
│   ├── observability/
│   ├── types/
│   ├── integrations/
│   └── spec_helper.rb
├── benchmarks/
│   ├── endpoint_creation.rb
│   ├── request_processing.rb
│   └── serialization.rb
├── .github/
│   ├── workflows/
│   │   ├── ci.yml
│   │   ├── release.yml
│   │   └── docs.yml
│   ├── ISSUE_TEMPLATE/
│   └── PULL_REQUEST_TEMPLATE.md
├── Gemfile
├── Rakefile
├── tapir.gemspec
├── README.md
├── CHANGELOG.md
├── LICENSE
└── .gitignore
```

## Core Philosophy

### Type Safety First
- Compile-time (or load-time) validation of endpoint definitions
- Runtime type checking with detailed error messages
- Integration with Ruby type checkers (Sorbet, RBS)

### Declarative API Design
- Separate endpoint shape from implementation logic
- Composable and reusable endpoint definitions
- Clean separation of concerns

### Developer Experience
- Intuitive DSL with excellent discoverability
- Rich error messages and debugging information
- IDE-friendly with autocomplete support

### Framework Agnostic
- Library, not framework approach
- Adapters for all major Ruby web frameworks
- Minimal dependencies and lightweight core

## Implementation Phases

### Phase 1: Core Foundation (Weeks 1-3)
**Goal**: Establish the core type system and endpoint definition capabilities

#### Week 1: Type System Foundation
- [ ] Implement basic type system (`Tapir::Types`)
- [ ] Create primitive types (String, Integer, Float, Boolean, Date, DateTime)
- [ ] Implement composite types (Array, Hash, Optional)
- [ ] Add validation framework integration points
- [ ] Create type coercion and serialization mechanisms

#### Week 2: Endpoint Definition Core
- [ ] Design and implement `Tapir::Endpoint` class
- [ ] Create input/output definition system
- [ ] Implement HTTP method and path specification
- [ ] Add header and query parameter support
- [ ] Create request/response body handling

#### Week 3: DSL and Schema Definition
- [ ] Implement endpoint definition DSL
- [ ] Create schema composition capabilities
- [ ] Add endpoint inheritance and mixins
- [ ] Implement validation integration
- [ ] Create basic error handling framework

**Deliverables**:
- Working endpoint definition system
- Basic type validation
- Simple DSL for defining endpoints
- Comprehensive test suite for core functionality

### Phase 2: Server Integration (Weeks 4-6)
**Goal**: Enable serving endpoints through major Ruby frameworks

#### Week 4: Rack Foundation
- [ ] Implement Rack adapter as base for all server integrations
- [ ] Create request processing pipeline
- [ ] Add middleware support for observability
- [ ] Implement response serialization
- [ ] Add error handling and status code management

#### Week 5: Framework Adapters
- [ ] Sinatra adapter with route registration
- [ ] Rails adapter with controller integration
- [ ] Hanami adapter with action integration
- [ ] Roda adapter with routing tree integration
- [ ] Basic performance optimizations

#### Week 6: Advanced Server Features
- [ ] Request/response interceptors
- [ ] Custom middleware integration
- [ ] Streaming response support
- [ ] File upload handling
- [ ] Authentication/authorization hooks

**Deliverables**:
- Working server adapters for major frameworks
- Request/response processing pipeline
- Middleware integration capabilities
- Example applications for each framework

### Phase 3: Client Generation (Weeks 7-8)
**Goal**: Generate type-safe HTTP clients from endpoint definitions

#### Week 7: Client Core
- [ ] Implement HTTP client generator
- [ ] Create Faraday adapter for HTTP requests
- [ ] Add Net::HTTP fallback adapter
- [ ] Implement request serialization
- [ ] Add response deserialization and validation

#### Week 8: Advanced Client Features
- [ ] Error handling and retry mechanisms
- [ ] Async/concurrent request support
- [ ] Client middleware and interceptors
- [ ] Connection pooling and caching
- [ ] Mock client for testing

**Deliverables**:
- Generated HTTP clients with type safety
- Multiple HTTP adapter support
- Error handling and retry logic
- Testing utilities and mocks

### Phase 4: Documentation Generation (Weeks 9-10)
**Goal**: Generate OpenAPI/Swagger documentation automatically

#### Week 9: OpenAPI Core
- [ ] Implement OpenAPI 3.x specification generation
- [ ] Create endpoint to OpenAPI path mapping
- [ ] Add schema to JSON Schema conversion
- [ ] Implement parameter and response documentation
- [ ] Add example generation from types

#### Week 10: Documentation UI
- [ ] Integrate Swagger UI for interactive docs
- [ ] Add ReDoc support as alternative
- [ ] Create custom documentation themes
- [ ] Implement live API testing from docs
- [ ] Add documentation versioning support

**Deliverables**:
- Complete OpenAPI 3.x specification generation
- Interactive documentation interfaces
- Custom documentation themes
- Live API testing capabilities

### Phase 5: Observability and Advanced Features (Weeks 11-12)
**Goal**: Add production-ready observability and advanced features

#### Week 11: Observability
- [ ] Implement metrics collection (response times, error rates)
- [ ] Add distributed tracing support (OpenTelemetry)
- [ ] Create structured logging integration
- [ ] Add health check endpoint generation
- [ ] Implement request/response logging

#### Week 12: Advanced Features
- [ ] Rate limiting and throttling
- [ ] Request/response caching
- [ ] API versioning strategies
- [ ] WebSocket endpoint support
- [ ] GraphQL endpoint integration

**Deliverables**:
- Production-ready observability features
- Advanced API management capabilities
- WebSocket and GraphQL support
- Performance monitoring tools

### Phase 6: Ecosystem Integration (Weeks 13-14)
**Goal**: Integrate with popular Ruby libraries and tools

#### Week 13: Validation Libraries
- [ ] Dry-validation integration
- [ ] Dry-struct integration
- [ ] Virtus integration
- [ ] ActiveModel integration
- [ ] Custom validation framework support

#### Week 14: Type Checking Integration
- [ ] Sorbet type annotations generation
- [ ] RBS signature generation
- [ ] YARD documentation integration
- [ ] IDE plugins and extensions
- [ ] Static analysis tools integration

**Deliverables**:
- Seamless integration with validation libraries
- Type checker integration
- IDE and tooling support
- Static analysis capabilities

## Technical Architecture

### Core Components

#### 1. Type System (`Tapir::Types`)
```ruby
# Primitive types
Tapir::Types::String.new(min_length: 3, max_length: 255)
Tapir::Types::Integer.new(minimum: 0, maximum: 100)
Tapir::Types::Boolean.new
Tapir::Types::DateTime.new(format: :iso8601)

# Composite types
Tapir::Types::Array.new(Tapir::Types::String.new)
Tapir::Types::Hash.new(
  name: Tapir::Types::String.new,
  age: Tapir::Types::Integer.new
)
Tapir::Types::Optional.new(Tapir::Types::String.new)

# Custom types
UserType = Tapir::Types::Object.new do
  field :id, Tapir::Types::Integer.new
  field :name, Tapir::Types::String.new
  field :email, Tapir::Types::String.new(format: :email)
end
```

#### 2. Endpoint Definition (`Tapir::Endpoint`)
```ruby
class UserEndpoints
  include Tapir::DSL

  # GET /users/{id}
  get_user = endpoint
    .get
    .in(path_param(:id, Tapir::Types::Integer.new))
    .out(json_body(UserType))
    .error_out(404, json_body(ErrorType))
    .summary("Get user by ID")
    .description("Retrieves a user by their unique identifier")

  # POST /users
  create_user = endpoint
    .post
    .in(json_body(CreateUserType))
    .out(status(201), json_body(UserType))
    .error_out(400, json_body(ValidationErrorType))
    .error_out(422, json_body(BusinessLogicErrorType))
end
```

#### 3. Server Integration
```ruby
# Sinatra
class UserAPI < Sinatra::Base
  include Tapir::Sinatra

  mount UserEndpoints.get_user do |user_id|
    user_service.find(user_id)
  end

  mount UserEndpoints.create_user do |user_data|
    user_service.create(user_data)
  end
end

# Rails
class UsersController < ApplicationController
  include Tapir::Rails

  mount UserEndpoints.get_user do |user_id|
    @user_service.find(user_id)
  end

  mount UserEndpoints.create_user do |user_data|
    @user_service.create(user_data)
  end
end
```

#### 4. Client Generation
```ruby
# Generated client
user_client = Tapir::Client.new(UserEndpoints, base_url: "https://api.example.com")

# Type-safe method calls
user = user_client.get_user(id: 123)  # Returns User object or raises typed error
new_user = user_client.create_user(name: "John", email: "john@example.com")
```

#### 5. Documentation Generation
```ruby
# Generate OpenAPI spec
openapi_spec = Tapir::Docs::OpenAPI.generate(UserEndpoints)

# Serve documentation
Tapir::Docs::SwaggerUI.mount(openapi_spec, path: "/docs")
```

## Key Design Principles

### 1. Type Safety
- **Compile-time validation**: Endpoint definitions are validated when loaded
- **Runtime type checking**: All inputs/outputs are validated against schemas
- **Error propagation**: Type errors include detailed information about failures
- **Integration**: Works with Sorbet, RBS, and other type systems

### 2. Composability
- **Endpoint reuse**: Common patterns can be extracted and reused
- **Schema composition**: Complex types built from simpler ones
- **Middleware chains**: Request/response processing is composable
- **Framework agnostic**: Same endpoints work across different frameworks

### 3. Performance
- **Lazy evaluation**: Schemas and validations are computed only when needed
- **Caching**: Compiled schemas and validators are cached
- **Zero-allocation paths**: Common cases avoid object allocation
- **Benchmarking**: Comprehensive performance testing and optimization

### 4. Developer Experience
- **Rich errors**: Detailed error messages with context and suggestions
- **IDE support**: Autocomplete, type hints, and inline documentation
- **Debugging**: Clear stack traces and debugging information
- **Documentation**: Comprehensive guides and API documentation

## Success Metrics

### Technical Metrics
- **Performance**: < 1ms overhead for simple endpoints
- **Memory**: < 10MB memory overhead for typical applications
- **Compatibility**: Support for Ruby 2.7+ and all major frameworks
- **Coverage**: > 95% test coverage across all components

### Developer Experience Metrics
- **Setup time**: < 5 minutes from gem install to first endpoint
- **Learning curve**: Clear tutorials for common use cases
- **Error clarity**: Meaningful error messages with actionable advice
- **Documentation**: Complete API reference and usage examples

### Ecosystem Integration
- **Framework support**: Adapters for top 5 Ruby web frameworks
- **Library integration**: Support for major validation/serialization libraries
- **Tooling**: IDE plugins and static analysis integration
- **Community**: Active contribution guidelines and responsive maintenance

## Risk Mitigation

### Performance Risks
- **Mitigation**: Comprehensive benchmarking suite and performance budgets
- **Monitoring**: Continuous performance testing in CI/CD
- **Optimization**: Profile-guided optimization for hot paths

### Complexity Risks
- **Mitigation**: Modular architecture with clear separation of concerns
- **Documentation**: Extensive architectural documentation and examples
- **Testing**: Comprehensive test suite with integration tests

### Adoption Risks
- **Mitigation**: Clear migration guides from existing solutions
- **Compatibility**: Gradual adoption path without requiring full rewrites
- **Community**: Active engagement with Ruby community for feedback

## Future Roadmap

### Version 1.0 (Core Features)
- Complete type system and endpoint definitions
- Server adapters for major frameworks
- Client generation capabilities
- OpenAPI documentation generation
- Basic observability features

### Version 1.1 (Performance & Polish)
- Performance optimizations and benchmarking
- Enhanced error messages and debugging
- Additional framework adapters
- Advanced documentation features

### Version 1.2 (Advanced Features)
- WebSocket endpoint support
- GraphQL integration
- Advanced caching and rate limiting
- Enhanced observability and monitoring

### Version 2.0 (Next Generation)
- Code generation and compile-time optimizations
- Advanced type system features
- Plugin architecture for extensibility
- Cross-language client generation

## Contributing Guidelines

### Code Style
- Follow RuboCop configuration
- Write comprehensive tests for all features
- Include documentation for public APIs
- Maintain backwards compatibility within major versions

### Architecture Decisions
- Document significant architectural decisions
- Prefer composition over inheritance
- Minimize dependencies and coupling
- Design for extensibility and modularity

### Testing Strategy
- Unit tests for all core functionality
- Integration tests for framework adapters
- Performance tests for critical paths
- End-to-end tests for complete workflows

This implementation plan provides a comprehensive roadmap for building a production-ready HTTP API library for Ruby that combines type safety, developer experience, and performance.

### 🎯 Goal
Create a Ruby library to **define HTTP endpoints declaratively**, **serve them**, **consume them**, and **generate OpenAPI documentation** – while ensuring type-safety, developer joy, and broad compatibility.

---

### ✅ Core Features
- ✅ **Endpoint DSL**: Declare endpoints using a readable and composable DSL.
- ✅ **Type-safe Inputs/Outputs**: Strong typing for parameters, headers, body, and response.
- ✅ **Server Adapter**: Pluggable support for Rack/Sinatra/Rails/etc.
- ✅ **Client Adapter**: Auto-generated client for declared endpoints.
- ✅ **OpenAPI Exporter**: Generate Swagger-compliant specs.
- ✅ **Observability Hooks**: Emit metrics and tracing events using metadata.
- ✅ **Composability**: Reuse common inputs, outputs, headers, and security schemes.
- ✅ **Minimal Dependencies**: Fast, lean, and stack-agnostic.

---

### 🛠️ Step-by-Step Implementation Plan

#### Phase 1 – Core DSL & Type System
- [ ] Define `Endpoint`, `Input`, `Output`, `Request`, and `Response` core types.
- [ ] Build a fluent, composable DSL for endpoint definition:
  ```ruby
  endpoint = RapiTapir.get("/hello")
    .in(query(:name, :string))
    .out(json_body(:message => :string))
  ```
- [ ] Add compile-time (or at least runtime) type-checking of endpoint specs.

#### Phase 2 – Server Integration
- [ ] Implement a Rack adapter that maps endpoint definitions to routes.
- [ ] Implement a Sinatra/Rails plug to automatically expose endpoints.
- [ ] Provide a generic handler system that separates route parsing and logic execution.

#### Phase 3 – Client Generation
- [ ] From an `Endpoint`, generate a callable HTTP client stub.
- [ ] Allow configuration of HTTP client backend (Faraday, HTTP.rb, etc.).

#### Phase 4 – OpenAPI Generator
- [ ] Traverse all defined `Endpoint`s to build an OpenAPI 3.1 spec.
- [ ] Support tags, descriptions, examples, and error codes.
- [ ] Generate and expose the YAML/JSON via a route.

#### Phase 5 – Observability & Metadata
- [ ] Collect execution metadata: latency, status code, parameters.
- [ ] Emit hooks for tracing (e.g., OpenTelemetry).
- [ ] Add instrumentation adapters (e.g., StatsD, Prometheus).

#### Phase 6 – Testing Utilities
- [ ] Provide test helpers to validate endpoints.
- [ ] Allow unit/integration tests to assert conformance to API.

---

### 🔄 Example
```ruby
endpoint = RapiTapir.post("/register")
  .in(json_body(:email => :string, :password => :string))
  .out(status_code(201), json_body(:user_id => :string))

# Expose as Sinatra route
RapiTapir.serve(endpoint) do |input|
  register_user(input[:email], input[:password])
end

# Use as HTTP client
response = RapiTapir.call(endpoint, { email: "hi@example.com", password: "secret" })
```

---

### 🤝 Target Compatibility
- Compatible with: **Rails, Sinatra, Roda, Hanami**
- HTTP Clients: **Faraday, Net::HTTP, HTTP.rb**
- JSON: **Oj, JSON, ActiveSupport::JSON**
- Tracing: **OpenTelemetry, NewRelic, Datadog**

---

### 📢 Naming Justification
- **RapiTapir** = **Rapid API** + homage to **Tapir**
- Suggests speed, elegance, and semantic richness

---

### 📚 Further Inspirations
- Scala Tapir
- Haskell Servant
- Elixir Phoenix Plug
- TypeScript tRPC

---

### 🚀 Future Ideas
- GraphQL API generation
- Codegen for clients (TypeScript/Ruby)
- Contracts-as-tests
- API versioning support

---

Want to contribute? Fork, star, and join the herd!

🦙 `rapitapir` – APIs so fast and clean, they practically run wild.