# frozen_string_literal: true

require_relative 'base'

module RapiTapir
  module Types
    class Boolean < Base
      def initialize(**options)
        super(**options)
      end

      protected

      def validate_type(value)
        return [] if value == true || value == false
        ["Expected boolean (true or false), got #{value.class}"]
      end

      def validate_constraints(value)
        # Boolean types don't have additional constraints beyond true/false
        []
      end

      def coerce_value(value)
        case value
        when true, false then value
        when 'true', 'TRUE', '1', 1 then true
        when 'false', 'FALSE', '0', 0 then false
        when ::String
          case value.strip.downcase
          when 'true', 'yes', 'on', '1' then true
          when 'false', 'no', 'off', '0' then false
          else
            raise CoercionError.new(value, 'Boolean', "Cannot convert '#{value}' to boolean")
          end
        else
          # Use Ruby's truthiness as fallback
          !!value
        end
      end

      def json_type
        'boolean'
      end
    end
  end
end
