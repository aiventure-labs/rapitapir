# frozen_string_literal: true

require_relative 'base'

module RapiTapir
  module Types
    # Array type for validating array values with element type constraints
    # Validates arrays with specific element types and size constraints
    class Array < Base
      attr_reader :item_type

      def initialize(item_type, min_items: nil, max_items: nil, unique_items: false, **options)
        @item_type = item_type
        super(
          min_items: min_items,
          max_items: max_items,
          unique_items: unique_items,
          **options
        )
      end

      protected

      def validate_type(value)
        return ["Expected array, got #{value.class}"] unless value.is_a?(::Array)

        []
      end

      def validate_constraints(value)
        errors = []

        errors.concat(validate_length_constraints(value))
        errors.concat(validate_uniqueness_constraint(value))
        errors.concat(validate_item_types(value))

        errors
      end

      def validate_length_constraints(value)
        errors = []

        errors.concat(validate_min_items_constraint(value))
        errors.concat(validate_max_items_constraint(value))

        errors
      end

      def validate_min_items_constraint(value)
        return [] unless constraints[:min_items] && value.length < constraints[:min_items]

        ["Array length #{value.length} is below minimum #{constraints[:min_items]}"]
      end

      def validate_max_items_constraint(value)
        return [] unless constraints[:max_items] && value.length > constraints[:max_items]

        ["Array length #{value.length} exceeds maximum #{constraints[:max_items]}"]
      end

      def validate_uniqueness_constraint(value)
        return [] unless constraints[:unique_items] && value.uniq.length != value.length

        ['Array contains duplicate items but must be unique']
      end

      def validate_item_types(value)
        errors = []

        value.each_with_index do |item, index|
          item_result = item_type.validate(item)
          next if item_result[:valid]

          item_result[:errors].each do |error|
            errors << "Item at index #{index}: #{error}"
          end
        end

        errors
      end

      def coerce_value(value)
        case value
        when ::Array
          coerce_array_value(value)
        when ::String
          coerce_string_value(value)
        else
          coerce_single_value(value)
        end
      rescue JSON::ParserError => e
        raise CoercionError.new(value, 'Array', "Invalid JSON: #{e.message}")
      rescue StandardError => e
        raise CoercionError.new(value, 'Array', e.message)
      end

      def coerce_array_value(value)
        value.map { |item| item_type.coerce(item) }
      end

      def coerce_string_value(value)
        # Try to parse as JSON array
        require 'json'
        parsed = JSON.parse(value)
        raise CoercionError.new(value, 'Array', 'JSON string did not parse to array') unless parsed.is_a?(::Array)

        parsed.map { |item| item_type.coerce(item) }
      end

      def coerce_single_value(value)
        # Wrap single value in array
        [item_type.coerce(value)]
      end

      def json_type
        'array'
      end

      def apply_constraints_to_schema(schema)
        super
        apply_array_specific_constraints(schema)
      end

      def apply_array_specific_constraints(schema)
        schema[:items] = item_type.to_json_schema
        apply_size_constraints(schema)
        apply_uniqueness_constraint(schema)
      end

      def apply_size_constraints(schema)
        schema[:minItems] = constraints[:min_items] if constraints[:min_items]
        schema[:maxItems] = constraints[:max_items] if constraints[:max_items]
      end

      def apply_uniqueness_constraint(schema)
        schema[:uniqueItems] = constraints[:unique_items] if constraints[:unique_items]
      end

      def to_s
        item_type_str = format_item_type_string
        constraint_part = format_constraints_string
        "Array[#{item_type_str}]#{constraint_part}"
      end

      def format_item_type_string
        item_type.respond_to?(:to_s) ? item_type.to_s : item_type.class.name
      end

      def format_constraints_string
        constraint_strs = build_constraint_strings
        constraint_strs.empty? ? '' : "(#{constraint_strs.join(', ')})"
      end

      def build_constraint_strings
        constraint_strs = []
        constraint_strs << "min_items: #{constraints[:min_items]}" if constraints[:min_items]
        constraint_strs << "max_items: #{constraints[:max_items]}" if constraints[:max_items]
        constraint_strs << "unique: #{constraints[:unique_items]}" if constraints[:unique_items]
        constraint_strs
      end
    end
  end
end
