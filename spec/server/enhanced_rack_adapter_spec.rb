# frozen_string_literal: true

require 'spec_helper'
require 'rack/test'
require_relative '../../lib/rapitapir'

RSpec.describe RapiTapir::Server::EnhancedRackAdapter do
  include Rack::Test::Methods

  let(:adapter) { described_class.new }
  let(:app) { adapter }

  before do
    RapiTapir.clear_endpoints
  end

  describe 'routing and defaults' do
    it 'returns 404 for unknown paths' do
      get '/nope'

      expect(last_response.status).to eq(404)
      body = JSON.parse(last_response.body)
      expect(body['error']).to eq('Not Found')
    end

    it 'defaults to 201 for POST with no explicit outputs and serializes JSON' do
      endpoint = RapiTapir.post('/items')
                          .json_body(RapiTapir::Types.hash({ 'name' => RapiTapir::Types.string }))
                          .build

      endpoint = endpoint.validate_request_with(->(_inputs) { true })

      adapter.mount(endpoint) do |inputs|
        { id: 1, name: inputs[:body]['name'] }
      end

      post '/items', JSON.generate({ name: 'Gadget' }), { 'CONTENT_TYPE' => 'application/json' }

      expect(last_response.status).to eq(201)
      expect(last_response.content_type).to include('application/json')
      body = JSON.parse(last_response.body)
      expect(body).to eq({ 'id' => 1, 'name' => 'Gadget' })
    end
  end

  describe 'input validation and errors' do
    it "returns 400 when required query param is missing" do
      endpoint = RapiTapir.get('/hello')
                          .query(:name, RapiTapir::Types.string)
                          .build

      adapter.mount(endpoint) { |_inputs| { ok: true } }

      get '/hello'

      expect(last_response.status).to eq(400)
      body = JSON.parse(last_response.body)
      expect(body['error']).to eq('Validation Error')
      expect(body['message']).to include("Required input 'name' is missing")
    end

    it 'returns 400 for invalid JSON body' do
      endpoint = RapiTapir.post('/json')
                          .json_body(RapiTapir::Types.hash({ 'foo' => RapiTapir::Types.string }))
                          .build

      adapter.mount(endpoint) { |inputs| { received: inputs[:body] } }

      post '/json', 'not-json', { 'CONTENT_TYPE' => 'application/json' }

      expect(last_response.status).to eq(400)
      body = JSON.parse(last_response.body)
      expect(body['error']).to eq('Validation Error')
      expect(body['message']).to include('Invalid JSON')
    end

    it "returns 400 when integer path param coercion fails" do
      endpoint = RapiTapir.get('/items/:id')
                          .path_param(:id, RapiTapir::Types.integer)
                          .build

      adapter.mount(endpoint) { |inputs| { id: inputs[:id] } }

      get '/items/not-a-number'

      expect(last_response.status).to eq(400)
      body = JSON.parse(last_response.body)
      expect(body['error']).to eq('Validation Error')
      expect(body['message']).to include("Input 'id' coercion failed")
    end

    it 'uses custom validator and returns specific type validation error payload' do
      endpoint = RapiTapir.get('/check').build

      # Inject a validator that raises a Types::ValidationError directly to hit that rescue path
      failing_type = RapiTapir::Types.string
      validator = lambda do |_inputs|
        raise RapiTapir::Types::ValidationError.new('bad', failing_type, ['not allowed'])
      end

      endpoint = endpoint.validate_request_with(validator)
      adapter.mount(endpoint) { |_inputs| { ok: true } }

      get '/check'

      expect(last_response.status).to eq(400)
      body = JSON.parse(last_response.body)
      expect(body['error']).to eq('Type Validation Error')
      expect(body['errors']).to include('not allowed')
    end
  end

  describe 'custom error handling' do
    it 'invokes registered error handler for StandardError' do
      endpoint = RapiTapir.get('/boom').build
      adapter.on_error(StandardError) { |e| { error: 'custom', message: e.message } }

      adapter.mount(endpoint) do |_inputs|
        raise StandardError, 'Boom'
      end

      get '/boom'

      expect(last_response.status).to eq(500)
      body = JSON.parse(last_response.body)
      expect(body).to eq({ 'error' => 'custom', 'message' => 'Boom' })
    end
  end

  describe 'body format detection and headers' do
    it 'parses application/x-www-form-urlencoded when format is form' do
      endpoint = RapiTapir.post('/form')
                          .form_body(RapiTapir::Types.hash({ 'a' => RapiTapir::Types.string, 'b' => RapiTapir::Types.string }))
                          .build

      adapter.mount(endpoint) { |inputs| { got: inputs[:body] } }

      post '/form', 'a=1&b=2', { 'CONTENT_TYPE' => 'application/x-www-form-urlencoded' }

      expect(last_response.status).to eq(201)
      body = JSON.parse(last_response.body)
      expect(body['got']).to include('a' => '1', 'b' => '2')
    end

    it 'extracts Authorization header via special casing' do
      endpoint = RapiTapir.get('/secure')
                          .header(:authorization, RapiTapir::Types.string)
                          .build

      adapter.mount(endpoint) { |inputs| { auth: inputs[:authorization] } }

      # Missing header -> 400
      get '/secure'
      expect(last_response.status).to eq(400)

      # With header -> 200
      header 'Authorization', 'Bearer abc123'
      get '/secure'
      expect(last_response.status).to eq(200)
      body = JSON.parse(last_response.body)
      expect(body).to eq({ 'auth' => 'Bearer abc123' })
    end

    it 'parses text/plain body when no explicit format is set' do
      endpoint = RapiTapir.post('/plain')
                          .body(RapiTapir::Types.string, content_type: 'text/plain')
                          .build

      adapter.mount(endpoint) { |inputs| { got: inputs[:body] } }

      post '/plain', 'raw text body', { 'CONTENT_TYPE' => 'text/plain' }

      expect(last_response.status).to eq(201)
      body = JSON.parse(last_response.body)
      expect(body['got']).to eq('raw text body')
    end

    it 'extracts dashed custom headers correctly' do
      endpoint = RapiTapir.get('/x')
                          .header(:'x-custom-header', RapiTapir::Types.string)
                          .build

      adapter.mount(endpoint) { |inputs| { header: inputs[:'x-custom-header'] } }

      header 'X-Custom-Header', 'abc'
      get '/x'
      expect(last_response.status).to eq(200)
      body = JSON.parse(last_response.body)
      expect(body).to eq({ 'header' => 'abc' })
    end
  end

  describe 'response defaults and validation' do
    it 'defaults DELETE to 204 when no outputs' do
      endpoint = RapiTapir.delete('/items/:id')
                          .path_param(:id, RapiTapir::Types.integer)
                          .build

      adapter.mount(endpoint) { |_inputs| {} }

      delete '/items/1'
      expect(last_response.status).to eq(204)
      # No body expected for 204
      expect(last_response.body).to eq('')
    end

    it 'supports text/plain output and content-type' do
      endpoint = RapiTapir.get('/text')
                          .ok(RapiTapir::Types.string, content_type: 'text/plain')
                          .build

      adapter.mount(endpoint) { |_inputs| 'hello' }

      get '/text'
      expect(last_response.status).to eq(200)
      expect(last_response.content_type).to include('text/plain')
      expect(last_response.body).to eq('hello')
    end

    it 'returns 500 when response validation fails' do
      endpoint = RapiTapir.get('/validate')
                          .ok(RapiTapir::Types.integer)
                          .build

      # Return a non-integer to trigger response validation failure
      adapter.mount(endpoint) { |_inputs| 'not-an-integer' }

      get '/validate'
      expect(last_response.status).to eq(500)
      body = JSON.parse(last_response.body)
      expect(body['error']).to eq('StandardError')
      expect(body['message']).to include('Response validation failed')
    end

    it 'returns 400 when JSON body contains unexpected additional properties' do
      schema = RapiTapir::Types.hash({ 'a' => RapiTapir::Types.string, 'b' => RapiTapir::Types.integer })
      endpoint = RapiTapir.post('/strict')
                          .json_body(schema)
                          .build

      adapter.mount(endpoint) { |inputs| inputs[:body] }

      post '/strict', JSON.generate({ a: 'ok', b: 1, extra: true }), { 'CONTENT_TYPE' => 'application/json' }

      expect(last_response.status).to eq(400)
      body = JSON.parse(last_response.body)
      expect(body['error']).to eq('Validation Error')
      expect(body['message']).to include('Unexpected fields')
    end

    it 'falls back to default error response when custom error handler raises' do
      endpoint = RapiTapir.get('/oops').build
      adapter.on_error(StandardError) { |_e| raise 'handler failure' }

      adapter.mount(endpoint) { |_inputs| raise StandardError, 'boom' }

      get '/oops'

      expect(last_response.status).to eq(500)
      body = JSON.parse(last_response.body)
      expect(body['error']).to eq('StandardError')
      expect(body['message']).to eq('boom')
    end
  end
end
