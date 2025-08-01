# frozen_string_literal: true

require_relative 'types'

module RapiTapir
  module Schema
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
    def self.define(&block)
      builder = SchemaBuilder.new
      builder.instance_eval(&block)
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
        if definition.keys == [:type] && definition[:type].is_a?(Symbol)
          create_primitive_type(definition[:type])
        else
          create_object_from_hash(definition)
        end
      when ::Array
        raise ArgumentError, 'Array definition must have exactly one element type' unless definition.length == 1

        Types.array(from_definition(definition.first))

      when Class
        # Assume it's already a type class
        definition
      else
        raise ArgumentError, "Unknown definition type: #{definition.class}"
      end
    end

    def self.create_primitive_type(type_symbol)
      case type_symbol
      when :string then Types.string
      when :integer then Types.integer
      when :float then Types.float
      when :boolean then Types.boolean
      when :date then Types.date
      when :datetime then Types.datetime
      when :uuid then Types.uuid
      when :email then Types.email
      else
        raise ArgumentError, "Unknown primitive type: #{type_symbol}"
      end
    end

    def self.create_object_from_hash(hash_definition)
      object_type = Types.object

      hash_definition.each do |field_name, field_definition|
        field_type = from_definition(field_definition)
        object_type.field(field_name, field_type)
      end

      object_type
    end

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
