# frozen_string_literal: true

module RapiTapir
  module Auth
    class Configuration
      attr_accessor :default_realm, :jwt_secret, :jwt_algorithm
      attr_reader :oauth2, :session, :rate_limiting, :cors

      def initialize
        @default_realm = 'RapiTapir API'
        @jwt_secret = nil
        @jwt_algorithm = 'HS256'
        @oauth2 = OAuth2Config.new
        @session = SessionConfig.new
        @rate_limiting = RateLimitingConfig.new
        @cors = CorsConfig.new
      end

      class OAuth2Config
        attr_accessor :authorization_url, :token_url, :refresh_url, :scopes, :client_id, :client_secret

        def initialize
          @authorization_url = nil
          @token_url = nil
          @refresh_url = nil
          @client_id = nil
          @client_secret = nil
          @scopes = {}
        end

        def add_scope(name, description)
          @scopes[name.to_s] = description
        end
      end

      class SessionConfig
        attr_accessor :enabled, :key, :secret, :domain, :path, :secure, :http_only, :same_site

        def initialize
          @enabled = false
          @key = '_rapitapir_session'
          @secret = nil
          @domain = nil
          @path = '/'
          @secure = false
          @http_only = true
          @same_site = 'Lax'
        end
      end

      class RateLimitingConfig
        attr_accessor :enabled, :requests_per_minute, :requests_per_hour,
                      :requests_per_day, :burst_limit, :identifier

        def initialize
          @enabled = false
          @requests_per_minute = 60
          @requests_per_hour = 1000
          @requests_per_day = 10_000
          @burst_limit = 10
          @identifier = :ip_address
        end

        def enable(requests_per_minute: 60, requests_per_hour: 1000,
                   requests_per_day: 10_000, burst_limit: 10, identifier: :ip_address)
          @enabled = true
          @requests_per_minute = requests_per_minute
          @requests_per_hour = requests_per_hour
          @requests_per_day = requests_per_day
          @burst_limit = burst_limit
          @identifier = identifier
        end
      end

      class CorsConfig
        attr_accessor :enabled, :allowed_origins, :allowed_methods, :allowed_headers,
                      :exposed_headers, :allow_credentials, :max_age, :preflight_continue

        def initialize
          @enabled = false
          @allowed_origins = ['*']
          @allowed_methods = %w[GET POST PUT PATCH DELETE OPTIONS HEAD]
          @allowed_headers = %w[Content-Type Authorization Accept X-Requested-With]
          @exposed_headers = []
          @allow_credentials = false
          @max_age = 86_400 # 24 hours
          @preflight_continue = false
        end

        def enable(allowed_origins: ['*'], allowed_methods: nil, allowed_headers: nil,
                   allow_credentials: false, max_age: 86_400)
          @enabled = true
          @allowed_origins = allowed_origins
          @allowed_methods = allowed_methods if allowed_methods
          @allowed_headers = allowed_headers if allowed_headers
          @allow_credentials = allow_credentials
          @max_age = max_age
        end
      end
    end
  end
end
