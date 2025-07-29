# frozen_string_literal: true

require 'logger'
require 'json'
require 'securerandom'

module RapiTapir
  module Observability
    module Logging
      class StructuredLogger
        attr_reader :logger, :formatter

        def initialize(output: $stdout, level: :info, format: :json)
          @logger = ::Logger.new(output)
          @logger.level = log_level(level)
          @format = format
          @formatter = create_formatter
          @logger.formatter = @formatter
        end

        def debug(message = nil, **fields, &block)
          log(:debug, message, **fields, &block)
        end

        def info(message = nil, **fields, &block)
          log(:info, message, **fields, &block)
        end

        def warn(message = nil, **fields, &block)
          log(:warn, message, **fields, &block)
        end

        def error(message = nil, **fields, &block)
          log(:error, message, **fields, &block)
        end

        def fatal(message = nil, **fields, &block)
          log(:fatal, message, **fields, &block)
        end

        def log_request(method:, path:, status:, duration:, request_id: nil, **extra_fields)
          fields = {
            event_type: 'http_request',
            method: method.to_s.upcase,
            path: path,
            status: status,
            duration_ms: (duration * 1000).round(2),
            request_id: request_id || generate_request_id
          }.merge(extra_fields)

          level = status >= 500 ? :error : (status >= 400 ? :warn : :info)
          log(level, "#{method.to_s.upcase} #{path} #{status} (#{fields[:duration_ms]}ms)", **fields)
        end

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
          when :info then ::Logger::INFO
          when :warn then ::Logger::WARN
          when :error then ::Logger::ERROR
          when :fatal then ::Logger::FATAL
          else ::Logger::INFO
          end
        end

        def generate_request_id
          SecureRandom.hex(8)
        end
      end

      class JsonFormatter
        def call(severity, timestamp, progname, msg)
          case msg
          when Hash
            msg_with_metadata = msg.merge(
              level: severity,
              timestamp: timestamp.utc.iso8601
            )
            "#{JSON.generate(msg_with_metadata)}\n"
          else
            JSON.generate(
              level: severity,
              timestamp: timestamp.utc.iso8601,
              message: msg.to_s
            ) + "\n"
          end
        end
      end

      class LogfmtFormatter
        def call(severity, timestamp, progname, msg)
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

      class TextFormatter
        def call(severity, timestamp, progname, msg)
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
            @logger.level = case level.to_sym
                           when :debug then ::Logger::DEBUG
                           when :info then ::Logger::INFO
                           when :warn then ::Logger::WARN
                           when :error then ::Logger::ERROR
                           when :fatal then ::Logger::FATAL
                           else ::Logger::INFO
                           end
          end
        end

        def enabled?
          RapiTapir::Observability.config.logging.enabled
        end

        [:debug, :info, :warn, :error, :fatal].each do |level|
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
