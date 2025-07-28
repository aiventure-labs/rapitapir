# frozen_string_literal: true

require_relative 'string'

module RapiTapir
  module Types
    class Email < String
      EMAIL_PATTERN = /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i

      def initialize(**options)
        super(pattern: EMAIL_PATTERN, format: :email, **options)
      end

      protected

      def validate_type(value)
        return ["Expected string, got #{value.class}"] unless value.is_a?(::String)
        return ["Invalid email format"] unless EMAIL_PATTERN.match?(value)
        []
      end

      def apply_constraints_to_schema(schema)
        super
        schema[:format] = 'email'
        schema[:pattern] = EMAIL_PATTERN.source
      end
    end
  end
end
