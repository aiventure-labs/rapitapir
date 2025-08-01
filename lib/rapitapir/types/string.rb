# frozen_string_literal: true

require_relative 'base'

module RapiTapir
  module Types
    # String type with length and format validation
    #
    # Validates string values with optional constraints for length, pattern matching,
    # and format validation (email, URI, etc.).
    #
    # @example Basic string
    #   RapiTapir::Types.string
    #
    # @example String with constraints
    #   RapiTapir::Types.string(min_length: 1, max_length: 255, format: :email)
    class String < Base
      def initialize(min_length: nil, max_length: nil, pattern: nil, format: nil, **options)
        super
      end

      protected

      def validate_type(value)
        return ["Expected string, got #{value.class}"] unless value.is_a?(::String)

        []
      end

      def validate_constraints(value)
        errors = []

        errors.concat(validate_length_constraints(value))
        errors.concat(validate_pattern_constraint(value))
        errors.concat(validate_format_constraint(value))

        errors
      end

      def validate_length_constraints(value)
        errors = []

        errors.concat(validate_min_length_constraint(value))
        errors.concat(validate_max_length_constraint(value))

        errors
      end

      def validate_min_length_constraint(value)
        return [] unless constraints[:min_length] && value.length < constraints[:min_length]

        ["String length #{value.length} is below minimum #{constraints[:min_length]}"]
      end

      def validate_max_length_constraint(value)
        return [] unless constraints[:max_length] && value.length > constraints[:max_length]

        ["String length #{value.length} exceeds maximum #{constraints[:max_length]}"]
      end

      def validate_pattern_constraint(value)
        return [] unless constraints[:pattern] && !constraints[:pattern].match?(value)

        ["String '#{value}' does not match pattern #{constraints[:pattern].inspect}"]
      end

      def validate_format_constraint(value)
        return [] unless constraints[:format]

        validate_format(value, constraints[:format])
      end

      def coerce_value(value)
        case value
        when ::String then value
        when Symbol, Numeric then value.to_s
        else
          raise CoercionError.new(value, 'String', 'Value does not respond to to_s') unless value.respond_to?(:to_s)

          value.to_s

        end
      end

      def json_type
        'string'
      end

      def apply_constraints_to_schema(schema)
        super
        apply_length_constraints_to_schema(schema)
        apply_pattern_and_format_constraints_to_schema(schema)
      end

      def apply_length_constraints_to_schema(schema)
        schema[:minLength] = constraints[:min_length] if constraints[:min_length]
        schema[:maxLength] = constraints[:max_length] if constraints[:max_length]
      end

      def apply_pattern_and_format_constraints_to_schema(schema)
        schema[:pattern] = constraints[:pattern].source if constraints[:pattern]
        schema[:format] = constraints[:format].to_s if constraints[:format]
      end

      private

      def validate_format(value, format)
        case format
        when :email
          validate_email_format(value)
        when :uri, :url
          validate_uri_format(value)
        when :uuid
          validate_uuid_format(value)
        when :date
          validate_date_format(value)
        when :datetime, :'date-time'
          validate_datetime_format(value)
        when :ipv4
          validate_ipv4_format(value)
        when :ipv6
          validate_ipv6_format(value)
        else
          []
        end
      end

      def validate_email_format(value)
        # Basic email validation - in production, consider using a more robust library
        email_pattern = /\A[\w+\-.]+@[a-z\d-]+(\.[a-z\d-]+)*\.[a-z]+\z/i
        email_pattern.match?(value) ? [] : ['Invalid email format']
      end

      def validate_uri_format(value)
        require 'uri'
        URI.parse(value)
        []
      rescue URI::InvalidURIError
        ['Invalid URI format']
      end

      def validate_uuid_format(value)
        uuid_pattern = /\A[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/i
        uuid_pattern.match?(value) ? [] : ['Invalid UUID format']
      end

      def validate_date_format(value)
        require 'date'
        ::Date.parse(value)
        []
      rescue ArgumentError
        ['Invalid date format']
      end

      def validate_datetime_format(value)
        require 'date'
        ::DateTime.parse(value)
        []
      rescue ArgumentError
        ['Invalid datetime format']
      end

      def validate_ipv4_format(value)
        ipv4_pattern = /\A(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\z/
        ipv4_pattern.match?(value) ? [] : ['Invalid IPv4 format']
      end

      def validate_ipv6_format(value)
        # Simplified IPv6 validation - in production, consider using a more robust library
        require 'ipaddr'
        IPAddr.new(value, Socket::AF_INET6)
        []
      rescue IPAddr::InvalidAddressError
        ['Invalid IPv6 format']
      end
    end
  end
end
