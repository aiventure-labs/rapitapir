# frozen_string_literal: true

# Add local lib to load path for development
$LOAD_PATH.unshift(File.expand_path('../../lib', __dir__))

# Load environment variables from .env file
begin
  require 'dotenv'
  Dotenv.load(File.join(__dir__, '.env'))
rescue LoadError
  puts "⚠️  dotenv gem not available. Make sure environment variables are set manually."
end

require 'json'
require 'securerandom'
require 'opentelemetry/sdk'
require 'opentelemetry/exporter/otlp'
require 'opentelemetry/instrumentation/all'
require 'opentelemetry/processor/baggage/baggage_span_processor'
require 'rapitapir'
require 'rapitapir/sinatra_rapitapir'

# Initialize OpenTelemetry with Honeycomb.io configuration
OpenTelemetry::SDK.configure do |config|
  config.use_all()
end

# Define schemas using RapiTapir Types
USER_SCHEMA = RapiTapir::Types.hash({
  'id' => RapiTapir::Types.string(description: 'Unique user ID'),
  'name' => RapiTapir::Types.string(min_length: 2, max_length: 100),
  'email' => RapiTapir::Types.email,
  'age' => RapiTapir::Types.integer(minimum: 18, maximum: 120),
  'department' => RapiTapir::Types.string(enum: %w[engineering sales marketing support]),
  'created_at' => RapiTapir::Types.string(description: 'ISO 8601 timestamp')
})

USER_CREATE_SCHEMA = RapiTapir::Types.hash({
  'name' => RapiTapir::Types.string(min_length: 2, max_length: 100),
  'email' => RapiTapir::Types.email,
  'age' => RapiTapir::Types.integer(minimum: 18, maximum: 120),
  'department' => RapiTapir::Types.string(enum: %w[engineering sales marketing support])
})

USER_UPDATE_SCHEMA = RapiTapir::Types.hash({
  'name' => RapiTapir::Types.optional(RapiTapir::Types.string(min_length: 2, max_length: 100)),
  'email' => RapiTapir::Types.optional(RapiTapir::Types.email),
  'age' => RapiTapir::Types.optional(RapiTapir::Types.integer(minimum: 18, maximum: 120)),
  'department' => RapiTapir::Types.optional(RapiTapir::Types.string(enum: %w[engineering sales marketing support]))
})

HEALTH_SCHEMA = RapiTapir::Types.hash({
  'status' => RapiTapir::Types.string,
  'timestamp' => RapiTapir::Types.string,
  'service' => RapiTapir::Types.string,
  'version' => RapiTapir::Types.string,
  'checks' => RapiTapir::Types.hash({
    'database' => RapiTapir::Types.hash({
      'status' => RapiTapir::Types.string,
      'response_time_ms' => RapiTapir::Types.float
    }),
    'redis' => RapiTapir::Types.hash({
      'status' => RapiTapir::Types.string,
      'response_time_ms' => RapiTapir::Types.float
    })
  })
})

USERS_LIST_SCHEMA = RapiTapir::Types.hash({
  'users' => RapiTapir::Types.array(USER_SCHEMA),
  'pagination' => RapiTapir::Types.hash({
    'page' => RapiTapir::Types.integer,
    'limit' => RapiTapir::Types.integer,
    'total' => RapiTapir::Types.integer,
    'has_more' => RapiTapir::Types.boolean
  })
})

ANALYTICS_SCHEMA = RapiTapir::Types.hash({
  'timestamp' => RapiTapir::Types.string,
  'total_users' => RapiTapir::Types.integer,
  'department_stats' => RapiTapir::Types.array(
    RapiTapir::Types.hash({
      'department' => RapiTapir::Types.string,
      'user_count' => RapiTapir::Types.integer,
      'average_age' => RapiTapir::Types.float
    })
  )
})

