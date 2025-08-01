# frozen_string_literal: true

require_relative 'base'

module RapiTapir
  module Types
    class Object < Base
      attr_reader :fields

      def initialize(**options, &block)
        @fields = {}
        super(**options)

        return unless block_given?

        builder = ObjectBuilder.new(self)
        builder.instance_eval(&block)
      end

      def field(name, type, required: true, **options)
        field_type = required ? type : ::RapiTapir::Types::Optional.new(type)
        field_type = field_type.with_metadata(**options) if options.any?
        @fields[name.to_sym] = field_type
        self
      end

      def required_field(name, type, **options)
        field(name, type, required: true, **options)
      end

      def optional_field(name, type, **options)
        field(name, type, required: false, **options)
      end

      protected

      def validate_type(value)
        return ["Expected hash/object, got #{value.class}"] unless value.is_a?(::Hash)

        []
      end

      def validate_constraints(value)
        errors = []

        # Validate each defined field
        fields.each do |field_name, field_type|
          field_value = extract_field_value(value, field_name)

          field_result = field_type.validate(field_value)
          next if field_result[:valid]

          field_result[:errors].each do |error|
            errors << "Field '#{field_name}': #{error}"
          end
        end

        errors
      end

      def coerce_value(value)
        case value
        when ::Hash
          coerced = {}

          # Coerce each defined field
          fields.each do |field_name, field_type|
            field_value = extract_field_value(value, field_name)

            coerced[field_name] = field_type.coerce(field_value) if field_value || !field_type.optional?
          end

          coerced
        when ::String
          # Try to parse as JSON
          require 'json'
          parsed = JSON.parse(value)
          raise CoercionError.new(value, 'Object', 'JSON string did not parse to object') unless parsed.is_a?(::Hash)

          coerce_value(parsed)
        else
          raise CoercionError.new(value, 'Object', 'Value cannot be converted to object')
        end
      rescue JSON::ParserError => e
        raise CoercionError.new(value, 'Object', "Invalid JSON: #{e.message}")
      end

      def json_type
        'object'
      end

      def apply_constraints_to_schema(schema)
        super

        if fields.any?
          schema[:properties] = {}
          required_fields = []

          fields.each do |field_name, field_type|
            schema[:properties][field_name] = field_type.to_json_schema
            required_fields << field_name unless field_type.optional?
          end

          schema[:required] = required_fields unless required_fields.empty?
        end

        schema[:additionalProperties] = false # Objects are strict by default
      end

      def to_s
        if fields.empty?
          'Object'
        else
          field_strs = fields.map { |name, type| "#{name}: #{type}" }
          "Object{#{field_strs.join(', ')}}"
        end
      end

      private

      def extract_field_value(hash, field_name)
        # Try different key formats: symbol, string, and string version of symbol
        hash[field_name] || hash[field_name.to_s] || hash[field_name.to_sym]
      end

      class ObjectBuilder
        def initialize(object_type)
          @object_type = object_type
        end

        def field(name, type, required: true, **options)
          @object_type.field(name, type, required: required, **options)
        end

        def required_field(name, type, **options)
          @object_type.required_field(name, type, **options)
        end

        def optional_field(name, type, **options)
          @object_type.optional_field(name, type, **options)
        end
      end
    end
  end
end
