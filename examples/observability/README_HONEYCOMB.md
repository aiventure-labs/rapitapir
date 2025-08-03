# 🍯 RapiTapir Honeycomb.io Observability Example

This example demonstrates how to integrate **RapiTapir** with **Honeycomb.io** using **OpenTelemetry** for comprehensive observability, including distributed tracing, custom spans, baggage propagation, and business metrics.

## 🚀 Features Demonstrated

- **OpenTelemetry Integration**: Full SDK setup with Honeycomb.io OTLP exporter
- **Automatic Instrumentation**: Sinatra, Rack, HTTP, and JSON instrumentation
- **Custom Spans**: Business logic tracing with detailed attributes
- **Baggage Propagation**: Context sharing across spans
- **Error Handling**: Comprehensive error tracing and status reporting
- **Health Checks**: Traced health check endpoints
- **Business Analytics**: Custom spans for complex operations
- **Performance Monitoring**: Request timing and resource usage

## 📋 Prerequisites

1. **Ruby 3.2+** installed
2. **Honeycomb.io account** (free account available at [honeycomb.io](https://ui.honeycomb.io/signup))
3. **Honeycomb API Key** with "Can create datasets" permission

## 🔧 Setup Instructions

### 1. Install Dependencies

First, install the required OpenTelemetry gems. The main Gemfile already includes them:

```bash
bundle install
```

### 2. Get Your Honeycomb API Key

1. Sign up for a free Honeycomb account at [honeycomb.io](https://ui.honeycomb.io/signup)
2. Go to **Environment Settings** → **API Keys**
3. Create a new API key with **"Can create datasets"** checked
4. Copy your API key (you won't be able to see it again!)

### 3. Configure Environment Variables

Copy the example environment file and update it with your API key:

```bash
cd examples/observability
cp .env.example .env
```

Edit `.env` and replace `your-honeycomb-api-key-here` with your actual API key:

```bash
# Required: Your Honeycomb API key
OTEL_EXPORTER_OTLP_HEADERS=x-honeycomb-team=YOUR_ACTUAL_API_KEY_HERE

# Honeycomb endpoint (US instance)
OTEL_EXPORTER_OTLP_ENDPOINT=https://api.honeycomb.io

# Service configuration
OTEL_SERVICE_NAME=rapitapir-demo
OTEL_SERVICE_VERSION=1.0.0
```

For EU instance users, use:
```bash
OTEL_EXPORTER_OTLP_ENDPOINT=https://api.eu1.honeycomb.io
```

### 4. Load Environment Variables

```bash
# Install dotenv if not already installed
gem install dotenv

# Load the environment
source .env
# Or use dotenv if you prefer
dotenv -f .env
```

## 🏃‍♂️ Running the Demo

### Start the Server

```bash
cd examples/observability
ruby honeycomb_example.rb
```

The server will start on `http://localhost:4567` and display:

```
🍯 Starting RapiTapir Demo API with Honeycomb.io Observability
📊 Traces will be sent to: https://api.honeycomb.io
🔧 Service Name: rapitapir-demo

🚀 Available endpoints:
   GET    /health                   - Health check
   GET    /users                    - List users
   POST   /users                    - Create user
   GET    /users/:id                - Get user by ID
   PUT    /users/:id                - Update user
   DELETE /users/:id                - Delete user
   GET    /analytics/department-stats - Department analytics
```

### Test the API

Generate some traces by making requests:

```bash
# Health check
curl http://localhost:4567/health

# Create users
curl -X POST http://localhost:4567/users \
  -H 'Content-Type: application/json' \
  -d '{
    "name": "Alice Engineer",
    "email": "alice@example.com",
    "age": 28,
    "department": "engineering"
  }'

curl -X POST http://localhost:4567/users \
  -H 'Content-Type: application/json' \
  -d '{
    "name": "Bob Sales",
    "email": "bob@example.com", 
    "age": 32,
    "department": "sales"
  }'

# List users with filtering and pagination
curl "http://localhost:4567/users"
curl "http://localhost:4567/users?department=engineering&page=1&limit=5"

# Get analytics (complex operation with multiple spans)
curl http://localhost:4567/analytics/department-stats

# Test error handling
curl -X POST http://localhost:4567/users \
  -H 'Content-Type: application/json' \
  -d '{"invalid": "data"}'
```

## 📊 Viewing Data in Honeycomb

1. Go to [Honeycomb.io](https://ui.honeycomb.io/) and log in
2. You should see a new dataset called **"rapitapir-demo"** (or whatever you set as `OTEL_SERVICE_NAME`)
3. Click on the dataset to start exploring your traces

### Key Honeycomb Features to Explore

#### 1. **Traces View**
- See complete request flows from HTTP request to business logic
- Identify performance bottlenecks and slow operations
- Visualize parent-child span relationships

#### 2. **Useful Queries to Try**

```sql
-- Find slow requests
WHERE duration_ms > 100

-- Find errors by type
WHERE error.type EXISTS

-- Analyze by department
GROUP BY user.department

-- Find database operations
WHERE db.operation EXISTS

-- Look at business operations
WHERE business.operation = "create_user"

-- Health check performance
WHERE business.operation = "health_check"
```

#### 3. **Custom Attributes Added**

The example adds rich context to spans:

**HTTP Attributes:**
- `http.method`, `http.url`, `http.status_code`
- `http.user_agent`, `http.response_size`

**Business Attributes:**
- `business.operation` (create_user, list_users, etc.)
- `business.entity` (user, analytics)
- `user.id`, `user.department`

**Database Simulation:**
- `db.operation` (SELECT, INSERT, UPDATE, DELETE)
- `db.table` (users)
- Query timing and performance

**Custom Metrics:**
- `duration_ms` - Request/operation timing
- `result.count` - Number of items returned
- `pagination.*` - Pagination metadata

#### 4. **Baggage Propagation**

The example demonstrates OpenTelemetry baggage:
- `request.id` - Unique identifier for each request
- `service.name` - Service context
- `user.created` - Business event flags

## 🔧 Advanced Configuration

### Sampling for Production

For high-traffic production environments, enable sampling:

```bash
# Keep 10% of traces (1/10)
OTEL_TRACES_SAMPLER=traceidratio
OTEL_TRACES_SAMPLER_ARG=0.1
OTEL_RESOURCE_ATTRIBUTES=SampleRate=10
```

### Custom Span Processors

The example includes custom span processors:

```ruby
# Add baggage to all spans
config.add_span_processor(OpenTelemetry::Processor::Baggage::BaggageSpanProcessor.new)

# Batch export to Honeycomb
config.add_span_processor(
  OpenTelemetry::SDK::Trace::Export::BatchSpanProcessor.new(
    OpenTelemetry::Exporter::OTLP::Exporter.new
  )
)
```

### Error Handling

Comprehensive error tracking:

```ruby
rescue StandardError => e
  span.set_attribute('error.type', e.class.name)
  span.set_attribute('error.message', e.message)
  span.status = OpenTelemetry::Trace::Status.error(e.message)
end
```

## 🏗️ Architecture

The example demonstrates a layered observability approach:

```
┌─────────────────────────────────────┐
│ HTTP Request (Automatic Instrumentation) │
├─────────────────────────────────────┤
│ Sinatra Route Handler               │
├─────────────────────────────────────┤
│ Business Logic Spans               │
├─────────────────────────────────────┤
│ Database/External Service Simulation│
├─────────────────────────────────────┤
│ Honeycomb.io via OTLP             │
└─────────────────────────────────────┘
```

### Span Hierarchy Example

```
POST /users
├─ users.create (business logic)
│  ├─ validation.user_input
│  └─ database.insert.user
└─ HTTP span (automatic)
```

## 🐛 Troubleshooting

### No Data in Honeycomb?

1. **Check API Key**: Ensure your API key is correct and has "Can create datasets" permission
2. **Check Endpoint**: US vs EU instance
3. **Check Environment**: Make sure environment variables are loaded
4. **Enable Debug Mode**:
   ```bash
   OTEL_RUBY_TRACES_EXPORTER_DEBUG=true
   OTEL_LOG_LEVEL=debug
   ```

### Debugging OpenTelemetry

Add debug logging to see what's happening:

```ruby
# Add this to the top of honeycomb_example.rb
ENV['OTEL_LOG_LEVEL'] = 'debug'
```

### Common Issues

1. **Missing Dataset**: Ensure API key has "Can create datasets" permission
2. **EU vs US Instance**: Check you're using the correct endpoint
3. **Firewall**: Ensure outbound HTTPS to Honeycomb is allowed
4. **Gem Conflicts**: Run `bundle install` to ensure all OpenTelemetry gems are compatible

## 📚 Further Reading

- [Honeycomb OpenTelemetry Ruby Guide](https://docs.honeycomb.io/send-data/ruby/opentelemetry-sdk/)
- [OpenTelemetry Ruby Documentation](https://opentelemetry.io/docs/instrumentation/ruby/)
- [Honeycomb Query Language](https://docs.honeycomb.io/query-data/)
- [OpenTelemetry Semantic Conventions](https://opentelemetry.io/docs/specs/semconv/)

## 🎯 Production Considerations

1. **Sampling**: Enable sampling for high-traffic applications
2. **Resource Attributes**: Add deployment environment, version tags
3. **Security**: Store API keys securely (not in code)
4. **Monitoring**: Set up alerts in Honeycomb for error rates and latency
5. **Performance**: Monitor the overhead of instrumentation

## 🤝 Integration with RapiTapir

This example shows how to extend RapiTapir with comprehensive observability:

- **Custom Sinatra Extension**: `RapiTapir::Extensions::HoneycombObservability`
- **Automatic Context Propagation**: Request IDs and business context
- **Health Check Integration**: Traced health checks with timing
- **Error Handling**: Structured error reporting with context

The pattern can be extended to other frameworks (Rails, Roda, etc.) and provides a foundation for production-ready observability in RapiTapir applications.
