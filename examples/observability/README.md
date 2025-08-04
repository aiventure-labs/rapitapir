# RapiTapir Honeycomb.io Observability Example

This example demonstrates how to integrate Honeycomb.io observability with a Ruby API using OpenTelemetry and RapiTapir patterns.

## Prerequisites

1. **Honeycomb.io Account**: Sign up at [honeycomb.io](https://honeycomb.io)
2. **API Key**: Get your API key from Honeycomb settings
3. **Ruby 3.1+**: Ensure you have Ruby installed
4. **Bundler**: For managing dependencies

## Setup

### 1. Install Dependencies

From the project root directory:

```bash
cd /path/to/ruby-tapir
bundle install
```

### 2. Configure Environment

Create a `.env` file in the `examples/observability/` directory:

```bash
# Honeycomb.io Configuration
HONEYCOMB_API_KEY=your_api_key_here
OTEL_EXPORTER_OTLP_ENDPOINT=https://api.honeycomb.io
OTEL_EXPORTER_OTLP_HEADERS=x-honeycomb-team=your_api_key_here
OTEL_SERVICE_NAME=rapitapir-demo
OTEL_RESOURCE_ATTRIBUTES=service.name=rapitapir-demo,service.version=1.0.0
```

Replace `your_api_key_here` with your actual Honeycomb API key.

### 3. Run the Server

From the project root directory:

```bash
bundle exec ruby examples/observability/honeycomb_working_example.rb
```

The server will start on `http://localhost:4567` and display available endpoints.

## API Endpoints

### Health Check
```bash
curl http://localhost:4567/health
```

### User Management
```bash
# List users (with pagination and filtering)
curl "http://localhost:4567/users?page=1&limit=10&department=engineering"

# Create user
curl -X POST http://localhost:4567/users \
  -H 'Content-Type: application/json' \
  -d '{"name":"Alice Johnson","email":"alice@example.com","age":28,"department":"engineering"}'

# Get user by ID
curl http://localhost:4567/users/USER_ID

# Update user
curl -X PUT http://localhost:4567/users/USER_ID \
  -H 'Content-Type: application/json' \
  -d '{"name":"Alice Johnson-Smith","department":"product"}'

# Delete user
curl -X DELETE http://localhost:4567/users/USER_ID
```

### Analytics
```bash
curl http://localhost:4567/analytics/department-stats
```

## Testing the Integration

Run the comprehensive test suite:

```bash
ruby examples/observability/complete_test.rb
```

This will:
1. Start the server
2. Test all endpoints
3. Generate sample data
4. Create traces in Honeycomb
5. Clean up the server

## Observability Features

### Automatic Instrumentation
- **HTTP Requests**: All incoming requests are automatically traced
- **Database Queries**: Simulated database operations with realistic timings
- **External API Calls**: Net::HTTP requests are automatically instrumented
- **Error Tracking**: Exceptions and errors are captured in spans

### Custom Business Context
Each request includes business-relevant attributes:
- User information (ID, department, etc.)
- Request metadata (pagination, filters)
- Performance metrics (database response times)
- Error context and stack traces

### Span Hierarchy
```
HTTP Request Span (e.g., "POST /users")
├── Database Operation Span (e.g., "users.create")
├── Validation Span (e.g., "validate_user_data")
└── Business Logic Span (e.g., "process_user_creation")
```

### Custom Metrics
- Request duration and status codes
- Database operation timing
- User activity by department
- Error rates and types

## Viewing Traces in Honeycomb

1. Log into your Honeycomb.io dashboard
2. Navigate to the `rapitapir-demo` dataset
3. You'll see traces for:
   - HTTP requests with full request/response context
   - Database operations with query timing
   - Business operations with custom attributes
   - Error traces with stack traces and context

### Useful Queries

**Find slow requests:**
```
duration_ms > 1000
```

**Group by endpoint:**
```
GROUP BY http.route
```

**Filter by department:**
```
user.department = "engineering"
```

**Find errors:**
```
status_code >= 400 OR error = true
```

## Architecture

### OpenTelemetry Integration
- **SDK**: Full OpenTelemetry SDK with OTLP exporter
- **Auto-instrumentation**: Rack, Sinatra, and Net::HTTP
- **Custom spans**: Business logic and database operations
- **Baggage**: Cross-service context propagation

### RapiTapir Extension
The `RapiTapirObservability` module provides:
- Automatic span creation for route handlers
- Business context extraction from requests
- Error handling and exception tracking
- Performance monitoring helpers

### Trace Context
Each trace includes:
- **Service metadata**: Name, version, environment
- **Request context**: Method, path, query parameters, headers
- **User context**: ID, department, business attributes
- **Performance data**: Timing, resource usage, dependencies
- **Error information**: Exception details, stack traces

## Best Practices

1. **Meaningful Span Names**: Use business-relevant names like "create_user" instead of generic ones
2. **Rich Attributes**: Include business context that helps with debugging
3. **Error Handling**: Always capture errors with full context
4. **Performance Monitoring**: Track both technical and business metrics
5. **Security**: Never log sensitive data like passwords or tokens

## Production Considerations

- **Sampling**: Configure sampling rates for high-traffic applications
- **Resource Limits**: Set memory and CPU limits for the OpenTelemetry SDK
- **Security**: Use environment variables for API keys, never commit them
- **Monitoring**: Monitor the observability system itself for health
- **Privacy**: Ensure compliance with data protection regulations

## Troubleshooting

### Server Won't Start
```bash
# Check if gems are installed
bundle install

# Run from project root with bundle exec
bundle exec ruby examples/observability/honeycomb_working_example.rb
```

### No Traces in Honeycomb
1. Verify API key is correct
2. Check environment variables are loaded
3. Confirm network connectivity to api.honeycomb.io
4. Look for OpenTelemetry initialization messages in logs

### Port Already in Use
```bash
# Kill any existing processes on port 4567
lsof -ti:4567 | xargs kill -9
```

## Contributing

Feel free to extend this example with:
- Additional instrumentation for your specific use cases
- Custom metrics and dashboards
- Integration with other observability tools
- Performance optimizations

---

This example demonstrates production-ready observability integration that you can adapt for your own RapiTapir applications. The patterns shown here scale from development to production environments.
