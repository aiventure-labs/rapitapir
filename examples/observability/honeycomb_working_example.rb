# frozen_string_literal: true

# Add local lib to load path
$LOAD_PATH.unshift(File.expand_path('../../lib', __dir__))

# Load environment variables from .env file
begin
  require 'dotenv'
  Dotenv.load(File.join(__dir__, '.env'))
rescue LoadError
  puts "⚠️  dotenv gem not available. Make sure environment variables are set manually."
end

require 'sinatra/base'
require 'json'
require 'opentelemetry/sdk'
require 'opentelemetry/exporter/otlp'
require 'opentelemetry/instrumentation/all'
require 'opentelemetry/processor/baggage/baggage_span_processor'

# Initialize OpenTelemetry with Honeycomb.io configuration
OpenTelemetry::SDK.configure do |config|
  # Use all available instrumentation 
  config.use_all()
end

# Custom Sinatra extension for Honeycomb observability
module RapiTapir
  module Extensions
    module HoneycombObservability
      def self.registered(app)
        # Get the OpenTelemetry tracer for our application
        tracer = OpenTelemetry.tracer_provider.tracer('rapitapir-sinatra-app')

        # Add before filter to start spans and add context
        app.before do
          # Start a new span for the request
          @current_span = tracer.start_span(
            "#{request.request_method} #{request.path_info}",
            kind: :server
          )

          # Add standard HTTP attributes
          @current_span.set_attribute('http.method', request.request_method)
          @current_span.set_attribute('http.url', request.url)
          @current_span.set_attribute('http.route', request.path_info)
          @current_span.set_attribute('http.user_agent', request.user_agent) if request.user_agent
          @current_span.set_attribute('service.name', 'rapitapir-demo')
          @current_span.set_attribute('service.version', '1.0.0')

          # Add custom business context via baggage
          OpenTelemetry::Baggage.set_value('request.id', SecureRandom.uuid)
          OpenTelemetry::Baggage.set_value('service.name', 'rapitapir-demo')

          # Start timing the request
          @request_start_time = Time.now
        end

        # Add after filter to complete spans
        app.after do
          next unless @current_span

          # Calculate request duration
          duration = Time.now - @request_start_time
          @current_span.set_attribute('http.status_code', response.status)
          @current_span.set_attribute('http.response_size', response.body.join.length)
          @current_span.set_attribute('duration_ms', (duration * 1000).round(2))

          # Set span status based on HTTP status
          if response.status >= 400
            @current_span.status = OpenTelemetry::Trace::Status.error("HTTP #{response.status}")
          else
            @current_span.status = OpenTelemetry::Trace::Status.ok
          end

          # Finish the span
          @current_span.finish
        end

        # Helper method to add custom attributes to current span
        app.helpers do
          def add_span_attributes(**attributes)
            return unless @current_span

            attributes.each do |key, value|
              @current_span.set_attribute(key.to_s, value)
            end
          end

          def create_child_span(name, **attributes)
            tracer = OpenTelemetry.tracer_provider.tracer('rapitapir-sinatra-app')
            span = tracer.start_span(name, with_parent: @current_span)

            attributes.each do |key, value|
              span.set_attribute(key.to_s, value)
            end

            yield(span) if block_given?
            span
          end
        end
      end
    end
  end
end

