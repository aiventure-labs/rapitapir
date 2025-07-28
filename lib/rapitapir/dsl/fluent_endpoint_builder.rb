# frozen_string_literal: true

require_relative '../types'
require_relative '../schema'
require_relative '../core/enhanced_endpoint'
require_relative 'enhanced_structures'

module RapiTapir
  module DSL
    # Fluent builder for creating endpoints with a chainable DSL
    class FluentEndpointBuilder
      attr_reader :method, :path, :inputs, :outputs, :errors, :metadata, :security_schemes

      def initialize(method, path)
        @method = method.to_sym
        @path = path.to_s
        @inputs = []
        @outputs = []
        @errors = []
        @metadata = {}
        @security_schemes = []
        @scopes = []
      end

      # Create a copy of this builder with new data
      def copy_with(**changes)
        new_builder = self.class.new(@method, @path)
        new_builder.instance_variable_set(:@inputs, changes[:inputs] || @inputs.dup)
        new_builder.instance_variable_set(:@outputs, changes[:outputs] || @outputs.dup) 
        new_builder.instance_variable_set(:@errors, changes[:errors] || @errors.dup)
        new_builder.instance_variable_set(:@metadata, changes[:metadata] || @metadata.dup)
        new_builder.instance_variable_set(:@security_schemes, changes[:security_schemes] || @security_schemes.dup)
        new_builder.instance_variable_set(:@scopes, changes[:scopes] || @scopes.dup)
        new_builder
      end

      # Documentation methods
      def summary(text)
        copy_with(metadata: @metadata.merge(summary: text))
      end

      def description(text)
        copy_with(metadata: @metadata.merge(description: text))
      end

      def tags(*tag_list)
        copy_with(metadata: @metadata.merge(tags: tag_list.flatten))
      end

      # Input specification methods
      def query(name, type_def, **options)
        type = resolve_type(type_def)
        input = create_input(:query, name, type, **options)
        copy_with(inputs: @inputs + [input])
      end

      def path_param(name, type_def, **options)
        type = resolve_type(type_def)
        input = create_input(:path, name, type, **options)
        copy_with(inputs: @inputs + [input])
      end
      alias_method :path, :path_param

      def header(name, type_def, **options)
        type = resolve_type(type_def)
        input = create_input(:header, name, type, **options)
        copy_with(inputs: @inputs + [input])
      end

      def json_body(type_def, **options)
        type = resolve_type(type_def)
        input = create_input(:body, :body, type, format: :json, **options)
        copy_with(inputs: @inputs + [input])
      end

      def form_body(type_def, **options)
        type = resolve_type(type_def)
        input = create_input(:body, :body, type, format: :form, **options)
        copy_with(inputs: @inputs + [input])
      end

      def body(type_def, content_type: 'application/json', **options)
        type = resolve_type(type_def)
        input = create_input(:body, :body, type, content_type: content_type, **options)
        copy_with(inputs: @inputs + [input])
      end

      # Output specification methods
      def responds_with(status_code, **options)
        output = create_output(status_code, **options)
        copy_with(outputs: @outputs + [output])
      end

      def json_response(status_code, type_def, **options)
        type = resolve_type(type_def)
        output = create_output(status_code, type: type, content_type: 'application/json', **options)
        copy_with(outputs: @outputs + [output])
      end

      def text_response(status_code, type_def = Types.string, **options)
        type = resolve_type(type_def)
        output = create_output(status_code, type: type, content_type: 'text/plain', **options)
        copy_with(outputs: @outputs + [output])
      end

      def status_response(status_code, **options)
        output = create_output(status_code, type: nil, **options)
        copy_with(outputs: @outputs + [output])
      end

      # Convenience methods for common status codes
      def ok(type_def = nil, **options)
        if type_def
          json_response(200, type_def, **options)
        else
          status_response(200, **options)
        end
      end

      def created(type_def = nil, **options)
        if type_def
          json_response(201, type_def, **options)
        else
          status_response(201, **options)
        end
      end

      def accepted(**options)
        status_response(202, **options)
      end

      def no_content(**options)
        status_response(204, **options)
      end

      # Error response methods
      def error_response(status_code, type_def = nil, **options)
        type = type_def ? resolve_type(type_def) : nil
        error = create_error(status_code, type, **options)
        copy_with(errors: @errors + [error])
      end

      def bad_request(type_def = nil, **options)
        error_response(400, type_def, **options)
      end

      def unauthorized(type_def = nil, **options)
        error_response(401, type_def, **options)
      end

      def forbidden(type_def = nil, **options)
        error_response(403, type_def, **options)
      end

      def not_found(type_def = nil, **options)
        error_response(404, type_def, **options)
      end

      def unprocessable_entity(type_def = nil, **options)
        error_response(422, type_def, **options)
      end

      def internal_server_error(type_def = nil, **options)
        error_response(500, type_def, **options)
      end

      # Authentication methods
      def bearer_auth(description = "Bearer token authentication", **options)
        security = create_security(:bearer, description, **options)
        copy_with(security_schemes: @security_schemes + [security])
      end

      def api_key_auth(name, location = :header, description = "API key authentication", **options)
        security = create_security(:api_key, description, name: name, location: location, **options)
        copy_with(security_schemes: @security_schemes + [security])
      end

      def basic_auth(description = "Basic authentication", **options)
        security = create_security(:basic, description, **options)
        copy_with(security_schemes: @security_schemes + [security])
      end

      def oauth2_auth(scopes = [], description = "OAuth2 authentication", **options)
        security = create_security(:oauth2, description, scopes: scopes, **options)
        copy_with(security_schemes: @security_schemes + [security])
      end

      def requires_scope(*scope_list)
        copy_with(scopes: @scopes + scope_list.flatten)
      end

      def optional_auth
        copy_with(metadata: @metadata.merge(optional_auth: true))
      end

      # Build the final endpoint
      def build
        Core::EnhancedEndpoint.new(
          method: @method,
          path: @path,
          inputs: @inputs,
          outputs: @outputs,
          errors: @errors,
          metadata: @metadata.merge(
            security_schemes: @security_schemes,
            scopes: @scopes
          )
        )
      end

      private

      def resolve_type(type_def)
        case type_def
        when Types::Base
          type_def
        when Symbol
          case type_def
          when :string
            Types.string
          when :integer
            Types.integer
          when :float
            Types.float
          when :boolean
            Types.boolean
          when :date
            Types.date
          when :datetime
            Types.datetime
          when :uuid
            Types.uuid
          when :email
            Types.email
          else
            raise ArgumentError, "Unknown type symbol: #{type_def}"
          end
        when Class
          if type_def < Types::Base
            type_def.new
          else
            raise ArgumentError, "Type class must inherit from Types::Base"
          end
        when Schema
          type_def
        else
          raise ArgumentError, "Invalid type definition: #{type_def}"
        end
      end

      def create_input(kind, name, type, **options)
        DSL::EnhancedInput.new(
          kind: kind,
          name: name,
          type: type,
          required: options.fetch(:required, true),
          description: options[:description],
          example: options[:example],
          format: options[:format],
          content_type: options[:content_type]
        )
      end

      def create_output(status_code, **options)
        DSL::EnhancedOutput.new(
          status_code: status_code,
          type: options[:type],
          content_type: options[:content_type],
          description: options[:description],
          example: options[:example],
          headers: options[:headers] || {}
        )
      end

      def create_error(status_code, type, **options)
        DSL::EnhancedError.new(
          status_code: status_code,
          type: type,
          description: options[:description],
          example: options[:example]
        )
      end

      def create_security(type, description, **options)
        DSL::EnhancedSecurity.new(
          type: type,
          description: description,
          **options
        )
      end
    end
  end
end
