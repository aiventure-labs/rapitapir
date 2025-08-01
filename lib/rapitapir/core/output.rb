# frozen_string_literal: true

require 'json'

module RapiTapir
  module Core
    # Output format definition for HTTP endpoints
    #
    # Represents different types of response outputs that an endpoint can produce,
    # including JSON responses, XML responses, status codes, and headers.
    #
    # @example JSON response
    #   RapiTapir::Core::Output.new(kind: :json, type: user_schema)
    #
    # @example Status response
    #   RapiTapir::Core::Output.new(kind: :status, type: 404)
    class Output
      VALID_KINDS = %i[json xml status header].freeze

      attr_reader :kind, :type, :options

      def initialize(kind:, type:, options: {})
        @kind = kind
        @type = type
        validate_kind!(kind)
        validate_type!(type)
        @options = options.freeze
      end

      def valid_type?(value)
        case type
        when :string then value.is_a?(String)
        when :integer then validate_integer_type(value)
        when :float then validate_float_type(value)
        when :boolean then validate_boolean_type(value)
        when Hash then validate_hash_schema(value)
        when Class then value.is_a?(type)
        else true # Accept any for custom types and status codes
        end
      end

      def validate_integer_type(value)
        value.is_a?(Integer) || value.is_a?(Float)
      end

      def validate_float_type(value)
        value.is_a?(Float) || value.is_a?(Integer)
      end

      def serialize(value)
        case kind
        when :json then serialize_json(value)
        when :xml then serialize_xml(value)
        when :status then value.to_i
        when :header then value.to_s
        else value
        end
      end

      def to_h
        {
          kind: kind,
          type: type,
          options: options
        }
      end

      private

      def validate_kind!(kind)
        return if VALID_KINDS.include?(kind)

        raise ArgumentError, "Invalid kind: #{kind}. Must be one of #{VALID_KINDS}"
      end

      def validate_type!(type)
        case kind
        when :status
          validate_status_type!(type)
        when :json, :xml
          # Allow any type for JSON/XML bodies
        when :header
          validate_header_type!(type)
        end
      end

      def validate_status_type!(type)
        return if type.is_a?(Integer) && type >= 100 && type <= 599

        raise ArgumentError, "Status type must be an integer between 100-599, got: #{type}"
      end

      def validate_header_type!(type)
        return if [:string, String].include?(type) || type.is_a?(Class)

        raise ArgumentError, "Header type must be :string or a Class, got: #{type}"
      end

      def validate_hash_schema(value)
        return false unless value.is_a?(Hash)
        return true unless type.is_a?(Hash) # If type is not a hash schema, accept any hash

        type.all? do |key, expected_type|
          validate_field_type(value[key], expected_type)
        end
      end

      def validate_field_type(field_value, expected_type)
        case expected_type
        when :string then field_value.is_a?(String)
        when :integer then field_value.is_a?(Integer)
        when :float then validate_numeric_type(field_value)
        when :boolean then validate_boolean_type(field_value)
        when :date then validate_date_type(field_value)
        when :datetime then validate_datetime_type(field_value)
        else true
        end
      end

      def validate_numeric_type(field_value)
        field_value.is_a?(Float) || field_value.is_a?(Integer)
      end

      def validate_boolean_type(field_value)
        [true, false].include?(field_value)
      end

      def validate_date_type(field_value)
        field_value.is_a?(Date) || field_value.is_a?(String)
      end

      def validate_datetime_type(field_value)
        field_value.is_a?(DateTime) || field_value.is_a?(String)
      end

      def serialize_json(value)
        case value
        when String then value
        else JSON.generate(value)
        end
      rescue JSON::GeneratorError, JSON::NestingError => e
        raise TypeError, "Cannot serialize value to JSON: #{e.message}"
      end

      def serialize_xml(value)
        # Basic XML serialization - would need a proper XML library in practice
        case value
        when String then value
        when Hash then hash_to_xml(value)
        else value.to_s
        end
      end

      def hash_to_xml(hash, root = 'root')
        xml = "<#{root}>"
        hash.each do |key, value|
          xml += "<#{key}>#{value}</#{key}>"
        end
        xml += "</#{root}>"
        xml
      end
    end
  end
end
