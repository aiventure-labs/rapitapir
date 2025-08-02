# frozen_string_literal: true

require_relative '../types'
require_relative '../schema'
require_relative 'input_methods'
require_relative 'output_methods'
require_relative 'observability_methods'
require_relative 'type_resolution'
require_relative 'enhanced_input'
require_relative 'enhanced_output'

module RapiTapir
  module DSL
    # Enhanced DSL module that works with the new type system
    module EnhancedEndpointDSL
      include InputMethods
      include OutputMethods
      include ObservabilityMethods
      include TypeResolution

      def out_status(code)
        create_output(:status, code)
      end

      # Authentication DSL methods
      def bearer_auth(description = 'Bearer token authentication')
        create_input(:header, :authorization, Types.string(pattern: /\ABearer .+\z/),
                     description: description, auth_type: :bearer)
      end

      def api_key_auth(header_name = 'X-API-Key', description = 'API key authentication')
        create_input(:header, header_name.downcase.to_sym, Types.string,
                     description: description, auth_type: :api_key)
      end

      def basic_auth(description = 'Basic authentication')
        create_input(:header, :authorization, Types.string(pattern: /\ABasic .+\z/),
                     description: description, auth_type: :basic)
      end

      # Validation DSL methods
      def validate_with(validator_proc)
        @custom_validators ||= []
        @custom_validators << validator_proc
      end

      def validate_json_schema(schema_def)
        validate_with(->(data) { Schema.validate!(data, resolve_type(schema_def)) })
      end

      private

      def create_input(kind, name, type, **options)
        EnhancedInput.new(kind: kind, name: name, type: type, options: options)
      end

      def create_output(kind, type, **options)
        EnhancedOutput.new(kind: kind, type: type, options: options)
      end
    end
  end
end
