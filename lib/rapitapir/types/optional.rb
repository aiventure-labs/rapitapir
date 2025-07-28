# frozen_string_literal: true

require_relative 'base'

module RapiTapir
  module Types
    class Optional < Base
      attr_reader :wrapped_type

      def initialize(wrapped_type)
        @wrapped_type = wrapped_type
        super(optional: true)
      end

      def validate(value)
        # Optional types allow nil
        return validation_result(true, []) if value.nil?
        
        # Delegate to wrapped type
        wrapped_type.validate(value)
      end

      def coerce(value)
        return nil if value.nil?
        wrapped_type.coerce(value)
      end

      def required?
        false
      end

      def optional?
        true
      end

      def to_json_schema
        schema = wrapped_type.to_json_schema
        # Optional types are handled by not including them in the required array
        # at the parent level, so we don't need to modify the schema here
        schema
      end

      def to_s
        "Optional[#{wrapped_type}]"
      end

      def with_metadata(**meta)
        # Delegate metadata to wrapped type but maintain Optional wrapper
        Optional.new(wrapped_type.with_metadata(**meta))
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