# Main API class using SinatraRapiTapir
class HoneycombDemoAPI < RapiTapir::SinatraRapiTapir
  # In-memory data store for demo
  @@users = []
  @@user_counter = 0

  # Observability helper methods
  def tracer
    @tracer ||= OpenTelemetry.tracer_provider.tracer('rapitapir-business-logic')
  end

  def with_span(name, **attributes)
    tracer.in_span(name) do |span|
      attributes.each { |key, value| span.set_attribute(key.to_s, value) }
      yield(span) if block_given?
    end
  end

  def add_business_context(span, operation:, entity:, **attrs)
    span.set_attribute('business.operation', operation)
    span.set_attribute('business.entity', entity)
    attrs.each { |key, value| span.set_attribute(key.to_s, value) }
  end

  def simulate_db_operation(operation, table, duration = 0.015)
    with_span("database.#{operation}.#{table}",
              'db.operation' => operation.upcase,
              'db.table' => table) do |span|
      sleep(duration)
      yield if block_given?
    end
  end

  # Configure RapiTapir
  rapitapir do
    info(
      title: 'RapiTapir Demo API with Honeycomb.io',
      description: 'Demonstrating observability integration with OpenTelemetry and Honeycomb',
      version: '1.0.0',
      contact: { email: 'demo@rapitapir.dev' }
    )

    development_defaults!

    # Enable automatic documentation
    enable_docs(path: '/docs', openapi_path: '/openapi.json')
  end

  # Health Check Endpoint
  endpoint(
    GET('/health')
      .summary('Health check')
      .description('Returns the health status of the API with system checks')
      .tags('Health')
      .ok(HEALTH_SCHEMA)
      .build
  ) do |inputs|
    with_span('health_check', 'health_check.type' => 'basic') do |span|
      health_data = {
        status: 'healthy',
        timestamp: Time.now.iso8601,
        service: 'rapitapir-demo',
        version: '1.0.0',
        checks: {
          database: { status: 'healthy', response_time_ms: 5.2 },
          redis: { status: 'healthy', response_time_ms: 2.1 }
        }
      }

      add_business_context(span,
                           operation: 'health_check',
                           entity: 'system',
                           'health_check.status' => 'healthy',
                           'health_check.checks_count' => health_data[:checks].size)

      health_data
    end
  end

  # List Users Endpoint
  endpoint(
    GET('/users')
      .summary('List users')
      .description('Get a paginated list of users with optional department filtering')
      .tags('Users')
      .query(:page, RapiTapir::Types.optional(RapiTapir::Types.integer(minimum: 1)), description: 'Page number')
      .query(:limit, RapiTapir::Types.optional(RapiTapir::Types.integer(minimum: 1, maximum: 100)), description: 'Items per page')
      .query(:department, RapiTapir::Types.optional(RapiTapir::Types.string(enum: %w[engineering sales marketing support])), description: 'Filter by department')
      .ok(USERS_LIST_SCHEMA)
      .build
  ) do |inputs|
    tracer = OpenTelemetry.tracer_provider.tracer('rapitapir-business-logic')
    tracer.in_span('users.list') do |span|
      page = inputs[:page] || 1
      limit = inputs[:limit] || 10
      department = inputs[:department]

      add_business_context(span,
                           operation: 'list_users',
                           entity: 'user',
                           'pagination.page' => page,
                           'pagination.limit' => limit)
      
      span.set_attribute('filter.department', department) if department

      # Simulate database query
      filtered_users = simulate_db_operation('select', 'users', 0.02) do
        users = @@users.dup
        users = users.select { |u| u[:department] == department } if department
        users
      end

      # Pagination
      start_index = (page - 1) * limit
      paginated_users = filtered_users[start_index, limit] || []

      add_business_context(span,
                           operation: 'list_users',
                           entity: 'user',
                           'result.count' => paginated_users.length,
                           'result.total_available' => filtered_users.length)

      {
        users: paginated_users,
        pagination: {
          page: page,
          limit: limit,
          total: filtered_users.length,
          has_more: start_index + limit < filtered_users.length
        }
      }
    end
  end

  # Create User Endpoint
  endpoint(
    POST('/users')
      .summary('Create user')
      .description('Create a new user with validation')
      .tags('Users')
      .json_body(USER_CREATE_SCHEMA)
      .created(USER_SCHEMA)
      .bad_request(RapiTapir::Types.hash({ 'error' => RapiTapir::Types.string, 'details' => RapiTapir::Types.array(RapiTapir::Types.string) }))
      .build
  ) do |inputs|
    with_span('users.create') do |span|
      user_data = inputs[:body]

      add_business_context(span,
                           operation: 'create_user',
                           entity: 'user',
                           'input.department' => user_data['department'])

      # Validate input with detailed tracing
      validation_errors = with_span('validation.user_input') do |validation_span|
        errors = []
        
        # Custom business validation beyond schema
        existing_email = @@users.find { |u| u[:email] == user_data['email'] }
        errors << 'Email already exists' if existing_email

        validation_span.set_attribute('validation.errors_count', errors.length)
        validation_span.set_attribute('validation.passed', errors.empty?)
        
        errors
      end

      unless validation_errors.empty?
        span.set_attribute('error.type', 'validation_error')
        span.set_attribute('error.details', validation_errors.join(', '))
        span.status = OpenTelemetry::Trace::Status.error('Validation failed')

        halt 400, { error: 'Validation failed', details: validation_errors }.to_json
      end

      # Create user with database simulation
      new_user = simulate_db_operation('insert', 'user', 0.015) do
        @@user_counter += 1
        user = {
          id: SecureRandom.uuid,
          name: user_data['name'],
          email: user_data['email'],
          age: user_data['age'],
          department: user_data['department'],
          created_at: Time.now.iso8601
        }

        @@users << user
        user
      end

      add_business_context(span,
                           operation: 'create_user',
                           entity: 'user',
                           'result.user_id' => new_user[:id],
                           'result.department' => new_user[:department])

      # Add success baggage for downstream spans
      OpenTelemetry::Baggage.set_value('user.created', 'true')
      OpenTelemetry::Baggage.set_value('user.id', new_user[:id])

      status 201
      new_user
    end
  end

  # Get User by ID Endpoint
  endpoint(
    GET('/users/{id}')
      .summary('Get user')
      .description('Get a specific user by ID')
      .tags('Users')
      .path_param(:id, RapiTapir::Types.string, description: 'User ID')
      .ok(USER_SCHEMA)
      .not_found(RapiTapir::Types.hash({ 'error' => RapiTapir::Types.string }))
      .build
  ) do |inputs|
    with_span('users.get') do |span|
      user_id = inputs[:id]

      add_business_context(span,
                           operation: 'get_user',
                           entity: 'user',
                           'user.id' => user_id)

      # Find user with database simulation
      user = simulate_db_operation('select', 'user', 0.01) do
        @@users.find { |u| u[:id] == user_id }
      end

      if user
        add_business_context(span,
                             operation: 'get_user',
                             entity: 'user',
                             'result.found' => true,
                             'result.department' => user[:department])
        user
      else
        span.set_attribute('result.found', false)
        span.set_attribute('error.type', 'not_found')
        halt 404, { error: 'User not found' }.to_json
      end
    end
  end

  # Update User Endpoint
  endpoint(
    PUT('/users/{id}')
      .summary('Update user')
      .description('Update an existing user')
      .tags('Users')
      .path_param(:id, RapiTapir::Types.string, description: 'User ID')
      .json_body(USER_UPDATE_SCHEMA)
      .ok(USER_SCHEMA)
      .not_found(RapiTapir::Types.hash({ 'error' => RapiTapir::Types.string }))
      .build
  ) do |inputs|
    with_span('users.update') do |span|
      user_id = inputs[:id]
      update_data = inputs[:body]

      add_business_context(span,
                           operation: 'update_user',
                           entity: 'user',
                           'user.id' => user_id)

      # Find user index
      user_index = @@users.find_index { |u| u[:id] == user_id }

      unless user_index
        span.set_attribute('error.type', 'not_found')
        halt 404, { error: 'User not found' }.to_json
      end

      # Update with database simulation
      updated_user = simulate_db_operation('update', 'user', 0.012) do
        user = @@users[user_index]
        user[:name] = update_data['name'] if update_data['name']
        user[:email] = update_data['email'] if update_data['email']
        user[:age] = update_data['age'] if update_data['age']
        user[:department] = update_data['department'] if update_data['department']

        @@users[user_index] = user
        user
      end

      add_business_context(span,
                           operation: 'update_user',
                           entity: 'user',
                           'result.updated' => true,
                           'result.department' => updated_user[:department])

      updated_user
    end
  end

  # Delete User Endpoint
  endpoint(
    DELETE('/users/{id}')
      .summary('Delete user')
      .description('Delete a user by ID')
      .tags('Users')
      .path_param(:id, RapiTapir::Types.string, description: 'User ID')
      .no_content
      .not_found(RapiTapir::Types.hash({ 'error' => RapiTapir::Types.string }))
      .build
  ) do |inputs|
    with_span('users.delete') do |span|
      user_id = inputs[:id]

      add_business_context(span,
                           operation: 'delete_user',
                           entity: 'user',
                           'user.id' => user_id)

      # Find user index
      user_index = @@users.find_index { |u| u[:id] == user_id }

      unless user_index
        span.set_attribute('error.type', 'not_found')
        halt 404, { error: 'User not found' }.to_json
      end

      # Delete with database simulation
      deleted_user = simulate_db_operation('delete', 'user', 0.008) do
        @@users.delete_at(user_index)
      end

      add_business_context(span,
                           operation: 'delete_user',
                           entity: 'user',
                           'result.deleted' => true,
                           'result.department' => deleted_user[:department])

      status 204
      ''
    end
  end

  # Analytics Endpoint
  endpoint(
    GET('/analytics/department-stats')
      .summary('Department analytics')
      .description('Get analytics data grouped by department')
      .tags('Analytics')
      .ok(ANALYTICS_SCHEMA)
      .build
  ) do |inputs|
    with_span('analytics.department_stats') do |span|
      add_business_context(span,
                           operation: 'department_analytics',
                           entity: 'analytics')

      # Complex analytics with child spans
      stats = with_span('analytics.compute.department_distribution') do |compute_span|
        # Simulate complex computation
        sleep(0.05)

        departments = %w[engineering sales marketing support]
        department_stats = departments.map do |dept|
          count = @@users.count { |u| u[:department] == dept }
          avg_age = if count > 0
                      ages = @@users.select { |u| u[:department] == dept }.map { |u| u[:age] }
                      ages.sum.to_f / ages.length
                    else
                      0
                    end

          {
            department: dept,
            user_count: count,
            average_age: avg_age.round(1)
          }
        end

        compute_span.set_attribute('analytics.departments_analyzed', departments.length)
        compute_span.set_attribute('analytics.total_users', @@users.length)

        department_stats
      end

      add_business_context(span,
                           operation: 'department_analytics',
                           entity: 'analytics',
                           'result.departments_count' => stats.length,
                           'result.total_users' => @@users.length)

      {
        timestamp: Time.now.iso8601,
        total_users: @@users.length,
        department_stats: stats
      }
    end
  end

  # Error handling with tracing
  error do
    tracer.in_span('error.handler') do |span|
      error = env['sinatra.error']
      span.set_attribute('error.type', error.class.name)
      span.set_attribute('error.message', error.message)
      span.status = OpenTelemetry::Trace::Status.error(error.message)

      content_type :json
      { error: 'Internal server error', message: error.message }.to_json
    end
  end
