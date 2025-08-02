# frozen_string_literal: true

module RapiTapir
  module DSL
    # Observability methods for enhanced endpoint DSL
    module ObservabilityMethods
      # Observability methods
      def with_metrics(enabled: true, name: nil, labels: {})
        @metrics_enabled = enabled
        @metric_name = name || generate_metric_name
        @metric_labels = labels
        self
      end

      def with_tracing(enabled: true, span_name: nil, attributes: {})
        @tracing_enabled = enabled
        @trace_span_name = span_name || generate_span_name
        @trace_attributes = attributes
        self
      end

      def with_logging(enabled: true, **config)
        @logging_enabled = enabled
        @log_config = config
        self
      end

      def metrics_enabled?
        @metrics_enabled
      end

      def tracing_enabled?
        @tracing_enabled
      end

      def logging_enabled?
        @logging_enabled
      end

      def metric_labels
        @metric_labels
      end

      def trace_attributes
        @trace_attributes
      end

      def metric_name
        @metric_name
      end

      def trace_span_name
        @trace_span_name
      end

      def log_config
        @log_config
      end

      private

      def generate_metric_name
        # Generate a metric name based on HTTP method and path
        method = @method&.downcase || 'unknown'
        path = if @path
                 @path.gsub(%r{[/:]}, '_').gsub(/_{2,}/, '_').strip('_')
               else
                 'unknown'
               end
        "#{method}_#{path}"
      end

      def generate_span_name
        # Generate a span name for tracing
        method = @method&.upcase || 'UNKNOWN'
        path = @path || '/unknown'
        "HTTP #{method} #{path}"
      end
    end
  end
end
