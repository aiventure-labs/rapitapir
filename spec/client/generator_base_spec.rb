# frozen_string_literal: true

require 'spec_helper'
require 'tempfile'

RSpec.describe RapiTapir::Client::GeneratorBase do
  include RapiTapir::DSL

  let(:endpoints) do
    [
      RapiTapir.get('/users')
               .ok(RapiTapir::Types.array(RapiTapir::Types.hash({ 'id' => RapiTapir::Types.integer,
                                                                  'name' => RapiTapir::Types.string })))
               .build,
      RapiTapir.post('/users')
               .json_body(RapiTapir::Types.hash({ 'name' => RapiTapir::Types.string }))
               .created(RapiTapir::Types.hash({ 'id' => RapiTapir::Types.integer, 'name' => RapiTapir::Types.string }))
               .build
    ]
  end

  let(:config) { { base_url: 'https://api.test.com', client_name: 'TestClient' } }
  let(:generator) { described_class.new(endpoints: endpoints, config: config) }

  describe '#initialize' do
    it 'sets endpoints and config' do
      expect(generator.endpoints).to eq(endpoints)
      expect(generator.config[:base_url]).to eq('https://api.test.com')
    end

    it 'merges config with defaults' do
      expect(generator.config[:client_name]).to eq('TestClient')
      expect(generator.config[:package_name]).to eq('api-client') # default
      expect(generator.config[:version]).to eq('1.0.0') # default
    end
  end

  describe '#generate' do
    it 'raises NotImplementedError' do
      expect { generator.generate }.to raise_error(NotImplementedError)
    end
  end

  describe '#convert_type' do
    context 'TypeScript conversion' do
      it 'converts basic types' do
        expect(generator.send(:convert_type, :string, language: :typescript)).to eq('string')
        expect(generator.send(:convert_type, :integer, language: :typescript)).to eq('number')
        expect(generator.send(:convert_type, :boolean, language: :typescript)).to eq('boolean')
        expect(generator.send(:convert_type, :date, language: :typescript)).to eq('Date')
      end

      it 'converts complex types' do
        hash_type = { name: :string, age: :integer }
        expect(generator.send(:convert_type, hash_type, language: :typescript))
          .to eq('{ name: string; age: number }')

        array_type = [:string]
        expect(generator.send(:convert_type, array_type, language: :typescript))
          .to eq('string[]')
      end
    end

    context 'Python conversion' do
      it 'converts basic types' do
        expect(generator.send(:convert_type, :string, language: :python)).to eq('str')
        expect(generator.send(:convert_type, :integer, language: :python)).to eq('int')
        expect(generator.send(:convert_type, :boolean, language: :python)).to eq('bool')
      end
    end
  end

  describe '#method_name_for_endpoint' do
    it 'generates method names for different HTTP methods' do
      get_endpoint = RapiTapir.get('/users').build
      post_endpoint = RapiTapir.post('/users').build
      put_endpoint = RapiTapir.put('/users/:id').path_param(:id, :integer).build
      delete_endpoint = RapiTapir.delete('/users/:id').path_param(:id, :integer).build

      expect(generator.send(:method_name_for_endpoint, get_endpoint)).to eq('getUsers')
      expect(generator.send(:method_name_for_endpoint, post_endpoint)).to eq('createUser')
      expect(generator.send(:method_name_for_endpoint, put_endpoint)).to eq('updateUser')
      expect(generator.send(:method_name_for_endpoint, delete_endpoint)).to eq('deleteUser')
    end

    it 'handles nested paths' do
      nested_endpoint = RapiTapir.get('/api/v1/users/:id/posts').path_param(:id, :integer).build
      expect(generator.send(:method_name_for_endpoint, nested_endpoint))
        .to eq('getApiV1UsersPostsById')
    end
  end

  describe '#singularize' do
    it 'singularizes common plural words' do
      expect(generator.send(:singularize, 'users')).to eq('user')
      expect(generator.send(:singularize, 'posts')).to eq('post')
      expect(generator.send(:singularize, 'categories')).to eq('category')
      expect(generator.send(:singularize, 'companies')).to eq('company')
    end

    it 'handles edge cases' do
      expect(generator.send(:singularize, 'user')).to eq('user') # already singular
      expect(generator.send(:singularize, nil)).to be_nil
      expect(generator.send(:singularize, '')).to eq('')
    end
  end

  describe 'parameter extraction methods' do
    let(:complex_endpoint) do
      RapiTapir.get('/users/:id')
               .path_param(:id, :integer)
               .query(:include, :string)
               .query(:format, :string, required: false)
               .header(:authorization, :string)
               .json_body(RapiTapir::Types.hash({ 'data' => RapiTapir::Types.string }))
               .ok(RapiTapir::Types.hash({ 'id' => RapiTapir::Types.integer, 'name' => RapiTapir::Types.string }))
               .build
    end

    describe '#path_parameters' do
      it 'extracts only path parameters' do
        params = generator.send(:path_parameters, complex_endpoint)
        expect(params.length).to eq(1)
        expect(params.first.kind).to eq(:path)
        expect(params.first.name).to eq(:id)
      end
    end

    describe '#query_parameters' do
      it 'extracts only query parameters' do
        params = generator.send(:query_parameters, complex_endpoint)
        expect(params.length).to eq(2)

        names = params.map(&:name)
        expect(names).to include(:include, :format)

        params.each { |param| expect(param.kind).to eq(:query) }
      end
    end

    describe '#request_body' do
      it 'extracts request body' do
        body = generator.send(:request_body, complex_endpoint)
        expect(body).not_to be_nil
        expect(body.kind).to eq(:body)
        expect(body.type).to be_a(RapiTapir::Types::Hash)
        expect(body.type.field_types.keys).to include('data')
        expect(body.type.field_types['data']).to be_a(RapiTapir::Types::String)
      end

      it 'returns nil when no body' do
        get_endpoint = RapiTapir.get('/users')
        body = generator.send(:request_body, get_endpoint)
        expect(body).to be_nil
      end
    end

    describe '#response_type' do
      it 'extracts response type from outputs' do
        response = generator.send(:response_type, complex_endpoint)
        expect(response).to be_a(RapiTapir::Types::Hash)
        expect(response.field_types.keys).to include('id', 'name')
        expect(response.field_types['id']).to be_a(RapiTapir::Types::Integer)
        expect(response.field_types['name']).to be_a(RapiTapir::Types::String)
      end

      it 'returns nil when no outputs' do
        empty_endpoint = RapiTapir.get('/ping')
        response = generator.send(:response_type, empty_endpoint)
        expect(response).to be_nil
      end
    end
  end

  describe '#save_to_file' do
    let(:concrete_generator) do
      Class.new(described_class) do
        def generate
          "// Generated content\nexport class TestClient {}"
        end
      end.new(endpoints: [], config: {})
    end

    let(:temp_file) { Tempfile.new(['test', '.ts']) }

    after { temp_file.unlink }

    it 'saves generated content to file' do
      concrete_generator.save_to_file(temp_file.path)

      content = File.read(temp_file.path)
      expect(content).to eq("// Generated content\nexport class TestClient {}")
    end
  end
end