end

# Configure and run the application
if __FILE__ == $PROGRAM_NAME
  puts "🍯 Starting RapiTapir Demo API with Honeycomb.io Observability"
  puts "📊 Traces will be sent to: #{ENV['OTEL_EXPORTER_OTLP_ENDPOINT'] || 'https://api.honeycomb.io'}"
  puts "🔧 Service Name: #{ENV['OTEL_SERVICE_NAME'] || 'rapitapir-demo'}"
  puts ""
  puts "🚀 Available endpoints:"
  puts "   GET    /health                   - Health check"
  puts "   GET    /users                    - List users (supports ?page=1&limit=10&department=engineering)"
  puts "   POST   /users                    - Create user"
  puts "   GET    /users/{id}               - Get user by ID"
  puts "   PUT    /users/{id}               - Update user"
  puts "   DELETE /users/{id}               - Delete user"
  puts "   GET    /analytics/department-stats - Department analytics"
  puts "   GET    /docs                     - Swagger UI documentation"
  puts "   GET    /openapi.json             - OpenAPI specification"
  puts ""
  puts "📝 Example curl commands:"
  puts "   curl http://localhost:4567/users"
  puts "   curl -X POST http://localhost:4567/users -H 'Content-Type: application/json' -d '{\"name\":\"John Doe\",\"email\":\"john@example.com\",\"age\":30,\"department\":\"engineering\"}'"
  puts ""

  HoneycombDemoAPI.run!(host: '0.0.0.0', port: 4567)
end
