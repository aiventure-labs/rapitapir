# frozen_string_literal: true

require_relative 'endpoint'
require_relative '../dsl/enhanced_endpoint_dsl'
require_relative '../types'
require_relative '../schema'

module RapiTapir
  module Core
    # Enhanced Endpoint class that integrates with the new type system
    class EnhancedEndpoint < Endpoint
      attr_reader :security_schemes, :custom_validators

      def initialize(method: nil, path: nil, inputs: [], outputs: [], errors: [], metadata: {})
        super
        @security_schemes = []
        @custom_validators = []
      end

      # Type validation helpers
      def validate_with_type(type, value)
        return true if type.nil?

        type.validate(value)
        true
      rescue Types::CoercionError => e
        raise ValidationError, "Type validation failed: #{e.message}"
      end

      # Enhanced error handling with typed errors
      def error_out(status_code, error_type_def, **options)
        error_type = resolve_type(error_type_def)
        error_output = DSL::EnhancedOutput.new(
          kind: :json,
          type: error_type,
          options: options.merge(status_code: status_code)
        )

        error_entry = {
          code: status_code,
          output: error_output,
          type: error_type
        }.merge(options)

        copy_with(errors: errors + [error_entry])
      end

      # Security integration
      def security_in(auth_scheme)
        copy_with(
          inputs: inputs + [auth_scheme],
          security_schemes: security_schemes + [auth_scheme]
        )
      end

      # Validation integration
      def validate_request_with(validator)
        new_validators = custom_validators + [validator]
        copy_with_validators(new_validators)
      end

      # Process a request with full type validation
      def process_request(extracted_inputs)
        # Run custom validators
        custom_validators.each do |validator|
          validator.call(extracted_inputs)
        end

        # Validate each input
        validation_errors = []
        inputs.each do |input|
          next unless extracted_inputs.key?(input.name)

          value = extracted_inputs[input.name]
          result = input.validate(value)

          next if result[:valid]

          result[:errors].each do |error|
            validation_errors << "Input '#{input.name}': #{error}"
          end
        end

        raise ValidationError, "Request validation failed:\n#{validation_errors.join("\n")}" if validation_errors.any?

        extracted_inputs
      end

      # Generate OpenAPI specification for this endpoint
      def to_openapi_spec
        spec = {
          summary: metadata[:summary],
          description: metadata[:description],
          tags: Array(metadata[:tags]),
          parameters: [],
          responses: {}
        }

        # Add parameters
        inputs.each do |input|
          next if input.kind == :body

          spec[:parameters] << input.to_openapi_parameter
        end

        # Add request body
        body_input = inputs.find { |i| i.kind == :body }
        if body_input
          spec[:requestBody] = {
            required: body_input.required?,
            content: {
              'application/json' => {
                schema: body_input.type.to_json_schema
              }
            }
          }
        end

        # Add responses
        outputs.each do |output|
          next if output.kind == :status

          status_code = find_status_code || 200
          spec[:responses][status_code.to_s] = output.to_openapi_response
        end

        # Add error responses
        errors.each do |error|
          spec[:responses][error[:code].to_s] = error[:output].to_openapi_response
        end

        # Add security if present
        if security_schemes.any?
          spec[:security] = security_schemes.map do |scheme|
            case scheme.options[:auth_type]
            when :bearer
              { 'bearerAuth' => [] }
            when :api_key
              { 'apiKeyAuth' => [] }
            when :basic
              { 'basicAuth' => [] }
            else
              {}
            end
          end
        end

        spec.compact
      end

      # Enhanced validation with detailed errors
      def validate!
        super

        # Additional validations for enhanced features
        validate_security_schemes!
        validate_type_consistency!
      end

      private

      def copy_with_validators(new_validators)
        new_endpoint = copy_with({})
        new_endpoint.instance_variable_set(:@custom_validators, new_validators)
        new_endpoint
      end

      def find_status_code
        status_output = outputs.find { |o| o.kind == :status }
        status_output&.type
      end

      def validate_security_schemes!
        security_schemes.each do |scheme|
          unless %i[bearer api_key basic].include?(scheme.options[:auth_type])
            raise ArgumentError, "Unknown authentication type: #{scheme.options[:auth_type]}"
          end
        end
      end

      def validate_type_consistency!
        inputs.each do |input|
          unless input.type.respond_to?(:validate)
            raise ArgumentError, "Input '#{input.name}' type does not support validation"
          end
        end

        outputs.each do |output|
          next if output.kind == :status
          raise ArgumentError, 'Output type does not support validation' unless output.type.respond_to?(:validate)
        end
      end

      class ValidationError < StandardError; end
    end
  end
end
