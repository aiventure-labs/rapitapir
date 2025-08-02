# frozen_string_literal: true

module RapiTapir
  module DSL
    # Output DSL methods for enhanced endpoint DSL
    module OutputMethods
      # Output DSL methods
      def out_json(type_def, **options)
        type = resolve_type(type_def)
        create_output(:json, type, **options)
      end

      def out_text(type_def = Types.string, **options)
        type = resolve_type(type_def)
        create_output(:text, type, **options)
      end

      def out_xml(type_def, **options)
        type = resolve_type(type_def)
        create_output(:xml, type, **options)
      end

      def status(code, **options)
        create_output(:status, code, **options)
      end

      def error_out(status_code, type_def, **options)
        type = resolve_type(type_def)
        @error_outputs ||= []
        @error_outputs << EnhancedOutput.new(kind: :json, type: type, options: options.merge(status: status_code))
        self
      end

      private

      def create_output(kind, type, **options)
        @outputs ||= []
        @outputs << EnhancedOutput.new(kind: kind, type: type, options: options)
        self
      end
    end
  end
end
