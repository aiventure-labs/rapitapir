# frozen_string_literal: true

module RapiTapir
  module Docs
    class MarkdownGenerator
      attr_reader :endpoints, :config

      def initialize(endpoints: [], config: {})
        @endpoints = endpoints
        @config = default_config.merge(config)
      end

      def generate
        [
          generate_header,
          generate_table_of_contents,
          generate_endpoints_documentation,
          generate_footer
        ].join("\n\n")
      end

      def save_to_file(filename)
        content = generate
        File.write(filename, content)
        puts "Documentation saved to #{filename}"
      end

      private

      def default_config
        {
          title: 'API Documentation',
          description: 'Auto-generated API documentation',
          version: '1.0.0',
          base_url: 'http://localhost:4567',
          include_toc: true,
          include_examples: true
        }
      end

      def generate_header
        <<~MARKDOWN
          # #{config[:title]}

          #{config[:description]}

          **Version:** #{config[:version]}#{'  '}
          **Base URL:** `#{config[:base_url]}`

          ---
        MARKDOWN
      end

      def generate_table_of_contents
        return '' unless config[:include_toc]

        toc_items = endpoints.map do |endpoint|
          method = endpoint.method.to_s.upcase
          path = endpoint.path
          summary = endpoint.metadata[:summary] || "#{method} #{path}"
          anchor = generate_anchor(method, path)

          "- [#{method} #{path}](##{anchor}) - #{summary}"
        end

        <<~MARKDOWN
          ## Table of Contents

          #{toc_items.join("\n")}

          ---
        MARKDOWN
      end

      def generate_endpoints_documentation
        endpoints.map { |endpoint| generate_endpoint_doc(endpoint) }.join("\n\n---\n\n")
      end

      def generate_endpoint_doc(endpoint)
        method = endpoint.method.to_s.upcase
        path = endpoint.path
        anchor = generate_anchor(method, path)

        doc = []

        # Header
        doc << "## #{method} #{path} {##{anchor}}"

        # Summary and description
        doc << "**#{endpoint.metadata[:summary]}**" if endpoint.metadata[:summary]

        doc << endpoint.metadata[:description] if endpoint.metadata[:description]

        # Path parameters
        path_params = endpoint.inputs.select { |input| input.kind == :path }
        if path_params.any?
          doc << '### Path Parameters'
          doc << ''
          doc << '| Parameter | Type | Description |'
          doc << '|-----------|------|-------------|'
          path_params.each do |param|
            doc << "| `#{param.name}` | #{format_type(param.type)} | #{(param.options && param.options[:description]) || 'No description'} |"
          end
        end

        # Query parameters
        query_params = endpoint.inputs.select { |input| input.kind == :query }
        if query_params.any?
          doc << '### Query Parameters'
          doc << ''
          doc << '| Parameter | Type | Required | Description |'
          doc << '|-----------|------|----------|-------------|'
          query_params.each do |param|
            required = param.required? ? 'Yes' : 'No'
            doc << "| `#{param.name}` | #{format_type(param.type)} | #{required} | #{(param.options && param.options[:description]) || 'No description'} |"
          end
        end

        # Request body
        body_param = endpoint.inputs.find { |input| input.kind == :body }
        if body_param
          doc << '### Request Body'
          doc << ''
          doc << '**Content-Type:** `application/json`'
          doc << ''
          doc << '**Schema:**'
          doc << '```json'
          doc << format_schema_example(body_param.type)
          doc << '```'
        end

        # Response
        if endpoint.outputs.any?
          doc << '### Response'
          doc << ''
          endpoint.outputs.each do |output|
            if output.kind == :json
              doc << '**Content-Type:** `application/json`'
              doc << ''
              doc << '**Schema:**'
              doc << '```json'
              doc << format_schema_example(output.type)
              doc << '```'
            elsif output.kind == :status
              doc << "**Status Code:** #{output.type}"
            end
          end
        end

        # Examples
        doc << generate_endpoint_examples(endpoint) if config[:include_examples]

        doc.join("\n\n")
      end

      def generate_endpoint_examples(endpoint)
        endpoint.method.to_s.upcase
        endpoint.path

        # Generate curl example
        curl_example = generate_curl_example(endpoint)

        # Generate response example
        response_example = generate_response_example(endpoint)

        examples = []
        examples << '### Example'
        examples << ''
        examples << '**Request:**'
        examples << '```bash'
        examples << curl_example
        examples << '```'

        if response_example
          examples << ''
          examples << '**Response:**'
          examples << '```json'
          examples << response_example
          examples << '```'
        end

        examples.join("\n")
      end

      def generate_curl_example(endpoint)
        method = endpoint.method.to_s.upcase
        path = endpoint.path

        # Replace path parameters with example values
        example_path = path.gsub(/:(\w+)/) do |_match|
          param_name = ::Regexp.last_match(1)
          case param_name
          when 'id' then '123'
          when 'slug' then 'example-slug'
          else 'example-value'
          end
        end

        curl_parts = ["curl -X #{method}"]

        # Add headers
        curl_parts << "-H 'Content-Type: application/json'"
        curl_parts << "-H 'Accept: application/json'"

        # Add query parameters example
        query_params = endpoint.inputs.select { |input| input.kind == :query }
        if query_params.any?
          query_string = query_params.map do |param|
            example_value = case param.type
                            when :string then 'example'
                            when :integer then '10'
                            when :boolean then 'true'
                            else 'value'
                            end
            "#{param.name}=#{example_value}"
          end.join('&')
          example_path += "?#{query_string}"
        end

        # Add request body
        body_param = endpoint.inputs.find { |input| input.kind == :body }
        if body_param
          body_example = format_schema_example(body_param.type)
          curl_parts << "-d '#{body_example}'"
        end

        # Add URL
        curl_parts << "'#{config[:base_url]}#{example_path}'"

        curl_parts.join(' \\\n  ')
      end

      def generate_response_example(endpoint)
        output = endpoint.outputs.find { |o| o.kind == :json }
        return nil unless output

        format_schema_example(output.type)
      end

      def format_schema_example(schema, indent_level = 0)
        indent = '  ' * indent_level

        case schema
        when Hash
          lines = ['{']
          schema.each_with_index do |(key, value), index|
            comma = index < schema.size - 1 ? ',' : ''
            if value.is_a?(Hash) || value.is_a?(Array)
              lines << "#{indent}  \"#{key}\": #{format_schema_example(value, indent_level + 1)}#{comma}"
            else
              example_value = generate_example_value(value)
              lines << "#{indent}  \"#{key}\": #{example_value}#{comma}"
            end
          end
          lines << "#{indent}}"
          lines.join("\n")
        when Array
          if schema.length == 1
            element_example = format_schema_example(schema.first, indent_level)
            "[\n#{indent}  #{element_example}\n#{indent}]"
          else
            '[]'
          end
        else
          generate_example_value(schema)
        end
      end

      def generate_example_value(type)
        case type
        when :string, String then '"example string"'
        when :integer, Integer then '123'
        when :float, Float then '123.45'
        when :boolean then 'true'
        when :date then '"2025-01-15"'
        when :datetime then '"2025-01-15T10:30:00Z"'
        else '"example"'
        end
      end

      def format_type(type)
        case type
        when RapiTapir::Types::String
          'string'
        when RapiTapir::Types::Integer
          'integer'
        when RapiTapir::Types::Float
          'number'
        when RapiTapir::Types::Boolean
          'boolean'
        when RapiTapir::Types::Date
          'date'
        when RapiTapir::Types::DateTime
          'datetime'
        when RapiTapir::Types::Array
          'array'
        when RapiTapir::Types::Hash
          'object'
        when :string, String then 'string'
        when :integer, Integer then 'integer'
        when :float, Float then 'number'
        when :boolean then 'boolean'
        when :date then 'date'
        when :datetime then 'datetime'
        else
          if type == Hash
            'object'
          elsif type == Array
            'array'
          else
            type.to_s
          end
        end
      end

      def generate_anchor(method, path)
        "#{method.downcase}-#{path.gsub('/', '').gsub(':', '')}"
      end

      def generate_footer
        <<~MARKDOWN
          ---

          *Generated by RapiTapir Documentation Generator*
        MARKDOWN
      end
    end
  end
end
