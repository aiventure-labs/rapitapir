# frozen_string_literal: true

require_relative 'types'

module RapiTapir
  # Schema definition and validation module
  # Provides tools for defining and validating data schemas
  module Schema
    # Error for schema validation failures
    # Raised when data does not conform to defined schema constraints
    class ValidationError < StandardError
      attr_reader :errors

      def initialize(errors)
        @errors = errors
        super(build_message)
      end

      private

      def build_message
        "Schema validation failed:\n#{errors.map { |error| "  - #{error}" }.join("\n")}"
      end
    end

    # Define a schema using a block
    def self.define(&)
      builder = SchemaBuilder.new
      builder.instance_eval(&)
      builder.build
    end

    # Validate a value against a type
    def self.validate!(value, type)
      result = type.validate(value)
      return value if result[:valid]

      raise ValidationError, result[:errors]
    end

    # Validate a value against a type, returning result
    def self.validate(value, type)
      type.validate(value)
    end

    # Coerce a value using a type
    def self.coerce(value, type)
      type.coerce(value)
    end

    # Create a type from a simplified definition
    def self.from_definition(definition)
      case definition
      when Symbol
        create_primitive_type(definition)
      when ::Hash
        create_type_from_hash(definition)
      when ::Array
        create_array_type_from_definition(definition)
      when Class
        # Assume it's already a type class
        definition
      else
        raise ArgumentError, "Unknown definition type: #{definition.class}"
      end
    end

    def self.create_type_from_hash(definition)
      if definition.keys == [:type] && definition[:type].is_a?(Symbol)
        create_primitive_type(definition[:type])
      else
        create_object_from_hash(definition)
      end
    end

    def self.create_array_type_from_definition(definition)
      raise ArgumentError, 'Array definition must have exactly one element type' unless definition.length == 1

      Types.array(from_definition(definition.first))
    end

    PRIMITIVE_TYPE_MAP = {
      string: -> { Types.string },
      integer: -> { Types.integer },
      float: -> { Types.float },
      boolean: -> { Types.boolean },
      date: -> { Types.date },
      datetime: -> { Types.datetime },
      uuid: -> { Types.uuid },
      email: -> { Types.email }
    }.freeze

    def self.create_primitive_type(type_symbol)
      type_creator = PRIMITIVE_TYPE_MAP[type_symbol]
      return type_creator.call if type_creator

      raise ArgumentError, "Unknown primitive type: #{type_symbol}"
    end

    def self.create_object_from_hash(hash_definition)
      object_type = Types.object

      hash_definition.each do |field_name, field_definition|
        field_type = from_definition(field_definition)
        object_type.field(field_name, field_type)
      end

      object_type
    end

    # Builder for constructing complex schemas from definitions
    # Provides a fluent interface for schema creation
    class SchemaBuilder
      def initialize
        @object_type = Types.object
      end

      def field(name, type_def, required: true, **options)
        type = Schema.from_definition(type_def)
        @object_type.field(name, type, required: required, **options)
      end

      def required_field(name, type_def, **options)
        field(name, type_def, required: true, **options)
      end

      def optional_field(name, type_def, **options)
        field(name, type_def, required: false, **options)
      end

      def build
        @object_type
      end
    end
  end
end
