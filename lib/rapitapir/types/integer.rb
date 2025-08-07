# frozen_string_literal: true

require_relative 'base'

module RapiTapir
  module Types
    # Integer type with numeric constraints
    #
    # Validates integer values with optional constraints for minimum/maximum values,
    # exclusive bounds, and multiple-of validation.
    #
    # @example Basic integer
    #   RapiTapir::Types.integer
    #
    # @example Integer with constraints
    #   RapiTapir::Types.integer(minimum: 0, maximum: 100, multiple_of: 5)
    class Integer < Base
      protected

      def validate_type(value)
        return ["Expected integer, got #{value.class}"] unless value.is_a?(::Integer)

        []
      end

      def validate_constraints(value)
        errors = []

        errors.concat(validate_range_constraints(value))
        errors.concat(validate_multiple_constraint(value))

        errors
      end

      private

      def validate_range_constraints(value)
        errors = []

        errors.concat(validate_minimum_constraints(value))
        errors.concat(validate_maximum_constraints(value))

        errors
      end

      def validate_minimum_constraints(value)
        errors = []

        errors << "Value #{value} is below minimum #{constraints[:minimum]}" if constraints[:minimum] && value < constraints[:minimum]

        if constraints[:exclusive_minimum] && value <= constraints[:exclusive_minimum]
          errors << "Value #{value} must be greater than #{constraints[:exclusive_minimum]}"
        end

        errors
      end

      def validate_maximum_constraints(value)
        errors = []

        errors << "Value #{value} exceeds maximum #{constraints[:maximum]}" if constraints[:maximum] && value > constraints[:maximum]

        if constraints[:exclusive_maximum] && value >= constraints[:exclusive_maximum]
          errors << "Value #{value} must be less than #{constraints[:exclusive_maximum]}"
        end

        errors
      end

      def validate_multiple_constraint(value)
        errors = []

        errors << "Value #{value} is not a multiple of #{constraints[:multiple_of]}" if constraints[:multiple_of] && (value % constraints[:multiple_of]) != 0

        errors
      end

      def coerce_value(value)
        case value
        when ::Integer then value
        when ::Float then value.to_i
        when ::String then coerce_string_to_integer(value)
        when true, false then coerce_boolean_to_integer(value)
        else
          coerce_other_to_integer(value)
        end
      rescue ArgumentError => e
        raise CoercionError.new(value, 'Integer', e.message)
      end

      def coerce_string_to_integer(value)
        Kernel.Integer(value.strip)
      end

      def coerce_boolean_to_integer(value)
        value ? 1 : 0
      end

      def coerce_other_to_integer(value)
        raise CoercionError.new(value, 'Integer', 'Value cannot be converted to integer') unless value.respond_to?(:to_i)

        value.to_i
      end

      def json_type
        'integer'
      end

      def apply_constraints_to_schema(schema)
        super
        apply_range_constraints_to_schema(schema)
        apply_multiple_constraint_to_schema(schema)
      end

      def apply_range_constraints_to_schema(schema)
        apply_minimum_constraints(schema)
        apply_maximum_constraints(schema)
      end

      def apply_minimum_constraints(schema)
        schema[:minimum] = constraints[:minimum] if constraints[:minimum]
        schema[:exclusiveMinimum] = constraints[:exclusive_minimum] if constraints[:exclusive_minimum]
      end

      def apply_maximum_constraints(schema)
        schema[:maximum] = constraints[:maximum] if constraints[:maximum]
        schema[:exclusiveMaximum] = constraints[:exclusive_maximum] if constraints[:exclusive_maximum]
      end

      def apply_multiple_constraint_to_schema(schema)
        schema[:multipleOf] = constraints[:multiple_of] if constraints[:multiple_of]
      end
    end
  end
end
