# frozen_string_literal: true

module RapiTapir
  module DSL
    # Enhanced Output class that uses the new type system
    class EnhancedOutput
      attr_reader :kind, :type, :options

      def initialize(kind:, type:, options: {})
        @kind = kind
        @type = type
        @options = options.freeze
      end

      def validate(value)
        return { valid: true, errors: [] } if kind == :status

        type.validate(value)
      end

      def serialize(value)
        case kind
        when :json
          JSON.generate(value)
        when :status
          # Status codes don't need serialization
          value
        else # :text and other formats
          value.to_s
        end
      end

      def to_openapi_response
        if kind == :status
          {
            description: options[:description] || "Response with status #{type}",
            content: {}
          }
        else
          schema = type.respond_to?(:to_json_schema) ? type.to_json_schema : { type: 'string' }
          content_type = kind == :json ? 'application/json' : 'text/plain'

          {
            description: options[:description] || 'Successful response',
            content: {
              content_type => {
                schema: schema
              }
            }
          }
        end
      end

      def to_h
        {
          kind: kind,
          type: type.respond_to?(:to_s) ? type.to_s : type.class.name,
          options: options
        }
      end
    end
  end
end
