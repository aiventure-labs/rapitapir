# frozen_string_literal: true

require 'spec_helper'
require 'rack/test'
require 'rapitapir/server/rack_adapter'

RSpec.describe RapiTapir::Server::RackAdapter do
  include Rack::Test::Methods

  let(:adapter) { described_class.new }
  let(:app) { adapter }

  describe '#register_endpoint' do
    let(:endpoint) { RapiTapir.get('/users').build }
    let(:handler) { proc { |inputs| { message: 'Hello' } } }

    it 'registers an endpoint with handler' do
      expect { adapter.register_endpoint(endpoint, handler) }.not_to raise_error
      expect(adapter.endpoints.size).to eq(1)
    end

    it 'validates endpoint type' do
      expect { adapter.register_endpoint('invalid', handler) }.to raise_error(ArgumentError, /Endpoint must be/)
    end

    it 'validates handler responds to call' do
      expect { adapter.register_endpoint(endpoint, 'invalid') }.to raise_error(ArgumentError, /Handler must respond to call/)
    end
  end

  describe '#use' do
    it 'adds middleware to stack' do
      middleware_class = Class.new
      adapter.use(middleware_class, option: 'value')
      
      expect(adapter.middleware_stack.size).to eq(1)
      expect(adapter.middleware_stack.first).to eq([middleware_class, [{ option: 'value' }], nil])
    end
  end

  describe 'request processing' do
    before do
      # Register a simple endpoint
      endpoint = RapiTapir.get('/hello')
        .query(:name, :string, required: false)
        .ok(RapiTapir::Types.hash({"message" => RapiTapir::Types.string}))
        .build
      
      handler = proc do |inputs|
        { message: "Hello, #{inputs[:name] || 'World'}!" }
      end
      
      adapter.register_endpoint(endpoint, handler)
    end

    it 'processes GET request successfully' do
      get '/hello?name=John'
      
      expect(last_response.status).to eq(200)
      expect(last_response.content_type).to include('application/json')
      
      response_data = JSON.parse(last_response.body)
      expect(response_data).to eq({ 'message' => 'Hello, John!' })
    end

    it 'handles missing optional parameters' do
      get '/hello'
      
      expect(last_response.status).to eq(200)
      response_data = JSON.parse(last_response.body)
      expect(response_data).to eq({ 'message' => 'Hello, World!' })
    end

    it 'returns 404 for unregistered paths' do
      get '/unknown'
      
      expect(last_response.status).to eq(404)
      response_data = JSON.parse(last_response.body)
      expect(response_data).to eq({ 'error' => 'Not Found' })
    end
  end

  describe 'path parameters' do
    before do
      endpoint = RapiTapir.get('/users/:id')
        .path_param(:id, :string)
        .ok(RapiTapir::Types.hash({"user_id" => RapiTapir::Types.string}))
        .build
      
      handler = proc do |inputs|
        { user_id: inputs[:id] }
      end
      
      adapter.register_endpoint(endpoint, handler)
    end

    it 'extracts path parameters' do
      get '/users/123'
      
      expect(last_response.status).to eq(200)
      response_data = JSON.parse(last_response.body)
      expect(response_data).to eq({ 'user_id' => '123' })
    end
  end

  describe 'POST with JSON body' do
    before do
      endpoint = RapiTapir.post('/users')
        .json_body(RapiTapir::Types.hash({"name" => RapiTapir::Types.string}))
        .ok(RapiTapir::Types.hash({"id" => RapiTapir::Types.integer, "name" => RapiTapir::Types.string}))
        .build
      
      handler = proc do |inputs|
        user_data = inputs[:body]
        { id: 1, name: user_data['name'] }
      end
      
      adapter.register_endpoint(endpoint, handler)
    end

    it 'processes JSON body' do
      post '/users', JSON.generate({ name: 'John Doe' }), { 'CONTENT_TYPE' => 'application/json' }
      
      expect(last_response.status).to eq(200)
      response_data = JSON.parse(last_response.body)
      expect(response_data).to eq({ 'id' => 1, 'name' => 'John Doe' })
    end
  end

  describe 'error handling' do
    before do
      endpoint = RapiTapir.get('/error')
        .query(:required_param, :string)
        .build
      
      handler = proc do |inputs|
        raise StandardError, 'Something went wrong'
      end
      
      adapter.register_endpoint(endpoint, handler)
    end

    it 'handles missing required parameters' do
      get '/error'
      
      expect(last_response.status).to eq(400)
      response_data = JSON.parse(last_response.body)
      expect(response_data['error']).to eq('ArgumentError')
      expect(response_data['message']).to include('Required input')
    end

    it 'handles handler exceptions' do
      get '/error?required_param=value'
      
      expect(last_response.status).to eq(500)
      response_data = JSON.parse(last_response.body)
      expect(response_data['error']).to eq('StandardError')
      expect(response_data['message']).to eq('Something went wrong')
    end
  end
end
