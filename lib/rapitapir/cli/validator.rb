# frozen_string_literal: true

module RapiTapir
  module CLI
    class Validator
      attr_reader :errors, :endpoints

      def initialize(endpoints = [])
        @endpoints = endpoints
        @errors = []
      end

      def validate
        @errors.clear
        
        return false if @endpoints.nil? || @endpoints.empty?
        
        @endpoints.each_with_index do |endpoint, index|
          validate_endpoint(endpoint, index)
        end
        
        @errors.empty?
      end

      private

      def validate_endpoint(endpoint, index)
        context = "Endpoint #{index + 1}"
        
        # Validate basic structure
        unless endpoint.respond_to?(:method) && endpoint.respond_to?(:path)
          @errors << "#{context}: Missing method or path"
          return
        end

        # Validate HTTP method
        valid_methods = %w[GET POST PUT PATCH DELETE HEAD OPTIONS]
        unless valid_methods.include?(endpoint.method.to_s.upcase)
          @errors << "#{context}: Invalid HTTP method '#{endpoint.method}'"
        end

        # Validate summary
        if !endpoint.metadata || !endpoint.metadata[:summary] || endpoint.metadata[:summary].empty?
          @errors << "#{context}: missing summary"
        end

        # Validate output definition
        if !endpoint.respond_to?(:outputs) || endpoint.outputs.nil? || endpoint.outputs.empty?
          @errors << "#{context}: missing output definition"
        end

        # Validate parameters
        if endpoint.respond_to?(:input_specs) && endpoint.input_specs
          validate_parameters(endpoint)
        end

        # Validate path
        validate_path(endpoint.path, context)

        # Validate inputs
        if endpoint.respond_to?(:inputs)
          endpoint.inputs.each_with_index do |input, input_index|
            validate_input(input, "#{context}, Input #{input_index + 1}")
          end
        end

        # Validate outputs
        if endpoint.respond_to?(:outputs)
          endpoint.outputs.each_with_index do |output, output_index|
            validate_output(output, "#{context}, Output #{output_index + 1}")
          end
        end

        # Validate path parameters consistency
        validate_path_parameters_consistency(endpoint, context)

        # Validate metadata
        validate_metadata(endpoint, context)
      end

      def validate_path(path, context)
        unless path.is_a?(String) && !path.empty?
          @errors << "#{context}: Path must be a non-empty string"
          return
        end

        unless path.start_with?('/')
          @errors << "#{context}: Path must start with '/'"
        end

        # Check for invalid characters
        if path.match?(/[^a-zA-Z0-9\/_:-]/)
          @errors << "#{context}: Path contains invalid characters"
        end

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

        # Validate kind
        valid_kinds = [:query, :path, :header, :body]
        unless valid_kinds.include?(input.kind)
          @errors << "#{context}: Invalid input kind '#{input.kind}'"
        end

        # Validate name
        unless input.name.is_a?(Symbol) || input.name.is_a?(String)
          @errors << "#{context}: Input name must be a symbol or string"
        end

        # Validate type
        validate_type(input.type, "#{context} type")

        # Validate options if present
        if input.respond_to?(:options) && input.options
          validate_input_options(input.options, context)
        end
      end

      def validate_output(output, context)
        unless output.respond_to?(:kind) && output.respond_to?(:type)
          @errors << "#{context}: Output missing required methods (kind, type)"
          return
        end

        # Validate kind
        valid_kinds = [:json, :xml, :status, :header]
        unless valid_kinds.include?(output.kind)
          @errors << "#{context}: Invalid output kind '#{output.kind}'"
        end

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
        valid_simple_types = [:string, :integer, :float, :boolean, :date, :datetime]
        
        case type
        when Symbol
          unless valid_simple_types.include?(type)
            @errors << "#{context}: Unknown type '#{type}'"
          end
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
        if options[:required] && options[:optional]
          @errors << "#{context}: Cannot be both required and optional"
        end

        # Validate description if present
        if options[:description] && !options[:description].is_a?(String)
          @errors << "#{context}: Description must be a string"
        end
      end

      def validate_path_parameters_consistency(endpoint, context)
        # Extract path parameters from the path
        path_param_names = endpoint.path.scan(/:(\w+)/).flatten.map(&:to_sym)
        
        # Find path input parameters
        if endpoint.respond_to?(:inputs)
          input_path_params = endpoint.inputs
            .select { |input| input.kind == :path }
            .map(&:name)
            .map(&:to_sym)

          # Check if all path parameters have corresponding inputs
          missing_inputs = path_param_names - input_path_params
          unless missing_inputs.empty?
            @errors << "#{context}: Missing input definitions for path parameters: #{missing_inputs.join(', ')}"
          end

          # Check if there are extra path inputs
          extra_inputs = input_path_params - path_param_names
          unless extra_inputs.empty?
            @errors << "#{context}: Extra path input definitions (not in path): #{extra_inputs.join(', ')}"
          end
        end
      end

      def validate_metadata(endpoint, context)
        return unless endpoint.respond_to?(:metadata)
        
        metadata = endpoint.metadata
        return unless metadata.is_a?(Hash)

        # Validate summary
        if metadata[:summary] && !metadata[:summary].is_a?(String)
          @errors << "#{context}: Summary must be a string"
        end

        # Validate description
        if metadata[:description] && !metadata[:description].is_a?(String)
          @errors << "#{context}: Description must be a string"
        end

        # Validate tags
        if metadata[:tags]
          unless metadata[:tags].is_a?(Array) && metadata[:tags].all? { |tag| tag.is_a?(String) }
            @errors << "#{context}: Tags must be an array of strings"
          end
        end

        # Validate deprecated flag
        if metadata[:deprecated] && ![true, false].include?(metadata[:deprecated])
          @errors << "#{context}: Deprecated must be a boolean"
        end
      end

      def validate_parameters(endpoint)
        return unless endpoint.input_specs

        body_params = endpoint.input_specs.select { |spec| spec.type == :body }
        if body_params.length > 1
          @errors << "#{endpoint.path}: multiple body parameters not allowed"
        end

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

        if !endpoint.respond_to?(:outputs) || endpoint.outputs.nil? || endpoint.outputs.empty?
          @errors << "#{endpoint.path}: missing output definition"
        end
      end

      def validate_output_definition(endpoint)
        return true if endpoint.respond_to?(:outputs) && endpoint.outputs && !endpoint.outputs.empty?
        false
      end
    end
  end
end
