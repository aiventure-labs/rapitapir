# frozen_string_literal: true

module RapiTapir
  module Observability
    # Metrics collection and management system
    # Provides counters, gauges, and histograms for monitoring
    module Metrics
      # Registry for metrics collection and storage
      # Manages metric definitions and their current values
      class Registry
        def initialize
          @metrics = {}
          @provider = nil
        end

        def configure(provider: :prometheus, namespace: 'rapitapir', custom_labels: {})
          @provider = provider
          @namespace = namespace
          @custom_labels = custom_labels

          case provider
          when :prometheus
            configure_prometheus
          end
        end

        def counter(name, help: '', labels: [])
          metric_name = "#{@namespace}_#{name}"
          return @metrics[metric_name] if @metrics[metric_name]

          case @provider
          when :prometheus
            require 'prometheus/client'
            @metrics[metric_name] = ::Prometheus::Client::Counter.new(
              metric_name.to_sym,
              docstring: help,
              labels: labels + @custom_labels.keys
            )
            ::Prometheus::Client.registry.register(@metrics[metric_name])
          end

          @metrics[metric_name]
        end

        def histogram(name, help: '', labels: [], buckets: nil)
          metric_name = "#{@namespace}_#{name}"
          return @metrics[metric_name] if @metrics[metric_name]

          case @provider
          when :prometheus
            require 'prometheus/client'
            buckets ||= [0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10]
            @metrics[metric_name] = ::Prometheus::Client::Histogram.new(
              metric_name.to_sym,
              docstring: help,
              labels: labels + @custom_labels.keys,
              buckets: buckets
            )
            ::Prometheus::Client.registry.register(@metrics[metric_name])
          end

          @metrics[metric_name]
        end

        def gauge(name, help: '', labels: [])
          metric_name = "#{@namespace}_#{name}"
          return @metrics[metric_name] if @metrics[metric_name]

          case @provider
          when :prometheus
            require 'prometheus/client'
            @metrics[metric_name] = ::Prometheus::Client::Gauge.new(
              metric_name.to_sym,
              docstring: help,
              labels: labels + @custom_labels.keys
            )
            ::Prometheus::Client.registry.register(@metrics[metric_name])
          end

          @metrics[metric_name]
        end

        def registry
          case @provider
          when :prometheus
            require 'prometheus/client'
            ::Prometheus::Client.registry
          end
        end

        private

        def configure_prometheus
          require 'prometheus/client'
          # Initialize default metrics
          register_default_metrics
        end

        def register_default_metrics
          # HTTP request metrics
          counter(
            :http_requests_total,
            help: 'Total number of HTTP requests',
            labels: %i[method endpoint status]
          )

          histogram(
            :http_request_duration_seconds,
            help: 'HTTP request duration in seconds',
            labels: %i[method endpoint status]
          )

          # Error metrics
          counter(
            :http_errors_total,
            help: 'Total number of HTTP errors',
            labels: %i[method endpoint error_type]
          )

          # Active requests
          gauge(
            :http_active_requests,
            help: 'Number of active HTTP requests',
            labels: %i[method endpoint]
          )
        end
      end

      # Metrics collector for automatic metric gathering
      # Automatically collects and updates metrics from various sources
      class Collector
        def initialize(registry)
          @registry = registry
        end

        def record_request(method:, endpoint:, status:, duration:, error_type: nil)
          labels = merge_custom_labels(method: method, endpoint: endpoint, status: status)

          # Record request count
          @registry.counter(:http_requests_total).increment(labels: labels)

          # Record request duration
          @registry.histogram(:http_request_duration_seconds).observe(duration, labels: labels)

          # Record errors if present
          return unless error_type

          error_labels = merge_custom_labels(method: method, endpoint: endpoint, error_type: error_type)
          @registry.counter(:http_errors_total).increment(labels: error_labels)
        end

        def increment_active_requests(method:, endpoint:)
          labels = merge_custom_labels(method: method, endpoint: endpoint)
          @registry.gauge(:http_active_requests).increment(labels: labels)
        end

        def decrement_active_requests(method:, endpoint:)
          labels = merge_custom_labels(method: method, endpoint: endpoint)
          @registry.gauge(:http_active_requests).decrement(labels: labels)
        end

        private

        def merge_custom_labels(**labels)
          custom_labels = @registry.instance_variable_get(:@custom_labels) || {}
          labels.merge(custom_labels)
        end
      end

      class << self
        attr_reader :registry, :collector

        def configure(provider: :prometheus, namespace: 'rapitapir', custom_labels: {})
          @registry = Registry.new
          @registry.configure(provider: provider, namespace: namespace, custom_labels: custom_labels)
          @collector = Collector.new(@registry)
        end

        def enabled?
          RapiTapir::Observability.config.metrics.enabled
        end

        def record_request(**args)
          return unless enabled?

          @collector&.record_request(**args)
        end

        def increment_active_requests(**args)
          return unless enabled?

          @collector&.increment_active_requests(**args)
        end

        def decrement_active_requests(**args)
          return unless enabled?

          @collector&.decrement_active_requests(**args)
        end
      end
    end
  end
end
