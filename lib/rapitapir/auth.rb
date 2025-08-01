# frozen_string_literal: true

require_relative 'auth/configuration'
require_relative 'auth/errors'
require_relative 'auth/context'
require_relative 'auth/schemes'
require_relative 'auth/middleware'

module RapiTapir
  # Authentication and authorization module for RapiTapir
  #
  # Provides comprehensive authentication schemes including Bearer tokens, API keys,
  # JWT, OAuth2, and basic authentication. Also includes authorization middleware,
  # rate limiting, CORS support, and security features.
  #
  # @example Configure authentication
  #   RapiTapir::Auth.configure do |config|
  #     config.jwt_secret = 'your-secret'
  #     config.rate_limiting.requests_per_minute = 100
  #   end
  #
  # @example Create authentication schemes
  #   bearer_auth = RapiTapir::Auth.bearer_token(:bearer, { token_validator: proc { |token| ... } })
  module Auth
    class << self
      attr_accessor :configuration

      def configure
        self.configuration ||= Configuration.new
        yield(configuration) if block_given?
        configuration
      end

      def config
        self.configuration ||= Configuration.new
      end

      # DSL methods for creating authentication schemes
      def bearer_token(name = :bearer, config = {})
        Schemes::BearerToken.new(name, config)
      end

      def api_key(name = :api_key, config = {})
        Schemes::ApiKey.new(name, config)
      end

      def basic_auth(name = :basic, config = {})
        Schemes::BasicAuth.new(name, config)
      end

      def oauth2(name = :oauth2, config = {})
        Schemes::OAuth2.new(name, config)
      end

      def jwt(name = :jwt, config = {})
        Schemes::JWT.new(name, config)
      end

      # Middleware factory methods
      def authentication_middleware(auth_schemes = {})
        Middleware::AuthenticationMiddleware.new(nil, auth_schemes)
      end

      def authorization_middleware(required_scopes: [], require_all: true)
        Middleware::AuthorizationMiddleware.new(nil, required_scopes: required_scopes, require_all: require_all)
      end

      def rate_limiting_middleware(config = {})
        Middleware::RateLimitingMiddleware.new(nil, config)
      end

      def cors_middleware(config = {})
        Middleware::CorsMiddleware.new(nil, config)
      end

      def security_headers_middleware(config = {})
        Middleware::SecurityHeadersMiddleware.new(nil, config)
      end

      # Context access
      def current_context
        ContextStore.current
      end

      def current_user
        current_context&.user
      end

      def authenticated?
        current_context&.authenticated? || false
      end

      def has_scope?(scope)
        current_context&.has_scope?(scope) || false
      end
    end
  end
end
