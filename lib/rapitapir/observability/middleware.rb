# frozen_string_literal: true

require 'securerandom'

module RapiTapir
  module Observability
    class Middleware
      def initialize(app)
        @app = app
      end

      def call(env)
        request = Rack::Request.new(env)
        request_id = extract_or_generate_request_id(env)

        # Add request ID to environment for downstream use
        env['HTTP_X_REQUEST_ID'] = request_id

        start_time = Time.now
        method = request.request_method
        path = extract_path(request)

        # Increment active requests metric
        Metrics.increment_active_requests(method: method, endpoint: path) if Metrics.enabled?

        # Start tracing span
        span_attributes = {
          'http.method' => method,
          'http.url' => request.url,
          'http.route' => path,
          'http.user_agent' => request.user_agent,
          'request.id' => request_id
        }

        Tracing.start_span("HTTP #{method}", attributes: span_attributes, kind: :server) do |span|
          # Process request
          status, headers, response = @app.call(env)
          duration = Time.now - start_time

          # Add response attributes to span
          span.set_attribute('http.status_code', status)
          span.set_attribute('http.response.size', calculate_response_size(response))

          # Record metrics
          record_metrics(method: method, endpoint: path, status: status, duration: duration)

          # Log request
          log_request(
            method: method,
            path: path,
            status: status,
            duration: duration,
            request_id: request_id,
            user_agent: request.user_agent,
            remote_ip: request.ip
          )

          # Add request ID to response headers
          headers['X-Request-ID'] = request_id

          [status, headers, response]
        rescue StandardError => e
          duration = Time.now - start_time
          error_type = e.class.name

          # Record error in span
          span.record_exception(e)
          span.set_attribute('error', true)

          # Record error metrics
          record_metrics(
            method: method,
            endpoint: path,
            status: 500,
            duration: duration,
            error_type: error_type
          )

          # Log error
          Logging.log_error(e, request_id: request_id, method: method, path: path)

          raise
        ensure
          # Decrement active requests metric
          Metrics.decrement_active_requests(method: method, endpoint: path) if Metrics.enabled?
        end
      end

      private

      def extract_or_generate_request_id(env)
        # Try to extract from headers (X-Request-ID, X-Correlation-ID, etc.)
        request_id = env['HTTP_X_REQUEST_ID'] ||
                     env['HTTP_X_CORRELATION_ID'] ||
                     env['HTTP_X_TRACE_ID']

        request_id || SecureRandom.hex(8)
      end

      def extract_path(request)
        # Extract the route pattern if available, otherwise use path
        request.env['REQUEST_URI'] || request.path_info || request.path
      end

      def calculate_response_size(response)
        return 0 unless response.respond_to?(:each)

        size = 0
        response.each { |chunk| size += chunk.bytesize if chunk.respond_to?(:bytesize) }
        size
      end

      def record_metrics(method:, endpoint:, status:, duration:, error_type: nil)
        return unless Metrics.enabled?

        Metrics.record_request(
          method: method,
          endpoint: endpoint,
          status: status,
          duration: duration,
          error_type: error_type
        )
      end

      def log_request(method:, path:, status:, duration:, request_id:, **extra_fields)
        return unless Logging.enabled?

        Logging.log_request(
          method: method,
          path: path,
          status: status,
          duration: duration,
          request_id: request_id,
          **extra_fields
        )
      end
    end

    class MetricsEndpoint
      def initialize(registry = nil)
        @registry = registry || Metrics.registry&.registry
      end

      def call(env)
        return not_found unless @registry && Metrics.enabled?

        request = Rack::Request.new(env)

        case request.path_info
        when '/metrics'
          handle_prometheus_metrics
        else
          not_found
        end
      end

      private

      def handle_prometheus_metrics
        require 'prometheus/client'

        output = ::Prometheus::Client::Formats::Text.marshal(@registry)

        [200, {
          'Content-Type' => ::Prometheus::Client::Formats::Text::CONTENT_TYPE,
          'Cache-Control' => 'no-cache'
        }, [output]]
      rescue StandardError => e
        [500, { 'Content-Type' => 'text/plain' }, ["Error generating metrics: #{e.message}"]]
      end

      def not_found
        [404, { 'Content-Type' => 'text/plain' }, ['Not Found']]
      end
    end

    # Rack middleware for adding observability to the stack
    class RackMiddleware
      def self.new(app, **_options)
        # Build middleware stack
        stack = app

        # Add health check endpoint if enabled
        if RapiTapir::Observability.config.health_check.enabled
          stack = Rack::URLMap.new({
                                     RapiTapir::Observability.config.health_check.endpoint => HealthCheck.endpoint,
                                     '/' => stack
                                   })
        end

        # Add metrics endpoint if enabled
        if RapiTapir::Observability.config.metrics.enabled
          stack = Rack::URLMap.new({
                                     '/metrics' => MetricsEndpoint.new,
                                     '/' => stack
                                   })
        end

        # Add observability middleware
        Middleware.new(stack)
      end
    end
  end
end
