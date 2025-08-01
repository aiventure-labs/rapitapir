# frozen_string_literal: true

require_relative 'string'

module RapiTapir
  module Types
    class UUID < String
      UUID_PATTERN = /\A[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/i

      def initialize(**options)
        super(pattern: UUID_PATTERN, **options)
      end

      protected

      def validate_type(value)
        return ["Expected string, got #{value.class}"] unless value.is_a?(::String)
        return ['Invalid UUID format'] unless UUID_PATTERN.match?(value)

        []
      end

      def apply_constraints_to_schema(schema)
        super
        schema[:format] = 'uuid'
        schema[:pattern] = UUID_PATTERN.source
      end
    end
  end
end
