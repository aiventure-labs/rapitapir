# frozen_string_literal: true

require_relative 'endpoint'
require_relative '../dsl/enhanced_endpoint_dsl'
require_relative '../types'
require_relative '../schema'

module RapiTapir
  module Core
    # Enhanced Endpoint class that integrates with the new type system
    class EnhancedEndpoint < Endpoint
      include DSL::EnhancedEndpointDSL

      attr_reader :security_schemes, :custom_validators

      def initialize(method: nil, path: nil, inputs: [], outputs: [], errors: [], metadata: {})
        super
        @security_schemes = []
        @custom_validators = []
      end

      # Override input methods to use enhanced DSL
      def in(input_def, **options)
        case input_def
        when DSL::EnhancedInput
          copy_with(inputs: inputs + [input_def])
        when Hash
          # Handle hash-based input definitions
          if input_def.key?(:query)
            copy_with(inputs: inputs + [query(input_def[:name] || :query, input_def[:query], **options)])
          elsif input_def.key?(:path)
            copy_with(inputs: inputs + [path_param(input_def[:name] || :path, input_def[:path], **options)])
          elsif input_def.key?(:header)
            copy_with(inputs: inputs + [header(input_def[:name] || :header, input_def[:header], **options)])
          elsif input_def.key?(:body)
            copy_with(inputs: inputs + [json_body(input_def[:body], **options)])
          else
            raise ArgumentError, "Unknown input definition: #{input_def}"
          end
        else
          # Fallback to parent implementation for backward compatibility
          super(input_def)
        end
      end

      def out(output_def, **options)
        case output_def
        when DSL::EnhancedOutput
          copy_with(outputs: outputs + [output_def])
        when Hash
          if output_def.key?(:json)
            copy_with(outputs: outputs + [out_json(output_def[:json], **options)])
          elsif output_def.key?(:text)
            copy_with(outputs: outputs + [out_text(output_def[:text], **options)])
          elsif output_def.key?(:status)
            copy_with(outputs: outputs + [out_status(output_def[:status])])
          else
            raise ArgumentError, "Unknown output definition: #{output_def}"
          end
        else
          # Fallback to parent implementation for backward compatibility
          super(output_def)
        end
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
          
          unless result[:valid]
            result[:errors].each do |error|
              validation_errors << "Input '#{input.name}': #{error}"
            end
          end
        end

        if validation_errors.any?
          raise ValidationError, "Request validation failed:\n#{validation_errors.join("\n")}"
        end

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
          unless [:bearer, :api_key, :basic].include?(scheme.options[:auth_type])
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
          unless output.type.respond_to?(:validate)
            raise ArgumentError, "Output type does not support validation"
          end
        end
      end

      class ValidationError < StandardError; end
    end
  end
end
