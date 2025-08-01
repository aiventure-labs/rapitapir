# frozen_string_literal: true

require_relative 'base'

module RapiTapir
  module Types
    # Hash type for validating hash/object structures with schema definitions
    # Validates hash keys and values according to defined schemas
    class Hash < Base
      attr_reader :field_types

      def initialize(field_types = {}, additional_properties: true, **options)
        @field_types = field_types.freeze
        super(
          additional_properties: additional_properties,
          **options
        )
      end

      protected

      def validate_type(value)
        return ["Expected hash/object, got #{value.class}"] unless value.is_a?(::Hash)

        []
      end

      def validate_constraints(value)
        errors = []

        errors.concat(validate_defined_fields(value))
        errors.concat(validate_additional_properties(value))

        errors
      end

      def validate_defined_fields(value)
        errors = []

        field_types.each do |field_name, field_type|
          field_value = extract_field_value(value, field_name)
          field_result = field_type.validate(field_value)
          next if field_result[:valid]

          field_result[:errors].each do |error|
            errors << "Field '#{field_name}': #{error}"
          end
        end

        errors
      end

      def validate_additional_properties(value)
        return [] if constraints[:additional_properties]

        expected_keys = field_types.keys.map { |k| [k, k.to_s, k.to_sym] }.flatten.uniq
        unexpected_keys = value.keys - expected_keys
        return [] if unexpected_keys.empty?

        ["Unexpected fields: #{unexpected_keys.join(', ')}"]
      end

      def extract_field_value(value, field_name)
        value[field_name] || value[field_name.to_s] || value[field_name.to_sym]
      end

      def coerce_value(value)
        case value
        when ::Hash
          coerce_hash_value(value)
        when ::String
          coerce_json_string_value(value)
        else
          raise CoercionError.new(value, 'Hash', 'Value cannot be converted to hash')
        end
      rescue JSON::ParserError => e
        raise CoercionError.new(value, 'Hash', "Invalid JSON: #{e.message}")
      end

      private

      def coerce_hash_value(value)
        coerced = {}

        # Coerce defined fields
        coerce_defined_fields(value, coerced)

        # Include additional properties if allowed
        coerce_additional_properties(value, coerced) if constraints[:additional_properties]

        coerced
      end

      def coerce_defined_fields(value, coerced)
        field_types.each do |field_name, field_type|
          field_value = find_field_value(value, field_name)
          coerced[field_name] = field_type.coerce(field_value) if field_value || !field_type.optional?
        end
      end

      def find_field_value(value, field_name)
        value[field_name] || value[field_name.to_s] || value[field_name.to_sym]
      end

      def coerce_additional_properties(value, coerced)
        additional_keys = value.keys - field_types.keys.map { |k| [k, k.to_s, k.to_sym] }.flatten
        additional_keys.each do |key|
          coerced[key] = value[key]
        end
      end

      def coerce_json_string_value(value)
        # Try to parse as JSON
        require 'json'
        parsed = JSON.parse(value)
        raise CoercionError.new(value, 'Hash', 'JSON string did not parse to hash') unless parsed.is_a?(::Hash)

        coerce_value(parsed)
      end

      def json_type
        'object'
      end

      def apply_constraints_to_schema(schema)
        super

        if field_types.any?
          schema[:properties] = {}
          required_fields = []

          field_types.each do |field_name, field_type|
            schema[:properties][field_name] = field_type.to_json_schema
            required_fields << field_name unless field_type.optional?
          end

          schema[:required] = required_fields unless required_fields.empty?
        end

        schema[:additionalProperties] = constraints[:additional_properties]
      end

      def to_s
        if field_types.empty?
          'Hash'
        else
          field_strs = field_types.map { |k, v| "#{k}: #{v}" }
          "Hash{#{field_strs.join(', ')}}"
        end
      end
    end
  end
end
