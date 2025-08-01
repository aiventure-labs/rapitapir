# frozen_string_literal: true

require_relative 'base'

module RapiTapir
  module Types
    class Float < Base
      def initialize(minimum: nil, maximum: nil, exclusive_minimum: nil, exclusive_maximum: nil, multiple_of: nil,
                     **options)
        super
      end

      protected

      def validate_type(value)
        return [] if value.is_a?(::Float) || value.is_a?(::Integer)

        ["Expected number (float or integer), got #{value.class}"]
      end

      def validate_constraints(value)
        errors = []
        float_value = value.to_f

        if constraints[:minimum] && float_value < constraints[:minimum]
          errors << "Value #{float_value} is below minimum #{constraints[:minimum]}"
        end

        if constraints[:maximum] && float_value > constraints[:maximum]
          errors << "Value #{float_value} exceeds maximum #{constraints[:maximum]}"
        end

        if constraints[:exclusive_minimum] && float_value <= constraints[:exclusive_minimum]
          errors << "Value #{float_value} must be greater than #{constraints[:exclusive_minimum]}"
        end

        if constraints[:exclusive_maximum] && float_value >= constraints[:exclusive_maximum]
          errors << "Value #{float_value} must be less than #{constraints[:exclusive_maximum]}"
        end

        if constraints[:multiple_of] && (float_value % constraints[:multiple_of]) != 0
          errors << "Value #{float_value} is not a multiple of #{constraints[:multiple_of]}"
        end

        errors
      end

      def coerce_value(value)
        case value
        when ::Float then value
        when ::Integer then value.to_f
        when ::String
          Kernel.Float(value.strip)
        when true then 1.0
        when false then 0.0
        else
          raise CoercionError.new(value, 'Float', 'Value cannot be converted to float') unless value.respond_to?(:to_f)

          value.to_f

        end
      rescue ArgumentError => e
        raise CoercionError.new(value, 'Float', e.message)
      end

      def json_type
        'number'
      end

      def apply_constraints_to_schema(schema)
        super
        schema[:minimum] = constraints[:minimum] if constraints[:minimum]
        schema[:maximum] = constraints[:maximum] if constraints[:maximum]
        schema[:exclusiveMinimum] = constraints[:exclusive_minimum] if constraints[:exclusive_minimum]
        schema[:exclusiveMaximum] = constraints[:exclusive_maximum] if constraints[:exclusive_maximum]
        schema[:multipleOf] = constraints[:multiple_of] if constraints[:multiple_of]
      end
    end
  end
end