# Sinatra app with Honeycomb observability
class HoneycombDemoAPI < Sinatra::Base
  register RapiTapir::Extensions::HoneycombObservability

  # In-memory data store for demo
  @@users = []
  @@user_counter = 0

  # Get tracer for business logic spans
  def tracer
    @tracer ||= OpenTelemetry.tracer_provider.tracer('rapitapir-business-logic')
  end

  # Health check endpoint
  get '/health' do
    tracer.in_span('health_check') do |span|
      span.set_attribute('health_check.type', 'basic')
      
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

      span.set_attribute('health_check.status', 'healthy')
      span.set_attribute('health_check.checks_count', health_data[:checks].size)

      content_type :json
      health_data.to_json
    end
  end

  # GET /users - List all users with pagination and filtering
  get '/users' do
    tracer.in_span('users.list') do |span|
      page = params[:page]&.to_i || 1
      limit = params[:limit]&.to_i || 10
      department = params[:department]

      span.set_attribute('pagination.page', page)
      span.set_attribute('pagination.limit', limit)
      span.set_attribute('filter.department', department) if department

      # Add custom business context
      add_span_attributes(
        'business.operation' => 'list_users',
        'business.entity' => 'user'
      )

      # Simulate database query with child span
      filtered_users = tracer.in_span('database.query.users') do |db_span|
        db_span.set_attribute('db.operation', 'SELECT')
        db_span.set_attribute('db.table', 'users')

        # Simulate query time
        sleep(0.02)

        users = @@users.dup
        users = users.select { |u| u[:department] == department } if department
        users
      end

      # Pagination logic
      start_index = (page - 1) * limit
      paginated_users = filtered_users[start_index, limit] || []

      span.set_attribute('result.count', paginated_users.length)
      span.set_attribute('result.total_available', filtered_users.length)

      content_type :json
      {
        users: paginated_users,
        pagination: {
          page: page,
          limit: limit,
          total: filtered_users.length,
          has_more: start_index + limit < filtered_users.length
        }
      }.to_json
    end
  end

  # POST /users - Create a new user
  post '/users' do
    tracer.in_span('users.create') do |span|
      begin
        # Parse and validate input
        request.body.rewind
        user_data = JSON.parse(request.body.read)

        span.set_attribute('business.operation', 'create_user')
        span.set_attribute('business.entity', 'user')
        span.set_attribute('input.department', user_data['department'])

        # Validation with detailed tracing
        validation_result = tracer.in_span('validation.user_input') do |validation_span|
          errors = []
          errors << 'Name is required' unless user_data['name']&.length&.between?(2, 100)
          errors << 'Email is required' unless user_data['email']&.match?(/\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i)
          errors << 'Age must be between 18 and 120' unless user_data['age']&.between?(18, 120)
          errors << 'Invalid department' unless %w[engineering sales marketing support].include?(user_data['department'])

          validation_span.set_attribute('validation.errors_count', errors.length)
          validation_span.set_attribute('validation.passed', errors.empty?)

          errors
        end

        unless validation_result.empty?
          span.set_attribute('error.type', 'validation_error')
          span.set_attribute('error.details', validation_result.join(', '))
          span.status = OpenTelemetry::Trace::Status.error('Validation failed')

          status 400
          content_type :json
          return { error: 'Validation failed', details: validation_result }.to_json
        end

        # Create user with database simulation
        new_user = tracer.in_span('database.insert.user') do |db_span|
          db_span.set_attribute('db.operation', 'INSERT')
          db_span.set_attribute('db.table', 'users')

          # Simulate database insert
          sleep(0.015)

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

        span.set_attribute('result.user_id', new_user[:id])
        span.set_attribute('result.department', new_user[:department])

        # Add success baggage for downstream spans
        OpenTelemetry::Baggage.set_value('user.created', 'true')
        OpenTelemetry::Baggage.set_value('user.id', new_user[:id])

        status 201
        content_type :json
        new_user.to_json

      rescue JSON::ParserError => e
        span.set_attribute('error.type', 'json_parse_error')
        span.set_attribute('error.message', e.message)
        span.status = OpenTelemetry::Trace::Status.error('JSON parsing failed')

        status 400
        content_type :json
        { error: 'Invalid JSON format' }.to_json
      rescue StandardError => e
        span.set_attribute('error.type', 'internal_error')
        span.set_attribute('error.message', e.message)
        span.status = OpenTelemetry::Trace::Status.error('Internal server error')

        status 500
        content_type :json
        { error: 'Internal server error' }.to_json
      end
    end
  end

  # GET /users/:id - Get a specific user
  get '/users/:id' do |user_id|
    tracer.in_span('users.get') do |span|
      span.set_attribute('business.operation', 'get_user')
      span.set_attribute('business.entity', 'user')
      span.set_attribute('user.id', user_id)

      # Find user with database simulation
      user = tracer.in_span('database.query.user_by_id') do |db_span|
        db_span.set_attribute('db.operation', 'SELECT')
        db_span.set_attribute('db.table', 'users')
        db_span.set_attribute('db.where', 'id = ?')

        # Simulate database lookup
        sleep(0.01)

        @@users.find { |u| u[:id] == user_id }
      end

      if user
        span.set_attribute('result.found', true)
        span.set_attribute('result.department', user[:department])

        content_type :json
        user.to_json
      else
        span.set_attribute('result.found', false)
        span.set_attribute('error.type', 'not_found')

        status 404
        content_type :json
        { error: 'User not found' }.to_json
      end
    end
  end

  # PUT /users/:id - Update a user
  put '/users/:id' do |user_id|
    tracer.in_span('users.update') do |span|
      begin
        request.body.rewind
        update_data = JSON.parse(request.body.read)

        span.set_attribute('business.operation', 'update_user')
        span.set_attribute('business.entity', 'user')
        span.set_attribute('user.id', user_id)

        # Find and update user
        user_index = @@users.find_index { |u| u[:id] == user_id }

        unless user_index
          span.set_attribute('error.type', 'not_found')
          status 404
          content_type :json
          return { error: 'User not found' }.to_json
        end

        # Update with database simulation
        updated_user = tracer.in_span('database.update.user') do |db_span|
          db_span.set_attribute('db.operation', 'UPDATE')
          db_span.set_attribute('db.table', 'users')

          # Simulate database update
          sleep(0.012)

          user = @@users[user_index]
          user[:name] = update_data['name'] if update_data['name']
          user[:email] = update_data['email'] if update_data['email']
          user[:age] = update_data['age'] if update_data['age']
          user[:department] = update_data['department'] if update_data['department']

          @@users[user_index] = user
          user
        end

        span.set_attribute('result.updated', true)
        span.set_attribute('result.department', updated_user[:department])

        content_type :json
        updated_user.to_json

      rescue JSON::ParserError => e
        span.set_attribute('error.type', 'json_parse_error')
        span.set_attribute('error.message', e.message)

        status 400
        content_type :json
        { error: 'Invalid JSON format' }.to_json
      end
    end
  end

  # DELETE /users/:id - Delete a user
  delete '/users/:id' do |user_id|
    tracer.in_span('users.delete') do |span|
      span.set_attribute('business.operation', 'delete_user')
      span.set_attribute('business.entity', 'user')
      span.set_attribute('user.id', user_id)

      # Find and delete user
      user_index = @@users.find_index { |u| u[:id] == user_id }

      unless user_index
        span.set_attribute('error.type', 'not_found')
        status 404
        content_type :json
        return { error: 'User not found' }.to_json
      end

      # Delete with database simulation
      deleted_user = tracer.in_span('database.delete.user') do |db_span|
        db_span.set_attribute('db.operation', 'DELETE')
        db_span.set_attribute('db.table', 'users')

        # Simulate database delete
        sleep(0.008)

        @@users.delete_at(user_index)
      end

      span.set_attribute('result.deleted', true)
      span.set_attribute('result.department', deleted_user[:department])

      status 204
    end
  end

  # GET /analytics/department-stats - Business analytics endpoint
  get '/analytics/department-stats' do
    tracer.in_span('analytics.department_stats') do |span|
      span.set_attribute('business.operation', 'department_analytics')
      span.set_attribute('business.entity', 'analytics')

      # Complex analytics with child spans
      stats = tracer.in_span('analytics.compute.department_distribution') do |compute_span|
        # Simulate complex computation
        sleep(0.05)

        departments = %w[engineering sales marketing support]
        stats = departments.map do |dept|
          count = @@users.count { |u| u[:department] == dept }
          avg_age = @@users.select { |u| u[:department] == dept }
                           .map { |u| u[:age] }
                           .then { |ages| ages.empty? ? 0 : ages.sum.to_f / ages.length }

          {
            department: dept,
            user_count: count,
            average_age: avg_age.round(1)
          }
        end

        compute_span.set_attribute('analytics.departments_analyzed', departments.length)
        compute_span.set_attribute('analytics.total_users', @@users.length)

        stats
      end

      span.set_attribute('result.departments_count', stats.length)
      span.set_attribute('result.total_users', @@users.length)

      content_type :json
      {
        timestamp: Time.now.iso8601,
        total_users: @@users.length,
        department_stats: stats
      }.to_json
    end
  end

  # Error handling with tracing
  error do
    tracer.in_span('error.handler') do |span|
      error = env['sinatra.error']
      span.set_attribute('error.type', error.class.name)
      span.set_attribute('error.message', error.message)
      span.status = OpenTelemetry::Trace::Status.error(error.message)

      status 500
      content_type :json
      { error: 'Internal server error', message: error.message }.to_json
    end
  end
