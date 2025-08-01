# frozen_string_literal: true

module RapiTapir
  module Auth
    # Base authentication error for all authentication-related exceptions
    # This is the parent class for all authentication errors in RapiTapir
    class AuthenticationError < StandardError
      attr_reader :status, :error_code, :error_description

      def initialize(message, status: 401, error_code: 'authentication_failed', error_description: nil)
        super(message)
        @status = status
        @error_code = error_code
        @error_description = error_description || message
      end

      def to_hash
        {
          error: @error_code,
          error_description: @error_description,
          status: @status
        }
      end
    end

    # Authorization error for insufficient permissions
    # Raised when a user lacks required permissions to access a resource
    class AuthorizationError < AuthenticationError
      def initialize(message, error_code: 'insufficient_scope', error_description: nil)
        super(message, status: 403, error_code: error_code, error_description: error_description)
      end
    end

    # Error for invalid or expired authentication tokens
    # Raised when a provided token is malformed, expired, or otherwise invalid
    class InvalidTokenError < AuthenticationError
      def initialize(message = 'Invalid or expired token', error_code: 'invalid_token')
        super
      end
    end

    # Error for missing authentication tokens
    # Raised when authentication is required but no token was provided
    class MissingTokenError < AuthenticationError
      def initialize(message = 'Authentication token required', error_code: 'missing_token')
        super
      end
    end

    # Error for invalid user credentials
    # Raised when provided username/password credentials are incorrect
    class InvalidCredentialsError < AuthenticationError
      def initialize(message = 'Invalid credentials', error_code: 'invalid_credentials')
        super
      end
    end

    # Error for exceeded rate limits
    # Raised when a client exceeds the configured rate limit for requests
    class RateLimitExceededError < AuthenticationError
      attr_reader :retry_after, :limit, :remaining, :reset_time

      def initialize(message = 'Rate limit exceeded', retry_after: nil, limit: nil, remaining: 0, reset_time: nil)
        super(message, status: 429, error_code: 'rate_limit_exceeded')
        @retry_after = retry_after
        @limit = limit
        @remaining = remaining
        @reset_time = reset_time
      end

      def to_hash
        super.merge({
          retry_after: @retry_after,
          limit: @limit,
          remaining: @remaining,
          reset_time: @reset_time&.to_i
        }.compact)
      end
    end

    # Error for insufficient OAuth scopes
    # Raised when a token lacks the required scopes for an operation
    class ScopeError < AuthorizationError
      attr_reader :required_scopes, :provided_scopes

      def initialize(required_scopes, provided_scopes = [])
        @required_scopes = Array(required_scopes)
        @provided_scopes = Array(provided_scopes)

        message = "Insufficient scope. Required: #{@required_scopes.join(', ')}"
        message += ". Provided: #{@provided_scopes.join(', ')}" unless @provided_scopes.empty?

        super(message, error_code: 'insufficient_scope')
      end

      def to_hash
        super.merge({
                      required_scopes: @required_scopes,
                      provided_scopes: @provided_scopes
                    })
      end
    end
  end
end
