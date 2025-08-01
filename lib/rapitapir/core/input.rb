# frozen_string_literal: true

module RapiTapir
  module Core
    class Input
      VALID_KINDS = %i[query path header body].freeze
      VALID_TYPES = %i[string integer float boolean date datetime].freeze

      attr_reader :kind, :name, :type, :options

      def initialize(kind:, name:, type:, options: {})
        validate_kind!(kind)
        validate_name!(name)
        validate_type!(type)

        @kind = kind
        @name = name.to_sym
        @type = type
        @options = options.freeze
      end

      def required?
        !options[:optional]
      end

      def optional?
        !!options[:optional]
      end

      def valid_type?(value)
        return true if value.nil? && optional?

        case type
        when :string then value.is_a?(String)
        when :integer then value.is_a?(Integer)
        when :float then value.is_a?(Float) || value.is_a?(Integer)
        when :boolean then [true, false].include?(value)
        when :date then value.is_a?(Date) || (value.is_a?(String) && date_string?(value))
        when :datetime then value.is_a?(DateTime) || (value.is_a?(String) && datetime_string?(value))
        when Hash then validate_hash_type(value)
        when Class then value.is_a?(type)
        else true # Accept any for custom types
        end
      end

      def coerce(value)
        return nil if value.nil? && optional?

        case type
        when :string then value.to_s
        when :integer then Integer(value)
        when :float then Float(value)
        when :boolean then !!value
        when :date then value.is_a?(Date) ? value : Date.parse(value.to_s)
        when :datetime then value.is_a?(DateTime) ? value : DateTime.parse(value.to_s)
        else value
        end
      rescue ArgumentError => e
        raise TypeError, "Cannot coerce #{value.inspect} to #{type}: #{e.message}"
      end

      def to_h
        {
          kind: kind,
          name: name,
          type: type,
          options: options,
          required: required?
        }
      end

      private

      def validate_kind!(kind)
        return if VALID_KINDS.include?(kind)

        raise ArgumentError, "Invalid kind: #{kind}. Must be one of #{VALID_KINDS}"
      end

      def validate_name!(name)
        return unless name.nil? || (name.respond_to?(:empty?) && name.empty?)

        raise ArgumentError, 'Input name cannot be nil or empty'
      end

      def validate_type!(type)
        return if VALID_TYPES.include?(type) || type.is_a?(Hash) || type.is_a?(Class)

        raise ArgumentError, "Invalid type: #{type}. Must be one of #{VALID_TYPES}, a Hash, or a Class"
      end

      def validate_hash_type(value)
        return false unless value.is_a?(Hash)

        type.all? do |key, expected_type|
          case expected_type
          when :string then value[key].is_a?(String)
          when :integer then value[key].is_a?(Integer)
          when :float then value[key].is_a?(Float) || value[key].is_a?(Integer)
          when :boolean then [true, false].include?(value[key])
          else true
          end
        end
      end

      def date_string?(value)
        Date.parse(value.to_s)
        true
      rescue ArgumentError
        false
      end

      def datetime_string?(value)
        DateTime.parse(value.to_s)
        true
      rescue ArgumentError
        false
      end
    end
  end
end
