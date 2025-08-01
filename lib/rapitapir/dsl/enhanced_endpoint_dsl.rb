# frozen_string_literal: true

require_relative '../types'
require_relative '../schema'

module RapiTapir
  module DSL
    # Enhanced DSL module that works with the new type system
    module EnhancedEndpointDSL
      # Input DSL methods
      def query(name, type_def, **options)
        type = resolve_type(type_def)
        create_input(:query, name, type, **options)
      end

      def path_param(name, type_def, **options)
        type = resolve_type(type_def)
        create_input(:path, name, type, **options)
      end

      def header(name, type_def, **options)
        type = resolve_type(type_def)
        create_input(:header, name, type, **options)
      end

      def body(type_def, **options)
        type = resolve_type(type_def)
        create_input(:body, :body, type, **options)
      end

      def json_body(type_def, **options)
        type = resolve_type(type_def)
        create_input(:body, :body, type, format: :json, **options)
      end

      def form_body(type_def, **options)
        type = resolve_type(type_def)
        create_input(:body, :body, type, format: :form, **options)
      end

      # Output DSL methods
      def out_json(type_def, **options)
        type = resolve_type(type_def)
        create_output(:json, type, **options)
      end

      def out_text(type_def = Types.string, **options)
        type = resolve_type(type_def)
        create_output(:text, type, **options)
      end

      def out_status(code)
        create_output(:status, code)
      end

      # Authentication DSL methods
      def bearer_auth(description = 'Bearer token authentication')
        create_input(:header, :authorization, Types.string(pattern: /\ABearer .+\z/),
                     description: description, auth_type: :bearer)
      end

      def api_key_auth(header_name = 'X-API-Key', description = 'API key authentication')
        create_input(:header, header_name.downcase.to_sym, Types.string,
                     description: description, auth_type: :api_key)
      end

      def basic_auth(description = 'Basic authentication')
        create_input(:header, :authorization, Types.string(pattern: /\ABasic .+\z/),
                     description: description, auth_type: :basic)
      end

      # Validation DSL methods
      def validate_with(validator_proc)
        @custom_validators ||= []
        @custom_validators << validator_proc
      end

      def validate_json_schema(schema_def)
        validate_with(->(data) { Schema.validate!(data, resolve_type(schema_def)) })
      end

      # Observability DSL methods (Phase 2.1)
      def with_metrics(metric_name = nil)
        @metric_name = metric_name || generate_metric_name
        self
      end

      def with_tracing(span_name = nil)
        @trace_span_name = span_name || generate_span_name
        self
      end

      def with_logging(level: :info, structured: true, fields: nil)
        @log_config = {
          level: level,
          structured: structured,
          fields: fields
        }
        self
      end

      def metric_name
        @metric_name
      end

      def trace_span_name
        @trace_span_name
      end

      def log_config
        @log_config
      end

      private

      def generate_metric_name
        # Generate a metric name based on HTTP method and path
        method = @method&.downcase || 'unknown'
        path = if @path
                 @path.gsub(%r{[/:]}, '_').gsub(/_{2,}/, '_').strip('_')
               else
                 'unknown'
               end
        "#{method}_#{path}"
      end

      def generate_span_name
        # Generate a span name for tracing
        method = @method&.upcase || 'UNKNOWN'
        path = @path || '/unknown'
        "HTTP #{method} #{path}"
      end

      def resolve_type(type_def)
        case type_def
        when Symbol
          create_primitive_type(type_def)
        when Hash, Array
          Schema.from_definition(type_def)
        when Class
          if type_def < Types::Base
            type_def.new
          else
            type_def
          end
        else
          # Assume it's already a resolved type
          type_def
        end
      end

      PRIMITIVE_TYPE_MAP = {
        string: -> { Types.string },
        integer: -> { Types.integer },
        float: -> { Types.float },
        boolean: -> { Types.boolean },
        date: -> { Types.date },
        datetime: -> { Types.datetime },
        uuid: -> { Types.uuid },
        email: -> { Types.email }
      }.freeze

      def create_primitive_type(type_symbol)
        type_creator = PRIMITIVE_TYPE_MAP[type_symbol]
        return type_creator.call if type_creator

        raise ArgumentError, "Unknown primitive type: #{type_symbol}"
      end

      def create_input(kind, name, type, **options)
        EnhancedInput.new(kind: kind, name: name, type: type, options: options)
      end

      def create_output(kind, type, **options)
        EnhancedOutput.new(kind: kind, type: type, options: options)
      end
    end

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
