# frozen_string_literal: true

module RapiTapir
  module DSL
    # Input DSL methods for enhanced endpoint DSL
    module InputMethods
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

      private

      def create_input(kind, name, type, **options)
        @inputs ||= []
        @inputs << EnhancedInput.new(kind: kind, name: name, type: type, options: options)
        self
      end
    end
  end
end
