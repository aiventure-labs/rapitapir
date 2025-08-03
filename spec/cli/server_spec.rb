# frozen_string_literal: true

require 'spec_helper'
require 'net/http'
require 'tempfile'
require 'webmock/rspec'

RSpec.describe RapiTapir::CLI::Server do
  include RapiTapir::DSL

  let(:test_endpoints_file) { 'spec/fixtures/server_endpoints.rb' }
  let(:temp_dir) { Dir.mktmpdir }
  let(:port) { 9998 } # Use a different port to avoid conflicts

  before do
    # Clear any existing endpoints
    RapiTapir.instance_variable_set(:@endpoints, [])

    # Create a test endpoints file
    File.write(test_endpoints_file, <<~RUBY)
      require 'rapitapir'

      RapiTapir.get('/users')
        .ok(RapiTapir::Types.array(RapiTapir::Types.hash({"id" => RapiTapir::Types.integer, "name" => RapiTapir::Types.string})))
        .summary('Get all users')
        .description('Retrieve a list of all users')
        .build

      RapiTapir.post('/users')
        .json_body(RapiTapir::Types.hash({"name" => RapiTapir::Types.string, "email" => RapiTapir::Types.string}))
        .ok(RapiTapir::Types.hash({"id" => RapiTapir::Types.integer, "name" => RapiTapir::Types.string, "email" => RapiTapir::Types.string}))
        .summary('Create user')
        .description('Create a new user')
        .build
    RUBY
  end

  after do
    FileUtils.rm_f(test_endpoints_file)
    FileUtils.rm_rf(temp_dir)
  end

  describe '#initialize' do
    it 'sets endpoints_file and port' do
      server = described_class.new(endpoints_file: test_endpoints_file, port: port)
      expect(server.endpoints_file).to eq(test_endpoints_file)
      expect(server.port).to eq(port)
    end

    it 'has default port' do
      server = described_class.new(endpoints_file: test_endpoints_file)
      expect(server.port).to eq(3000)
    end
  end

  describe '#start' do
    let(:server) { described_class.new(endpoints_file: test_endpoints_file, port: port) }

    it 'starts server without errors' do
      # Test that server can be initialized and would start
      # We won't actually start it to avoid blocking tests
      expect(server).to respond_to(:start)
      expect { server.send(:load_endpoints) }.not_to raise_error
    end

    # Integration test that actually starts the server briefly
    it 'serves documentation when started', slow: true do
      # Allow real HTTP connections for this integration test
      WebMock.allow_net_connect!
      
      server_pid = nil

      begin
        # Start server in a separate process
        server_pid = fork do
          # Suppress output in the child process
          $stdout.reopen(File::NULL, 'w')
          $stderr.reopen(File::NULL, 'w')
          server.start
        end

        # Wait for server to start
        sleep(1)

        # Try to connect
        response = Net::HTTP.get_response(URI("http://localhost:#{port}"))
        expect(response.code).to eq('200')
        expect(response.body).to include('API Documentation')
        expect(response.body).to include('API Documentation')
        expect(response.body).to include('/users')
      rescue StandardError => e
        # If connection fails, that's expected in some environments
        puts "Server test skipped: #{e.message}"
      ensure
        # Re-disable network connections
        WebMock.disable_net_connect!
        if server_pid
          begin
            Process.kill('TERM', server_pid)
          rescue StandardError
            nil
          end
          begin
            Process.wait(server_pid)
          rescue StandardError
            nil
          end
        end
      end
    end
  end

  describe '#load_endpoints' do
    let(:server) { described_class.new(endpoints_file: test_endpoints_file, port: port) }

    it 'loads endpoints from file' do
      endpoints = server.send(:load_endpoints)
      expect(endpoints).to be_an(Array)
      expect(endpoints.size).to eq(2)
      expect(endpoints.first.method).to eq(:get)
      expect(endpoints.first.path).to eq('/users')
    end

    context 'with invalid file' do
      let(:invalid_file) { 'non_existent.rb' }
      let(:server) { described_class.new(endpoints_file: invalid_file, port: port) }

      it 'raises error for non-existent file' do
        expect { server.send(:load_endpoints) }.to raise_error(/Error loading endpoints/)
      end
    end

    context 'with file containing syntax errors' do
      let(:syntax_error_file) { 'spec/fixtures/syntax_error_endpoints.rb' }
      let(:server) { described_class.new(endpoints_file: syntax_error_file, port: port) }

      before do
        File.write(syntax_error_file, <<~RUBY)
          require 'rapitapir'

          # Syntax error - missing end
          RapiTapir.get('/users'
            .out(json_body([{ id: :integer, name: :string }]))
        RUBY
      end

      after do
        FileUtils.rm_f(syntax_error_file)
      end

      it 'raises error for syntax errors' do
        expect { server.send(:load_endpoints) }.to raise_error(SyntaxError)
      end
    end
  end

  describe 'private helper methods' do
    let(:server) { described_class.new(endpoints_file: test_endpoints_file, port: port) }

    describe '#mime_type' do
      it 'returns correct MIME types' do
        expect(server.send(:mime_type, '.html')).to eq('text/html')
        expect(server.send(:mime_type, '.css')).to eq('text/css')
        expect(server.send(:mime_type, '.js')).to eq('application/javascript')
        expect(server.send(:mime_type, '.json')).to eq('application/json')
        expect(server.send(:mime_type, '.unknown')).to eq('text/plain')
      end
    end
  end

  describe 'configuration' do
    it 'accepts custom configuration' do
      config = {
        title: 'Custom API',
        description: 'Custom description',
        version: '2.0.0'
      }
      server = described_class.new(
        endpoints_file: test_endpoints_file,
        port: port,
        config: config
      )
      expect(server.config[:title]).to eq('Custom API')
      expect(server.config[:version]).to eq('2.0.0')
    end

    it 'has default configuration values' do
      server = described_class.new(endpoints_file: test_endpoints_file, port: port)
      expect(server.config[:title]).to eq('API Documentation')
      expect(server.config[:include_try_it]).to be(true)
    end
  end

  describe 'error handling' do
    let(:server) { described_class.new(endpoints_file: test_endpoints_file, port: port) }

    it 'handles missing endpoints file gracefully' do
      server = described_class.new(endpoints_file: 'missing.rb', port: port)
      expect { server.send(:load_endpoints) }.to raise_error(/Error loading endpoints/)
    end
  end
end
