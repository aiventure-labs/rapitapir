# frozen_string_literal: true

module RapiTapir
  module Types
    class Base
      attr_reader :constraints, :metadata

      def initialize(**constraints)
        @constraints = constraints.freeze
        @metadata = {}
      end

      # Validate a value against this type
      def validate(value)
        errors = []
        
        # Check if value is required but nil
        if value.nil? && required?
          errors << "Value is required but got nil"
          return validation_result(false, errors)
        end

        # Allow nil for optional types
        return validation_result(true, []) if value.nil? && !required?

        # Perform type-specific validation
        type_errors = validate_type(value)
        errors.concat(type_errors)

        # Perform constraint validation
        constraint_errors = validate_constraints(value)
        errors.concat(constraint_errors)

        validation_result(errors.empty?, errors)
      end

      # Coerce a value to this type
      def coerce(value)
        return nil if value.nil? && !required?
        
        if value.nil? && required?
          raise CoercionError.new(value, self.class.name, "Required value cannot be nil")
        end

        coerce_value(value)
      end

      # Check if this type is required
      def required?
        !constraints.fetch(:optional, false)
      end

      # Check if this type is optional
      def optional?
        constraints.fetch(:optional, false)
      end

      # Get the JSON Schema representation
      def to_json_schema
        schema = base_json_schema
        apply_constraints_to_schema(schema)
        schema
      end

      # Get a string representation
      def to_s
        constraint_strs = constraints.map { |k, v| "#{k}: #{v}" }
        constraint_part = constraint_strs.empty? ? "" : "(#{constraint_strs.join(', ')})"
        "#{self.class.name.split('::').last}#{constraint_part}"
      end

      # Add metadata to this type
      def with_metadata(**meta)
        dup.tap { |type| type.instance_variable_set(:@metadata, metadata.merge(meta)) }
      end

      # Add description to this type
      def description(text)
        with_metadata(description: text)
      end

      # Add example to this type
      def example(value)
        with_metadata(example: value)
      end

      protected

      # Override in subclasses to implement type-specific validation
      def validate_type(value)
        []
      end

      # Override in subclasses to implement constraint validation
      def validate_constraints(value)
        []
      end

      # Override in subclasses to implement value coercion
      def coerce_value(value)
        value
      end

      # Override in subclasses to provide base JSON schema
      def base_json_schema
        { type: json_type }
      end

      # Override in subclasses to specify JSON type
      def json_type
        'object'
      end

      # Apply constraints to JSON schema
      def apply_constraints_to_schema(schema)
        # Add common constraint mappings here
        schema[:description] = metadata[:description] if metadata[:description]
        schema[:example] = metadata[:example] if metadata[:example]
      end

      private

      def validation_result(valid, errors)
        {
          valid: valid,
          errors: errors,
          value_errors: errors.empty? ? [] : [ValidationError.new(nil, self, errors)]
        }
      end
    end
  end
end
