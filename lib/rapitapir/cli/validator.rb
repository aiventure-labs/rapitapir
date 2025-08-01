# frozen_string_literal: true

module RapiTapir
  module CLI
    # Validator for RapiTapir endpoint definitions
    # Validates endpoint configurations for correctness and completeness
    class Validator
      attr_reader :errors, :endpoints

      def initialize(endpoints = [])
        @endpoints = endpoints
        @errors = []
      end

      def valid?
        @errors.clear

        return false if @endpoints.nil? || @endpoints.empty?

        @endpoints.each_with_index do |endpoint, index|
          validate_endpoint(endpoint, index)
        end

        @errors.empty?
      end
      alias validate valid?

      private

      def validate_endpoint(endpoint, index)
        context = "Endpoint #{index + 1}"

        return unless validate_endpoint_structure(endpoint, context)

        validate_endpoint_basics(endpoint, context)
        validate_endpoint_content(endpoint, context)
        validate_endpoint_consistency(endpoint, context)
      end

      def validate_endpoint_structure(endpoint, context)
        unless endpoint.respond_to?(:method) && endpoint.respond_to?(:path)
          @errors << "#{context}: Missing method or path"
          return false
        end
        true
      end

      def validate_endpoint_basics(endpoint, context)
        validate_http_method(endpoint, context)
        validate_summary(endpoint, context)
        validate_output_definition(endpoint, context)
        validate_parameters(endpoint) if endpoint.respond_to?(:input_specs) && endpoint.input_specs
        validate_path(endpoint.path, context)
      end

      def validate_endpoint_content(endpoint, context)
        validate_endpoint_inputs(endpoint, context)
        validate_endpoint_outputs(endpoint, context)
      end

      def validate_endpoint_consistency(endpoint, context)
        validate_path_parameters_consistency(endpoint, context)
        validate_metadata(endpoint, context)
      end

      def validate_http_method(endpoint, context)
        valid_methods = %w[GET POST PUT PATCH DELETE HEAD OPTIONS]
        return if valid_methods.include?(endpoint.method.to_s.upcase)

        @errors << "#{context}: Invalid HTTP method '#{endpoint.method}'"
      end

      def validate_summary(endpoint, context)
        return unless !endpoint.metadata || !endpoint.metadata[:summary] || endpoint.metadata[:summary].empty?

        @errors << "#{context}: missing summary"
      end

      def validate_output_definition(endpoint, context)
        return unless !endpoint.respond_to?(:outputs) || endpoint.outputs.nil? || endpoint.outputs.empty?

        @errors << "#{context}: missing output definition"
      end

      def validate_endpoint_inputs(endpoint, context)
        return unless endpoint.respond_to?(:inputs)

        endpoint.inputs.each_with_index do |input, input_index|
          validate_input(input, "#{context}, Input #{input_index + 1}")
        end
      end

      def validate_endpoint_outputs(endpoint, context)
        return unless endpoint.respond_to?(:outputs)

        endpoint.outputs.each_with_index do |output, output_index|
          validate_output(output, "#{context}, Output #{output_index + 1}")
        end
      end

      def validate_path(path, context)
        unless path.is_a?(String) && !path.empty?
          @errors << "#{context}: Path must be a non-empty string"
          return
        end

        @errors << "#{context}: Path must start with '/'" unless path.start_with?('/')

        # Check for invalid characters
        @errors << "#{context}: Path contains invalid characters" if path.match?(%r{[^a-zA-Z0-9/_:-]})

        # Check path parameter format
        path.scan(/:(\w+)/).each do |param_match|
          param_name = param_match[0]
          unless param_name.match?(/^[a-zA-Z][a-zA-Z0-9_]*$/)
            @errors << "#{context}: Invalid path parameter name '#{param_name}'"
          end
        end
      end

      def validate_input(input, context)
        unless input.respond_to?(:kind) && input.respond_to?(:name) && input.respond_to?(:type)
          @errors << "#{context}: Input missing required methods (kind, name, type)"
          return
        end

        validate_input_kind(input, context)
        validate_input_name(input, context)
        validate_input_type(input, context)
        validate_input_options_if_present(input, context)
      end

      def validate_input_kind(input, context)
        valid_kinds = %i[query path header body]
        return if valid_kinds.include?(input.kind)

        @errors << "#{context}: Invalid input kind '#{input.kind}'"
      end

      def validate_input_name(input, context)
        return if input.name.is_a?(Symbol) || input.name.is_a?(String)

        @errors << "#{context}: Input name must be a symbol or string"
      end

      def validate_input_type(input, context)
        validate_type(input.type, "#{context} type")
      end

      def validate_input_options_if_present(input, context)
        return unless input.respond_to?(:options) && input.options

        validate_input_options(input.options, context)
      end

      def validate_output(output, context)
        unless output.respond_to?(:kind) && output.respond_to?(:type)
          @errors << "#{context}: Output missing required methods (kind, type)"
          return
        end

        # Validate kind
        valid_kinds = %i[json xml status header]
        @errors << "#{context}: Invalid output kind '#{output.kind}'" unless valid_kinds.include?(output.kind)

        # Validate type based on kind
        case output.kind
        when :status
          unless output.type.is_a?(Integer) && output.type >= 100 && output.type <= 599
            @errors << "#{context}: Status code must be an integer between 100-599"
          end
        when :json, :xml
          validate_type(output.type, "#{context} schema")
        end
      end

      def validate_type(type, context)
        valid_simple_types = %i[string integer float boolean date datetime]

        case type
        when Symbol
          @errors << "#{context}: Unknown type '#{type}'" unless valid_simple_types.include?(type)
        when Hash
          validate_hash_schema(type, context)
        when Array
          if type.empty?
            @errors << "#{context}: Array type cannot be empty"
          else
            type.each_with_index do |element_type, index|
              validate_type(element_type, "#{context}[#{index}]")
            end
          end
        when Class
          # Allow custom classes
        when RapiTapir::Types::Base
          # Enhanced types - these are valid
        else
          @errors << "#{context}: Invalid type '#{type}'"
        end
      end

      def validate_hash_schema(schema, context)
        schema.each do |key, value|
          unless key.is_a?(Symbol) || key.is_a?(String)
            @errors << "#{context}: Hash key '#{key}' must be a symbol or string"
          end

          validate_type(value, "#{context}.#{key}")
        end
      end

      def validate_input_options(options, context)
        unless options.is_a?(Hash)
          @errors << "#{context}: Options must be a hash"
          return
        end

        # Check for conflicting options
        @errors << "#{context}: Cannot be both required and optional" if options[:required] && options[:optional]

        # Validate description if present
        return unless options[:description] && !options[:description].is_a?(String)

        @errors << "#{context}: Description must be a string"
      end

      def validate_path_parameters_consistency(endpoint, context)
        path_param_names = extract_path_parameter_names(endpoint)
        input_path_params = extract_input_path_parameters(endpoint)

        validate_missing_path_inputs(path_param_names, input_path_params, context)
        validate_extra_path_inputs(path_param_names, input_path_params, context)
      end

      def extract_path_parameter_names(endpoint)
        endpoint.path.scan(/:(\w+)/).flatten.map(&:to_sym)
      end

      def extract_input_path_parameters(endpoint)
        return [] unless endpoint.respond_to?(:inputs)

        endpoint.inputs
                .select { |input| input.kind == :path }
                .map(&:name)
                .map(&:to_sym)
      end

      def validate_missing_path_inputs(path_param_names, input_path_params, context)
        missing_inputs = path_param_names - input_path_params
        return if missing_inputs.empty?

        @errors << "#{context}: Missing input definitions for path parameters: #{missing_inputs.join(', ')}"
      end

      def validate_extra_path_inputs(path_param_names, input_path_params, context)
        extra_inputs = input_path_params - path_param_names
        return if extra_inputs.empty?

        @errors << "#{context}: Extra path input definitions (not in path): #{extra_inputs.join(', ')}"
      end

      def validate_metadata(endpoint, context)
        return unless endpoint.respond_to?(:metadata)

        metadata = endpoint.metadata
        return unless metadata.is_a?(Hash)

        validate_metadata_summary(metadata, context)
        validate_metadata_description(metadata, context)
        validate_metadata_tags(metadata, context)
        validate_metadata_deprecated_flag(metadata, context)
      end

      def validate_metadata_summary(metadata, context)
        return unless metadata[:summary] && !metadata[:summary].is_a?(String)

        @errors << "#{context}: Summary must be a string"
      end

      def validate_metadata_description(metadata, context)
        return unless metadata[:description] && !metadata[:description].is_a?(String)

        @errors << "#{context}: Description must be a string"
      end

      def validate_metadata_tags(metadata, context)
        return unless metadata[:tags]
        return if metadata[:tags].is_a?(Array) && metadata[:tags].all? { |tag| tag.is_a?(String) }

        @errors << "#{context}: Tags must be an array of strings"
      end

      def validate_metadata_deprecated_flag(metadata, context)
        return unless metadata[:deprecated] && ![true, false].include?(metadata[:deprecated])

        @errors << "#{context}: Deprecated must be a boolean"
      end

      def validate_parameters(endpoint)
        return unless endpoint.input_specs

        body_params = endpoint.input_specs.select { |spec| spec.type == :body }
        @errors << "#{endpoint.path}: multiple body parameters not allowed" if body_params.length > 1

        endpoint.input_specs.each do |input_spec|
          next unless input_spec.respond_to?(:param_type)

          unless valid_param_type?(input_spec.param_type)
            @errors << "#{endpoint.path}: invalid parameter type '#{input_spec.param_type}'"
          end
        end
      end

      def valid_param_type?(type)
        valid_types = [:string, :integer, :float, :boolean, :date, :datetime, Hash, Array]
        valid_types.include?(type)
      end

      def validate_basic_properties(endpoint)
        if !endpoint.metadata || !endpoint.metadata[:summary] || endpoint.metadata[:summary].empty?
          @errors << "#{endpoint.path}: missing summary"
        end

        return unless !endpoint.respond_to?(:outputs) || endpoint.outputs.nil? || endpoint.outputs.empty?

        @errors << "#{endpoint.path}: missing output definition"
      end

      def valid_output_definition?(endpoint)
        return true if endpoint.respond_to?(:outputs) && endpoint.outputs && !endpoint.outputs.empty?

        false
      end
    end
  end
end
