# frozen_string_literal: true

module RapiTapir
  module Client
    class GeneratorBase
      attr_reader :endpoints, :config

      def initialize(endpoints: [], config: {})
        @endpoints = endpoints
        @config = default_config.merge(config)
      end

      # Generate client code - to be implemented by subclasses
      def generate
        raise NotImplementedError, "Subclasses must implement #generate"
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
        when :string, String
          'string'
        when :integer, Integer
          'number'
        when :number, Float
          'number'
        when :boolean
          'boolean'
        when :date
          'Date'
        when :datetime
          'Date'
        when RapiTapir::Types::String
          'string'
        when RapiTapir::Types::Integer
          'number'
        when RapiTapir::Types::Float
          'number'
        when RapiTapir::Types::Boolean
          'boolean'
        when RapiTapir::Types::Date, RapiTapir::Types::DateTime
          'Date'
        when RapiTapir::Types::Array
          "#{convert_to_typescript_type(type.item_type)}[]"
        when RapiTapir::Types::Hash
          if type.field_types.empty?
            'Record<string, any>'
          else
            properties = type.field_types.map do |key, value|
              "#{key}: #{convert_to_typescript_type(value)}"
            end
            "{ #{properties.join('; ')} }"
          end
        when Array
          if type.length == 1
            "#{convert_to_typescript_type(type.first)}[]"
          else
            'any[]'
          end
        when Hash
          if type.empty?
            'Record<string, any>'
          else
            properties = type.map do |key, value|
              "#{key}: #{convert_to_typescript_type(value)}"
            end
            "{ #{properties.join('; ')} }"
          end
        else
          'any'
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
          if type.empty?
            'Dict[str, Any]'
          else
            'Dict[str, Any]'  # Could be more specific with TypedDict
          end
        else
          'Any'
        end
      end

      # Generate HTTP method name
      def method_name_for_endpoint(endpoint)
        method = endpoint.method.to_s.downcase
        path_parts = endpoint.path.split('/').reject(&:empty?).map do |part|
          part.start_with?(':') ? nil : part
        end.compact
        
        case method
        when 'get'
          if endpoint.path.include?(':')
            # GET /users/:id -> getUserById
            base_name = path_parts.map(&:capitalize).join('')
            "get#{base_name}ById"
          else
            # GET /users -> getUsers
            "get#{path_parts.map(&:capitalize).join('')}"
          end
        when 'post'
          # POST /users -> createUser
          singular_name = singularize(path_parts.last) if path_parts.any?
          "create#{singular_name&.capitalize || path_parts.map(&:capitalize).join('')}"
        when 'put'
          # PUT /users/:id -> updateUser
          singular_name = singularize(path_parts.last) if path_parts.any?
          "update#{singular_name&.capitalize || path_parts.map(&:capitalize).join('')}"
        when 'delete'
          # DELETE /users/:id -> deleteUser
          singular_name = singularize(path_parts.last) if path_parts.any?
          "delete#{singular_name&.capitalize || path_parts.map(&:capitalize).join('')}"
        else
          "#{method}#{path_parts.map(&:capitalize).join('')}"
        end
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
        output ? output.type : nil
      end
    end
  end
end
