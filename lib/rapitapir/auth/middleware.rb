# frozen_string_literal: true

require 'json'
require 'uri'
require 'ostruct'
require_relative 'context'
require_relative 'errors'

module RapiTapir
  module Auth
    module Middleware
      class AuthenticationMiddleware
        def initialize(app, auth_schemes = {})
          @app = app
          @auth_schemes = auth_schemes
        end

        def call(env)
          request = create_request(env)
          auth_context = authenticate_request(request)
          
          # Store context for the request
          ContextStore.with_context(auth_context) do
            @app.call(env)
          end
        end

        private

        def create_request(env)
          # Create a simple request object
          OpenStruct.new(
            env: env,
            params: parse_query_params(env['QUERY_STRING']),
            headers: extract_headers(env)
          )
        end

        def parse_query_params(query_string)
          return {} if query_string.nil? || query_string.empty?
          
          URI.decode_www_form(query_string).to_h
        end

        def extract_headers(env)
          headers = {}
          env.each do |key, value|
            if key.start_with?('HTTP_')
              header_name = key[5..-1].downcase.tr('_', '-')
              headers[header_name] = value
            end
          end
          headers
        end

        def authenticate_request(request)
          @auth_schemes.each do |_name, scheme|
            context = scheme.authenticate(request)
            return context if context&.authenticated?
          end

          # Return empty context if no authentication succeeded
          Context.new
        end
      end

      class AuthorizationMiddleware
        def initialize(app, required_scopes: [], require_all: true)
          @app = app
          @required_scopes = Array(required_scopes)
          @require_all = require_all
        end

        def call(env)
          context = ContextStore.current
          
          unless context&.authenticated?
            return unauthorized_response("Authentication required")
          end

          unless authorized?(context)
            return forbidden_response("Insufficient permissions")
          end

          @app.call(env)
        end

        private

        def authorized?(context)
          return true if @required_scopes.empty?

          if @require_all
            context.has_all_scopes?(*@required_scopes)
          else
            context.has_any_scope?(*@required_scopes)
          end
        end

        def unauthorized_response(message)
          [
            401,
            { 'Content-Type' => 'application/json' },
            [JSON.generate({ error: 'Unauthorized', message: message })]
          ]
        end

        def forbidden_response(message)
          [
            403,
            { 'Content-Type' => 'application/json' },
            [JSON.generate({ error: 'Forbidden', message: message })]
          ]
        end
      end

      class RateLimitingMiddleware
        def initialize(app, config = {})
          @app = app
          @requests_per_minute = config[:requests_per_minute] || 60
          @requests_per_hour = config[:requests_per_hour] || 1000
          @storage = config[:storage] || MemoryStorage.new
          @key_generator = config[:key_generator] || method(:default_key_generator)
        end

        def call(env)
          key = @key_generator.call(env)
          
          unless rate_limit_allowed?(key)
            return rate_limit_exceeded_response
          end

          record_request(key)
          @app.call(env)
        end

        private

        def rate_limit_allowed?(key)
          minute_key = "#{key}:minute:#{Time.now.to_i / 60}"
          hour_key = "#{key}:hour:#{Time.now.to_i / 3600}"

          minute_count = @storage.get(minute_key) || 0
          hour_count = @storage.get(hour_key) || 0

          minute_count < @requests_per_minute && hour_count < @requests_per_hour
        end

        def record_request(key)
          minute_key = "#{key}:minute:#{Time.now.to_i / 60}"
          hour_key = "#{key}:hour:#{Time.now.to_i / 3600}"

          @storage.increment(minute_key, expires_in: 60)
          @storage.increment(hour_key, expires_in: 3600)
        end

        def default_key_generator(env)
          # Use IP address and user ID if available
          ip = env['REMOTE_ADDR'] || env['HTTP_X_FORWARDED_FOR']
          context = ContextStore.current
          user_id = context&.user_id

          user_id ? "user:#{user_id}" : "ip:#{ip}"
        end

        def rate_limit_exceeded_response
          [
            429,
            { 
              'Content-Type' => 'application/json',
              'Retry-After' => '60'
            },
            [JSON.generate({ 
              error: 'Rate Limit Exceeded', 
              message: 'Too many requests. Please try again later.' 
            })]
          ]
        end

        # Simple in-memory storage for rate limiting
        class MemoryStorage
          def initialize
            @storage = {}
            @mutex = Mutex.new
          end

          def get(key)
            @mutex.synchronize do
              entry = @storage[key]
              return nil unless entry
              return nil if entry[:expires_at] && Time.now > entry[:expires_at]
              
              entry[:value]
            end
          end

          def increment(key, expires_in: nil)
            @mutex.synchronize do
              entry = @storage[key]
              current_value = 0
              
              if entry && (!entry[:expires_at] || Time.now <= entry[:expires_at])
                current_value = entry[:value]
              end
              
              expires_at = expires_in ? Time.now + expires_in : nil
              
              @storage[key] = {
                value: current_value + 1,
                expires_at: expires_at
              }
            end
          end

          def cleanup_expired
            @mutex.synchronize do
              now = Time.now
              @storage.reject! do |_key, entry|
                entry[:expires_at] && now > entry[:expires_at]
              end
            end
          end
        end
      end

      class CorsMiddleware
        def initialize(app, config = {})
          @app = app
          @allowed_origins = config[:allowed_origins] || ['*']
          @allowed_methods = config[:allowed_methods] || ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS']
          @allowed_headers = config[:allowed_headers] || ['Authorization', 'Content-Type', 'X-API-Key']
          @max_age = config[:max_age] || 86400
          @allow_credentials = config[:allow_credentials] || false
        end

        def call(env)
          origin = env['HTTP_ORIGIN']
          
          # Handle preflight requests
          if env['REQUEST_METHOD'] == 'OPTIONS'
            return preflight_response(origin)
          end

          status, headers, body = @app.call(env)
          
          # Add CORS headers to actual requests
          headers = add_cors_headers(headers, origin)
          
          [status, headers, body]
        end

        private

        def preflight_response(origin)
          headers = {
            'Content-Type' => 'text/plain',
            'Content-Length' => '0'
          }
          
          headers = add_cors_headers(headers, origin)
          headers['Access-Control-Max-Age'] = @max_age.to_s
          
          [200, headers, ['']]
        end

        def add_cors_headers(headers, origin)
          headers = headers.dup
          
          if @allowed_origins.include?('*')
            headers['Access-Control-Allow-Origin'] = '*'
          elsif origin_allowed?(origin)
            headers['Access-Control-Allow-Origin'] = origin
          end

          headers['Access-Control-Allow-Methods'] = @allowed_methods.join(', ')
          headers['Access-Control-Allow-Headers'] = @allowed_headers.join(', ')
          
          if @allow_credentials
            headers['Access-Control-Allow-Credentials'] = 'true'
          end

          headers
        end

        def origin_allowed?(origin)
          return false unless origin
          return true if @allowed_origins.include?('*')
          
          @allowed_origins.any? do |allowed|
            if allowed.include?('*')
              # Simple wildcard matching
              pattern = allowed.gsub('*', '.*')
              origin.match?(/\A#{pattern}\z/)
            else
              origin == allowed
            end
          end
        end
      end

      class SecurityHeadersMiddleware
        def initialize(app, config = {})
          @app = app
          @headers = {
            'X-Content-Type-Options' => 'nosniff',
            'X-Frame-Options' => 'DENY',
            'X-XSS-Protection' => '1; mode=block',
            'Strict-Transport-Security' => 'max-age=31536000; includeSubDomains',
            'Referrer-Policy' => 'strict-origin-when-cross-origin'
          }.merge(config[:headers] || {})
        end

        def call(env)
          status, headers, body = @app.call(env)
          
          # Add security headers
          @headers.each do |name, value|
            headers[name] = value unless headers.key?(name)
          end
          
          [status, headers, body]
        end
      end
    end
  end
end
