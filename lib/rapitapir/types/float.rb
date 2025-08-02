# frozen_string_literal: true

require_relative 'base'

module RapiTapir
  module Types
    # Float type for validating floating-point numbers with range constraints
    # Supports minimum, maximum, and multiple validation rules
    class Float < Base
      protected

      def validate_type(value)
        return [] if value.is_a?(::Float) || value.is_a?(::Integer)

        ["Expected number (float or integer), got #{value.class}"]
      end

      def validate_constraints(value)
        errors = []
        float_value = value.to_f

        errors.concat(validate_range_constraints(float_value))
        errors.concat(validate_multiple_constraint(float_value))

        errors
      end

      private

      def validate_range_constraints(float_value)
        errors = []

        errors.concat(validate_minimum_constraints(float_value))
        errors.concat(validate_maximum_constraints(float_value))

        errors
      end

      def validate_minimum_constraints(float_value)
        errors = []

        if constraints[:minimum] && float_value < constraints[:minimum]
          errors << "Value #{float_value} is below minimum #{constraints[:minimum]}"
        end

        if constraints[:exclusive_minimum] && float_value <= constraints[:exclusive_minimum]
          errors << "Value #{float_value} must be greater than #{constraints[:exclusive_minimum]}"
        end

        errors
      end

      def validate_maximum_constraints(float_value)
        errors = []

        if constraints[:maximum] && float_value > constraints[:maximum]
          errors << "Value #{float_value} exceeds maximum #{constraints[:maximum]}"
        end

        if constraints[:exclusive_maximum] && float_value >= constraints[:exclusive_maximum]
          errors << "Value #{float_value} must be less than #{constraints[:exclusive_maximum]}"
        end

        errors
      end

      def validate_multiple_constraint(float_value)
        errors = []

        if constraints[:multiple_of] && (float_value % constraints[:multiple_of]) != 0
          errors << "Value #{float_value} is not a multiple of #{constraints[:multiple_of]}"
        end

        errors
      end

      def coerce_value(value)
        case value
        when ::Float then value
        when ::Integer then value.to_f
        when ::String then coerce_string_to_float(value)
        when true, false then coerce_boolean_to_float(value)
        else
          coerce_other_to_float(value)
        end
      rescue ArgumentError => e
        raise CoercionError.new(value, 'Float', e.message)
      end

      def coerce_string_to_float(value)
        Kernel.Float(value.strip)
      end

      def coerce_boolean_to_float(value)
        value ? 1.0 : 0.0
      end

      def coerce_other_to_float(value)
        raise CoercionError.new(value, 'Float', 'Value cannot be converted to float') unless value.respond_to?(:to_f)

        value.to_f
      end

      def json_type
        'number'
      end

      def apply_constraints_to_schema(schema)
        super
        apply_range_constraints_to_schema(schema)
        apply_multiple_constraint_to_schema(schema)
      end

      def apply_range_constraints_to_schema(schema)
        apply_minimum_constraints_to_schema(schema)
        apply_maximum_constraints_to_schema(schema)
      end

      def apply_minimum_constraints_to_schema(schema)
        schema[:minimum] = constraints[:minimum] if constraints[:minimum]
        schema[:exclusiveMinimum] = constraints[:exclusive_minimum] if constraints[:exclusive_minimum]
      end

      def apply_maximum_constraints_to_schema(schema)
        schema[:maximum] = constraints[:maximum] if constraints[:maximum]
        schema[:exclusiveMaximum] = constraints[:exclusive_maximum] if constraints[:exclusive_maximum]
      end

      def apply_multiple_constraint_to_schema(schema)
        schema[:multipleOf] = constraints[:multiple_of] if constraints[:multiple_of]
      end
    end
  end
end
