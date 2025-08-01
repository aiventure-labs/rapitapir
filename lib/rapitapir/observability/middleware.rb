# frozen_string_literal: true

require 'securerandom'

module RapiTapir
  module Observability
    # Observability middleware for request tracking
    # Middleware that collects metrics, logs, and traces for each request
    class Middleware
      def initialize(app)
        @app = app
      end

      def call(env)
        request_data = build_request_data(env)

        # Increment active requests metric
        if Metrics.enabled?
          Metrics.increment_active_requests(method: request_data[:method],
                                            endpoint: request_data[:path])
        end

        # Start tracing span
        span_attributes = build_span_attributes(request_data)

        Tracing.start_span("HTTP #{request_data[:method]}", attributes: span_attributes, kind: :server) do |span|
          process_request_with_observability(request_data, span)
        rescue StandardError => e
          handle_request_error(request_data, span, e)
        ensure
          # Decrement active requests metric
          if Metrics.enabled?
            Metrics.decrement_active_requests(method: request_data[:method],
                                              endpoint: request_data[:path])
          end
        end
      end

      private

      def build_request_data(env)
        request = Rack::Request.new(env)
        request_id = extract_or_generate_request_id(env)

        # Add request ID to environment for downstream use
        env['HTTP_X_REQUEST_ID'] = request_id

        {
          request: request,
          request_id: request_id,
          method: request.request_method,
          path: extract_path(request),
          start_time: Time.now
        }
      end

      def build_span_attributes(request_data)
        request = request_data[:request]
        {
          'http.method' => request_data[:method],
          'http.url' => request.url,
          'http.route' => request_data[:path],
          'http.user_agent' => request.user_agent,
          'request.id' => request_data[:request_id]
        }
      end

      def process_request_with_observability(request_data, span)
        # Process request
        status, headers, response = @app.call(request_data[:request].env)
        duration = Time.now - request_data[:start_time]

        # Add response attributes to span
        span.set_attribute('http.status_code', status)
        span.set_attribute('http.response.size', calculate_response_size(response))

        # Record metrics and logs
        record_request_observability(request_data, status, duration)

        # Add request ID to response headers
        headers['X-Request-ID'] = request_data[:request_id]

        [status, headers, response]
      end

      def record_request_observability(request_data, status, duration)
        # Record metrics
        record_metrics(
          method: request_data[:method],
          endpoint: request_data[:path],
          status: status,
          duration: duration
        )

        # Log request
        log_request(
          method: request_data[:method],
          path: request_data[:path],
          status: status,
          duration: duration,
          request_id: request_data[:request_id],
          user_agent: request_data[:request].user_agent,
          remote_ip: request_data[:request].ip
        )
      end

      def handle_request_error(request_data, span, error)
        duration = Time.now - request_data[:start_time]
        error_type = error.class.name

        # Record error in span
        span.record_exception(error)
        span.set_attribute('error', true)

        # Record error metrics
        record_metrics(
          method: request_data[:method],
          endpoint: request_data[:path],
          status: 500,
          duration: duration,
          error_type: error_type
        )

        # Log error
        Logging.log_error(
          error,
          request_id: request_data[:request_id],
          method: request_data[:method],
          path: request_data[:path]
        )

        raise
      end

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

      def log_request(**options)
        return unless Logging.enabled?

        Logging.log_request(**options)
      end
    end

    # HTTP endpoint for exposing metrics
    # Provides an HTTP interface for metrics scraping (Prometheus format)
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
