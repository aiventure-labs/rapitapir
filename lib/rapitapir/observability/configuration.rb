# frozen_string_literal: true

module RapiTapir
  module Observability
    class Configuration
      attr_accessor :metrics, :tracing, :logging, :health_check

      def initialize
        @metrics = MetricsConfig.new
        @tracing = TracingConfig.new
        @logging = LoggingConfig.new
        @health_check = HealthCheckConfig.new
      end

      class MetricsConfig
        attr_accessor :enabled, :provider, :namespace, :custom_labels

        def initialize
          @enabled = false
          @provider = :prometheus
          @namespace = 'rapitapir'
          @custom_labels = {}
        end

        def enable_prometheus(namespace: 'rapitapir', labels: {})
          @enabled = true
          @provider = :prometheus
          @namespace = namespace
          @custom_labels = labels
        end

        def disable
          @enabled = false
        end
      end

      class TracingConfig
        attr_accessor :enabled, :provider, :service_name, :service_version

        def initialize
          @enabled = false
          @provider = :opentelemetry
          @service_name = 'rapitapir-api'
          @service_version = RapiTapir::VERSION
        end

        def enable_opentelemetry(service_name: 'rapitapir-api', service_version: nil)
          @enabled = true
          @provider = :opentelemetry
          @service_name = service_name
          @service_version = service_version || RapiTapir::VERSION
        end

        def disable
          @enabled = false
        end
      end

      class LoggingConfig
        attr_accessor :enabled, :structured, :level, :format, :fields

        def initialize
          @enabled = true
          @structured = false
          @level = :info
          @format = :text
          @fields = %i[timestamp level message request_id method path status duration]
        end

        def enable_structured(level: :info, fields: nil)
          @enabled = true
          @structured = true
          @level = level
          @fields = fields if fields
        end
      end

      class HealthCheckConfig
        attr_accessor :enabled, :endpoint, :checks

        def initialize
          @enabled = false
          @endpoint = '/health'
          @checks = []
        end

        def enable(endpoint: '/health')
          @enabled = true
          @endpoint = endpoint
        end

        def add_check(name, &block)
          @checks << { name: name, check: block }
        end
      end
    end
  end
end
