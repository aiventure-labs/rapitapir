# frozen_string_literal: true

require 'spec_helper'
require 'rack/test'
require 'rapitapir/server/middleware'

RSpec.describe RapiTapir::Server::Middleware do
  include Rack::Test::Methods

  describe RapiTapir::Server::Middleware::CORS do
    let(:app) do
      RapiTapir::Server::Middleware::CORS.new(
        ->(env) { [200, {}, ['Hello World']] }
      )
    end

    it 'adds CORS headers to responses' do
      get '/'
      
      expect(last_response.headers['Access-Control-Allow-Origin']).to eq('*')
      expect(last_response.headers['Access-Control-Allow-Methods']).to include('GET')
      expect(last_response.headers['Access-Control-Allow-Headers']).to include('Content-Type')
    end

    it 'handles preflight OPTIONS requests' do
      options '/'
      
      expect(last_response.status).to eq(200)
      expect(last_response.headers['Access-Control-Allow-Origin']).to eq('*')
    end
  end

  describe RapiTapir::Server::Middleware::Logger do
    let(:logger) { instance_double('Logger') }
    let(:app) do
      RapiTapir::Server::Middleware::Logger.new(
        ->(env) { [200, {}, ['Hello World']] },
        logger
      )
    end

    it 'logs request start and completion' do
      expect(logger).to receive(:info).with(/Started GET/)
      expect(logger).to receive(:info).with(/Completed 200/)
      
      get '/'
    end
  end

  describe RapiTapir::Server::Middleware::ExceptionHandler do
    let(:logger) { instance_double('Logger') }
    let(:app) do
      RapiTapir::Server::Middleware::ExceptionHandler.new(
        ->(env) { raise StandardError, 'Test error' },
        logger: logger, show_exceptions: true
      )
    end

    it 'catches exceptions and returns error response' do
      expect(logger).to receive(:error).with(/Unhandled exception/)
      expect(logger).to receive(:error) # For backtrace
      
      get '/'
      
      expect(last_response.status).to eq(500)
      response_data = JSON.parse(last_response.body)
      expect(response_data['exception']).to eq('StandardError')
      expect(response_data['message']).to eq('Test error')
    end
  end
end
