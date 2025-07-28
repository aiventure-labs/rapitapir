# frozen_string_literal: true

require 'webrick'
require 'json'

module RapiTapir
  module CLI
    class Server
      attr_reader :endpoints_file, :port, :config

      def initialize(endpoints_file:, port: 3000, config: {})
        @endpoints_file = endpoints_file
        @port = port
        @config = {
          title: 'API Documentation',
          description: 'Live API documentation',
          auto_reload: true,
          include_try_it: true
        }.merge(config)
      end

      def start
        server = WEBrick::HTTPServer.new(
          Port: @port,
          DocumentRoot: Dir.pwd,
          Logger: WEBrick::Log.new(File.open(File::NULL, 'w')),
          AccessLog: []
        )

        # Serve HTML documentation
        server.mount_proc '/' do |req, res|
          case req.path
          when '/'
            serve_documentation(res)
          when '/api.json'
            serve_openapi_json(res)
          when '/reload'
            serve_reload_endpoint(res)
          else
            res.status = 404
            res.body = 'Not Found'
          end
        end

        # Handle Ctrl+C gracefully
        trap('INT') do
          puts "\nShutting down server..."
          server.shutdown
        end

        puts "Documentation server running at http://localhost:#{port}"
        puts "Press Ctrl+C to stop"
        
        server.start
      end

      private

      def serve_documentation(response)
        begin
          endpoints = load_endpoints
          
          require_relative '../docs/html_generator'
          generator = RapiTapir::Docs::HtmlGenerator.new(
            endpoints: endpoints,
            config: config.merge(include_reload: true)
          )
          
          html_content = generator.generate
          
          # Add auto-reload script if enabled
          if config[:auto_reload]
            html_content = html_content.gsub(
              '</body>',
              auto_reload_script + '</body>'
            )
          end
          
          response['Content-Type'] = 'text/html'
          response.body = html_content
        rescue => e
          response.status = 500
          response['Content-Type'] = 'text/html'
          response.body = error_page(e)
        end
      end

      def serve_openapi_json(response)
        begin
          endpoints = load_endpoints
          
          require_relative '../openapi/schema_generator'
          generator = RapiTapir::OpenAPI::SchemaGenerator.new(endpoints: endpoints)
          
          response['Content-Type'] = 'application/json'
          response.body = generator.to_json
        rescue => e
          response.status = 500
          response['Content-Type'] = 'application/json'
          response.body = JSON.generate({ error: e.message })
        end
      end

      def serve_reload_endpoint(response)
        # This endpoint is called by the auto-reload script
        # Return current file modification time
        mtime = File.exist?(input_file) ? File.mtime(input_file).to_i : 0
        
        response['Content-Type'] = 'application/json'
        response.body = JSON.generate({ mtime: mtime })
      end

      def load_endpoints
        unless File.exist?(@endpoints_file)
          raise "Error loading endpoints: File '#{@endpoints_file}' not found"
        end

        # Create a new binding to evaluate the endpoints file
        evaluation_context = Object.new
        evaluation_context.extend(RapiTapir::DSL)
        
        begin
          code = File.read(@endpoints_file)
          evaluation_context.instance_eval(code, @endpoints_file)
          
          # Return the registered endpoints
          RapiTapir.endpoints
        rescue => e
          raise "Error loading endpoints from '#{@endpoints_file}': #{e.message}"
        end
      end

      def auto_reload_script
        <<~JAVASCRIPT
          <script>
            let lastMtime = 0;
            
            async function checkForUpdates() {
              try {
                const response = await fetch('/reload');
                const data = await response.json();
                
                if (lastMtime === 0) {
                  lastMtime = data.mtime;
                } else if (data.mtime > lastMtime) {
                  console.log('File changed, reloading...');
                  window.location.reload();
                }
              } catch (error) {
                console.log('Auto-reload check failed:', error);
              }
            }
            
            // Check for updates every 2 seconds
            setInterval(checkForUpdates, 2000);
            checkForUpdates(); // Initial check
          </script>
        JAVASCRIPT
      end

      def error_page(error)
        <<~HTML
          <!DOCTYPE html>
          <html>
          <head>
            <title>Error - API Documentation</title>
            <style>
              body { 
                font-family: Arial, sans-serif; 
                margin: 40px; 
                background-color: #f8f9fa;
              }
              .error {
                background: #fff;
                border: 1px solid #dc3545;
                border-radius: 8px;
                padding: 20px;
                box-shadow: 0 2px 4px rgba(0,0,0,0.1);
              }
              .error h1 {
                color: #dc3545;
                margin-top: 0;
              }
              .error pre {
                background: #f8f9fa;
                padding: 15px;
                border-radius: 4px;
                overflow-x: auto;
                border: 1px solid #dee2e6;
              }
              .retry-button {
                background: #007bff;
                color: white;
                border: none;
                padding: 10px 20px;
                border-radius: 4px;
                cursor: pointer;
                margin-top: 15px;
              }
              .retry-button:hover {
                background: #0056b3;
              }
            </style>
          </head>
          <body>
            <div class="error">
              <h1>Error Loading Documentation</h1>
              <p>There was an error processing your endpoint definitions:</p>
              <pre>#{error.message}</pre>
              <p>Please check your input file and try again.</p>
              <button class="retry-button" onclick="window.location.reload()">Retry</button>
            </div>
          </body>
          </html>
        HTML
      end

      private

      def mime_type(extension)
        case extension
        when '.html' then 'text/html'
        when '.css' then 'text/css'
        when '.js' then 'application/javascript'
        when '.json' then 'application/json'
        when '.xml' then 'application/xml'
        else 'text/plain'
        end
      end
    end
  end
end
