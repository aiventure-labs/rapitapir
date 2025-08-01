# frozen_string_literal: true

require_relative 'base'
require 'date'

module RapiTapir
  module Types
    # DateTime type for validating datetime values with timezone handling
    # Accepts DateTime objects and string representations in various formats
    class DateTime < Base
      def initialize(format: nil, **options)
        super
      end

      protected

      def validate_type(value)
        return [] if value.is_a?(::DateTime) || value.is_a?(::Time)
        return [] if value.is_a?(::String) && parseable_datetime?(value)

        ["Expected DateTime, Time, or datetime string, got #{value.class}"]
      end

      def validate_constraints(value)
        errors = []

        if constraints[:format] && value.is_a?(::String)
          format_errors = validate_datetime_format(value, constraints[:format])
          errors.concat(format_errors)
        end

        errors
      end

      def coerce_value(value)
        case value
        when ::DateTime then value
        when ::Time then value.to_datetime
        when ::Date then value.to_datetime
        when ::String
          ::DateTime.parse(value)
        when ::Integer
          # Assume Unix timestamp
          ::Time.at(value).to_datetime
        else
          unless value.respond_to?(:to_datetime)
            raise CoercionError.new(value, 'DateTime', 'Value cannot be converted to DateTime')
          end

          value.to_datetime

        end
      rescue ArgumentError => e
        raise CoercionError.new(value, 'DateTime', e.message)
      end

      def json_type
        'string'
      end

      def apply_constraints_to_schema(schema)
        super
        schema[:format] = 'date-time'
        schema[:format] = constraints[:format].to_s if constraints[:format]
      end

      private

      def parseable_datetime?(value)
        ::DateTime.parse(value)
        true
      rescue ArgumentError
        false
      end

      def validate_datetime_format(value, format)
        case format
        when :iso8601, 'iso8601'
          iso_datetime_pattern = /\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?(?:Z|[+-]\d{2}:\d{2})\z/
          iso_datetime_pattern.match?(value) ? [] : ['DateTime must be in ISO8601 format']
        when :rfc3339, 'rfc3339'
          # RFC3339 is essentially the same as ISO8601 for our purposes
          iso_datetime_pattern = /\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?(?:Z|[+-]\d{2}:\d{2})\z/
          iso_datetime_pattern.match?(value) ? [] : ['DateTime must be in RFC3339 format']
        when String
          # Custom format validation
          begin
            ::DateTime.strptime(value, format)
            []
          rescue ArgumentError
            ["DateTime does not match format #{format}"]
          end
        else
          []
        end
      end
    end
  end
end
