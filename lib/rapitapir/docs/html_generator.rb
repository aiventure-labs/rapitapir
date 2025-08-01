# frozen_string_literal: true

module RapiTapir
  module Docs
    # HTML documentation generator for RapiTapir APIs
    # Generates interactive HTML documentation with Try-It functionality
    class HtmlGenerator
      attr_reader :endpoints, :config

      def initialize(endpoints: [], config: {})
        @endpoints = endpoints
        @config = default_config.merge(config)
      end

      def generate
        <<~HTML
          <!DOCTYPE html>
          <html lang="en">
          <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>#{config[:title]}</title>
            #{generate_styles}
          </head>
          <body>
            <div class="container">
              #{generate_header}
              #{generate_sidebar}
              #{generate_main_content}
            </div>
            #{generate_scripts}
          </body>
          </html>
        HTML
      end

      def save_to_file(filename)
        content = generate
        File.write(filename, content)
        puts "HTML documentation saved to #{filename}"
      end

      private

      def default_config
        {
          title: 'API Documentation',
          description: 'Auto-generated API documentation',
          version: '1.0.0',
          base_url: 'http://localhost:4567',
          theme: 'light',
          include_try_it: true
        }
      end

      def generate_styles
        <<~CSS
          <style>
            * {
              margin: 0;
              padding: 0;
              box-sizing: border-box;
            }

            body {
              font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
              line-height: 1.6;
              color: #333;
              background-color: #f8f9fa;
            }

            .container {
              display: flex;
              min-height: 100vh;
            }

            .header {
              position: fixed;
              top: 0;
              left: 0;
              right: 0;
              background: #fff;
              border-bottom: 1px solid #e1e5e9;
              padding: 1rem 2rem;
              z-index: 1000;
              box-shadow: 0 2px 4px rgba(0,0,0,0.1);
            }

            .header h1 {
              color: #2c3e50;
              font-size: 1.5rem;
              margin-bottom: 0.5rem;
            }

            .header .meta {
              color: #6c757d;
              font-size: 0.9rem;
            }

            .sidebar {
              width: 300px;
              background: #fff;
              border-right: 1px solid #e1e5e9;
              position: fixed;
              top: 80px;
              bottom: 0;
              overflow-y: auto;
              padding: 1rem;
            }

            .sidebar h3 {
              color: #2c3e50;
              margin-bottom: 1rem;
              font-size: 1.1rem;
            }

            .sidebar ul {
              list-style: none;
            }

            .sidebar li {
              margin-bottom: 0.5rem;
            }

            .sidebar a {
              text-decoration: none;
              color: #495057;
              padding: 0.5rem;
              border-radius: 4px;
              display: block;
              transition: background-color 0.2s;
            }

            .sidebar a:hover {
              background-color: #f8f9fa;
            }

            .method-badge {
              display: inline-block;
              padding: 0.2rem 0.5rem;
              border-radius: 3px;
              font-size: 0.7rem;
              font-weight: bold;
              margin-right: 0.5rem;
              min-width: 45px;
              text-align: center;
            }

            .method-get { background-color: #28a745; color: white; }
            .method-post { background-color: #007bff; color: white; }
            .method-put { background-color: #ffc107; color: black; }
            .method-delete { background-color: #dc3545; color: white; }
            .method-patch { background-color: #17a2b8; color: white; }

            .main-content {
              flex: 1;
              margin-left: 300px;
              margin-top: 80px;
              padding: 2rem;
            }

            .endpoint {
              background: #fff;
              border-radius: 8px;
              box-shadow: 0 2px 4px rgba(0,0,0,0.1);
              margin-bottom: 2rem;
              overflow: hidden;
            }

            .endpoint-header {
              padding: 1.5rem;
              border-bottom: 1px solid #e1e5e9;
            }

            .endpoint-title {
              display: flex;
              align-items: center;
              margin-bottom: 0.5rem;
            }

            .endpoint-path {
              font-family: 'Monaco', 'Menlo', monospace;
              font-size: 1.1rem;
              margin-left: 0.5rem;
            }

            .endpoint-description {
              color: #6c757d;
              margin-top: 0.5rem;
            }

            .endpoint-content {
              padding: 1.5rem;
            }

            .section {
              margin-bottom: 2rem;
            }

            .section h4 {
              color: #2c3e50;
              margin-bottom: 1rem;
              padding-bottom: 0.5rem;
              border-bottom: 2px solid #e1e5e9;
            }

            .params-table {
              width: 100%;
              border-collapse: collapse;
              margin-bottom: 1rem;
            }

            .params-table th,
            .params-table td {
              padding: 0.75rem;
              text-align: left;
              border-bottom: 1px solid #e1e5e9;
            }

            .params-table th {
              background-color: #f8f9fa;
              font-weight: 600;
            }

            .param-name {
              font-family: 'Monaco', 'Menlo', monospace;
              background-color: #f8f9fa;
              padding: 0.2rem 0.4rem;
              border-radius: 3px;
            }

            .code-block {
              background-color: #f8f9fa;
              border: 1px solid #e1e5e9;
              border-radius: 4px;
              padding: 1rem;
              overflow-x: auto;
              font-family: 'Monaco', 'Menlo', monospace;
              font-size: 0.9rem;
            }

            .try-it-section {
              background-color: #f8f9fa;
              border-radius: 8px;
              padding: 1.5rem;
              margin-top: 2rem;
            }

            .try-it-form {
              display: grid;
              gap: 1rem;
            }

            .form-group {
              display: flex;
              flex-direction: column;
            }

            .form-group label {
              margin-bottom: 0.5rem;
              font-weight: 600;
            }

            .form-group input,
            .form-group textarea {
              padding: 0.5rem;
              border: 1px solid #ced4da;
              border-radius: 4px;
              font-family: inherit;
            }

            .btn {
              padding: 0.75rem 1.5rem;
              border: none;
              border-radius: 4px;
              cursor: pointer;
              font-weight: 600;
              transition: background-color 0.2s;
            }

            .btn-primary {
              background-color: #007bff;
              color: white;
            }

            .btn-primary:hover {
              background-color: #0056b3;
            }

            .response-section {
              margin-top: 1rem;
              padding: 1rem;
              background-color: #fff;
              border-radius: 4px;
              border: 1px solid #e1e5e9;
            }

            .required-badge {
              background-color: #dc3545;
              color: white;
              padding: 0.1rem 0.3rem;
              border-radius: 3px;
              font-size: 0.7rem;
              margin-left: 0.5rem;
            }

            .optional-badge {
              background-color: #6c757d;
              color: white;
              padding: 0.1rem 0.3rem;
              border-radius: 3px;
              font-size: 0.7rem;
              margin-left: 0.5rem;
            }
          </style>
        CSS
      end

      def generate_header
        <<~HTML
          <div class="header">
            <h1>#{config[:title]}</h1>
            <div class="meta">
              Version: #{config[:version]} | Base URL: <code>#{config[:base_url]}</code>
            </div>
          </div>
        HTML
      end

      def generate_sidebar
        nav_items = endpoints.map do |endpoint|
          method = endpoint.method.to_s.upcase
          path = endpoint.path
          summary = endpoint.metadata[:summary] || path
          anchor = generate_anchor(method, path)
          method_class = "method-#{method.downcase}"

          <<~HTML
            <li>
              <a href="##{anchor}">
                <span class="method-badge #{method_class}">#{method}</span>
                #{summary}
              </a>
            </li>
          HTML
        end

        <<~HTML
          <div class="sidebar">
            <h3>Endpoints</h3>
            <ul>
              #{nav_items.join}
            </ul>
          </div>
        HTML
      end

      def generate_main_content
        endpoint_docs = endpoints.map { |endpoint| generate_endpoint_html(endpoint) }.join

        <<~HTML
          <div class="main-content">
            #{endpoint_docs}
          </div>
        HTML
      end

      def generate_endpoint_html(endpoint)
        method = endpoint.method.to_s.upcase
        path = endpoint.path
        anchor = generate_anchor(method, path)
        method_class = "method-#{method.downcase}"

        sections = build_endpoint_sections(endpoint)

        build_endpoint_html_structure(method, path, anchor, method_class, sections, endpoint)
      end

      def build_endpoint_sections(endpoint)
        sections = []

        sections << build_path_params_section(endpoint)
        sections << build_query_params_section(endpoint)
        sections << build_body_section(endpoint)
        sections << build_response_section(endpoint)
        sections << build_try_it_section(endpoint)

        sections.compact
      end

      def build_path_params_section(endpoint)
        path_params = endpoint.inputs.select { |input| input.kind == :path }
        return nil unless path_params.any?

        generate_params_section('Path Parameters', path_params)
      end

      def build_query_params_section(endpoint)
        query_params = endpoint.inputs.select { |input| input.kind == :query }
        return nil unless query_params.any?

        generate_params_section('Query Parameters', query_params)
      end

      def build_body_section(endpoint)
        body_param = endpoint.inputs.find { |input| input.kind == :body }
        return nil unless body_param

        generate_body_section(body_param)
      end

      def build_response_section(endpoint)
        return nil unless endpoint.outputs.any?

        generate_response_section(endpoint.outputs)
      end

      def build_try_it_section(endpoint)
        return nil unless config[:include_try_it]

        generate_try_it_section(endpoint)
      end

      def build_endpoint_html_structure(method, path, anchor, method_class, sections, endpoint)
        <<~HTML
          <div class="endpoint" id="#{anchor}">
            <div class="endpoint-header">
              <div class="endpoint-title">
                <span class="method-badge #{method_class}">#{method}</span>
                <span class="endpoint-path">#{path}</span>
              </div>
              #{build_endpoint_summary(endpoint)}
              #{build_endpoint_description(endpoint)}
            </div>
            <div class="endpoint-content">
              #{sections.join}
            </div>
          </div>
        HTML
      end

      def build_endpoint_summary(endpoint)
        return '' unless endpoint.metadata[:summary]

        "<div class=\"endpoint-summary\"><strong>#{endpoint.metadata[:summary]}</strong></div>"
      end

      def build_endpoint_description(endpoint)
        return '' unless endpoint.metadata[:description]

        "<div class=\"endpoint-description\">#{endpoint.metadata[:description]}</div>"
      end

      def generate_params_section(title, params)
        rows = params.map do |param|
          required_badge = if param.required?
                             '<span class="required-badge">Required</span>'
                           else
                             '<span class="optional-badge">Optional</span>'
                           end

          <<~HTML
            <tr>
              <td><code class="param-name">#{param.name}</code></td>
              <td>#{format_type(param.type)}</td>
              <td>#{required_badge}</td>
              <td>#{(param.options && param.options[:description]) || 'No description'}</td>
            </tr>
          HTML
        end

        <<~HTML
          <div class="section">
            <h4>#{title}</h4>
            <table class="params-table">
              <thead>
                <tr>
                  <th>Parameter</th>
                  <th>Type</th>
                  <th>Required</th>
                  <th>Description</th>
                </tr>
              </thead>
              <tbody>
                #{rows.join}
              </tbody>
            </table>
          </div>
        HTML
      end

      def generate_body_section(body_param)
        example = format_schema_example(body_param.type)

        <<~HTML
          <div class="section">
            <h4>Request Body</h4>
            <p><strong>Content-Type:</strong> <code>application/json</code></p>
            <div class="code-block">#{html_escape(example)}</div>
          </div>
        HTML
      end

      def generate_response_section(outputs)
        response_content = outputs.map do |output|
          if output.kind == :json
            example = format_schema_example(output.type)
            <<~HTML
              <p><strong>Content-Type:</strong> <code>application/json</code></p>
              <div class="code-block">#{html_escape(example)}</div>
            HTML
          elsif output.kind == :status
            "<p><strong>Status Code:</strong> #{output.type}</p>"
          end
        end.join

        <<~HTML
          <div class="section">
            <h4>Response</h4>
            #{response_content}
          </div>
        HTML
      end

      def generate_try_it_section(endpoint)
        method = endpoint.method.to_s.upcase
        path = endpoint.path
        endpoint_id = generate_anchor(method, path).gsub('-', '_')

        form_fields = build_try_it_form_fields(endpoint, endpoint_id)

        <<~HTML
          <div class="try-it-section">
            <h4>Try it out</h4>
            <form class="try-it-form" onsubmit="return tryRequest('#{endpoint_id}', '#{method}', '#{path}')">
              #{form_fields.join}
              <button type="submit" class="btn btn-primary">Send Request</button>
            </form>
            <div id="#{endpoint_id}_response" class="response-section" style="display: none;">
              <h5>Response</h5>
              <div class="code-block" id="#{endpoint_id}_response_content"></div>
            </div>
          </div>
        HTML
      end

      def build_try_it_form_fields(endpoint, endpoint_id)
        form_fields = []
        
        form_fields.concat(build_path_parameter_fields(endpoint, endpoint_id))
        form_fields.concat(build_query_parameter_fields(endpoint, endpoint_id))
        form_fields.concat(build_body_parameter_field(endpoint, endpoint_id))
        
        form_fields
      end

      def build_path_parameter_fields(endpoint, endpoint_id)
        path_params = endpoint.inputs.select { |input| input.kind == :path }
        path_params.map do |param|
          <<~HTML
            <div class="form-group">
              <label for="#{endpoint_id}_#{param.name}">#{param.name} (path parameter)</label>
              <input type="text" id="#{endpoint_id}_#{param.name}" name="#{param.name}" placeholder="Enter #{param.name}" required>
            </div>
          HTML
        end
      end

      def build_query_parameter_fields(endpoint, endpoint_id)
        query_params = endpoint.inputs.select { |input| input.kind == :query }
        query_params.map do |param|
          required = param.required? ? 'required' : ''
          <<~HTML
            <div class="form-group">
              <label for="#{endpoint_id}_#{param.name}">#{param.name} (query parameter)</label>
              <input type="text" id="#{endpoint_id}_#{param.name}" name="#{param.name}" placeholder="Enter #{param.name}" #{required}>
            </div>
          HTML
        end
      end

      def build_body_parameter_field(endpoint, endpoint_id)
        body_param = endpoint.inputs.find { |input| input.kind == :body }
        return [] unless body_param

        example = format_schema_example(body_param.type)
        [<<~HTML]
          <div class="form-group">
            <label for="#{endpoint_id}_body">Request Body (JSON)</label>
            <textarea id="#{endpoint_id}_body" name="body" rows="6" placeholder="Enter JSON body">#{html_escape(example)}</textarea>
          </div>
        HTML
      end

      def generate_scripts
        <<~JAVASCRIPT
          <script>
            async function tryRequest(endpointId, method, path) {
              event.preventDefault();
          #{'    '}
              const form = event.target;
              const formData = new FormData(form);
          #{'    '}
              // Build URL with path parameters
              let url = '#{config[:base_url]}' + path;
              const pathParams = {};
              const queryParams = {};
              let body = null;
          #{'    '}
              // Process form data
              for (const [key, value] of formData.entries()) {
                if (key === 'body') {
                  if (value.trim()) {
                    try {
                      body = JSON.parse(value);
                    } catch (e) {
                      alert('Invalid JSON in request body');
                      return false;
                    }
                  }
                } else if (path.includes(':' + key)) {
                  pathParams[key] = value;
                } else if (value.trim()) {
                  queryParams[key] = value;
                }
              }
          #{'    '}
              // Replace path parameters
              for (const [key, value] of Object.entries(pathParams)) {
                url = url.replace(':' + key, encodeURIComponent(value));
              }
          #{'    '}
              // Add query parameters
              const queryString = new URLSearchParams(queryParams).toString();
              if (queryString) {
                url += '?' + queryString;
              }
          #{'    '}
              // Prepare request options
              const options = {
                method: method,
                headers: {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json'
                }
              };
          #{'    '}
              if (body && (method === 'POST' || method === 'PUT' || method === 'PATCH')) {
                options.body = JSON.stringify(body);
              }
          #{'    '}
              // Show loading state
              const responseDiv = document.getElementById(endpointId + '_response');
              const responseContent = document.getElementById(endpointId + '_response_content');
              responseDiv.style.display = 'block';
              responseContent.textContent = 'Loading...';
          #{'    '}
              try {
                const response = await fetch(url, options);
                const responseText = await response.text();
          #{'      '}
                let responseData;
                try {
                  responseData = JSON.parse(responseText);
                  responseContent.innerHTML = `
                    <strong>Status:</strong> ${response.status} ${response.statusText}<br><br>
                    <strong>Response:</strong><br>
                    ${JSON.stringify(responseData, null, 2)}
                  `;
                } catch (e) {
                  responseContent.innerHTML = `
                    <strong>Status:</strong> ${response.status} ${response.statusText}<br><br>
                    <strong>Response:</strong><br>
                    ${responseText}
                  `;
                }
              } catch (error) {
                responseContent.innerHTML = `
                  <strong>Error:</strong><br>
                  ${error.message}
                `;
              }
          #{'    '}
              return false;
            }
          </script>
        JAVASCRIPT
      end

      def format_schema_example(schema)
        case schema
        when Hash
          JSON.pretty_generate(
            schema.transform_values { |v| generate_example_value(v) }
          )
        when Array
          if schema.length == 1
            JSON.pretty_generate([generate_example_value(schema.first)])
          else
            '[]'
          end
        else
          generate_example_value(schema).to_s
        end
      end

      def generate_example_value(type)
        case type
        when :string, String then 'example string'
        when :integer, Integer then 123
        when :float, Float then 123.45
        when :boolean then true
        when :date then '2025-01-15'
        when :datetime then '2025-01-15T10:30:00Z'
        when Hash then type.transform_values { |v| generate_example_value(v) }
        when Array then type.length == 1 ? [generate_example_value(type.first)] : []
        else 'example'
        end
      end

      def format_type(type)
        case type
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

      def html_escape(text)
        text.to_s
            .gsub('&', '&amp;')
            .gsub('<', '&lt;')
            .gsub('>', '&gt;')
            .gsub('"', '&quot;')
            .gsub("'", '&#39;')
      end
    end
  end
end
