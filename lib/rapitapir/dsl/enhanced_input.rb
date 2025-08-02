# frozen_string_literal: true

module RapiTapir
  module DSL
    # Enhanced Input class that uses the new type system
    class EnhancedInput
      attr_reader :kind, :name, :type, :options

      def initialize(kind:, name:, type:, options: {})
        @kind = kind
        @name = name.to_sym
        @type = type
        @options = options.freeze
      end

      def required?
        !type.optional? && !(options && options[:optional])
      end

      def optional?
        type.optional? || (options && options[:optional])
      end

      def validate(value)
        return { valid: true, errors: [] } if value.nil? && optional?

        return { valid: false, errors: ["#{name} is required but got nil"] } if value.nil? && required?

        type.validate(value)
      end

      def coerce(value)
        return nil if value.nil? && optional?

        type.coerce(value)
      end

      def to_openapi_parameter
        schema = type.to_json_schema

        {
          name: name.to_s,
          in: openapi_location,
          required: required?,
          description: options[:description],
          schema: schema
        }.compact
      end

      def to_h
        {
          kind: kind,
          name: name,
          type: type.to_s,
          required: required?,
          options: options
        }
      end

      private

      def openapi_location
        case kind
        when :query then 'query'
        when :path then 'path'
        when :header then 'header'
        when :body then 'requestBody'
        else kind.to_s
        end
      end
    end
  end
end
