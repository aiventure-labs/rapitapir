# frozen_string_literal: true

require 'base64'
require 'json'
require 'openssl'
require_relative 'configuration'
require_relative 'errors'
require_relative 'context'

module RapiTapir
  module Auth
    module Schemes
      # Base class for all authentication schemes
      # Defines the interface that all authentication schemes must implement
      class Base
        attr_reader :name, :config

        def initialize(name, config = {})
          @name = name
          @config = config
        end

        def authenticate(request)
          raise NotImplementedError, 'Subclasses must implement #authenticate'
        end

        def challenge
          raise NotImplementedError, 'Subclasses must implement #challenge'
        end

        protected

        def create_context(user: nil, scopes: [], token: nil, metadata: {})
          Context.new(
            user: user,
            scopes: scopes,
            token: token,
            metadata: metadata.merge(scheme: @name)
          )
        end
      end

      # Bearer token authentication scheme
      # Authenticates using tokens in the Authorization header
      class BearerToken < Base
        def initialize(name, config = {})
          super
          @token_validator = config[:token_validator] || method(:default_token_validator)
          @realm = config[:realm] || 'API'
        end

        def authenticate(request)
          auth_header = request.env['HTTP_AUTHORIZATION']
          return nil unless auth_header

          token = extract_bearer_token(auth_header)
          return nil unless token

          user_data = @token_validator.call(token)
          return nil unless user_data

          create_context(
            user: user_data[:user],
            scopes: user_data[:scopes] || [],
            token: token,
            metadata: { token_type: 'bearer' }
          )
        rescue InvalidTokenError
          nil
        end

        def challenge
          "Bearer realm=\"#{@realm}\""
        end

        private

        def extract_bearer_token(auth_header)
          match = auth_header.match(/\ABearer\s+(.+)\z/i)
          match ? match[1] : nil
        end

        def default_token_validator(token)
          # Default implementation - should be overridden
          return nil if token.nil? || token.empty?

          {
            user: { id: 'default_user', name: 'Default User' },
            scopes: ['read']
          }
        end
      end

      # API key authentication scheme
      # Authenticates using API keys in headers or query parameters
      class ApiKey < Base
        def initialize(name, config = {})
          super
          @key_validator = config[:key_validator] || method(:default_key_validator)
          @header_name = config[:header_name] || 'X-API-Key'
          @query_param = config[:query_param] || 'api_key'
          @location = config[:location] || :header # :header, :query, or :both
        end

        def authenticate(request)
          api_key = extract_api_key(request)
          return nil unless api_key

          user_data = @key_validator.call(api_key)
          return nil unless user_data

          create_context(
            user: user_data[:user],
            scopes: user_data[:scopes] || [],
            token: api_key,
            metadata: {
              token_type: 'api_key',
              location: @location
            }
          )
        rescue InvalidTokenError
          nil
        end

        def challenge
          'ApiKey'
        end

        private

        def extract_api_key(request)
          case @location
          when :header
            request.env["HTTP_#{@header_name.upcase.tr('-', '_')}"]
          when :query
            request.params[@query_param]
          when :both
            request.env["HTTP_#{@header_name.upcase.tr('-', '_')}"] ||
              request.params[@query_param]
          end
        end

        def default_key_validator(key)
          # Default implementation - should be overridden
          return nil if key.nil? || key.empty?

          {
            user: { id: 'api_user', name: 'API User' },
            scopes: ['api']
          }
        end
      end

      # HTTP Basic authentication scheme
      # Authenticates using username and password in the Authorization header
      class BasicAuth < Base
        def initialize(name, config = {})
          super
          @credential_validator = config[:credential_validator] || method(:default_credential_validator)
          @realm = config[:realm] || 'API'
        end

        def authenticate(request)
          auth_header = request.env['HTTP_AUTHORIZATION']
          return nil unless auth_header

          credentials = extract_basic_credentials(auth_header)
          return nil unless credentials

          user_data = @credential_validator.call(credentials[:username], credentials[:password])
          return nil unless user_data

          create_context(
            user: user_data[:user],
            scopes: user_data[:scopes] || [],
            metadata: {
              token_type: 'basic',
              username: credentials[:username]
            }
          )
        rescue AuthenticationError
          nil
        end

        def challenge
          "Basic realm=\"#{@realm}\""
        end

        private

        def extract_basic_credentials(auth_header)
          match = auth_header.match(/\ABasic\s+(.+)\z/i)
          return nil unless match

          decoded = Base64.decode64(match[1])
          username, password = decoded.split(':', 2)

          return nil if username.nil? || password.nil?

          { username: username, password: password }
        rescue ArgumentError
          nil
        end

        def default_credential_validator(username, password)
          # Default implementation - should be overridden
          return nil if username.nil? || password.nil? || username.empty? || password.empty?

          {
            user: { id: username, name: username.capitalize },
            scopes: ['basic']
          }
        end
      end

      # OAuth2 authentication scheme
      # Authenticates using OAuth2 tokens with optional token introspection
      class OAuth2 < Base
        def initialize(name, config = {})
          super
          @token_validator = config[:token_validator] || method(:default_oauth2_validator)
          @introspection_endpoint = config[:introspection_endpoint]
          @client_id = config[:client_id]
          @client_secret = config[:client_secret]
          @realm = config[:realm] || 'API'
        end

        def authenticate(request)
          auth_header = request.env['HTTP_AUTHORIZATION']
          return nil unless auth_header

          token = extract_bearer_token(auth_header)
          return nil unless token

          user_data = validate_oauth2_token(token)
          return nil unless user_data

          create_context(
            user: user_data[:user],
            scopes: user_data[:scopes] || [],
            token: token,
            metadata: {
              token_type: 'oauth2',
              client_id: user_data[:client_id],
              expires_at: user_data[:expires_at]
            }
          )
        rescue InvalidTokenError, TokenExpiredError
          nil
        end

        def challenge
          "Bearer realm=\"#{@realm}\""
        end

        private

        def extract_bearer_token(auth_header)
          match = auth_header.match(/\ABearer\s+(.+)\z/i)
          match ? match[1] : nil
        end

        def validate_oauth2_token(token)
          if @introspection_endpoint
            introspect_token(token)
          else
            @token_validator.call(token)
          end
        end

        def introspect_token(token)
          # OAuth2 token introspection (RFC 7662)
          # This would typically make an HTTP request to the introspection endpoint
          # For now, we'll use the configured validator
          @token_validator.call(token)
        end

        def default_oauth2_validator(token)
          # Default implementation - should be overridden
          return nil if token.nil? || token.empty?

          {
            user: { id: 'oauth_user', name: 'OAuth User' },
            scopes: %w[read write],
            client_id: 'default_client',
            expires_at: Time.now + 3600
          }
        end
      end

      # JWT (JSON Web Token) authentication scheme
      # Authenticates using signed JWT tokens with verification
      class JWT < Base
        def initialize(name, config = {})
          super
          @secret = config[:secret] || raise(ArgumentError, 'JWT secret is required')
          @algorithm = config[:algorithm] || 'HS256'
          @verify_expiration = config.fetch(:verify_expiration, true)
          @verify_issuer = config[:verify_issuer]
          @verify_audience = config[:verify_audience]
          @realm = config[:realm] || 'API'
        end

        def authenticate(request)
          auth_header = request.env['HTTP_AUTHORIZATION']
          return nil unless auth_header

          token = extract_bearer_token(auth_header)
          return nil unless token

          payload = decode_jwt_token(token)
          return nil unless payload

          create_context(
            user: extract_user_from_payload(payload),
            scopes: extract_scopes_from_payload(payload),
            token: token,
            metadata: {
              token_type: 'jwt',
              payload: payload
            }
          )
        rescue InvalidTokenError, TokenExpiredError
          nil
        end

        def challenge
          "Bearer realm=\"#{@realm}\""
        end

        private

        def extract_bearer_token(auth_header)
          match = auth_header.match(/\ABearer\s+(.+)\z/i)
          match ? match[1] : nil
        end

        def decode_jwt_token(token)
          # This is a simplified JWT decoder
          # In a real implementation, you'd use a library like ruby-jwt
          parts = split_jwt_token(token)
          return nil unless parts

          begin
            _, payload, signature = parse_jwt_parts(parts)
            return nil unless valid_jwt_signature?(parts, signature)
            return nil unless valid_jwt_claims?(payload)

            payload
          rescue JSON::ParserError, ArgumentError
            nil
          end
        end

        def split_jwt_token(token)
          parts = token.split('.')
          parts.length == 3 ? parts : nil
        end

        def parse_jwt_parts(parts)
          header_b64 = add_base64_padding(parts[0])
          payload_b64 = add_base64_padding(parts[1])

          header = JSON.parse(Base64.urlsafe_decode64(header_b64))
          payload = JSON.parse(Base64.urlsafe_decode64(payload_b64))
          signature = parts[2]

          [header, payload, signature]
        end

        def add_base64_padding(base64_string)
          missing_padding = 4 - (base64_string.length % 4)
          base64_string += '=' * missing_padding if missing_padding != 4
          base64_string
        end

        def valid_jwt_signature?(parts, signature)
          expected_signature = Base64.urlsafe_encode64(
            OpenSSL::HMAC.digest('SHA256', @secret, "#{parts[0]}.#{parts[1]}")
          ).tr('=', '')

          signature == expected_signature
        end

        def valid_jwt_claims?(payload)
          return false if @verify_expiration && jwt_expired?(payload)
          return false if @verify_issuer && payload['iss'] != @verify_issuer
          return false if @verify_audience && payload['aud'] != @verify_audience

          true
        end

        def jwt_expired?(payload)
          payload['exp'] && (Time.at(payload['exp']) < Time.now)
        end

        def extract_user_from_payload(payload)
          user_data = payload['user'] || payload['sub']
          return { id: user_data, name: user_data } if user_data.is_a?(String)

          user_data || { id: payload['sub'], name: payload['name'] || payload['sub'] }
        end

        def extract_scopes_from_payload(payload)
          scopes = payload['scopes'] || payload['scope']
          return [] unless scopes

          case scopes
          when Array
            scopes
          when String
            scopes.split
          else
            []
          end
        end
      end
    end
  end
end
