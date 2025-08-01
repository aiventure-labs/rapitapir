# frozen_string_literal: true

require_relative 'base'

module RapiTapir
  module Types
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

        if constraints[:min_items] && value.length < constraints[:min_items]
          errors << "Array length #{value.length} is below minimum #{constraints[:min_items]}"
        end

        if constraints[:max_items] && value.length > constraints[:max_items]
          errors << "Array length #{value.length} exceeds maximum #{constraints[:max_items]}"
        end

        if constraints[:unique_items] && value.uniq.length != value.length
          errors << 'Array contains duplicate items but must be unique'
        end

        # Validate each item
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
          value.map { |item| item_type.coerce(item) }
        when ::String
          # Try to parse as JSON array
          require 'json'
          parsed = JSON.parse(value)
          raise CoercionError.new(value, 'Array', 'JSON string did not parse to array') unless parsed.is_a?(::Array)

          parsed.map { |item| item_type.coerce(item) }
        else
          # Wrap single value in array
          [item_type.coerce(value)]
        end
      rescue JSON::ParserError => e
        raise CoercionError.new(value, 'Array', "Invalid JSON: #{e.message}")
      rescue StandardError => e
        raise CoercionError.new(value, 'Array', e.message)
      end

      def json_type
        'array'
      end

      def apply_constraints_to_schema(schema)
        super
        schema[:items] = item_type.to_json_schema
        schema[:minItems] = constraints[:min_items] if constraints[:min_items]
        schema[:maxItems] = constraints[:max_items] if constraints[:max_items]
        schema[:uniqueItems] = constraints[:unique_items] if constraints[:unique_items]
      end

      def to_s
        item_type_str = item_type.respond_to?(:to_s) ? item_type.to_s : item_type.class.name
        constraint_strs = []
        constraint_strs << "min_items: #{constraints[:min_items]}" if constraints[:min_items]
        constraint_strs << "max_items: #{constraints[:max_items]}" if constraints[:max_items]
        constraint_strs << "unique: #{constraints[:unique_items]}" if constraints[:unique_items]

        constraint_part = constraint_strs.empty? ? '' : "(#{constraint_strs.join(', ')})"
        "Array[#{item_type_str}]#{constraint_part}"
      end
    end
  end
end
