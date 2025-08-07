# frozen_string_literal: true

# RapiTapir::AI::LLMInstruction
#
# Generates LLM instructions and prompts from endpoint schemas and metadata.
# Supports multiple instruction purposes like validation, transformation, and analysis.
#
# Usage:
#   - Use `.llm_instruction(purpose:, fields:)` in endpoint DSL to mark endpoints for instruction generation.
#   - Use InstructionGenerator to create structured prompts from endpoint schemas.

module RapiTapir
  module AI
    module LLMInstruction
      # Generates structured LLM instructions from endpoint definitions
      class Generator
        SUPPORTED_PURPOSES = %i[
          validation # Generate validation prompts for input/output
          transformation # Generate data transformation instructions
          analysis # Generate analysis and summarization prompts
          documentation # Generate documentation from schemas
          testing # Generate test case instructions
          completion # Generate field completion suggestions
        ].freeze

        def initialize(endpoints)
          @endpoints = endpoints
        end

        # Generate instructions for all LLM-enabled endpoints
        def generate_all_instructions
          llm_endpoints = @endpoints.select(&:llm_instruction?)

          instructions = llm_endpoints.map do |endpoint|
            config = endpoint.llm_instruction_config
            generate_instruction(endpoint, config)
          end.compact

          {
            meta: {
              generator: 'RapiTapir LLM Instruction Generator',
              version: '1.0.0',
              generated_at: Time.now.iso8601,
              total_instructions: instructions.size
            },
            instructions: instructions
          }
        end

        # Generate instruction for a single endpoint
        def generate_instruction(endpoint, config)
          purpose = config[:purpose]
          fields = config[:fields] || :all

          raise ArgumentError, "Unsupported purpose: #{purpose}. Supported: #{SUPPORTED_PURPOSES.join(', ')}" unless SUPPORTED_PURPOSES.include?(purpose)

          {
            endpoint_id: endpoint_id(endpoint),
            method: endpoint.method&.to_s&.upcase,
            path: endpoint.path,
            purpose: purpose,
            instruction: build_instruction(endpoint, purpose, fields),
            schema_context: extract_schema_context(endpoint, fields),
            examples: extract_examples(endpoint),
            metadata: {
              summary: endpoint.metadata[:summary],
              description: endpoint.metadata[:description],
              generated_at: Time.now.iso8601
            }
          }
        end

        private

        def endpoint_id(endpoint)
          "#{endpoint.method}_#{endpoint.path}".gsub(/[^a-zA-Z0-9_]/, '_').downcase
        end

        def build_instruction(endpoint, purpose, fields)
          case purpose
          when :validation
            build_validation_instruction(endpoint, fields)
          when :transformation
            build_transformation_instruction(endpoint, fields)
          when :analysis
            build_analysis_instruction(endpoint, fields)
          when :documentation
            build_documentation_instruction(endpoint, fields)
          when :testing
            build_testing_instruction(endpoint, fields)
          when :completion
            build_completion_instruction(endpoint, fields)
          else
            raise ArgumentError, "Unknown purpose: #{purpose}"
          end
        end

        def build_validation_instruction(endpoint, fields)
          input_schema = extract_input_fields(endpoint, fields)
          output_schema = extract_output_fields(endpoint, fields)

          [
            "You are a data validation assistant for the #{endpoint.method&.upcase} #{endpoint.path} API endpoint.",
            endpoint.metadata[:summary] ? "Purpose: #{endpoint.metadata[:summary]}" : nil,
            '',
            'INPUT VALIDATION:',
            'Validate the following input data against these requirements:',
            format_schema_for_validation(input_schema),
            '',
            'OUTPUT VALIDATION:',
            'Ensure the response data matches this structure:',
            format_schema_for_validation(output_schema),
            '',
            'INSTRUCTIONS:',
            '1. Check all required fields are present',
            '2. Validate data types match the schema',
            '3. Verify constraints (min/max length, patterns, etc.)',
            '4. Report any validation errors with specific field names',
            "5. Confirm successful validation with 'VALID' or list errors"
          ].compact.join("\n")
        end

        def build_transformation_instruction(endpoint, fields)
          input_schema = extract_input_fields(endpoint, fields)
          output_schema = extract_output_fields(endpoint, fields)

          [
            "You are a data transformation assistant for the #{endpoint.method&.upcase} #{endpoint.path} API endpoint.",
            endpoint.metadata[:summary] ? "Purpose: #{endpoint.metadata[:summary]}" : nil,
            '',
            'TRANSFORMATION TASK:',
            'Transform input data from this format:',
            format_schema_for_transformation(input_schema),
            '',
            'To this output format:',
            format_schema_for_transformation(output_schema),
            '',
            'INSTRUCTIONS:',
            '1. Map all relevant input fields to appropriate output fields',
            '2. Apply any necessary data type conversions',
            '3. Calculate derived fields based on business logic',
            '4. Ensure all required output fields are populated',
            '5. Return the transformed data in the exact output schema format'
          ].compact.join("\n")
        end

        def build_analysis_instruction(endpoint, fields)
          schema_context = extract_schema_context(endpoint, fields)

          [
            "You are a data analysis assistant for the #{endpoint.method&.upcase} #{endpoint.path} API endpoint.",
            endpoint.metadata[:summary] ? "Purpose: #{endpoint.metadata[:summary]}" : nil,
            '',
            'ANALYSIS CONTEXT:',
            'Analyze data related to this API endpoint structure:',
            format_schema_for_analysis(schema_context),
            '',
            'INSTRUCTIONS:',
            '1. Identify patterns and trends in the data',
            '2. Summarize key insights and findings',
            '3. Highlight any anomalies or unusual values',
            '4. Provide actionable recommendations based on the data',
            '5. Format your analysis clearly with sections for patterns, insights, and recommendations'
          ].compact.join("\n")
        end

        def build_documentation_instruction(endpoint, fields)
          schema_context = extract_schema_context(endpoint, fields)

          [
            "You are a technical documentation assistant for the #{endpoint.method&.upcase} #{endpoint.path} API endpoint.",
            endpoint.metadata[:summary] ? "Purpose: #{endpoint.metadata[:summary]}" : nil,
            '',
            'DOCUMENTATION TASK:',
            'Generate comprehensive documentation for this API endpoint:',
            format_schema_for_documentation(schema_context),
            '',
            'INSTRUCTIONS:',
            '1. Write a clear endpoint description and purpose',
            '2. Document all input parameters with types and constraints',
            '3. Describe the response format and all output fields',
            '4. Include practical usage examples',
            '5. Note any special requirements or business rules',
            '6. Format as clean, readable API documentation'
          ].compact.join("\n")
        end

        def build_testing_instruction(endpoint, fields)
          schema_context = extract_schema_context(endpoint, fields)

          [
            "You are a test case generation assistant for the #{endpoint.method&.upcase} #{endpoint.path} API endpoint.",
            endpoint.metadata[:summary] ? "Purpose: #{endpoint.metadata[:summary]}" : nil,
            '',
            'TEST GENERATION TASK:',
            'Create comprehensive test cases for this API endpoint:',
            format_schema_for_testing(schema_context),
            '',
            'INSTRUCTIONS:',
            '1. Generate positive test cases with valid inputs',
            '2. Create negative test cases for invalid inputs',
            '3. Test boundary conditions and edge cases',
            '4. Include tests for required vs optional fields',
            '5. Provide expected responses for each test case',
            '6. Format test cases with clear descriptions and assertions'
          ].compact.join("\n")
        end

        def build_completion_instruction(endpoint, fields)
          input_schema = extract_input_fields(endpoint, fields)

          [
            "You are a smart completion assistant for the #{endpoint.method&.upcase} #{endpoint.path} API endpoint.",
            endpoint.metadata[:summary] ? "Purpose: #{endpoint.metadata[:summary]}" : nil,
            '',
            'COMPLETION TASK:',
            'Provide intelligent field completion suggestions based on this schema:',
            format_schema_for_completion(input_schema),
            '',
            'INSTRUCTIONS:',
            '1. Analyze partial input data provided by the user',
            '2. Suggest realistic values for incomplete fields',
            '3. Ensure suggestions match the field types and constraints',
            '4. Provide multiple options when appropriate',
            '5. Explain the reasoning behind each suggestion',
            '6. Format suggestions clearly with field names and proposed values'
          ].compact.join("\n")
        end

        def extract_schema_context(endpoint, fields)
          {
            inputs: extract_input_fields(endpoint, fields),
            outputs: extract_output_fields(endpoint, fields),
            errors: extract_error_fields(endpoint)
          }
        end

        def extract_input_fields(endpoint, fields)
          return {} unless endpoint.inputs

          input_schema = {}
          endpoint.inputs.each do |input|
            next unless include_field?(input.name, fields)

            input_schema[input.name] = {
              type: describe_type(input.type),
              kind: input.kind,
              required: input.respond_to?(:required?) ? input.required? : true,
              description: input.respond_to?(:description) ? input.description : nil
            }
          end
          input_schema
        end

        def extract_output_fields(endpoint, fields)
          return {} unless endpoint.outputs

          output_schema = {}
          endpoint.outputs.each do |output|
            next if output.kind == :status
            next unless include_field?(output.kind, fields)

            output_schema[output.kind] = {
              type: describe_type(output.type),
              description: output.respond_to?(:description) ? output.description : nil
            }
          end
          output_schema
        end

        def extract_error_fields(endpoint)
          return {} unless endpoint.errors

          error_schema = {}
          endpoint.errors.each do |error|
            # Handle both old hash format and new EnhancedError objects
            if error.respond_to?(:status_code)
              # New EnhancedError object
              error_schema[error.status_code] = {
                type: describe_type(error.type),
                description: error.description
              }
            elsif error.is_a?(Hash)
              # Old hash format
              error_schema[error[:code]] = {
                type: describe_type(error[:output]&.type),
                description: error[:description]
              }
            end
          end
          error_schema
        end

        def extract_examples(endpoint)
          examples = endpoint.metadata[:examples] || []
          examples.is_a?(Array) ? examples : [examples]
        end

        def include_field?(field_name, fields)
          return true if fields == :all
          return true if fields.nil?
          return true if fields.empty?

          fields = [fields] unless fields.is_a?(Array)
          fields.include?(field_name) || fields.include?(field_name.to_s) || fields.include?(field_name.to_sym)
        end

        def describe_type(type)
          return 'unknown' unless type

          case type
          when Types::String
            constraints = []
            constraints << "min_length: #{type.constraints[:min_length]}" if type.constraints[:min_length]
            constraints << "max_length: #{type.constraints[:max_length]}" if type.constraints[:max_length]
            constraints << "pattern: #{type.constraints[:pattern]}" if type.constraints[:pattern]

            base = 'string'
            constraints.empty? ? base : "#{base} (#{constraints.join(', ')})"
          when Types::Integer
            constraints = []
            constraints << "min: #{type.constraints[:minimum]}" if type.constraints[:minimum]
            constraints << "max: #{type.constraints[:maximum]}" if type.constraints[:maximum]

            base = 'integer'
            constraints.empty? ? base : "#{base} (#{constraints.join(', ')})"
          when Types::Array
            item_type = describe_type(type.item_type)
            "array of #{item_type}"
          when Types::Hash
            if type.field_types.any?
              fields = type.field_types.map { |k, v| "#{k}: #{describe_type(v)}" }.join(', ')
              "object {#{fields}}"
            else
              'object'
            end
          when Types::Optional
            "optional #{describe_type(type.wrapped_type)}"
          else
            type.class.name.split('::').last.downcase
          end
        end

        def format_schema_for_validation(schema)
          return 'No schema defined' if schema.empty?

          schema.map do |name, info|
            required_text = info[:required] ? 'REQUIRED' : 'optional'
            description_text = info[:description] ? " - #{info[:description]}" : ''
            "- #{name}: #{info[:type]} (#{required_text})#{description_text}"
          end.join("\n")
        end

        def format_schema_for_transformation(schema)
          return 'No schema defined' if schema.empty?

          schema.map do |name, info|
            description_text = info[:description] ? " // #{info[:description]}" : ''
            "#{name}: #{info[:type]}#{description_text}"
          end.join("\n")
        end

        def format_schema_for_analysis(schema_context)
          sections = []

          unless schema_context[:inputs].empty?
            sections << 'Input Fields:'
            sections += schema_context[:inputs].map { |name, info| "- #{name}: #{info[:type]}" }
          end

          unless schema_context[:outputs].empty?
            sections << "\nOutput Fields:"
            sections += schema_context[:outputs].map { |name, info| "- #{name}: #{info[:type]}" }
          end

          sections.join("\n")
        end

        def format_schema_for_documentation(schema_context)
          format_schema_for_analysis(schema_context)
        end

        def format_schema_for_testing(schema_context)
          format_schema_for_analysis(schema_context)
        end

        def format_schema_for_completion(schema)
          return 'No input fields defined' if schema.empty?

          schema.map do |name, info|
            required_text = info[:required] ? ' (required)' : ' (optional)'
            description_text = info[:description] ? " - #{info[:description]}" : ''
            "#{name}: #{info[:type]}#{required_text}#{description_text}"
          end.join("\n")
        end
      end

      # Export utility for different output formats
      class Exporter
        def initialize(instructions_data)
          @data = instructions_data
        end

        def to_json(*_args)
          require 'json'
          JSON.pretty_generate(@data)
        end

        def to_yaml
          require 'yaml'
          YAML.dump(@data)
        end

        def to_markdown
          md = []
          md << '# LLM Instructions'
          md << ''
          md << "Generated: #{@data[:meta][:generated_at]}"
          md << "Total Instructions: #{@data[:meta][:total_instructions]}"
          md << ''

          @data[:instructions].each do |instruction|
            md << "## #{instruction[:method]} #{instruction[:path]}"
            md << ''
            md << "**Purpose:** #{instruction[:purpose]}"
            md << ''
            md << "**Summary:** #{instruction[:metadata][:summary]}" if instruction[:metadata][:summary]
            md << ''
            md << '### Instruction'
            md << ''
            md << '```'
            md << instruction[:instruction]
            md << '```'
            md << ''
          end

          md.join("\n")
        end

        def to_prompt_files(output_dir)
          require 'fileutils'
          FileUtils.mkdir_p(output_dir)

          @data[:instructions].each do |instruction|
            filename = "#{instruction[:endpoint_id]}_#{instruction[:purpose]}.txt"
            filepath = File.join(output_dir, filename)

            File.write(filepath, instruction[:instruction])
          end

          "Exported #{@data[:instructions].size} prompt files to #{output_dir}"
        end
      end
    end
  end
end
