# frozen_string_literal: true

module RapiTapir
  module Core
    # Input parameter definition for HTTP endpoints
    #
    # Represents different types of input parameters that an endpoint can accept,
    # including query parameters, path parameters, headers, and request body.
    #
    # @example Query parameter
    #   RapiTapir::Core::Input.new(kind: :query, name: :limit, type: :integer)
    #
    # @example Path parameter
    #   RapiTapir::Core::Input.new(kind: :path, name: :id, type: :string)
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

        validate_type_match(value, type)
      end

      def validate_type_match(value, target_type)
        case target_type
        when :string then value.is_a?(String)
        when :integer then value.is_a?(Integer)
        when :float then numeric_value?(value)
        when :boolean then boolean_value?(value)
        else
          validate_complex_type_match(value, target_type)
        end
      end

      def validate_complex_type_match(value, target_type)
        case target_type
        when :date then validate_date_type(value)
        when :datetime then validate_datetime_type(value)
        when Hash then validate_hash_type(value)
        when Class then value.is_a?(target_type)
        else true # Accept any for custom types
        end
      end

      def numeric_value?(value)
        value.is_a?(Float) || value.is_a?(Integer)
      end

      def boolean_value?(value)
        [true, false].include?(value)
      end

      def validate_date_type(value)
        value.is_a?(Date) || (value.is_a?(String) && date_string?(value))
      end

      def validate_datetime_type(value)
        value.is_a?(DateTime) || (value.is_a?(String) && datetime_string?(value))
      end

      def coerce(value)
        return nil if value.nil? && optional?

        coerce_by_type(value, type)
      rescue ArgumentError => e
        raise TypeError, "Cannot coerce #{value.inspect} to #{type}: #{e.message}"
      end

      def coerce_by_type(value, target_type)
        case target_type
        when :string then value.to_s
        when :integer then Integer(value)
        when :float then Float(value)
        when :boolean then !!value
        when :date then coerce_to_date(value)
        when :datetime then coerce_to_datetime(value)
        else value
        end
      end

      def coerce_to_date(value)
        value.is_a?(Date) ? value : Date.parse(value.to_s)
      end

      def coerce_to_datetime(value)
        value.is_a?(DateTime) ? value : DateTime.parse(value.to_s)
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
          valid_hash_field_type?(value[key], expected_type)
        end
      end

      def valid_hash_field_type?(field_value, expected_type)
        case expected_type
        when :string then field_value.is_a?(String)
        when :integer then field_value.is_a?(Integer)
        when :float then numeric_field_value?(field_value)
        when :boolean then boolean_field_value?(field_value)
        else true
        end
      end

      def numeric_field_value?(field_value)
        field_value.is_a?(Float) || field_value.is_a?(Integer)
      end

      def boolean_field_value?(field_value)
        [true, false].include?(field_value)
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
