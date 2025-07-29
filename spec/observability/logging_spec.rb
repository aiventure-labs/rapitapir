# frozen_string_literal: true

require 'spec_helper'
require 'rapitapir/observability'
require 'stringio'

RSpec.describe RapiTapir::Observability::Logging do
  let(:output) { StringIO.new }
  let(:logger) { RapiTapir::Observability::Logging::StructuredLogger.new(output: output, level: :debug, format: :json) }

  after(:each) do
    # Reset module-level logger
    described_class.instance_variable_set(:@logger, nil)
  end

  describe RapiTapir::Observability::Logging::StructuredLogger do
    describe '#initialize' do
      it 'creates logger with specified output and level' do
        expect(logger.logger).to be_a(::Logger)
        expect(logger.logger.level).to eq ::Logger::DEBUG
      end
    end

    describe 'log level methods' do
      [:debug, :info, :warn, :error, :fatal].each do |level|
        describe "##{level}" do
          it "logs at #{level} level with structured format" do
            RapiTapir::Observability.configure do |config|
              config.logging.enabled = true
            end
            
            logger.public_send(level, "Test message", custom_field: "value")
            
            output.rewind
            log_line = output.read
            expect(log_line).to include('"message":"Test message"')
            expect(log_line).to include('"custom_field":"value"')
            expect(log_line).to include('"service":"rapitapir"')
          end
        end
      end
    end

    describe '#log_request' do
      it 'logs HTTP request with structured format' do
        RapiTapir::Observability.configure do |config|
          config.logging.enabled = true
        end
        
        logger.log_request(
          method: :post,
          path: '/users',
          status: 201,
          duration: 0.123,
          request_id: 'req-123'
        )
        
        output.rewind
        log_line = output.read
        
        parsed = JSON.parse(log_line)
        expect(parsed['event_type']).to eq 'http_request'
        expect(parsed['method']).to eq 'POST'
        expect(parsed['path']).to eq '/users'
        expect(parsed['status']).to eq 201
        expect(parsed['duration_ms']).to eq 123.0
        expect(parsed['request_id']).to eq 'req-123'
      end

      it 'uses appropriate log level based on status code' do
        RapiTapir::Observability.configure do |config|
          config.logging.enabled = true
        end
        
        # Test 500 error (should be error level)
        logger.log_request(method: :get, path: '/test', status: 500, duration: 0.1)
        output.rewind
        log_line = output.read
        parsed = JSON.parse(log_line)
        expect(parsed['level']).to eq 'ERROR'
        
        output.truncate(0)
        output.rewind
        
        # Test 400 error (should be warn level)
        logger.log_request(method: :get, path: '/test', status: 400, duration: 0.1)
        output.rewind
        log_line = output.read
        parsed = JSON.parse(log_line)
        expect(parsed['level']).to eq 'WARN'
        
        output.truncate(0)
        output.rewind
        
        # Test 200 success (should be info level)
        logger.log_request(method: :get, path: '/test', status: 200, duration: 0.1)
        output.rewind
        log_line = output.read
        parsed = JSON.parse(log_line)
        expect(parsed['level']).to eq 'INFO'
      end
    end

    describe '#log_error' do
      it 'logs exception with structured format' do
        RapiTapir::Observability.configure do |config|
          config.logging.enabled = true
        end
        
        exception = StandardError.new("Test error")
        exception.set_backtrace([
          "/path/to/file.rb:10:in `method1'",
          "/path/to/file.rb:5:in `method2'"
        ])
        
        logger.log_error(exception, request_id: 'req-123', operation: 'test_op')
        
        output.rewind
        log_line = output.read
        
        parsed = JSON.parse(log_line)
        expect(parsed['event_type']).to eq 'error'
        expect(parsed['error_class']).to eq 'StandardError'
        expect(parsed['error_message']).to eq 'Test error'
        expect(parsed['error_backtrace']).to be_an Array
        expect(parsed['request_id']).to eq 'req-123'
        expect(parsed['operation']).to eq 'test_op'
      end
    end
  end

  describe 'formatters' do
    describe RapiTapir::Observability::Logging::JsonFormatter do
      let(:formatter) { described_class.new }

      it 'formats hash as JSON' do
        result = formatter.call('INFO', Time.now, nil, { message: 'test', field: 'value' })
        parsed = JSON.parse(result)
        expect(parsed['message']).to eq 'test'
        expect(parsed['field']).to eq 'value'
      end

      it 'formats string message as JSON' do
        timestamp = Time.now
        result = formatter.call('INFO', timestamp, nil, 'test message')
        parsed = JSON.parse(result)
        expect(parsed['level']).to eq 'INFO'
        expect(parsed['message']).to eq 'test message'
      end
    end

    describe RapiTapir::Observability::Logging::LogfmtFormatter do
      let(:formatter) { described_class.new }

      it 'formats hash as logfmt' do
        result = formatter.call('INFO', Time.now, nil, { message: 'test', field: 'value' })
        expect(result).to include('message=test')
        expect(result).to include('field=value')
      end

      it 'handles values with spaces by quoting them' do
        result = formatter.call('INFO', Time.now, nil, { message: 'test message' })
        expect(result).to include('message="test message"')
      end
    end

    describe RapiTapir::Observability::Logging::TextFormatter do
      let(:formatter) { described_class.new }

      it 'formats hash as text with key=value pairs' do
        timestamp = Time.now
        result = formatter.call('INFO', timestamp, nil, { message: 'test', field: 'value' })
        expect(result).to include('[INFO]')
        expect(result).to include('test')
        expect(result).to include('field=value')
      end

      it 'formats simple string message' do
        timestamp = Time.now
        result = formatter.call('INFO', timestamp, nil, 'simple message')
        expect(result).to include('[INFO]')
        expect(result).to include('simple message')
      end
    end
  end

  describe 'module methods' do
    before do
      RapiTapir::Observability.configure do |config|
        config.logging.enabled = true
        config.logging.structured = true
      end
      
      described_class.configure(
        output: output,
        level: :debug,
        format: :json,
        structured: true
      )
    end

    [:debug, :info, :warn, :error, :fatal].each do |level|
      describe ".#{level}" do
        it "delegates to logger #{level} method" do
          described_class.public_send(level, "Test message", field: "value")
          
          output.rewind
          log_line = output.read
          expect(log_line).to include('"message":"Test message"')
          expect(log_line).to include('"field":"value"')
        end
      end
    end

    describe '.log_request' do
      it 'delegates to logger log_request method' do
        described_class.log_request(
          method: :get,
          path: '/test',
          status: 200,
          duration: 0.1,
          request_id: 'req-123'
        )
        
        output.rewind
        log_line = output.read
        parsed = JSON.parse(log_line)
        expect(parsed['event_type']).to eq 'http_request'
        expect(parsed['method']).to eq 'GET'
      end
    end

    describe '.log_error' do
      it 'delegates to logger log_error method' do
        exception = StandardError.new("Test error")
        described_class.log_error(exception, request_id: 'req-123')
        
        output.rewind
        log_line = output.read
        parsed = JSON.parse(log_line)
        expect(parsed['event_type']).to eq 'error'
        expect(parsed['error_class']).to eq 'StandardError'
      end
    end

    context 'when logging is disabled' do
      before do
        RapiTapir::Observability.configure do |config|
          config.logging.enabled = false
        end
      end

      it 'does not log when disabled' do
        described_class.info("This should not be logged")
        
        output.rewind
        expect(output.read).to be_empty
      end
    end
  end
end
