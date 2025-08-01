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

        if constraints[:minimum] && value < constraints[:minimum]
          errors << "Value #{value} is below minimum #{constraints[:minimum]}"
        end

        if constraints[:maximum] && value > constraints[:maximum]
          errors << "Value #{value} exceeds maximum #{constraints[:maximum]}"
        end

        if constraints[:exclusive_minimum] && value <= constraints[:exclusive_minimum]
          errors << "Value #{value} must be greater than #{constraints[:exclusive_minimum]}"
        end

        if constraints[:exclusive_maximum] && value >= constraints[:exclusive_maximum]
          errors << "Value #{value} must be less than #{constraints[:exclusive_maximum]}"
        end

        errors
      end

      def validate_multiple_constraint(value)
        errors = []

        if constraints[:multiple_of] && (value % constraints[:multiple_of]) != 0
          errors << "Value #{value} is not a multiple of #{constraints[:multiple_of]}"
        end

        errors
      end

      def coerce_value(value)
        case value
        when ::Integer then value
        when ::Float then value.to_i
        when ::String
          Kernel.Integer(value.strip)
        when true then 1
        when false then 0
        else
          unless value.respond_to?(:to_i)
            raise CoercionError.new(value, 'Integer', 'Value cannot be converted to integer')
          end

          value.to_i

        end
      rescue ArgumentError => e
        raise CoercionError.new(value, 'Integer', e.message)
      end

      def json_type
        'integer'
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
