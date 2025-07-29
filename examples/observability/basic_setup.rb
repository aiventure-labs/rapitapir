# frozen_string_literal: true

require 'rapitapir'

# Configure observability for the application
RapiTapir.configure do |config|
  # Enable Prometheus metrics
  config.metrics.enable_prometheus(
    namespace: 'my_api',
    labels: { service: 'user_service', version: '1.0.0' }
  )
  
  # Enable OpenTelemetry tracing
  config.tracing.enable_opentelemetry(
    service_name: 'my-api-service',
    service_version: '1.0.0'
  )
  
  # Enable structured logging
  config.logging.enable_structured(
    level: :info,
    fields: [:timestamp, :level, :message, :request_id, :method, :path, :status, :duration, :user_id]
  )
  
  # Enable health checks
  config.health_check.enable(endpoint: '/health')
  
  # Add custom health checks
  config.health_check.add_check(:database) do
    # Simulate database health check
    { status: :healthy, message: 'Database connection OK' }
  end
  
  config.health_check.add_check(:redis) do
    # Simulate Redis health check
    { status: :healthy, message: 'Redis connection OK' }
  end
end

# Example endpoint with observability
user_creation_endpoint = RapiTapir.endpoint
  .post
  .in("/users")
  .json_body({
    name: :string,
    email: :email,
    age: { type: :integer, minimum: 18 }
  })
  .out_json({
    id: :uuid,
    name: :string,
    email: :email,
    created_at: :datetime
  })
  .with_metrics("user_creation")
  .with_tracing
  .with_logging(level: :info, fields: [:user_email, :user_age])
  .description("Create a new user")
  .tag("users")
  .handle do |request|
    # Extract user data
    user_data = request.body
    
    # Add custom attributes to tracing span
    RapiTapir::Observability::Tracing.set_attribute('user.email', user_data[:email])
    RapiTapir::Observability::Tracing.set_attribute('user.age', user_data[:age])
    
    # Log user creation attempt
    RapiTapir::Observability::Logging.info(
      "Creating user",
      user_email: user_data[:email],
      user_age: user_data[:age]
    )
    
    begin
      # Simulate user creation with metrics
      user_id = SecureRandom.uuid
      created_at = Time.now.utc
      
      # Add event to tracing span
      RapiTapir::Observability::Tracing.add_event(
        'user.created',
        attributes: { 'user.id' => user_id }
      )
      
      # Return created user
      {
        id: user_id,
        name: user_data[:name],
        email: user_data[:email],
        created_at: created_at.iso8601
      }
    rescue => e
      # Record exception in tracing
      RapiTapir::Observability::Tracing.record_exception(e)
      
      # Log error with structured format
      RapiTapir::Observability::Logging.log_error(
        e,
        user_email: user_data[:email],
        operation: 'user_creation'
      )
      
      raise
    end
  end

# Example endpoint with custom metrics
user_list_endpoint = RapiTapir.endpoint
  .get
  .in("/users")
  .query(:page, Types.integer(minimum: 1, default: 1))
  .query(:limit, Types.integer(minimum: 1, maximum: 100, default: 20))
  .out_json({
    users: [{
      id: :uuid,
      name: :string,
      email: :email
    }],
    pagination: {
      current_page: :integer,
      total_pages: :integer,
      total_count: :integer
    }
  })
  .with_metrics("user_list")
  .with_tracing("GET /users")
  .handle do |request|
    page = request.query[:page] || 1
    limit = request.query[:limit] || 20
    
    # Custom span attributes
    RapiTapir::Observability::Tracing.set_attribute('pagination.page', page)
    RapiTapir::Observability::Tracing.set_attribute('pagination.limit', limit)
    
    # Simulate fetching users
    users = (1..limit).map do |i|
      {
        id: SecureRandom.uuid,
        name: "User #{(page - 1) * limit + i}",
        email: "user#{(page - 1) * limit + i}@example.com"
      }
    end
    
    total_count = 1000 # Simulated total
    total_pages = (total_count / limit.to_f).ceil
    
    {
      users: users,
      pagination: {
        current_page: page,
        total_pages: total_pages,
        total_count: total_count
      }
    }
  end

# Error handling endpoint example
error_endpoint = RapiTapir.endpoint
  .get
  .in("/error-test")
  .out_json({ error: :string })
  .with_metrics("error_test")
  .with_tracing
  .handle do |request|
    # Simulate different types of errors for testing observability
    error_type = request.query[:type] || 'generic'
    
    case error_type
    when 'timeout'
      raise Timeout::Error, "Operation timed out"
    when 'validation'
      raise ArgumentError, "Invalid input data"
    when 'not_found'
      raise StandardError, "Resource not found"
    else
      raise RuntimeError, "Generic error for testing"
    end
  end

puts "Observability example configured!"
puts "Available endpoints:"
puts "- POST /users (create user with full observability)"
puts "- GET /users (list users with pagination tracking)"
puts "- GET /error-test (test error tracking)"
puts "- GET /health (health check endpoint)"
puts "- GET /metrics (Prometheus metrics endpoint)"
puts ""
puts "To run with a Rack server:"
puts "require 'rack'"
puts "use RapiTapir::Observability::RackMiddleware"
puts "run YourApp"
