# RapiTapir Observability Guide

This guide covers the comprehensive observability features introduced in RapiTapir Phase 2.1, including metrics collection, distributed tracing, structured logging, and health checks.

## Table of Contents

- [Quick Start](#quick-start)
- [Configuration](#configuration)
- [Metrics](#metrics)
- [Distributed Tracing](#distributed-tracing)
- [Structured Logging](#structured-logging)
- [Health Checks](#health-checks)
- [Middleware Integration](#middleware-integration)
- [Examples](#examples)

## Quick Start

```ruby
require 'rapitapir'

# Configure observability
RapiTapir.configure do |config|
  # Enable Prometheus metrics
  config.metrics.enable_prometheus
  
  # Enable OpenTelemetry tracing
  config.tracing.enable_opentelemetry
  
  # Enable structured logging
  config.logging.enable_structured
  
  # Enable health checks
  config.health_check.enable
end

# Create an endpoint with observability
endpoint = RapiTapir.endpoint
  .get
  .in("/users")
  .out_json({ users: [{ id: :uuid, name: :string }] })
  .with_metrics("user_list")
  .with_tracing
  .with_logging(level: :info)
  .handle do |request|
    # Your endpoint logic here
    { users: [] }
  end
```

## Configuration

### Metrics Configuration

```ruby
RapiTapir.configure do |config|
  config.metrics.enable_prometheus(
    namespace: 'my_api',           # Metrics namespace (default: 'rapitapir')
    labels: {                      # Custom labels for all metrics
      service: 'user_service',
      version: '1.0.0',
      environment: 'production'
    }
  )
end
```

### Tracing Configuration

```ruby
RapiTapir.configure do |config|
  config.tracing.enable_opentelemetry(
    service_name: 'my-api-service',    # Service name for tracing
    service_version: '1.0.0'           # Service version
  )
end
```

### Logging Configuration

```ruby
RapiTapir.configure do |config|
  config.logging.enable_structured(
    level: :info,                      # Log level (:debug, :info, :warn, :error, :fatal)
    fields: [                          # Fields to include in structured logs
      :timestamp, :level, :message, :request_id,
      :method, :path, :status, :duration,
      :user_id, :tenant_id            # Custom fields
    ]
  )
end
```

### Health Check Configuration

```ruby
RapiTapir.configure do |config|
  config.health_check.enable(endpoint: '/health')
  
  # Add custom health checks
  config.health_check.add_check(:database) do
    # Database health check logic
    { status: :healthy, message: 'Database connection OK' }
  end
  
  config.health_check.add_check(:redis) do
    # Redis health check logic
    { status: :healthy, message: 'Redis connection OK' }
  end
end
```

## Metrics

RapiTapir automatically collects the following metrics:

### Default HTTP Metrics

- `{namespace}_http_requests_total` - Total number of HTTP requests
- `{namespace}_http_request_duration_seconds` - HTTP request duration histogram
- `{namespace}_http_errors_total` - Total number of HTTP errors
- `{namespace}_http_active_requests` - Number of active HTTP requests

### Custom Metrics

You can record custom metrics in your endpoint handlers:

```ruby
endpoint = RapiTapir.endpoint
  .post
  .in("/orders")
  .with_metrics("order_creation")
  .handle do |request|
    # Custom counter
    RapiTapir::Observability::Metrics.registry
      .counter(:custom_events_total, labels: [:event_type])
      .increment(labels: { event_type: 'order_created' })
    
    # Custom histogram
    duration = measure_time do
      # Some operation
    end
    
    RapiTapir::Observability::Metrics.registry
      .histogram(:operation_duration_seconds, labels: [:operation])
      .observe(duration, labels: { operation: 'order_processing' })
    
    # Your logic here
  end
```

### Accessing Metrics

Metrics are exposed at `/metrics` endpoint in Prometheus format:

```bash
curl http://localhost:9292/metrics
```

## Distributed Tracing

RapiTapir integrates with OpenTelemetry for distributed tracing:

### Automatic Tracing

Every HTTP request is automatically traced with:
- Span name: `HTTP {METHOD} {PATH}`
- HTTP method, URL, status code, duration
- Request and response size
- Error information if applicable

### Custom Tracing

Add custom spans and attributes in your endpoints:

```ruby
endpoint = RapiTapir.endpoint
  .post
  .in("/orders")
  .with_tracing("POST /orders")
  .handle do |request|
    # Add custom attributes to current span
    RapiTapir::Observability::Tracing.set_attribute('user.id', request.user_id)
    RapiTapir::Observability::Tracing.set_attribute('order.total', request.body[:total])
    
    # Create nested spans
    RapiTapir::Observability::Tracing.start_span("validate_order") do |span|
      span.set_attribute('validation.type', 'business_rules')
      validate_order(request.body)
    end
    
    RapiTapir::Observability::Tracing.start_span("process_payment") do |span|
      payment_result = process_payment(request.body[:payment])
      span.set_attribute('payment.provider', payment_result[:provider])
      span.set_attribute('payment.transaction_id', payment_result[:transaction_id])
    end
    
    # Add events to span
    RapiTapir::Observability::Tracing.add_event(
      'order.created',
      attributes: { 'order.id' => order_id }
    )
    
    # Record exceptions
    begin
      risky_operation()
    rescue => e
      RapiTapir::Observability::Tracing.record_exception(e)
      raise
    end
    
    # Your logic here
  end
```

## Structured Logging

RapiTapir provides comprehensive structured logging:

### Automatic Request Logging

Every HTTP request is automatically logged with:
- Request method, path, status code
- Request duration
- Request ID for correlation
- User agent, IP address
- Custom fields you configure

### Custom Logging

Add structured logging in your endpoints:

```ruby
endpoint = RapiTapir.endpoint
  .post
  .in("/users")
  .with_logging(level: :info, fields: [:user_id, :operation])
  .handle do |request|
    user_data = request.body
    
    # Structured info logging
    RapiTapir::Observability::Logging.info(
      "Creating user",
      user_email: user_data[:email],
      user_age: user_data[:age],
      operation: 'user_creation'
    )
    
    # Log with different levels
    RapiTapir::Observability::Logging.debug(
      "Validation passed",
      validation_time_ms: 5.2
    )
    
    RapiTapir::Observability::Logging.warn(
      "Slow database response",
      db_response_time_ms: 1200
    )
    
    # Log errors with context
    begin
      create_user(user_data)
    rescue => e
      RapiTapir::Observability::Logging.log_error(
        e,
        user_email: user_data[:email],
        operation: 'user_creation',
        request_id: request.id
      )
      raise
    end
    
    # Your logic here
  end
```

### Log Formats

Choose from multiple log formats:

```ruby
# JSON format (default for structured logging)
{"timestamp":"2024-01-01T12:00:00Z","level":"INFO","message":"User created","user_id":"123"}

# Logfmt format
timestamp=2024-01-01T12:00:00Z level=INFO message="User created" user_id=123

# Text format
2024-01-01 12:00:00 [INFO] User created user_id=123
```

## Health Checks

RapiTapir provides comprehensive health check functionality:

### Default Health Checks

- `ruby_runtime` - Ruby runtime status
- `memory_usage` - Memory and GC statistics
- `thread_count` - Active thread count

### Custom Health Checks

Add custom health checks for your dependencies:

```ruby
RapiTapir.configure do |config|
  config.health_check.enable
  
  # Database health check
  config.health_check.add_check(:database) do
    begin
      result = ActiveRecord::Base.connection.execute("SELECT 1")
      { status: :healthy, message: "Database connection OK" }
    rescue => e
      { status: :unhealthy, message: "Database error: #{e.message}" }
    end
  end
  
  # Redis health check with timeout
  config.health_check.add_check(:redis) do
    begin
      Timeout.timeout(5) do
        Redis.current.ping
        { status: :healthy, message: "Redis connection OK" }
      end
    rescue Timeout::Error
      { status: :unhealthy, message: "Redis timeout" }
    rescue => e
      { status: :unhealthy, message: "Redis error: #{e.message}" }
    end
  end
  
  # External API health check
  config.health_check.add_check(:payment_api) do
    begin
      response = HTTP.timeout(10).get("https://api.stripe.com/v1/charges")
      if response.status.success?
        { status: :healthy, message: "Payment API reachable" }
      else
        { status: :unhealthy, message: "Payment API returned #{response.status}" }
      end
    rescue => e
      { status: :unhealthy, message: "Payment API unreachable: #{e.message}" }
    end
  end
end
```

### Health Check Endpoints

Health checks are available at multiple endpoints:

```bash
# Overall health status
GET /health
{
  "status": "healthy",
  "timestamp": "2024-01-01T12:00:00Z",
  "service": "rapitapir",
  "version": "0.1.0",
  "checks": [
    {
      "name": "database",
      "status": "healthy",
      "message": "Database connection OK",
      "duration_ms": 2.5
    }
  ]
}

# Individual health check
GET /health/check?name=database
{
  "name": "database",
  "status": "healthy", 
  "message": "Database connection OK",
  "duration_ms": 2.5
}

# List available checks
GET /health/checks
{
  "available_checks": [
    {"name": "ruby_runtime", "url": "/health/check?name=ruby_runtime"},
    {"name": "database", "url": "/health/check?name=database"}
  ],
  "total": 2
}
```

## Middleware Integration

### Rack Applications

Use the observability middleware with any Rack application:

```ruby
require 'rack'
require 'rapitapir'

# Configure observability
RapiTapir.configure do |config|
  config.metrics.enable_prometheus
  config.tracing.enable_opentelemetry
  config.logging.enable_structured
  config.health_check.enable
end

# Build application with observability
app = Rack::Builder.new do
  # Add observability middleware (includes metrics, tracing, logging)
  use RapiTapir::Observability::RackMiddleware
  
  # Your application
  run MyApp.new
end

run app
```

### Sinatra Integration

```ruby
require 'sinatra'
require 'rapitapir'

# Configure observability
RapiTapir.configure do |config|
  config.metrics.enable_prometheus
  config.tracing.enable_opentelemetry
  config.logging.enable_structured
  config.health_check.enable
end

class MyApp < Sinatra::Base
  use RapiTapir::Observability::RackMiddleware
  
  get '/users' do
    # Your route logic
  end
end
```

### Rails Integration

```ruby
# config/application.rb
require 'rapitapir'

class Application < Rails::Application
  # Configure observability
  config.before_configuration do
    RapiTapir.configure do |config|
      config.metrics.enable_prometheus(
        namespace: 'rails_app',
        labels: { environment: Rails.env }
      )
      config.tracing.enable_opentelemetry(
        service_name: 'my-rails-app',
        service_version: MyApp::VERSION
      )
      config.logging.enable_structured(level: :info)
      config.health_check.enable
    end
  end
  
  # Add observability middleware
  config.middleware.use RapiTapir::Observability::RackMiddleware
end
```

## Examples

### Basic E-commerce API

```ruby
require 'rapitapir'

# Configure observability
RapiTapir.configure do |config|
  config.metrics.enable_prometheus(namespace: 'ecommerce')
  config.tracing.enable_opentelemetry(service_name: 'ecommerce-api')
  config.logging.enable_structured
  config.health_check.enable
end

# Create order endpoint
create_order = RapiTapir.endpoint
  .post
  .in("/orders")
  .json_body({
    customer_id: :uuid,
    items: [{ product_id: :uuid, quantity: :integer, price: :float }]
  })
  .out_json({ id: :uuid, status: :string, total: :float })
  .with_metrics("order_creation")
  .with_tracing
  .with_logging(fields: [:customer_id, :order_total, :item_count])
  .handle do |request|
    order_data = request.body
    
    # Add business context to tracing
    RapiTapir::Observability::Tracing.set_attribute('customer.id', order_data[:customer_id])
    RapiTapir::Observability::Tracing.set_attribute('order.item_count', order_data[:items].length)
    
    total = order_data[:items].sum { |item| item[:quantity] * item[:price] }
    RapiTapir::Observability::Tracing.set_attribute('order.total', total)
    
    # Structured logging
    RapiTapir::Observability::Logging.info(
      "Processing order",
      customer_id: order_data[:customer_id],
      order_total: total,
      item_count: order_data[:items].length
    )
    
    # Process order with nested tracing
    order_id = RapiTapir::Observability::Tracing.start_span("create_order_record") do
      SecureRandom.uuid
    end
    
    RapiTapir::Observability::Tracing.start_span("send_confirmation_email") do |span|
      span.set_attribute('email.type', 'order_confirmation')
      # Send confirmation email
    end
    
    {
      id: order_id,
      status: 'confirmed',
      total: total
    }
  end
```

### Advanced Monitoring Setup

```ruby
# Production observability configuration
RapiTapir.configure do |config|
  # Comprehensive metrics
  config.metrics.enable_prometheus(
    namespace: 'production_api',
    labels: {
      service: ENV['SERVICE_NAME'],
      version: ENV['APP_VERSION'],
      environment: ENV['RAILS_ENV'],
      datacenter: ENV['DATACENTER']
    }
  )
  
  # Distributed tracing
  config.tracing.enable_opentelemetry(
    service_name: ENV['SERVICE_NAME'],
    service_version: ENV['APP_VERSION']
  )
  
  # Structured logging for log aggregation
  config.logging.enable_structured(
    level: ENV.fetch('LOG_LEVEL', 'info').to_sym,
    fields: [
      :timestamp, :level, :message, :request_id, :trace_id,
      :method, :path, :status, :duration,
      :user_id, :tenant_id, :session_id,
      :source_ip, :user_agent
    ]
  )
  
  # Comprehensive health checks
  config.health_check.enable(endpoint: '/health')
  
  # Database health check
  config.health_check.add_check(:database) do
    ActiveRecord::Base.connection.execute("SELECT 1")
    { status: :healthy, message: "Primary database OK" }
  rescue => e
    { status: :unhealthy, message: "Database error: #{e.message}" }
  end
  
  # Redis health check
  config.health_check.add_check(:redis) do
    Redis.current.ping
    { status: :healthy, message: "Redis cache OK" }
  rescue => e
    { status: :unhealthy, message: "Redis error: #{e.message}" }
  end
  
  # Message queue health check
  config.health_check.add_check(:message_queue) do
    # Check Sidekiq or similar
    if defined?(Sidekiq)
      stats = Sidekiq::Stats.new
      queue_size = stats.enqueued
      
      if queue_size > 10000
        { status: :warning, message: "High queue size: #{queue_size}" }
      else
        { status: :healthy, message: "Queue size: #{queue_size}" }
      end
    else
      { status: :healthy, message: "No message queue configured" }
    end
  rescue => e
    { status: :unhealthy, message: "Queue error: #{e.message}" }
  end
end
```

## Best Practices

### 1. Metric Naming

Use consistent metric naming:
- Use underscores for separating words
- Include units in metric names (e.g., `_seconds`, `_bytes`)
- Use clear, descriptive names

### 2. Trace Context

Add meaningful attributes to traces:
- Business identifiers (user_id, order_id, etc.)
- Request context (tenant_id, api_version)
- Performance indicators (cache_hit, db_query_count)

### 3. Structured Logging

Design your log structure:
- Use consistent field names across services
- Include correlation IDs for request tracing
- Log at appropriate levels (debug for development, info+ for production)

### 4. Health Check Design

Create meaningful health checks:
- Test actual functionality, not just connectivity
- Include response time thresholds
- Use timeouts to prevent hanging checks
- Return actionable status messages

### 5. Error Handling

Implement comprehensive error observability:
- Always record exceptions in traces
- Log errors with sufficient context
- Use error metrics to track error rates
- Include error classification (validation, system, external)

This observability implementation provides production-ready monitoring capabilities for RapiTapir applications, enabling comprehensive visibility into system performance, health, and behavior.
