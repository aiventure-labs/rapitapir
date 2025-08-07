# frozen_string_literal: true

require 'logger'
require 'json'
require 'securerandom'

module RapiTapir
  module Observability
    # Structured logging system for RapiTapir
    # Provides structured logging with multiple formatters and levels
    module Logging
      # Structured logger with contextual information
      # Enhanced logger that adds structured data to log entries
      class StructuredLogger
        attr_reader :logger, :formatter

        def initialize(output: $stdout, level: :info, format: :json)
          @logger = ::Logger.new(output)
          @logger.level = log_level(level)
          @format = format
          @formatter = create_formatter
          @logger.formatter = @formatter
        end

        def debug(message = nil, **fields, &)
          log(:debug, message, **fields, &)
        end

        def info(message = nil, **fields, &)
          log(:info, message, **fields, &)
        end

        def warn(message = nil, **fields, &)
          log(:warn, message, **fields, &)
        end

        def error(message = nil, **fields, &)
          log(:error, message, **fields, &)
        end

        def fatal(message = nil, **fields, &)
          log(:fatal, message, **fields, &)
        end

        def log_request(**options)
          fields = build_request_log_fields(options)
          status = options.fetch(:status)
          method = options.fetch(:method)
          path = options.fetch(:path)

          level = determine_log_level_from_status(status)
          message = build_request_log_message(method, path, status, fields[:duration_ms])

          log(level, message, **fields)
        end

        private

        def build_request_log_fields(options)
          method = options.fetch(:method)
          path = options.fetch(:path)
          status = options.fetch(:status)
          duration = options.fetch(:duration)
          request_id = options[:request_id]
          extra_fields = options.except(:method, :path, :status, :duration, :request_id)

          request_data = {
            method: method,
            path: path,
            status: status,
            duration: duration,
            request_id: request_id,
            extra_fields: extra_fields
          }

          create_log_fields(request_data)
        end

        def create_log_fields(data)
          {
            event_type: 'http_request',
            method: data[:method].to_s.upcase,
            path: data[:path],
            status: data[:status],
            duration_ms: (data[:duration] * 1000).round(2),
            request_id: data[:request_id] || generate_request_id
          }.merge(data[:extra_fields])
        end

        def determine_log_level_from_status(status)
          if status >= 500
            :error
          else
            (status >= 400 ? :warn : :info)
          end
        end

        def build_request_log_message(method, path, status, duration_ms)
          "#{method.to_s.upcase} #{path} #{status} (#{duration_ms}ms)"
        end

        public

        def log_error(exception, request_id: nil, **extra_fields)
          fields = {
            event_type: 'error',
            error_class: exception.class.name,
            error_message: exception.message,
            error_backtrace: exception.backtrace&.first(10),
            request_id: request_id
          }.merge(extra_fields)

          error("#{exception.class}: #{exception.message}", **fields)
        end

        private

        def log(level, message = nil, **fields, &block)
          return unless enabled?

          message = block.call if block_given? && message.nil?

          # Add common fields
          fields = common_fields.merge(fields)
          fields[:message] = message if message

          @logger.public_send(level, fields)
        end

        def enabled?
          RapiTapir::Observability.config.logging.enabled
        end

        def create_formatter
          case @format
          when :json
            JsonFormatter.new
          when :logfmt
            LogfmtFormatter.new
          else
            TextFormatter.new
          end
        end

        def common_fields
          {
            timestamp: Time.now.utc.iso8601,
            service: 'rapitapir',
            version: RapiTapir::VERSION,
            process_id: Process.pid
          }
        end

        def log_level(level)
          case level.to_sym
          when :debug then ::Logger::DEBUG
          when :warn then ::Logger::WARN
          when :error then ::Logger::ERROR
          when :fatal then ::Logger::FATAL
          else ::Logger::INFO # Default for :info and unknown levels
          end
        end

        def generate_request_id
          SecureRandom.hex(8)
        end
      end

      # JSON formatter for structured log output
      # Formats log entries as JSON for machine-readable logs
      class JsonFormatter
        def call(severity, timestamp, _progname, msg)
          case msg
          when Hash
            msg_with_metadata = msg.merge(
              level: severity,
              timestamp: timestamp.utc.iso8601
            )
            "#{JSON.generate(msg_with_metadata)}\n"
          else
            "#{JSON.generate(
              level: severity,
              timestamp: timestamp.utc.iso8601,
              message: msg.to_s
            )}\n"
          end
        end
      end

      # Logfmt formatter for key-value log output
      # Formats log entries using the logfmt key=value format
      class LogfmtFormatter
        def call(severity, timestamp, _progname, msg)
          case msg
          when Hash
            fields = msg.map { |k, v| "#{k}=#{format_value(v)}" }
            "#{fields.join(' ')}\n"
          else
            "level=#{severity} timestamp=#{timestamp.utc.iso8601} message=#{format_value(msg)}\n"
          end
        end

        private

        def format_value(value)
          case value
          when String
            value.include?(' ') ? "\"#{value}\"" : value
          when Array
            "[#{value.join(',')}]"
          else
            value.to_s
          end
        end
      end

      # Plain text formatter for human-readable logs
      # Formats log entries as readable text for development
      class TextFormatter
        def call(severity, timestamp, _progname, msg)
          case msg
          when Hash
            message = msg.delete(:message) || ''
            extra = msg.map { |k, v| "#{k}=#{v}" }.join(' ')
            "#{timestamp.strftime('%Y-%m-%d %H:%M:%S')} [#{severity}] #{message} #{extra}\n"
          else
            "#{timestamp.strftime('%Y-%m-%d %H:%M:%S')} [#{severity}] #{msg}\n"
          end
        end
      end

      class << self
        attr_reader :logger

        def configure(output: $stdout, level: :info, format: :json, structured: true)
          if structured
            @logger = StructuredLogger.new(output: output, level: level, format: format)
          else
            @logger = ::Logger.new(output)
            @logger.level = log_level(level)
          end
        end

        def enabled?
          RapiTapir::Observability.config.logging.enabled
        end

        %i[debug info warn error fatal].each do |level|
          define_method(level) do |*args, **kwargs, &block|
            return unless enabled?

            @logger&.public_send(level, *args, **kwargs, &block)
          end
        end

        def log_request(**args)
          return unless enabled?

          @logger&.log_request(**args)
        end

        def log_error(exception, **extra_fields)
          return unless enabled?

          @logger&.log_error(exception, **extra_fields)
        end
      end
    end
  end
end
