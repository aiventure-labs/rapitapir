# frozen_string_literal: true

require_relative 'types/base'
require_relative 'types/string'
require_relative 'types/integer'
require_relative 'types/float'
require_relative 'types/boolean'
require_relative 'types/date'
require_relative 'types/datetime'
require_relative 'types/uuid'
require_relative 'types/email'
require_relative 'types/array'
require_relative 'types/hash'
require_relative 'types/optional'
require_relative 'types/object'

module RapiTapir
  module Types
    class ValidationError < StandardError
      attr_reader :value, :type, :errors

      def initialize(value, type, errors = [])
        @value = value
        @type = type
        @errors = errors
        super(build_message)
      end

      private

      def build_message
        begin
          type_name = type.to_s
        rescue StandardError
          type_name = type.class.name
        end
        base = "Validation failed for value #{value.inspect} against type #{type_name}"
        return base if errors.empty?

        "#{base}:\n#{errors.map { |error| "  - #{error}" }.join("\n")}"
      end
    end

    class CoercionError < StandardError
      attr_reader :value, :type, :reason

      def initialize(value, type, reason = nil)
        @value = value
        @type = type
        @reason = reason
        super(build_message)
      end

      private

      def build_message
        base = "Cannot coerce #{value.inspect} to #{type}"
        reason ? "#{base}: #{reason}" : base
      end
    end

    # Convenience methods for creating types
    def self.string(**options)
      String.new(**options)
    end

    def self.integer(**options)
      Integer.new(**options)
    end

    def self.float(**options)
      Float.new(**options)
    end

    def self.boolean
      Boolean.new
    end

    def self.date(**options)
      Date.new(**options)
    end

    def self.datetime(**options)
      DateTime.new(**options)
    end

    def self.uuid
      UUID.new
    end

    def self.email
      Email.new
    end

    def self.array(item_type, **options)
      Array.new(item_type, **options)
    end

    def self.hash(field_types = {}, **options)
      Hash.new(field_types, **options)
    end

    def self.optional(type)
      Optional.new(type)
    end

    def self.object(&block)
      Object.new(&block)
    end
  end
end
