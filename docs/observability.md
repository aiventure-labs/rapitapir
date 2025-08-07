# RapiTapir Observability Guide

This comprehensive guide covers RapiTapir's observability features including metrics collection, distributed tracing, structured logging, and health checks for production-ready APIs.

## Table of Contents

- [Overview](#overview)
- [Quick Start](#quick-start)
- [Configuration](#configuration)
- [Metrics](#metrics)
- [Distributed Tracing](#distributed-tracing)
- [Structured Logging](#structured-logging)
- [Health Checks](#health-checks)
- [Integration Examples](#integration-examples)
- [Production Setup](#production-setup)

## Overview

RapiTapir provides comprehensive observability features out of the box:

- **Metrics**: Prometheus-compatible metrics with custom labels and dashboards
- **Tracing**: OpenTelemetry distributed tracing with automatic instrumentation
- **Logging**: Structured JSON logging with request correlation
- **Health Checks**: Built-in health monitoring with custom checks
- **Performance Monitoring**: Request duration, throughput, and error rate tracking

## Quick Start

```ruby
class ObservableAPI < SinatraRapiTapir
  rapitapir do
    info(title: 'Observable API', version: '1.0.0')
    
    # Enable observability features
    enable_metrics(
      provider: :prometheus,
      namespace: 'my_api',
      labels: { service: 'user_service', environment: 'production' }
    )
    
    enable_tracing(
      provider: :opentelemetry,
      service_name: 'user-api',
      service_version: '1.0.0'
    )
    
    enable_structured_logging(
      level: :info,
      include_request_body: false,
      include_response_body: false
    )
    
    enable_health_checks(endpoint: '/health')
    
    production_defaults!
  end

  # Basic endpoint with automatic observability
  endpoint(
    GET('/users')
      .summary('List users with observability')
      .query(:limit, T.optional(T.integer(minimum: 1, maximum: 100)), description: 'Page size')
      .tags('Users', 'Observability')
      .ok(T.hash({
        "users" => T.array(T.hash({
          "id" => T.uuid,
          "name" => T.string,
          "email" => T.email,
          "created_at" => T.datetime
        })),
        "total" => T.integer,
        "page_info" => T.hash({
          "limit" => T.integer,
          "has_next" => T.boolean
        })
      }))
      .build
  ) do |inputs|
    # Automatic metrics and tracing are enabled
    users = User.limit(inputs[:limit] || 50)
    
    {
      users: users.map(&:to_h),
      total: User.count,
      page_info: {
        limit: inputs[:limit] || 50,
        has_next: users.length == (inputs[:limit] || 50)
      }
    }
  end

  # Enhanced endpoint with custom observability
  endpoint(
    POST('/orders')
      .summary('Create order with enhanced observability')
      .body(T.hash({
        "user_id" => T.uuid,
        "items" => T.array(T.hash({
          "product_id" => T.uuid,
          "quantity" => T.integer(minimum: 1),
          "price" => T.float(minimum: 0)
        })),
        "payment_method" => T.string(enum: %w[card paypal bank_transfer])
      }))
      .tags('Orders', 'Observability')
      .created(T.hash({
        "id" => T.uuid,
        "status" => T.string,
        "total" => T.float,
        "created_at" => T.datetime
      }))
      .with_metrics('order_creation', labels: { operation: 'create' })
      .with_tracing('create_order')
      .with_structured_logging(
        include_fields: %w[user_id total payment_method],
        exclude_fields: %w[payment_details]
      )
      .build
  ) do |inputs|
    order_data = inputs[:body]
    
    # Add custom metrics
    increment_counter('orders_attempted_total', labels: { 
      payment_method: order_data['payment_method']
    })
    
    # Add tracing attributes
    set_trace_attributes({
      'order.user_id' => order_data['user_id'],
      'order.item_count' => order_data['items'].length,
      'order.payment_method' => order_data['payment_method']
    })
    
    # Create nested spans for different operations
    user = trace_span('fetch_user') do |span|
      span.set_attribute('user.id', order_data['user_id'])
      User.find(order_data['user_id'])
    end
    
    total = trace_span('calculate_total') do |span|
      calculated_total = order_data['items'].sum { |item| 
        item['quantity'] * item['price'] 
      }
      span.set_attribute('order.calculated_total', calculated_total)
      calculated_total
    end
    
    order = trace_span('process_payment') do |span|
      span.set_attribute('payment.method', order_data['payment_method'])
      span.set_attribute('payment.amount', total)
      
      payment_result = PaymentService.process(
        amount: total,
        method: order_data['payment_method'],
        user: user
      )
      
      span.set_attribute('payment.transaction_id', payment_result[:transaction_id])
      span.add_event('payment_processed', {
        'payment.status' => payment_result[:status],
        'payment.provider' => payment_result[:provider]
      })
      
      Order.create!(
        user: user,
        items: order_data['items'],
        total: total,
        payment_transaction_id: payment_result[:transaction_id]
      )
    end
    
    # Record custom metrics
    histogram('order_total_amount', total, labels: { 
      payment_method: order_data['payment_method']
    })
    
    # Log structured data
    log_info('Order created successfully', {
      order_id: order.id,
      user_id: user.id,
      total: total,
      payment_method: order_data['payment_method']
    })
    
    status 201
    order.to_h
  end
end
```

## Configuration

### Global Configuration

```ruby
class MyAPI < SinatraRapiTapir
  rapitapir do
    # Comprehensive observability setup
    enable_observability do |obs|
      # Metrics configuration
      obs.metrics do |metrics|
        metrics.provider = :prometheus
        metrics.namespace = 'myapi'
        metrics.endpoint = '/metrics'
        metrics.labels = {
          service: 'user-service',
          version: '2.0.0',
          environment: ENV['RACK_ENV'] || 'development'
        }
        metrics.include_default_metrics = true
        metrics.include_request_metrics = true
        metrics.include_response_metrics = true
      end
      
      # Tracing configuration
      obs.tracing do |tracing|
        tracing.provider = :opentelemetry
        tracing.service_name = 'user-api'
        tracing.service_version = '2.0.0'
        tracing.environment = ENV['RACK_ENV']
        tracing.sample_rate = ENV['RACK_ENV'] == 'production' ? 0.1 : 1.0
        tracing.include_request_attributes = true
        tracing.include_response_attributes = true
        tracing.include_database_spans = true
      end
      
      # Logging configuration
      obs.logging do |logging|
        logging.level = ENV['LOG_LEVEL'] || 'info'
        logging.format = :json
        logging.include_request_id = true
        logging.include_user_id = true
        logging.include_trace_id = true
        logging.exclude_paths = ['/health', '/metrics']
        logging.sanitize_headers = %w[authorization x-api-key]
        logging.max_body_size = 1024
      end
      
      # Health checks configuration
      obs.health_checks do |health|
        health.endpoint = '/health'
        health.detailed_endpoint = '/health/detailed'
        health.include_system_info = true
        health.include_dependency_checks = true
      end
    end
  end
end
```

### Environment-Specific Configuration

```ruby
class ProductionAPI < SinatraRapiTapir
  rapitapir do
    case ENV['RACK_ENV']
    when 'production'
      enable_observability do |obs|
        obs.metrics.sample_rate = 1.0
        obs.tracing.sample_rate = 0.1  # Sample 10% in production
        obs.logging.level = 'warn'
        obs.logging.include_request_body = false
        obs.logging.include_response_body = false
      end
      
    when 'staging'
      enable_observability do |obs|
        obs.metrics.sample_rate = 1.0
        obs.tracing.sample_rate = 0.5  # Sample 50% in staging
        obs.logging.level = 'info'
        obs.logging.include_request_body = true
        obs.logging.include_response_body = false
      end
      
    when 'development'
      enable_observability do |obs|
        obs.metrics.sample_rate = 1.0
        obs.tracing.sample_rate = 1.0  # Sample 100% in development
        obs.logging.level = 'debug'
        obs.logging.include_request_body = true
        obs.logging.include_response_body = true
      end
    end
  end
end
```

## Metrics

### Built-in Metrics

RapiTapir automatically collects these metrics:

- `http_requests_total` - Total HTTP requests by method, path, status
- `http_request_duration_seconds` - Request duration histogram
- `http_request_size_bytes` - Request size histogram
- `http_response_size_bytes` - Response size histogram
- `rapitapir_endpoints_total` - Total defined endpoints
- `rapitapir_validations_total` - Total validation operations
- `rapitapir_validation_errors_total` - Total validation errors

### Custom Metrics in Endpoints

```ruby
endpoint(
  GET('/analytics/dashboard')
    .summary('Analytics dashboard with custom metrics')
    .query(:timeframe, T.string(enum: %w[hour day week month]), description: 'Analytics timeframe')
    .tags('Analytics')
    .ok(T.hash({
      "metrics" => T.hash({}),
      "generated_at" => T.datetime
    }))
    .build
) do |inputs|
  timeframe = inputs[:timeframe] || 'day'
  
  # Increment custom counters
  increment_counter('dashboard_views_total', labels: { 
    timeframe: timeframe,
    user_id: current_user&.id || 'anonymous'
  })
  
  # Record custom gauge
  set_gauge('active_users_count', User.active.count)
  
  # Record histogram
  analytics_data = measure_histogram('analytics_query_duration', 
    labels: { timeframe: timeframe }
  ) do
    AnalyticsService.get_dashboard_data(timeframe: timeframe)
  end
  
  # Record summary
  record_summary('dashboard_data_points', analytics_data[:data_points].count)
  
  {
    metrics: analytics_data,
    generated_at: Time.now
  }
end
```

### Accessing Metrics

Metrics are automatically exposed at `/metrics` endpoint:

```bash
# Get all metrics
curl http://localhost:4567/metrics

# Example output:
# http_requests_total{method="GET",path="/users",status="200"} 42
# http_request_duration_seconds_bucket{method="GET",path="/users",le="0.1"} 38
# http_request_duration_seconds_bucket{method="GET",path="/users",le="0.5"} 42
# dashboard_views_total{timeframe="day",user_id="123"} 15
```

## Distributed Tracing

### Automatic Tracing

Every request gets automatic tracing with:

- Span name: `HTTP {METHOD} {path_template}`
- Automatic attributes: method, URL, status, duration, user agent
- Request/response size tracking
- Error tracking with stack traces

### Custom Tracing in Endpoints

```ruby
endpoint(
  POST('/orders/:id/process')
    .path_param(:id, T.uuid, description: 'Order ID')
    .body(T.hash({
      "processing_options" => T.hash({
        "priority" => T.string(enum: %w[low normal high urgent]),
        "async" => T.boolean
      })
    }))
    .tags('Orders')
    .ok(T.hash({
      "order_id" => T.uuid,
      "status" => T.string,
      "processing_time_ms" => T.float
    }))
    .build
) do |inputs|
  order_id = inputs[:id]
  options = inputs[:body]['processing_options']
  start_time = Time.now
  
  # Set span attributes
  set_trace_attributes({
    'order.id' => order_id,
    'order.priority' => options['priority'],
    'order.async' => options['async']
  })
  
  # Create nested spans
  order = trace_span('fetch_order', attributes: { 'order.id' => order_id }) do |span|
    order = Order.find(order_id)
    span.set_attribute('order.status', order.status)
    span.set_attribute('order.total', order.total)
    order
  end
  
  validation_result = trace_span('validate_processing') do |span|
    result = OrderValidator.can_process?(order, options)
    span.set_attribute('validation.result', result[:valid])
    span.set_attribute('validation.errors', result[:errors].join(', ')) if result[:errors]
    
    unless result[:valid]
      span.record_exception(ValidationError.new(result[:errors].join(', ')))
      span.set_status(:error, 'Validation failed')
    end
    
    result
  end
  
  halt 422, { error: 'Validation failed', details: validation_result[:errors] }.to_json unless validation_result[:valid]
  
  processed_order = trace_span('process_order') do |span|
    span.set_attribute('processing.priority', options['priority'])
    span.set_attribute('processing.async', options['async'])
    
    if options['async']
      # Enqueue background job
      job_id = OrderProcessingJob.perform_async(order_id, options)
      span.set_attribute('job.id', job_id)
      span.add_event('job_enqueued', { 'job.id' => job_id })
      
      order.update!(status: 'processing', processing_job_id: job_id)
    else
      # Process synchronously
      OrderProcessor.process!(order, options)
      order.reload
    end
    
    span.set_attribute('order.new_status', order.status)
    order
  end
  
  processing_time = ((Time.now - start_time) * 1000).round(2)
  
  # Add final event
  add_trace_event('order_processing_completed', {
    'order.id' => order_id,
    'processing.duration_ms' => processing_time,
    'processing.mode' => options['async'] ? 'async' : 'sync'
  })
  
  {
    order_id: order_id,
    status: processed_order.status,
    processing_time_ms: processing_time
  }
end
```

### Cross-Service Tracing

```ruby
endpoint(
  GET('/users/:id/recommendations')
    .path_param(:id, T.uuid, description: 'User ID')
    .query(:category, T.optional(T.string), description: 'Recommendation category')
    .tags('Users', 'Recommendations')
    .ok(T.hash({
      "recommendations" => T.array(T.hash({
        "id" => T.uuid,
        "title" => T.string,
        "score" => T.float
      }))
    }))
    .build
) do |inputs|
  user_id = inputs[:id]
  
  # External service call with tracing
  recommendations = trace_span('fetch_recommendations') do |span|
    span.set_attribute('user.id', user_id)
    span.set_attribute('service.name', 'recommendation-service')
    
    # Propagate trace context to external service
    headers = {
      'Content-Type' => 'application/json',
      'X-Trace-Id' => current_trace_id,
      'X-Span-Id' => current_span_id
    }
    
    begin
      response = HTTP.timeout(5)
                     .headers(headers)
                     .get("#{ENV['RECOMMENDATION_SERVICE_URL']}/users/#{user_id}/recommendations")
      
      span.set_attribute('http.status_code', response.status)
      span.set_attribute('http.response_size', response.body.bytesize)
      
      if response.status.success?
        recommendations = JSON.parse(response.body)
        span.set_attribute('recommendations.count', recommendations.length)
        recommendations
      else
        span.set_status(:error, "HTTP #{response.status}")
        span.record_exception(StandardError.new("Recommendation service error: #{response.status}"))
        []
      end
      
    rescue => e
      span.record_exception(e)
      span.set_status(:error, e.message)
      []
    end
  end
  
  { recommendations: recommendations }
end
```

## Structured Logging

### Automatic Request Logging

Every request automatically logs:

```json
{
  "timestamp": "2024-01-15T10:30:45.123Z",
  "level": "info",
  "message": "HTTP Request",
  "request_id": "req_1234567890abcdef",
  "trace_id": "trace_abcdef1234567890",
  "span_id": "span_fedcba0987654321",
  "method": "POST",
  "path": "/users",
  "user_agent": "curl/7.68.0",
  "remote_ip": "192.168.1.100",
  "status": 201,
  "duration_ms": 234.56,
  "request_size_bytes": 156,
  "response_size_bytes": 89
}
```

### Custom Logging in Endpoints

```ruby
endpoint(
  PUT('/users/:id/profile')
    .path_param(:id, T.uuid, description: 'User ID')
    .body(T.hash({
      "name" => T.optional(T.string),
      "bio" => T.optional(T.string),
      "preferences" => T.optional(T.hash({}))
    }))
    .tags('Users')
    .ok(T.hash({
      "id" => T.uuid,
      "name" => T.string,
      "updated_at" => T.datetime
    }))
    .build
) do |inputs|
  user_id = inputs[:id]
  updates = inputs[:body]
  
  # Structured info logging
  log_info('Profile update started', {
    user_id: user_id,
    fields_to_update: updates.keys,
    request_size: updates.to_json.bytesize
  })
  
  begin
    user = User.find(user_id)
    
    # Log user context
    log_debug('User found', {
      user_id: user.id,
      user_email: user.email,
      last_updated: user.updated_at
    })
    
    # Validate and apply updates
    original_values = {}
    updates.each do |field, value|
      original_values[field] = user.send(field)
      user.send("#{field}=", value)
    end
    
    if user.valid?
      user.save!
      
      # Log successful update
      log_info('Profile updated successfully', {
        user_id: user_id,
        updated_fields: updates.keys,
        original_values: original_values,
        new_values: updates
      })
      
      user.to_h
    else
      # Log validation errors
      log_warn('Profile update validation failed', {
        user_id: user_id,
        validation_errors: user.errors.full_messages,
        attempted_updates: updates
      })
      
      halt 422, {
        error: 'Validation failed',
        details: user.errors.full_messages
      }.to_json
    end
    
  rescue ActiveRecord::RecordNotFound => e
    log_warn('User not found for profile update', {
      user_id: user_id,
      error: e.message
    })
    
    halt 404, { error: 'User not found' }.to_json
    
  rescue => e
    log_error('Profile update failed', {
      user_id: user_id,
      error_class: e.class.name,
      error_message: e.message,
      backtrace: e.backtrace.first(10)
    })
    
    halt 500, { error: 'Internal server error' }.to_json
  end
end
```

### Correlation IDs

Request correlation is automatically handled:

```ruby
# Access correlation IDs in endpoints
endpoint(
  GET('/debug/request-info')
    .summary('Get current request debugging info')
    .tags('Debug')
    .ok(T.hash({
      "request_id" => T.string,
      "trace_id" => T.string,
      "span_id" => T.string,
      "user_id" => T.optional(T.string)
    }))
    .build
) do |inputs|
  {
    request_id: current_request_id,
    trace_id: current_trace_id,
    span_id: current_span_id,
    user_id: current_user&.id
  }
end
```

## Health Checks

### Built-in Health Checks

```ruby
class HealthyAPI < SinatraRapiTapir
  rapitapir do
    enable_health_checks do |health|
      health.endpoint = '/health'
      health.detailed_endpoint = '/health/detailed'
      
      # Add custom health checks
      health.add_check(:database) do
        begin
          ActiveRecord::Base.connection.execute('SELECT 1')
          { status: :healthy, message: 'Database connection OK' }
        rescue => e
          { status: :unhealthy, message: "Database error: #{e.message}" }
        end
      end
      
      health.add_check(:redis) do
        begin
          Redis.current.ping
          { status: :healthy, message: 'Redis connection OK' }
        rescue => e
          { status: :unhealthy, message: "Redis error: #{e.message}" }
        end
      end
      
      health.add_check(:external_api) do
        begin
          response = HTTP.timeout(5).get("#{ENV['EXTERNAL_API_URL']}/health")
          if response.status.success?
            { status: :healthy, message: 'External API responding' }
          else
            { status: :unhealthy, message: "External API returned #{response.status}" }
          end
        rescue => e
          { status: :unhealthy, message: "External API error: #{e.message}" }
        end
      end
    end
  end
end
```

Health check endpoints respond with:

```bash
# Basic health check
curl http://localhost:4567/health
# Response: {"status":"healthy","timestamp":"2024-01-15T10:30:45Z"}

# Detailed health check
curl http://localhost:4567/health/detailed
```

```json
{
  "status": "healthy",
  "timestamp": "2024-01-15T10:30:45Z",
  "checks": {
    "database": {
      "status": "healthy",
      "message": "Database connection OK",
      "duration_ms": 12.34
    },
    "redis": {
      "status": "healthy", 
      "message": "Redis connection OK",
      "duration_ms": 5.67
    },
    "external_api": {
      "status": "unhealthy",
      "message": "External API error: Connection timeout",
      "duration_ms": 5000.0
    }
  },
  "system": {
    "uptime_seconds": 86400,
    "memory_usage_mb": 125.6,
    "load_average": [0.1, 0.2, 0.15]
  }
}
```

## Integration Examples

### Kubernetes Integration

```ruby
class KubernetesAPI < SinatraRapiTapir
  rapitapir do
    enable_observability do |obs|
      # Kubernetes-friendly configuration
      obs.metrics.endpoint = '/metrics'
      obs.health_checks.endpoint = '/health'
      obs.health_checks.readiness_endpoint = '/ready'
      obs.health_checks.liveness_endpoint = '/live'
      
      obs.logging.format = :json
      obs.logging.include_kubernetes_metadata = true
    end
  end
end
```

### Honeycomb Integration

```ruby
class HoneycombAPI < SinatraRapiTapir
  rapitapir do
    enable_tracing do |tracing|
      tracing.provider = :opentelemetry
      tracing.exporter = :honeycomb
      tracing.honeycomb_api_key = ENV['HONEYCOMB_API_KEY']
      tracing.honeycomb_dataset = 'user-api'
      tracing.sample_rate = 0.1
    end
  end
end
```

### DataDog Integration

```ruby
class DataDogAPI < SinatraRapiTapir
  rapitapir do
    enable_observability do |obs|
      obs.metrics do |metrics|
        metrics.provider = :datadog
        metrics.datadog_api_key = ENV['DATADOG_API_KEY']
        metrics.tags = {
          env: ENV['RACK_ENV'],
          service: 'user-api',
          version: ENV['APP_VERSION']
        }
      end
      
      obs.tracing do |tracing|
        tracing.provider = :datadog
        tracing.service_name = 'user-api'
        tracing.environment = ENV['RACK_ENV']
      end
    end
  end
end
```

## Production Setup

### Docker Configuration

```dockerfile
# Dockerfile
FROM ruby:3.2-alpine

# Install dependencies
RUN apk add --no-cache build-base

WORKDIR /app
COPY Gemfile* ./
RUN bundle install

COPY . .

# Expose metrics and health check ports
EXPOSE 4567 9090

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:4567/health || exit 1

CMD ["bundle", "exec", "ruby", "app.rb"]
```

### Docker Compose with Observability Stack

```yaml
# docker-compose.yml
version: '3.8'

services:
  api:
    build: .
    ports:
      - "4567:4567"
    environment:
      - RACK_ENV=production
      - JAEGER_ENDPOINT=http://jaeger:14268/api/traces
      - PROMETHEUS_PUSHGATEWAY=prometheus-pushgateway:9091
    depends_on:
      - jaeger
      - prometheus

  prometheus:
    image: prom/prometheus:latest
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'

  jaeger:
    image: jaegertracing/all-in-one:latest
    ports:
      - "16686:16686"
      - "14268:14268"
    environment:
      - COLLECTOR_OTLP_ENABLED=true

  grafana:
    image: grafana/grafana:latest
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
    volumes:
      - grafana-data:/var/lib/grafana

volumes:
  grafana-data:
```

### Prometheus Configuration

```yaml
# prometheus.yml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'rapitapir-api'
    static_configs:
      - targets: ['api:4567']
    metrics_path: '/metrics'
    scrape_interval: 5s

  - job_name: 'node-exporter'
    static_configs:
      - targets: ['node-exporter:9100']
```

### Grafana Dashboard

```json
{
  "dashboard": {
    "title": "RapiTapir API Metrics",
    "panels": [
      {
        "title": "Request Rate",
        "type": "graph",
        "targets": [
          {
            "expr": "rate(http_requests_total[5m])",
            "legendFormat": "{{method}} {{path}}"
          }
        ]
      },
      {
        "title": "Response Time",
        "type": "graph", 
        "targets": [
          {
            "expr": "histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))",
            "legendFormat": "95th percentile"
          }
        ]
      },
      {
        "title": "Error Rate",
        "type": "graph",
        "targets": [
          {
            "expr": "rate(http_requests_total{status=~\"5..\"}[5m])",
            "legendFormat": "5xx errors"
          }
        ]
      }
    ]
  }
}
```

---

This guide provides comprehensive coverage of RapiTapir's observability features. For more examples, see the [observability examples](../examples/observability/) and the [production setup guide](../examples/production_ready_example.rb).
