# frozen_string_literal: true

require 'rspec'
require_relative '../../lib/rapitapir'
require_relative '../../lib/rapitapir/openapi/schema_generator'

RSpec.describe RapiTapir::OpenAPI::SchemaGenerator do
  describe '#generate' do
    let(:endpoints) do
      [
        RapiTapir.get('/users')
                 .summary('List all users')
                 .description('Returns a list of all users')
                 .ok(RapiTapir::Types.hash({ 'users' => RapiTapir::Types.array(RapiTapir::Types.hash({
                                                                                                       'id' => RapiTapir::Types.integer, 'name' => RapiTapir::Types.string
                                                                                                     })) }))
                 .build,

        RapiTapir.get('/users/:id')
                 .summary('Get user by ID')
                 .path_param(:id, :integer)
                 .ok(RapiTapir::Types.hash({ 'id' => RapiTapir::Types.integer, 'name' => RapiTapir::Types.string }))
                 .build,

        RapiTapir.post('/users')
                 .summary('Create user')
                 .json_body(RapiTapir::Types.hash({ 'name' => RapiTapir::Types.string }))
                 .ok(RapiTapir::Types.hash({ 'id' => RapiTapir::Types.integer, 'name' => RapiTapir::Types.string }))
                 .build
      ]
    end

    let(:generator) do
      described_class.new(
        endpoints: endpoints,
        info: { title: 'Test API', version: '1.0.0' }
      )
    end

    let(:schema) { generator.generate }

    it 'generates valid OpenAPI 3.0.3 schema' do
      expect(schema[:openapi]).to eq('3.0.3')
    end

    it 'includes API info' do
      expect(schema[:info][:title]).to eq('Test API')
      expect(schema[:info][:version]).to eq('1.0.0')
    end

    it 'includes default servers' do
      expect(schema[:servers]).to be_an(Array)
      expect(schema[:servers].first[:url]).to eq('http://localhost:4567')
    end

    it 'converts paths to OpenAPI format' do
      paths = schema[:paths]
      expect(paths).to have_key('/users')
      expect(paths).to have_key('/users/{id}')
      expect(paths).not_to have_key('/users/:id')
    end

    it 'generates GET operation for list endpoint' do
      get_users = schema[:paths]['/users']['get']
      expect(get_users[:summary]).to eq('List all users')
      expect(get_users[:description]).to eq('Returns a list of all users')
      expect(get_users[:operationId]).to eq('get_users')
      expect(get_users[:tags]).to eq(['Users'])
    end

    it 'generates path parameters' do
      get_user = schema[:paths]['/users/{id}']['get']
      param = get_user[:parameters].first

      expect(param[:name]).to eq('id')
      expect(param[:in]).to eq('path')
      expect(param[:required]).to be true
      expect(param[:schema][:type]).to eq('integer')
    end

    it 'generates request body for POST operations' do
      post_users = schema[:paths]['/users']['post']
      request_body = post_users[:requestBody]

      expect(request_body[:required]).to be true
      expect(request_body[:content]).to have_key('application/json')

      schema_def = request_body[:content]['application/json'][:schema]
      expect(schema_def[:type]).to eq('object')
      expect(schema_def[:properties]).to have_key('name')
      expect(schema_def[:properties]['name'][:type]).to eq('string')
    end

    it 'generates response schemas' do
      get_user = schema[:paths]['/users/{id}']['get']
      response = get_user[:responses]['200']

      expect(response[:description]).to eq('Successful response')
      expect(response[:content]).to have_key('application/json')

      schema_def = response[:content]['application/json'][:schema]
      expect(schema_def[:type]).to eq('object')
      expect(schema_def[:properties]).to have_key('id')
      expect(schema_def[:properties]).to have_key('name')
    end

    it 'converts complex types to OpenAPI schemas' do
      response = schema[:paths]['/users']['get'][:responses]['200']
      schema_def = response[:content]['application/json'][:schema]

      # Should be object with users array
      expect(schema_def[:type]).to eq('object')
      expect(schema_def[:properties]['users'][:type]).to eq('array')
      expect(schema_def[:properties]['users'][:items][:type]).to eq('object')
    end
  end

  describe '#to_json' do
    let(:generator) { described_class.new(endpoints: []) }

    it 'generates valid JSON' do
      json_output = generator.to_json
      expect { JSON.parse(json_output) }.not_to raise_error
    end
  end

  describe '#to_yaml' do
    let(:generator) { described_class.new(endpoints: []) }

    it 'generates valid YAML' do
      yaml_output = generator.to_yaml
      expect(yaml_output).to include('openapi: 3.0.3')
    end
  end
end
