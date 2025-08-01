# frozen_string_literal: true

module RapiTapir
  module Core
    # Core endpoint definition representing an HTTP API endpoint
    #
    # Encapsulates the definition of an HTTP endpoint including its method, path,
    # input parameters, output formats, error responses, and metadata.
    #
    # @example Create an endpoint
    #   endpoint = RapiTapir::Core::Endpoint.new(
    #     method: :get,
    #     path: '/users/{id}',
    #     inputs: [path_param(:id, :integer)],
    #     outputs: [json_output(user_schema)]
    #   )
    class Endpoint
      HTTP_METHODS = %i[get post put patch delete options head].freeze

      attr_reader :method, :path, :inputs, :outputs, :errors, :metadata

      def initialize(method: nil, path: nil, inputs: [], outputs: [], errors: [], metadata: {})
        @method = method
        @path = path
        @inputs = inputs.freeze
        @outputs = outputs.freeze
        @errors = errors.freeze
        @metadata = metadata.freeze
      end

      HTTP_METHODS.each do |http_method|
        define_singleton_method(http_method) do |path = nil|
          new(method: http_method, path: path)
        end
      end

      def in(input)
        validate_input!(input)
        copy_with(inputs: inputs + [input])
      end

      def out(output)
        validate_output!(output)
        copy_with(outputs: outputs + [output])
      end

      def error_out(code, output, **options)
        validate_status_code!(code)
        validate_output!(output)
        error_entry = { code: code, output: output }.merge(options)
        copy_with(errors: errors + [error_entry])
      end

      def with_metadata(**meta)
        copy_with(metadata: metadata.merge(meta))
      end

      def description(text)
        with_metadata(description: text)
      end

      def summary(text)
        with_metadata(summary: text)
      end

      def tag(name)
        with_metadata(tag: name)
      end

      def deprecated(flag = true)
        with_metadata(deprecated: flag)
      end

      # Validate input/output types for a given input/output hash
      def validate!(input_hash = {}, output_hash = {})
        validate_inputs!(input_hash)
        validate_outputs!(output_hash) unless output_hash.empty?
        true
      end

      def to_h
        {
          method: method,
          path: path,
          inputs: inputs.map(&:to_h),
          outputs: outputs.map(&:to_h),
          errors: errors,
          metadata: metadata
        }
      end

      private

      def copy_with(**changes)
        self.class.new(
          method: changes.fetch(:method, method),
          path: changes.fetch(:path, path),
          inputs: changes.fetch(:inputs, inputs),
          outputs: changes.fetch(:outputs, outputs),
          errors: changes.fetch(:errors, errors),
          metadata: changes.fetch(:metadata, metadata)
        )
      end

      def validate_input!(input)
        return if input.respond_to?(:kind) && input.respond_to?(:name) && input.respond_to?(:type)

        raise ArgumentError, 'Input must respond to :kind, :name, and :type'
      end

      def validate_output!(output)
        return if output.respond_to?(:kind) && output.respond_to?(:type)

        raise ArgumentError, 'Output must respond to :kind and :type'
      end

      def validate_status_code!(code)
        return if code.is_a?(Integer) && code >= 100 && code <= 599

        raise ArgumentError, "Invalid status code: #{code}. Must be an integer between 100-599"
      end

      def validate_inputs!(input_hash)
        inputs.each do |input|
          next unless input_hash.key?(input.name)

          unless input.valid_type?(input_hash[input.name])
            raise TypeError,
                  "Invalid type for input '#{input.name}': expected #{input.type}, got #{input_hash[input.name].class}"
          end
        end
      end

      def validate_outputs!(output_hash)
        outputs.each do |output|
          if output.type.is_a?(Hash)
            unless output.valid_type?(output_hash)
              raise TypeError, "Invalid output hash: expected #{output.type}, got #{output_hash}"
            end
          else
            output_hash.each do |k, v|
              unless output.valid_type?(v)
                raise TypeError, "Invalid type for output '#{k}': expected #{output.type}, got #{v.class}"
              end
            end
          end
        end
      end
    end
  end
end
