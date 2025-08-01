# frozen_string_literal: true

module RapiTapir
  module Docs
    # Markdown documentation generator for APIs
    # Generates human-readable Markdown documentation from endpoint definitions
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
        doc = []

        doc << generate_endpoint_header(endpoint)
        doc.concat(generate_all_endpoint_sections(endpoint))
        doc << generate_endpoint_examples(endpoint) if config[:include_examples]

        doc.join("\n\n")
      end

      def generate_endpoint_header(endpoint)
        method = endpoint.method.to_s.upcase
        path = endpoint.path
        anchor = generate_anchor(method, path)
        "## #{method} #{path} {##{anchor}}"
      end

      def generate_all_endpoint_sections(endpoint)
        sections = []
        sections.concat(generate_metadata_section(endpoint))
        sections.concat(generate_path_parameters_section(endpoint))
        sections.concat(generate_query_parameters_section(endpoint))
        sections.concat(generate_request_body_section(endpoint))
        sections.concat(generate_response_section(endpoint))
        sections
      end

      def generate_metadata_section(endpoint)
        doc = []

        # Summary and description
        doc << "**#{endpoint.metadata[:summary]}**" if endpoint.metadata[:summary]
        doc << endpoint.metadata[:description] if endpoint.metadata[:description]

        doc
      end

      def generate_path_parameters_section(endpoint)
        path_params = endpoint.inputs.select { |input| input.kind == :path }
        return [] unless path_params.any?

        doc = []
        doc << '### Path Parameters'
        doc << ''
        doc.concat(generate_path_parameters_table_header)
        doc.concat(generate_path_parameters_rows(path_params))

        doc
      end

      def generate_path_parameters_table_header
        [
          '| Parameter | Type | Description |',
          '|-----------|------|-------------|'
        ]
      end

      def generate_path_parameters_rows(path_params)
        path_params.map do |param|
          description = extract_parameter_description(param)
          "| `#{param.name}` | #{format_type(param.type)} | #{description} |"
        end
      end

      def generate_query_parameters_section(endpoint)
        query_params = endpoint.inputs.select { |input| input.kind == :query }
        return [] unless query_params.any?

        doc = []
        doc << '### Query Parameters'
        doc << ''
        doc.concat(generate_parameters_table_header)
        doc.concat(generate_query_parameters_rows(query_params))

        doc
      end

      def generate_parameters_table_header
        [
          '| Parameter | Type | Required | Description |',
          '|-----------|------|----------|-------------|'
        ]
      end

      def generate_query_parameters_rows(query_params)
        query_params.map do |param|
          required = param.required? ? 'Yes' : 'No'
          description = extract_parameter_description(param)
          "| `#{param.name}` | #{format_type(param.type)} | #{required} | #{description} |"
        end
      end

      def extract_parameter_description(param)
        (param.options && param.options[:description]) || 'No description'
      end

      def generate_request_body_section(endpoint)
        body_param = endpoint.inputs.find { |input| input.kind == :body }
        return [] unless body_param

        doc = []
        doc << '### Request Body'
        doc << ''
        doc << '**Content-Type:** `application/json`'
        doc << ''
        doc << '**Schema:**'
        doc << '```json'
        doc << format_schema_example(body_param.type)
        doc << '```'

        doc
      end

      def generate_response_section(endpoint)
        return [] unless endpoint.outputs.any?

        doc = []
        doc << '### Response'
        doc << ''
        doc.concat(generate_response_outputs(endpoint.outputs))

        doc
      end

      def generate_response_outputs(outputs)
        outputs.flat_map do |output|
          generate_single_response_output(output)
        end
      end

      def generate_single_response_output(output)
        case output.kind
        when :json
          generate_json_response_output(output)
        when :status
          ["**Status Code:** #{output.type}"]
        else
          []
        end
      end

      def generate_json_response_output(output)
        [
          '**Content-Type:** `application/json`',
          '',
          '**Schema:**',
          '```json',
          format_schema_example(output.type),
          '```'
        ]
      end

      def generate_endpoint_examples(endpoint)
        curl_example = generate_curl_example(endpoint)
        response_example = generate_response_example(endpoint)

        examples = []
        examples << '### Example'
        examples << ''
        examples.concat(build_request_example_section(curl_example))
        examples.concat(build_response_example_section(response_example)) if response_example

        examples.join("\n")
      end

      def build_request_example_section(curl_example)
        [
          '**Request:**',
          '```bash',
          curl_example,
          '```'
        ]
      end

      def build_response_example_section(response_example)
        [
          '',
          '**Response:**',
          '```json',
          response_example,
          '```'
        ]
      end

      def generate_curl_example(endpoint)
        method = endpoint.method.to_s.upcase
        example_path = build_example_path(endpoint.path, endpoint)

        curl_parts = build_curl_parts(method, endpoint, example_path)
        curl_parts.join(' \\\n  ')
      end

      def build_example_path(path, endpoint)
        example_path = replace_path_parameters(path)
        add_query_parameters(example_path, endpoint)
      end

      def replace_path_parameters(path)
        path.gsub(/:(\w+)/) do |_match|
          param_name = ::Regexp.last_match(1)
          case param_name
          when 'id' then '123'
          when 'slug' then 'example-slug'
          else 'example-value'
          end
        end
      end

      def add_query_parameters(example_path, endpoint)
        query_params = endpoint.inputs.select { |input| input.kind == :query }
        return example_path unless query_params.any?

        query_string = build_query_string(query_params)
        "#{example_path}?#{query_string}"
      end

      def build_query_string(query_params)
        query_params.map do |param|
          example_value = generate_param_example_value(param.type)
          "#{param.name}=#{example_value}"
        end.join('&')
      end

      def generate_param_example_value(param_type)
        case param_type
        when :string then 'example'
        when :integer then '10'
        when :boolean then 'true'
        else 'value'
        end
      end

      def build_curl_parts(method, endpoint, example_path)
        curl_parts = ["curl -X #{method}"]

        curl_parts.concat(build_curl_headers)
        curl_parts.concat(build_curl_body(endpoint))
        curl_parts << "'#{config[:base_url]}#{example_path}'"

        curl_parts
      end

      def build_curl_headers
        [
          "-H 'Content-Type: application/json'",
          "-H 'Accept: application/json'"
        ]
      end

      def build_curl_body(endpoint)
        body_param = endpoint.inputs.find { |input| input.kind == :body }
        return [] unless body_param

        body_example = format_schema_example(body_param.type)
        ["-d '#{body_example}'"]
      end

      def generate_response_example(endpoint)
        output = endpoint.outputs.find { |o| o.kind == :json }
        return nil unless output

        format_schema_example(output.type)
      end

      def format_schema_example(schema, indent_level = 0)
        case schema
        when Hash
          format_hash_schema_example(schema, indent_level)
        when Array
          format_array_schema_example(schema, indent_level)
        else
          generate_example_value(schema)
        end
      end

      def format_hash_schema_example(schema, indent_level)
        indent = '  ' * indent_level
        lines = ['{']

        schema.each_with_index do |(key, value), index|
          comma = index < schema.size - 1 ? ',' : ''
          formatted_line = format_hash_property_line(key, value, indent_level, comma)
          lines << formatted_line
        end

        lines << "#{indent}}"
        lines.join("\n")
      end

      def format_hash_property_line(key, value, indent_level, comma)
        indent = '  ' * indent_level

        if value.is_a?(Hash) || value.is_a?(Array)
          nested_example = format_schema_example(value, indent_level + 1)
          "#{indent}  \"#{key}\": #{nested_example}#{comma}"
        else
          example_value = generate_example_value(value)
          "#{indent}  \"#{key}\": #{example_value}#{comma}"
        end
      end

      def format_array_schema_example(schema, indent_level)
        if schema.length == 1
          indent = '  ' * indent_level
          element_example = format_schema_example(schema.first, indent_level)
          "[\n#{indent}  #{element_example}\n#{indent}]"
        else
          '[]'
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
        when RapiTapir::Types::String, :string
          'string'
        when RapiTapir::Types::Integer, :integer
          'integer'
        when RapiTapir::Types::Float, :float
          'number'
        when RapiTapir::Types::Boolean, :boolean
          'boolean'
        when RapiTapir::Types::Date, :date
          'date'
        when RapiTapir::Types::DateTime, :datetime
          'datetime'
        when RapiTapir::Types::Array
          'array'
        when RapiTapir::Types::Hash
          'object'
        else
          # Handle Ruby built-in classes
          case type
          when String
            'string'
          when Integer
            'integer'
          when Float
            'number'
          else
            # Check class identity for built-in classes
            if type == Hash
              'object'
            elsif type == Array
              'array'
            else
              type.to_s
            end
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
