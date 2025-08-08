# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RapiTapir::DSL::EnhancedOutput do
  it 'maps common status codes to standard descriptions and handles custom headers' do
    type = RapiTapir::Types.hash({ 'message' => RapiTapir::Types.string })
    out = described_class.new(status_code: 201, type: type, headers: { 'X-RateLimit' => 'Limit info' })

    spec = out.to_openapi_spec
    expect(spec[:description]).to eq('Created')
    expect(spec[:content]['application/json'][:schema]).to be_a(Hash)
    expect(spec[:headers]['X-RateLimit'][:description]).to eq('Limit info')
  end

  it 'returns :status kind for outputs without body' do
    out = described_class.new(status_code: 204, type: nil)
    expect(out.kind).to eq(:status)
    spec = out.to_openapi_spec
    expect(spec[:description]).to eq('No Content')
  end

  it 'serializes values based on content type' do
    out_json = described_class.new(status_code: 200, type: RapiTapir::Types.string, content_type: 'application/json')
    out_text = described_class.new(status_code: 200, type: RapiTapir::Types.string, content_type: 'text/plain')

    expect(out_json.serialize({ a: 1 })).to eq('{"a":1}')
    expect(out_text.serialize('hello')).to eq('hello')
  end
end

RSpec.describe RapiTapir::DSL::EnhancedInput do
  it 'computes required? based on explicit flag and optional types' do
    input1 = described_class.new(kind: :query, name: :q, type: RapiTapir::Types.string)
    input2 = described_class.new(kind: :query, name: :q, type: RapiTapir::Types.optional(RapiTapir::Types.string))
    input3 = described_class.new(kind: :query, name: :q, type: RapiTapir::Types.string, required: false)

    expect(input1.required?).to be(true)
    expect(input2.required?).to be(false)
    expect(input3.required?).to be(false)
  end

  it 'maps locations to OpenAPI in values' do
    expect(described_class.new(kind: :query, name: :q, type: RapiTapir::Types.string).to_openapi_spec[:in]).to eq('query')
    expect(described_class.new(kind: :path, name: :id, type: RapiTapir::Types.integer).to_openapi_spec[:in]).to eq('path')
    expect(described_class.new(kind: :header, name: :h, type: RapiTapir::Types.string).to_openapi_spec[:in]).to eq('header')
    expect(described_class.new(kind: :body, name: :body, type: RapiTapir::Types.hash({})).to_openapi_spec[:in]).to eq('requestBody')
  end
end

RSpec.describe RapiTapir::DSL::EnhancedError do
  it 'describes standard HTTP error codes and supports schema' do
    err = described_class.new(status_code: 404, type: RapiTapir::Types.hash({ 'code' => RapiTapir::Types.integer }))
    spec = err.to_openapi_spec
    expect(spec[:description]).to include('Not Found')
    expect(spec[:content]['application/json'][:schema]).to be_a(Hash)
    expect(err.matches?(double('Error', status_code: 404))).to be(true)
  end
end

RSpec.describe RapiTapir::DSL::EnhancedSecurity do
  let(:rack_request) do
    # Minimal rack-like request double
    Struct.new(:env, :params).new({}, {})
  end

  it 'validates bearer tokens and returns details' do
    sec = described_class.new(type: :bearer, description: 'Bearer')
    request = rack_request
    request.env['HTTP_AUTHORIZATION'] = 'Bearer token123'
    result = sec.validate_request(request)
    expect(result[:valid]).to be(true)
    expect(result[:token]).to eq('token123')
  end

  it 'validates API key in header and query' do
    sec_header = described_class.new(type: :api_key, description: 'API', name: 'X-API-Key', location: :header)
    req1 = rack_request
    req1.env['HTTP_X_API_KEY'] = 'k1'
    expect(sec_header.validate_request(req1)[:valid]).to be(true)

    sec_query = described_class.new(type: :api_key, description: 'API', name: 'api_key', location: :query)
    req2 = rack_request
    req2.params['api_key'] = 'k2'
    expect(sec_query.validate_request(req2)[:valid]).to be(true)
  end

  it 'validates basic auth and handles malformed credentials' do
    sec = described_class.new(type: :basic, description: 'Basic')
    req = rack_request
    creds = Base64.strict_encode64('user:pass')
    req.env['HTTP_AUTHORIZATION'] = "Basic #{creds}"
    res = sec.validate_request(req)
    expect(res[:valid]).to be(true)
    expect(res[:username]).to eq('user')

  req_bad = rack_request
  # Empty encoded credentials should be invalid
  req_bad.env['HTTP_AUTHORIZATION'] = 'Basic '
  expect(sec.validate_request(req_bad)[:valid]).to be(false)
  end

  it 'returns unsupported auth type error' do
    sec = described_class.new(type: :something_else, description: 'x')
    res = sec.validate_request(rack_request)
    expect(res[:valid]).to be(false)
    expect(res[:error]).to include('Unsupported auth type')
  end
end
