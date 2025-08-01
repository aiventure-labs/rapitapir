# frozen_string_literal: true

module RapiTapir
  module Client
    # Base class for client code generators
    # Provides common functionality for generating API clients in different languages
    class GeneratorBase
      attr_reader :endpoints, :config

      def initialize(endpoints: [], config: {})
        @endpoints = endpoints
        @config = default_config.merge(config)
      end

      # Generate client code - to be implemented by subclasses
      def generate
        raise NotImplementedError, 'Subclasses must implement #generate'
      end

      # Save generated client to file
      def save_to_file(filename)
        content = generate
        File.write(filename, content)
        puts "Client saved to #{filename}"
      end

      protected

      def default_config
        {
          base_url: 'http://localhost:4567',
          client_name: 'ApiClient',
          package_name: 'api-client',
          version: '1.0.0'
        }
      end

      # Convert RapiTapir types to language-specific types
      def convert_type(type, language:)
        case language
        when :typescript
          convert_to_typescript_type(type)
        when :python
          convert_to_python_type(type)
        else
          type.to_s
        end
      end

      def convert_to_typescript_type(type)
        case type
        when :string, String, RapiTapir::Types::String
          'string'
        when :integer, Integer, RapiTapir::Types::Integer, :number, Float, RapiTapir::Types::Float
          'number'
        when :boolean, RapiTapir::Types::Boolean
          'boolean'
        when :date, :datetime, RapiTapir::Types::Date, RapiTapir::Types::DateTime
          'Date'
        when RapiTapir::Types::Array
          convert_array_type_to_typescript(type)
        when RapiTapir::Types::Hash, Hash
          convert_hash_type_to_typescript(type)
        when Array
          convert_ruby_array_to_typescript(type)
        else
          'any'
        end
      end

      def convert_array_type_to_typescript(type)
        "#{convert_to_typescript_type(type.item_type)}[]"
      end

      def convert_hash_type_to_typescript(type)
        if hash_type_empty?(type)
          'Record<string, any>'
        else
          convert_hash_properties_to_typescript(type)
        end
      end

      def hash_type_empty?(type)
        (type.respond_to?(:field_types) && type.field_types.empty?) ||
          (type.respond_to?(:empty?) && type.empty?)
      end

      def convert_hash_properties_to_typescript(type)
        properties = if type.respond_to?(:field_types)
                       convert_field_types_to_typescript(type.field_types)
                     else
                       convert_hash_entries_to_typescript(type)
                     end
        "{ #{properties.join('; ')} }"
      end

      def convert_field_types_to_typescript(field_types)
        field_types.map do |key, value|
          "#{key}: #{convert_to_typescript_type(value)}"
        end
      end

      def convert_hash_entries_to_typescript(hash)
        hash.map do |key, value|
          "#{key}: #{convert_to_typescript_type(value)}"
        end
      end

      def convert_ruby_array_to_typescript(type)
        if type.length == 1
          "#{convert_to_typescript_type(type.first)}[]"
        else
          'any[]'
        end
      end

      def convert_to_python_type(type)
        case type
        when :string, String
          'str'
        when :integer, Integer
          'int'
        when :number, Float
          'float'
        when :boolean
          'bool'
        when :date, :datetime
          'datetime'
        when Array
          if type.length == 1
            "List[#{convert_to_python_type(type.first)}]"
          else
            'List[Any]'
          end
        when Hash
          return 'Dict[str, Any]' if type.empty?

          'Dict[str, Any]'
        else
          'Any'
        end
      end

      # Generate HTTP method name
      def method_name_for_endpoint(endpoint)
        method = endpoint.method.to_s.downcase
        path_parts = extract_static_path_parts(endpoint.path)

        generate_method_name_by_http_method(method, endpoint.path, path_parts)
      end

      def extract_static_path_parts(path)
        path.split('/').reject(&:empty?).map do |part|
          part.start_with?(':') ? nil : part
        end.compact
      end

      def generate_method_name_by_http_method(method, path, path_parts)
        case method
        when 'get'
          generate_get_method_name(path, path_parts)
        when 'post'
          generate_post_method_name(path_parts)
        when 'put'
          generate_put_method_name(path_parts)
        when 'delete'
          generate_delete_method_name(path_parts)
        else
          generate_default_method_name(method, path_parts)
        end
      end

      def generate_get_method_name(path, path_parts)
        if path.include?(':')
          # GET /users/:id -> getUserById
          base_name = path_parts.map(&:capitalize).join
          "get#{base_name}ById"
        else
          # GET /users -> getUsers
          "get#{path_parts.map(&:capitalize).join}"
        end
      end

      def generate_post_method_name(path_parts)
        # POST /users -> createUser
        singular_name = get_singular_name(path_parts)
        "create#{singular_name}"
      end

      def generate_put_method_name(path_parts)
        # PUT /users/:id -> updateUser
        singular_name = get_singular_name(path_parts)
        "update#{singular_name}"
      end

      def generate_delete_method_name(path_parts)
        # DELETE /users/:id -> deleteUser
        singular_name = get_singular_name(path_parts)
        "delete#{singular_name}"
      end

      def generate_default_method_name(method, path_parts)
        "#{method}#{path_parts.map(&:capitalize).join}"
      end

      def get_singular_name(path_parts)
        return path_parts.map(&:capitalize).join unless path_parts.any?

        singular_name = singularize(path_parts.last)
        singular_name&.capitalize || path_parts.map(&:capitalize).join
      end

      # Simple singularize method (basic implementation)
      def singularize(word)
        return nil unless word

        word = word.to_s
        case word
        when /ies$/
          word.sub(/ies$/, 'y')
        when /s$/
          word.sub(/s$/, '')
        else
          word
        end
      end

      # Extract path parameters from endpoint
      def path_parameters(endpoint)
        endpoint.inputs.select { |input| input.kind == :path }
      end

      # Extract query parameters from endpoint
      def query_parameters(endpoint)
        endpoint.inputs.select { |input| input.kind == :query }
      end

      # Extract request body from endpoint
      def request_body(endpoint)
        endpoint.inputs.find { |input| input.kind == :body }
      end

      # Get response type from endpoint
      def response_type(endpoint)
        output = endpoint.outputs.first
        output&.type
      end
    end
  end
end
