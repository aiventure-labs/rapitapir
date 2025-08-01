# frozen_string_literal: true

module RapiTapir
  module Sinatra
    # Swagger UI HTML generator
    # Follows Single Responsibility Principle - only generates UI HTML
    class SwaggerUIGenerator
      def initialize(openapi_path, api_info)
        @openapi_path = openapi_path
        @api_info = api_info
      end

      def generate
        <<~HTML
          <!DOCTYPE html>
          <html lang="en">
          <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>#{@api_info[:title]} - API Documentation</title>
            <link rel="stylesheet" type="text/css" href="https://unpkg.com/swagger-ui-dist@5.9.0/swagger-ui.css" />
            <style>
              #{custom_styles}
            </style>
          </head>
          <body>
            #{header_banner}
            <div id="swagger-ui"></div>
            <script src="https://unpkg.com/swagger-ui-dist@5.9.0/swagger-ui-bundle.js"></script>
            <script src="https://unpkg.com/swagger-ui-dist@5.9.0/swagger-ui-standalone-preset.js"></script>
            <script>
              #{swagger_ui_config}
            </script>
          </body>
          </html>
        HTML
      end

      private

      def custom_styles
        <<~CSS
          html {
            box-sizing: border-box;
            overflow: -moz-scrollbars-vertical;
            overflow-y: scroll;
          }
          *, *:before, *:after {
            box-sizing: inherit;
          }
          body {
            margin: 0;
            background: #fafafa;
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
          }
          .swagger-ui .topbar {
            display: none;
          }
          .info-banner {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 30px 20px;
            text-align: center;
            margin-bottom: 20px;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
          }
          .info-banner h1 {
            margin: 0 0 10px 0;
            font-size: 28px;
            font-weight: 600;
          }
          .info-banner p {
            margin: 0;
            opacity: 0.9;
            font-size: 16px;
          }
          .info-banner .badge {
            display: inline-block;
            background: rgba(255, 255, 255, 0.2);
            padding: 4px 12px;
            border-radius: 20px;
            font-size: 14px;
            margin: 10px 5px 0 0;
          }
          .swagger-ui .scheme-container {
            padding: 30px 0;
            background: white;
            box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
          }
        CSS
      end

      def header_banner
        <<~HTML
          <div class="info-banner">
            <h1>#{@api_info[:title]}</h1>
            <p>#{@api_info[:description]}</p>
            <div>
              <span class="badge">v#{@api_info[:version]}</span>
              <span class="badge">🚀 RapiTapir</span>
              <span class="badge">⚡ Auto-generated</span>
            </div>
          </div>
        HTML
      end

      def swagger_ui_config
        <<~JS
          window.onload = function() {
            const ui = SwaggerUIBundle({
              url: '#{@openapi_path}',
              dom_id: '#swagger-ui',
              deepLinking: true,
              presets: [
                SwaggerUIBundle.presets.apis,
                SwaggerUIStandalonePreset
              ],
              plugins: [
                SwaggerUIBundle.plugins.DownloadUrl
              ],
              layout: "StandaloneLayout",
              tryItOutEnabled: true,
              supportedSubmitMethods: ['get', 'post', 'put', 'delete', 'patch', 'head', 'options'],
              validatorUrl: null,
              docExpansion: 'list',
              filter: true,
              showExtensions: true,
              showCommonExtensions: true,
              defaultModelsExpandDepth: 2,
              defaultModelExpandDepth: 2,
              displayRequestDuration: true,
              requestInterceptor: function(request) {
                // Add custom request headers or modify requests here
                return request;
              },
              responseInterceptor: function(response) {
                // Handle responses here
                return response;
              },
              onComplete: function() {
                console.log('🚀 RapiTapir Swagger UI loaded successfully');
                console.log('📋 OpenAPI spec auto-generated from RapiTapir endpoints');
                console.log('🔧 Powered by RapiTapir Sinatra Extension');
              },
              onFailure: function(error) {
                console.error('Failed to load Swagger UI:', error);
              }
            });

            // Custom enhancements
            setTimeout(function() {
              // Add custom styling or behavior after UI loads
              const infoSection = document.querySelector('.swagger-ui .info');
              if (infoSection && !infoSection.querySelector('.rapitapir-badge')) {
                const badge = document.createElement('div');
                badge.className = 'rapitapir-badge';
                badge.innerHTML = '<small style="color: #666; font-style: italic;">Generated with RapiTapir Sinatra Extension</small>';
                infoSection.appendChild(badge);
              }
            }, 1000);
          };
        JS
      end
    end
  end
end
