# frozen_string_literal: true

require 'optparse'
require 'fileutils'

module RapiTapir
  module CLI
    # Command-line interface for RapiTapir operations
    # Provides commands for generating OpenAPI specs, clients, and documentation
    class Command
      attr_reader :options

      def initialize(args = ARGV)
        @args = args
        @options = {
          input: nil,
          output: nil,
          format: 'json',
          config: {}
        }
      end

      def run
        parser = create_option_parser

        begin
          parser.parse!(@args)

          command = @args.shift
          case command
          when 'generate'
            run_generate(@args)
          when 'serve'
            run_serve(@args)
          when 'validate'
            run_validate(@args)
          when 'version'
            puts "RapiTapir version #{RapiTapir::VERSION}"
          when 'help', nil
            puts parser.help
          else
            puts "Unknown command: #{command}"
            puts parser.help
            exit 1
          end
        rescue OptionParser::InvalidOption => e
          puts "Error: #{e.message}"
          puts parser.help
          exit 1
        rescue StandardError => e
          puts "Error: #{e.message}"
          raise e if ENV['RSPEC_RUNNING']

          exit 1
        end
      end

      private

      def create_option_parser
        OptionParser.new do |opts|
          opts.banner = 'Usage: rapitapir [options] command [args]'
          opts.separator ''
          opts.separator 'Commands:'
          opts.separator '  generate TYPE    Generate clients or documentation'
          opts.separator '  serve           Start documentation server'
          opts.separator '  validate        Validate endpoint definitions'
          opts.separator '  version         Show version'
          opts.separator '  help            Show this help'
          opts.separator ''
          opts.separator 'Options:'

          opts.on('-i', '--input FILE', '--endpoints FILE', 'Input Ruby file with endpoint definitions') do |file|
            @options[:input] = file
          end

          opts.on('-o', '--output FILE', 'Output file path') do |file|
            @options[:output] = file
          end

          opts.on('-f', '--format FORMAT', 'Output format (json, yaml, ts, py, md, html)') do |format|
            @options[:format] = format
          end

          opts.on('-c', '--config KEY=VALUE', 'Configuration option (can be used multiple times)') do |config|
            key, value = config.split('=', 2)
            @options[:config][key.to_sym] = value
          end

          opts.on('--base-url URL', 'Base URL for the API') do |url|
            @options[:config][:base_url] = url
          end

          opts.on('--client-name NAME', 'Name for generated client class') do |name|
            @options[:config][:client_name] = name
          end

          opts.on('--package-name NAME', 'Package name for generated client') do |name|
            @options[:config][:package_name] = name
          end

          opts.on('--client-version VERSION', 'Version for generated client') do |version|
            @options[:config][:version] = version
          end

          opts.on('-v', '--version', 'Show RapiTapir version') do
            puts "RapiTapir version #{RapiTapir::VERSION}"
            exit
          end

          opts.on('-h', '--help', 'Show this help') do
            puts opts
            exit
          end
        end
      end

      def run_generate(args)
        type = args.shift
        unless type
          puts 'Error: Generate command requires a type'
          puts 'Available types: openapi, client, docs'
          exit 1
        end

        case type
        when 'openapi'
          generate_openapi
        when 'client'
          client_type = args.shift || 'typescript'
          generate_client(client_type)
        when 'docs'
          docs_type = args.shift || 'html'
          generate_docs(docs_type)
        else
          puts "Error: Unknown generation type: #{type}"
          puts 'Available types: openapi, client, docs'
          exit 1
        end
      end

      def run_serve(args)
        port = args.shift || '3000'

        unless @options[:input]
          puts 'Error: --endpoints option is required for serve command'
          exit 1
        end

        require_relative 'server'
        server = CLI::Server.new(endpoints_file: @options[:input], port: port.to_i, config: @options[:config] || {})
        puts "Starting documentation server on port #{port}..."
        server.start
      end

      def run_validate(_args)
        unless @options[:input]
          puts 'Error: --endpoints is required'
          exit 1
        end

        endpoints = load_endpoints(@options[:input])
        require_relative 'validator'
        validator = CLI::Validator.new(endpoints)

        if validator.validate
          puts '✓ All endpoints are valid'
        else
          puts '✗ Validation failed:'
          validator.errors.each { |error| puts "  - #{error}" }
          exit 1
        end
      end

      def generate_openapi
        unless @options[:input]
          puts 'Error: --endpoints is required'
          exit 1
        end

        unless @options[:output]
          puts 'Error: --output is required'
          exit 1
        end

        begin
          endpoints = load_endpoints(@options[:input])

          require_relative '../openapi/schema_generator'

          # Prepare config for OpenAPI generator
          openapi_info = {
            title: @options[:config][:title] || 'API Documentation',
            version: @options[:config][:version] || '1.0.0',
            description: @options[:config][:description] || 'Auto-generated API documentation'
          }

          openapi_servers = []
          openapi_servers << { url: @options[:config][:base_url] } if @options[:config][:base_url]

          generator = RapiTapir::OpenAPI::SchemaGenerator.new(
            endpoints: endpoints,
            info: openapi_info,
            servers: openapi_servers
          )

          content = case @options[:format]
                    when 'yaml', 'yml'
                      generator.to_yaml
                    else
                      generator.to_json
                    end

          if @options[:output]
            File.write(@options[:output], content)
            puts "OpenAPI schema saved to #{@options[:output]}"
          else
            puts content
          end
        rescue StandardError => e
          puts "Error generating OpenAPI schema: #{e.message}"
          puts "Backtrace: #{e.backtrace.first(5).join("\n")}"
          exit 1
        end
      end

      def generate_client(client_type)
        unless @options[:input]
          puts 'Error: --endpoints is required'
          exit 1
        end

        unless @options[:output]
          puts 'Error: --output is required'
          exit 1
        end

        endpoints = load_endpoints(@options[:input])

        case client_type
        when 'typescript', 'ts'
          require_relative '../client/typescript_generator'
          generator = RapiTapir::Client::TypescriptGenerator.new(
            endpoints: endpoints,
            config: @options[:config]
          )
          extension = 'ts'
        when 'python', 'py'
          # TODO: Implement Python generator
          puts 'Error: Python client generator not implemented yet'
          exit 1
        else
          puts "Error: Unknown client type: #{client_type}"
          puts 'Available types: typescript, python'
          exit 1
        end

        content = generator.generate

        if @options[:output]
          File.write(@options[:output], content)
          puts "#{client_type.capitalize} client saved to #{@options[:output]}"
        else
          # Generate default filename
          default_output = "api-client.#{extension}"
          File.write(default_output, content)
          puts "#{client_type.capitalize} client saved to #{default_output}"
        end
      end

      def generate_docs(docs_type)
        unless @options[:input]
          puts 'Error: --endpoints is required'
          exit 1
        end

        unless @options[:output]
          puts 'Error: --output is required'
          exit 1
        end

        endpoints = load_endpoints(@options[:input])

        case docs_type
        when 'markdown', 'md'
          require_relative '../docs/markdown_generator'
          generator = RapiTapir::Docs::MarkdownGenerator.new(
            endpoints: endpoints,
            config: @options[:config]
          )
          extension = 'md'
        when 'html'
          require_relative '../docs/html_generator'
          generator = RapiTapir::Docs::HtmlGenerator.new(
            endpoints: endpoints,
            config: @options[:config]
          )
          extension = 'html'
        else
          puts "Error: Unknown documentation type: #{docs_type}"
          puts 'Available types: markdown, html'
          exit 1
        end

        content = generator.generate

        if @options[:output]
          File.write(@options[:output], content)
          puts "#{docs_type.capitalize} documentation saved to #{@options[:output]}"
        else
          # Generate default filename
          default_output = "api-docs.#{extension}"
          File.write(default_output, content)
          puts "#{docs_type.capitalize} documentation saved to #{default_output}"
        end
      end

      def load_endpoints(file_path)
        raise "Input file not found: #{file_path}" unless File.exist?(file_path)

        prepare_loading_environment(file_path) do
          content = File.read(file_path)
          load_endpoints_from_content(content, file_path) || load_endpoints_fallback(file_path)
        end
      end

      def prepare_loading_environment(file_path)
        # Store original state
        original_endpoints = RapiTapir.instance_variable_get(:@endpoints) || []
        original_load_path = $LOAD_PATH.dup

        # Add the file's directory to load path for relative requires
        file_dir = File.dirname(File.expand_path(file_path))
        $LOAD_PATH.unshift(file_dir) unless $LOAD_PATH.include?(file_dir)

        RapiTapir.instance_variable_set(:@endpoints, [])

        begin
          yield
        rescue SyntaxError => e
          raise "Syntax error in #{file_path}: #{e.message}"
        ensure
          RapiTapir.instance_variable_set(:@endpoints, original_endpoints)
          $LOAD_PATH.replace(original_load_path)
        end
      end

      def load_endpoints_from_content(content, file_path)
        return nil unless content.match?(/(\w+_api|\w+_endpoints|\wendpoints\w*)\s*=\s*\[/)

        file_dir = File.dirname(File.expand_path(file_path))
        Dir.chdir(file_dir) do
          # Execute the file content using load instead of eval for safety
          # rubocop:disable Security/Eval
          eval(content, TOPLEVEL_BINDING, file_path)
          # rubocop:enable Security/Eval
        end

        find_endpoints_in_variables(content)
      end

      def find_endpoints_in_variables(content)
        # Try instance variables
        endpoints = find_endpoints_in_instance_variables
        return endpoints if endpoints

        # Try global variables
        endpoints = find_endpoints_in_global_variables
        return endpoints if endpoints

        # Try content-matched variables
        find_endpoints_in_content_variables(content)
      end

      def find_endpoints_in_instance_variables
        main_obj = TOPLEVEL_BINDING.eval('self')
        endpoints_var = main_obj.instance_variables.find do |var|
          var.to_s.include?('api') || var.to_s.include?('endpoint')
        end

        return nil unless endpoints_var

        endpoints = main_obj.instance_variable_get(endpoints_var)
        normalize_endpoints_array(endpoints)
      end

      def find_endpoints_in_global_variables
        global_endpoints_var = global_variables.find do |var|
          var.to_s.include?('api') || var.to_s.include?('endpoint')
        end

        return nil unless global_endpoints_var

        # rubocop:disable Security/Eval
        endpoints = eval(global_endpoints_var.to_s)
        # rubocop:enable Security/Eval
        normalize_endpoints_array(endpoints)
      end

      def find_endpoints_in_content_variables(content)
        var_match = content.match(/(\w+_api|\w+_endpoints|\wendpoints\w*)\s*=/)
        return nil unless var_match

        var_name = var_match[1]
        begin
          # rubocop:disable Security/Eval
          endpoints = eval(var_name, TOPLEVEL_BINDING)
          # rubocop:enable Security/Eval
          normalize_endpoints_array(endpoints)
        rescue NameError
          nil
        end
      end

      def normalize_endpoints_array(endpoints)
        return nil unless endpoints

        endpoints = [endpoints] unless endpoints.is_a?(Array)
        endpoints.flatten.compact
      end

      def load_endpoints_fallback(file_path)
        # Fallback: try loading the file normally
        load File.expand_path(file_path)
        endpoints = RapiTapir.instance_variable_get(:@endpoints) || []

        if endpoints.empty?
          error_msg = "No endpoints found in #{file_path}. " \
                      'Make sure the file defines endpoints in a variable ' \
                      "containing 'api' or 'endpoints' in its name."
          raise error_msg
        end

        endpoints
      end
    end
  end
end