end

# Configure the application to run
if __FILE__ == $PROGRAM_NAME
  puts "🍯 Starting RapiTapir Demo API with Honeycomb.io Observability"
  puts "📊 Traces will be sent to: #{ENV['OTEL_EXPORTER_OTLP_ENDPOINT'] || 'https://api.honeycomb.io'}"
  puts "🔧 Service Name: #{ENV['OTEL_SERVICE_NAME'] || 'rapitapir-demo'}"
  puts ""
  puts "🚀 Available endpoints:"
  puts "   GET    /health                   - Health check"
  puts "   GET    /users                    - List users (supports ?page=1&limit=10&department=engineering)"
  puts "   POST   /users                    - Create user"
  puts "   GET    /users/:id                - Get user by ID"
  puts "   PUT    /users/:id                - Update user"
  puts "   DELETE /users/:id                - Delete user"
  puts "   GET    /analytics/department-stats - Department analytics"
  puts ""
  puts "📝 Example curl commands:"
  puts "   curl http://localhost:4567/users"
  puts "   curl -X POST http://localhost:4567/users -H 'Content-Type: application/json' -d '{\"name\":\"John Doe\",\"email\":\"john@example.com\",\"age\":30,\"department\":\"engineering\"}'"
  puts ""

  HoneycombDemoAPI.run!(host: '0.0.0.0', port: 4567)
end
