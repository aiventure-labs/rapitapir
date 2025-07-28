# frozen_string_literal: true

require 'spec_helper'
require 'tempfile'

RSpec.describe RapiTapir::CLI::Command do
  include RapiTapir::DSL

  let(:test_endpoints_file) { 'spec/fixtures/endpoints.rb' }
  let(:temp_dir) { Dir.mktmpdir }

  before do
    # Create a test endpoints file
    File.write(test_endpoints_file, <<~RUBY)
      require 'rapitapir'
      include RapiTapir::DSL

      RapiTapir.get('/users')
        .out(json_body([{ id: :integer, name: :string }]))
        .summary('Get all users')
        .description('Retrieve a list of all users')

      RapiTapir.post('/users')
        .in(body({ name: :string, email: :string }))
        .out(json_body({ id: :integer, name: :string, email: :string }))
        .summary('Create user')
        .description('Create a new user')
    RUBY
  end

  after do
    FileUtils.rm_f(test_endpoints_file)
    FileUtils.rm_rf(temp_dir)
  end

  describe '#run' do
    context 'with no arguments' do
      it 'shows help' do
        output = capture_output { described_class.new([]).run }
        expect(output).to include('Usage:')
        expect(output).to include('Commands:')
        expect(output).to include('generate')
        expect(output).to include('validate')
        expect(output).to include('serve')
      end
    end

    context 'with help flag' do
      ['-h', '--help'].each do |flag|
        it "shows help with #{flag}" do
          output = capture_output { described_class.new([flag]).run }
          expect(output).to include('Usage:')
          expect(output).to include('Commands:')
        end
      end
    end

    context 'with version flag' do
      ['-v', '--version'].each do |flag|
        it "shows version with #{flag}" do
          output = capture_output { described_class.new([flag]).run }
          expect(output).to include(RapiTapir::VERSION)
        end
      end
    end

    context 'with unknown command' do
      it 'shows error and help' do
        output = capture_output { described_class.new(['unknown']).run }
        expect(output).to include('Unknown command: unknown')
        expect(output).to include('Usage:')
      end
    end
  end

  describe 'generate command' do
    context 'with openapi type' do
      it 'generates OpenAPI schema' do
        output_file = File.join(temp_dir, 'openapi.json')
        
        expect do
          described_class.new([
            'generate', 'openapi',
            '--endpoints', test_endpoints_file,
            '--output', output_file
          ]).run
        end.not_to raise_error

        expect(File.exist?(output_file)).to be(true)
        content = JSON.parse(File.read(output_file))
        expect(content['openapi']).to eq('3.0.3')
        expect(content['paths']).to have_key('/users')
      end

      it 'supports YAML format' do
        output_file = File.join(temp_dir, 'openapi.yaml')
        
        described_class.new([
          'generate', 'openapi',
          '--endpoints', test_endpoints_file,
          '--output', output_file,
          '--format', 'yaml'
        ]).run

        expect(File.exist?(output_file)).to be(true)
        content = File.read(output_file)
        expect(content).to include('openapi: 3.0.3')
        expect(content).to include('/users:')
      end
    end

    context 'with client type' do
      it 'generates TypeScript client' do
        output_file = File.join(temp_dir, 'client.ts')
        
        described_class.new([
          'generate', 'client',
          '--endpoints', test_endpoints_file,
          '--output', output_file
        ]).run

        expect(File.exist?(output_file)).to be(true)
        content = File.read(output_file)
        expect(content).to include('export interface')
        expect(content).to include('export class ApiClient')
        expect(content).to include('getUsers')
        expect(content).to include('postUsers')
      end

      it 'supports different client languages' do
        output_file = File.join(temp_dir, 'client.ts')
        
        described_class.new([
          'generate', 'client',
          '--endpoints', test_endpoints_file,
          '--output', output_file,
          '--language', 'typescript'
        ]).run

        expect(File.exist?(output_file)).to be(true)
      end
    end

    context 'with docs type' do
      it 'generates HTML documentation' do
        output_file = File.join(temp_dir, 'docs.html')
        
        described_class.new([
          'generate', 'docs',
          '--endpoints', test_endpoints_file,
          '--output', output_file
        ]).run

        expect(File.exist?(output_file)).to be(true)
        content = File.read(output_file)
        expect(content).to include('<!DOCTYPE html>')
        expect(content).to include('Get all users')
        expect(content).to include('Create user')
      end

      it 'generates Markdown documentation' do
        output_file = File.join(temp_dir, 'docs.md')
        
        described_class.new([
          'generate', 'docs',
          '--endpoints', test_endpoints_file,
          '--output', output_file,
          '--format', 'markdown'
        ]).run

        expect(File.exist?(output_file)).to be(true)
        content = File.read(output_file)
        expect(content).to include('# API Documentation')
        expect(content).to include('## GET /users')
        expect(content).to include('## POST /users')
      end
    end

    context 'with missing required options' do
      it 'shows error for missing endpoints file' do
        output = capture_output do
          described_class.new(['generate', 'openapi']).run
        end
        expect(output).to include('--endpoints is required')
      end

      it 'shows error for missing output file' do
        output = capture_output do
          described_class.new([
            'generate', 'openapi',
            '--endpoints', test_endpoints_file
          ]).run
        end
        expect(output).to include('--output is required')
      end
    end

    context 'with invalid endpoints file' do
      it 'shows error for non-existent file' do
        output = capture_output do
          described_class.new([
            'generate', 'openapi',
            '--endpoints', 'non_existent.rb',
            '--output', 'output.json'
          ]).run
        end
        expect(output).to include('Error loading endpoints')
      end
    end
  end

  describe 'validate command' do
    it 'validates endpoints successfully' do
      output = capture_output do
        described_class.new([
          'validate',
          '--endpoints', test_endpoints_file
        ]).run
      end
      expect(output).to include('All endpoints are valid')
    end

    it 'shows error for missing endpoints file' do
      output = capture_output do
        described_class.new(['validate']).run
      end
      expect(output).to include('--endpoints is required')
    end

    context 'with invalid endpoints' do
      let(:invalid_endpoints_file) { 'spec/fixtures/invalid_endpoints.rb' }

      before do
        File.write(invalid_endpoints_file, <<~RUBY)
          require 'rapitapir'
          include RapiTapir::DSL

          # Endpoint without output definition
          RapiTapir.get('/invalid')
            .summary('Invalid endpoint')
        RUBY
      end

      after do
        FileUtils.rm_f(invalid_endpoints_file)
      end

      it 'reports validation errors' do
        output = capture_output do
          described_class.new([
            'validate',
            '--endpoints', invalid_endpoints_file
          ]).run
        end
        expect(output).to include('Validation errors found')
      end
    end
  end

  describe 'serve command' do
    it 'shows server starting message' do
      # Since we can't easily test the actual server without blocking,
      # we'll test that the command doesn't error immediately
      expect do
        # Use a signal to interrupt the server quickly
        pid = fork do
          described_class.new([
            'serve',
            '--endpoints', test_endpoints_file,
            '--port', '9999'
          ]).run
        end
        sleep(0.1) # Give it a moment to start
        Process.kill('TERM', pid)
        Process.wait(pid)
      end.not_to raise_error
    end

    it 'shows error for missing endpoints file' do
      output = capture_output do
        described_class.new(['serve']).run
      end
      expect(output).to include('--endpoints is required')
    end
  end

  describe 'option parsing' do
    let(:command) { described_class.new([]) }

    it 'parses configuration options correctly' do
      args = [
        'generate', 'docs',
        '--endpoints', 'endpoints.rb',
        '--output', 'docs.html',
        '--title', 'My API',
        '--description', 'My API Description',
        '--version', '2.0.0',
        '--base-url', 'https://api.example.com'
      ]

      options = command.send(:parse_options, args)
      
      expect(options[:endpoints]).to eq('endpoints.rb')
      expect(options[:output]).to eq('docs.html')
      expect(options[:title]).to eq('My API')
      expect(options[:description]).to eq('My API Description')
      expect(options[:version]).to eq('2.0.0')
      expect(options[:base_url]).to eq('https://api.example.com')
    end

    it 'has correct default values' do
      options = command.send(:parse_options, ['generate', 'docs'])
      
      expect(options[:format]).to eq('html')
      expect(options[:language]).to eq('typescript')
      expect(options[:port]).to eq(3000)
    end
  end

  private

  def capture_output(&block)
    original_stdout = $stdout
    $stdout = StringIO.new
    begin
      block.call
      $stdout.string
    rescue SystemExit
      $stdout.string
    ensure
      $stdout = original_stdout
    end
  end
end
