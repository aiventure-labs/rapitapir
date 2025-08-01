# frozen_string_literal: true

module RapiTapir
  module DSL
    # Enhanced input specification with full type system integration
    class EnhancedInput
      attr_reader :kind, :name, :type, :required, :description, :example, :format, :content_type

      def initialize(kind:, name:, type:, required: true, description: nil, example: nil, format: nil, content_type: nil)
        @kind = kind.to_sym
        @name = name.to_sym
        @type = type
        @required = required
        @description = description
        @example = example
        @format = format
        @content_type = content_type
      end

      def required?
        # Check if the input is required based on:
        # 1. Explicit required parameter
        # 2. Whether the type is optional
        return !@required if @required == false  # Explicitly set to false
        return false if @type.respond_to?(:optional?) && @type.optional?
        @required
      end

      def optional?
        !@required
      end

      def to_openapi_spec
        spec = {
          name: @name.to_s,
          in: openapi_location,
          required: @required,
          schema: @type.to_json_schema
        }

        spec[:description] = @description if @description
        spec[:example] = @example if @example
        
        spec
      end

      def validate(value)
        @type.validate(value)
      end

      def coerce(value)
        @type.coerce(value)
      end

      private

      def openapi_location
        case @kind
        when :query
          'query'
        when :path
          'path'
        when :header
          'header'
        when :body
          'requestBody'
        else
          @kind.to_s
        end
      end
    end

    # Enhanced output specification with status codes and content types
    class EnhancedOutput
      attr_reader :status_code, :type, :content_type, :description, :example, :headers

      def initialize(status_code:, type: nil, content_type: 'application/json', description: nil, example: nil, headers: {})
        @status_code = status_code.to_i
        @type = type
        @content_type = content_type
        @description = description
        @example = example
        @headers = headers || {}
      end

      # Legacy compatibility method for validators
      def kind
        return :status if @type.nil?
        
        case @content_type
        when 'application/json'
          :json
        when 'application/xml', 'text/xml'
          :xml
        else
          :json  # Default to json for unknown content types
        end
      end

      def to_openapi_spec
        spec = {
          description: @description || http_status_description
        }

        if @type
          spec[:content] = {
            @content_type => {
              schema: @type.to_json_schema
            }
          }
          
          if @example
            spec[:content][@content_type][:example] = @example
          end
        end

        if @headers.any?
          spec[:headers] = @headers.transform_values do |header_spec|
            case header_spec
            when Hash
              header_spec
            when String
              { description: header_spec }
            else
              { description: header_spec.to_s }
            end
          end
        end

        spec
      end

      def validate(value)
        return { valid: true, errors: [] } unless @type
        @type.validate(value)
      end

      def serialize(value)
        return nil unless @type
        
        case @content_type
        when 'application/json'
          JSON.generate(value)
        when 'text/plain'
          value.to_s
        else
          value
        end
      end

      private

      def http_status_description
        case @status_code
        when 200
          'OK'
        when 201
          'Created'
        when 202
          'Accepted'
        when 204
          'No Content'
        when 400
          'Bad Request'
        when 401
          'Unauthorized'
        when 403
          'Forbidden'
        when 404
          'Not Found'
        when 422
          'Unprocessable Entity'
        when 500
          'Internal Server Error'
        else
          "HTTP #{@status_code}"
        end
      end
    end

    # Enhanced error specification for detailed error responses
    class EnhancedError
      attr_reader :status_code, :type, :description, :example

      def initialize(status_code:, type: nil, description: nil, example: nil)
        @status_code = status_code.to_i
        @type = type
        @description = description
        @example = example
      end

      def to_openapi_spec
        spec = {
          description: @description || http_error_description
        }

        if @type
          spec[:content] = {
            'application/json' => {
              schema: @type.to_json_schema
            }
          }
          
          if @example
            spec[:content]['application/json'][:example] = @example
          end
        end

        spec
      end

      def matches?(error)
        error.respond_to?(:status_code) && error.status_code == @status_code
      end

      private

      def http_error_description
        case @status_code
        when 400
          'Bad Request - Invalid input parameters'
        when 401
          'Unauthorized - Authentication required'
        when 403
          'Forbidden - Insufficient permissions'
        when 404
          'Not Found - Resource not found'
        when 422
          'Unprocessable Entity - Validation failed'
        when 500
          'Internal Server Error - Server encountered an error'
        else
          "HTTP Error #{@status_code}"
        end
      end
    end

    # Enhanced security specification for authentication schemes
    class EnhancedSecurity
      attr_reader :type, :description, :name, :location, :scopes, :flows

      def initialize(type:, description:, name: nil, location: nil, scopes: [], flows: nil, **options)
        @type = type.to_sym
        @description = description
        @name = name
        @location = location&.to_sym
        @scopes = Array(scopes)
        @flows = flows
        @options = options
      end

      def to_openapi_spec
        spec = {
          type: openapi_type,
          description: @description
        }

        case @type
        when :bearer
          spec[:scheme] = 'bearer'
          spec[:bearerFormat] = @options[:bearer_format] if @options[:bearer_format]
        when :api_key
          spec[:name] = @name || 'X-API-Key'
          spec[:in] = (@location || :header).to_s
        when :basic
          spec[:scheme] = 'basic'
        when :oauth2
          spec[:flows] = @flows || default_oauth2_flows
        end

        spec
      end

      def validate_request(request)
        case @type
        when :bearer
          validate_bearer_token(request)
        when :api_key
          validate_api_key(request)
        when :basic
          validate_basic_auth(request)
        when :oauth2
          validate_oauth2_token(request)
        else
          { valid: false, error: "Unsupported auth type: #{@type}" }
        end
      end

      private

      def openapi_type
        case @type
        when :bearer, :basic
          'http'
        when :api_key
          'apiKey'
        when :oauth2
          'oauth2'
        else
          @type.to_s
        end
      end

      def default_oauth2_flows
        {
          implicit: {
            authorizationUrl: @options[:authorization_url] || 'https://example.com/oauth/authorize',
            scopes: @scopes.each_with_object({}) { |scope, hash| hash[scope] = scope.to_s.humanize }
          }
        }
      end

      def validate_bearer_token(request)
        auth_header = request.env['HTTP_AUTHORIZATION']
        return { valid: false, error: 'Missing Authorization header' } unless auth_header
        
        unless auth_header.start_with?('Bearer ')
          return { valid: false, error: 'Invalid Authorization header format' }
        end

        token = auth_header[7..-1] # Remove 'Bearer ' prefix
        return { valid: false, error: 'Empty token' } if token.empty?

        { valid: true, token: token }
      end

      def validate_api_key(request)
        key_name = @name || 'X-API-Key'
        
        key_value = case @location
                   when :header
                     request.env["HTTP_#{key_name.upcase.gsub('-', '_')}"]
                   when :query
                     request.params[key_name]
                   else
                     request.env["HTTP_#{key_name.upcase.gsub('-', '_')}"]
                   end

        return { valid: false, error: "Missing API key: #{key_name}" } unless key_value
        return { valid: false, error: 'Empty API key' } if key_value.empty?

        { valid: true, api_key: key_value }
      end

      def validate_basic_auth(request)
        auth_header = request.env['HTTP_AUTHORIZATION']
        return { valid: false, error: 'Missing Authorization header' } unless auth_header
        
        unless auth_header.start_with?('Basic ')
          return { valid: false, error: 'Invalid Authorization header format' }
        end

        encoded_credentials = auth_header[6..-1] # Remove 'Basic ' prefix
        return { valid: false, error: 'Empty credentials' } if encoded_credentials.empty?

        begin
          decoded_credentials = Base64.decode64(encoded_credentials)
          username, password = decoded_credentials.split(':', 2)
          { valid: true, username: username, password: password }
        rescue => e
          { valid: false, error: "Invalid credentials encoding: #{e.message}" }
        end
      end

      def validate_oauth2_token(request)
        # OAuth2 validation would typically involve token introspection
        # For now, we'll do basic Bearer token validation
        validate_bearer_token(request)
      end
    end
  end
end
