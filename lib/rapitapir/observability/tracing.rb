# frozen_string_literal: true

module RapiTapir
  module Observability
    module Tracing
      class Tracer
        def initialize(service_name:, service_version:)
          @service_name = service_name
          @service_version = service_version
          @provider = nil
        end

        def configure(provider: :opentelemetry)
          @provider = provider
          case provider
          when :opentelemetry
            configure_opentelemetry
          end
        end

        def start_span(name, attributes: {}, kind: :server)
          return yield(NoOpSpan.new) unless enabled?

          case @provider
          when :opentelemetry
            require 'opentelemetry/api'
            tracer = OpenTelemetry.tracer_provider.tracer(@service_name, @service_version)
            span = tracer.start_span(name, kind: kind, attributes: attributes)
            OpenTelemetry::Context.with_current_span(span) do
              yield(span)
            ensure
              span.finish
            end
          end
        end

        def current_span
          return NoOpSpan.new unless enabled?

          case @provider
          when :opentelemetry
            require 'opentelemetry/api'
            OpenTelemetry::Context.current_span
          end
        end

        def add_event(name, attributes: {})
          return unless enabled?

          current_span.add_event(name, attributes: attributes)
        end

        def set_attribute(key, value)
          return unless enabled?

          current_span.set_attribute(key, value)
        end

        def record_exception(exception)
          return unless enabled?

          current_span.record_exception(exception)
        end

        private

        def enabled?
          RapiTapir::Observability.config.tracing.enabled
        end

        def configure_opentelemetry
          require 'opentelemetry/sdk'
          require 'opentelemetry/instrumentation/all'

          OpenTelemetry::SDK.configure do |c|
            c.service_name = @service_name
            c.service_version = @service_version
            c.use_all # Use all available instrumentation
          end
        rescue LoadError
          warn "OpenTelemetry SDK not available. Install 'opentelemetry-sdk' and 'opentelemetry-instrumentation-all' gems."
        end
      end

      class NoOpSpan
        def add_event(name, attributes: {}); end
        def set_attribute(key, value); end
        def record_exception(exception); end
        def finish; end
      end

      class << self
        attr_reader :tracer

        def configure(service_name:, service_version:, provider: :opentelemetry)
          @tracer = Tracer.new(service_name: service_name, service_version: service_version)
          @tracer.configure(provider: provider)
        end

        def enabled?
          RapiTapir::Observability.config.tracing.enabled
        end

        def start_span(name, ...)
          return yield(NoOpSpan.new) unless enabled?

          @tracer&.start_span(name, ...)
        end

        def current_span
          return NoOpSpan.new unless enabled?

          @tracer&.current_span || NoOpSpan.new
        end

        def add_event(name, attributes: {})
          return unless enabled?

          @tracer&.add_event(name, attributes: attributes)
        end

        def set_attribute(key, value)
          return unless enabled?

          @tracer&.set_attribute(key, value)
        end

        def record_exception(exception)
          return unless enabled?

          @tracer&.record_exception(exception)
        end
      end
    end
  end
end
