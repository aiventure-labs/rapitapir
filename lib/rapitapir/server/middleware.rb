# frozen_string_literal: true

module RapiTapir
  module Server
    module Middleware
      # Base middleware class for RapiTapir middleware
      class Base
        def initialize(app)
          @app = app
        end

        def call(env)
          @app.call(env)
        end
      end

      # Logging middleware for request/response logging
      class Logger < Base
        def initialize(app, logger = nil)
          super(app)
          @logger = logger || default_logger
        end

        def call(env)
          start_time = Time.now
          request = Rack::Request.new(env)

          @logger.info("Started #{request.request_method} #{request.fullpath}")

          status, headers, body = @app.call(env)

          duration = ((Time.now - start_time) * 1000).round(2)
          @logger.info("Completed #{status} in #{duration}ms")

          [status, headers, body]
        end

        private

        def default_logger
          require 'logger'
          Logger.new($stdout).tap do |logger|
            logger.level = Logger::INFO
            logger.formatter = proc do |severity, datetime, _progname, msg|
              "[#{datetime.strftime('%Y-%m-%d %H:%M:%S')}] #{severity}: #{msg}\n"
            end
          end
        end
      end

      # CORS middleware for cross-origin requests
      class CORS < Base
        def initialize(app, options = {})
          super(app)
          @options = {
            allow_origin: '*',
            allow_methods: %w[GET POST PUT DELETE OPTIONS PATCH],
            allow_headers: %w[Content-Type Authorization],
            max_age: 86_400
          }.merge(options)
        end

        def call(env)
          if env['REQUEST_METHOD'] == 'OPTIONS'
            # Preflight request
            [200, cors_headers, ['']]
          else
            status, headers, body = @app.call(env)
            [status, headers.merge(cors_headers), body]
          end
        end

        private

        def cors_headers
          {
            'Access-Control-Allow-Origin' => @options[:allow_origin],
            'Access-Control-Allow-Methods' => @options[:allow_methods].join(', '),
            'Access-Control-Allow-Headers' => @options[:allow_headers].join(', '),
            'Access-Control-Max-Age' => @options[:max_age].to_s
          }
        end
      end

      # Exception handling middleware
      class ExceptionHandler < Base
        def initialize(app, options = {})
          super(app)
          @show_exceptions = options.fetch(:show_exceptions, false)
          @logger = options[:logger]
        end

        def call(env)
          @app.call(env)
        rescue StandardError => e
          @logger&.error("Unhandled exception: #{e.class}: #{e.message}")
          @logger&.error(e.backtrace.join("\n")) if @show_exceptions

          error_response(e)
        end

        private

        def error_response(error)
          error_data = { error: 'Internal Server Error' }

          if @show_exceptions
            error_data.merge!(
              exception: error.class.name,
              message: error.message,
              backtrace: error.backtrace
            )
          end

          [500, { 'Content-Type' => 'application/json' }, [JSON.generate(error_data)]]
        end
      end
    end
  end
end
