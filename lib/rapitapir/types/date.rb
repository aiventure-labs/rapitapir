# frozen_string_literal: true

require_relative 'base'
require 'date'

module RapiTapir
  module Types
    class Date < Base
      def initialize(format: nil, **options)
        super(format: format, **options)
      end

      protected

      def validate_type(value)
        return [] if value.is_a?(::Date)
        return [] if value.is_a?(::String) && parseable_date?(value)
        ["Expected Date or date string, got #{value.class}"]
      end

      def validate_constraints(value)
        errors = []
        
        if constraints[:format] && value.is_a?(::String)
          format_errors = validate_date_format(value, constraints[:format])
          errors.concat(format_errors)
        end

        errors
      end

      def coerce_value(value)
        case value
        when ::Date then value
        when ::DateTime then value.to_date
        when ::Time then value.to_date
        when ::String
          ::Date.parse(value)
        when ::Integer
          # Assume Unix timestamp
          ::Time.at(value).to_date
        else
          if value.respond_to?(:to_date)
            value.to_date
          else
            raise CoercionError.new(value, 'Date', 'Value cannot be converted to Date')
          end
        end
      rescue ArgumentError => e
        raise CoercionError.new(value, 'Date', e.message)
      end

      def json_type
        'string'
      end

      def apply_constraints_to_schema(schema)
        super
        schema[:format] = 'date'
        schema[:format] = constraints[:format].to_s if constraints[:format]
      end

      private

      def parseable_date?(value)
        ::Date.parse(value)
        true
      rescue ArgumentError
        false
      end

      def validate_date_format(value, format)
        case format
        when :iso8601, 'iso8601'
          iso_date_pattern = /\A\d{4}-\d{2}-\d{2}\z/
          iso_date_pattern.match?(value) ? [] : ["Date must be in ISO8601 format (YYYY-MM-DD)"]
        when String
          # Custom format validation
          begin
            ::Date.strptime(value, format)
            []
          rescue ArgumentError
            ["Date does not match format #{format}"]
          end
        else
          []
        end
      end
    end
  end
end
