# frozen_string_literal: true

require 'spec_helper'
require 'tempfile'

RSpec.describe RapiTapir::Docs::MarkdownGenerator do
  include RapiTapir::DSL

  let(:endpoints) do
    [
      RapiTapir.get('/users')
               .ok(RapiTapir::Types.array(RapiTapir::Types.hash({ 'id' => RapiTapir::Types.integer,
                                                                  'name' => RapiTapir::Types.string })))
               .summary('Get all users')
               .description('Retrieve a list of all users')
               .build,

      RapiTapir.get('/users/:id')
               .path_param(:id, :integer)
               .ok(RapiTapir::Types.hash({ 'id' => RapiTapir::Types.integer, 'name' => RapiTapir::Types.string,
                                           'email' => RapiTapir::Types.string }))
               .summary('Get user by ID')
               .description('Retrieve a specific user by their ID')
               .build,

      RapiTapir.post('/users')
               .json_body(RapiTapir::Types.hash({ 'name' => RapiTapir::Types.string,
                                                  'email' => RapiTapir::Types.string }))
               .created(RapiTapir::Types.hash({ 'id' => RapiTapir::Types.integer, 'name' => RapiTapir::Types.string,
                                                'email' => RapiTapir::Types.string }))
               .summary('Create user')
               .description('Create a new user')
               .build,

      RapiTapir.get('/users/search')
               .query(:q, :string)
               .query(:limit, :integer, required: false)
               .ok(RapiTapir::Types.array(RapiTapir::Types.hash({ 'id' => RapiTapir::Types.integer,
                                                                  'name' => RapiTapir::Types.string })))
               .summary('Search users')
               .description('Search for users')
               .build
    ]
  end

  let(:config) do
    {
      title: 'Test API',
      description: 'Test API documentation',
      version: '1.0.0',
      base_url: 'https://api.test.com',
      include_toc: true,
      include_examples: true
    }
  end

  let(:generator) { described_class.new(endpoints: endpoints, config: config) }

  describe '#initialize' do
    it 'sets endpoints and config' do
      expect(generator.endpoints).to eq(endpoints)
      expect(generator.config[:title]).to eq('Test API')
    end

    it 'merges with default config' do
      simple_generator = described_class.new(endpoints: [])
      expect(simple_generator.config[:title]).to eq('API Documentation')
      expect(simple_generator.config[:include_toc]).to be(true)
    end
  end

  describe '#generate' do
    let(:generated_markdown) { generator.generate }

    it 'generates valid Markdown' do
      expect(generated_markdown).to be_a(String)
      expect(generated_markdown).not_to be_empty
    end

    it 'includes header information' do
      expect(generated_markdown).to include('# Test API')
      expect(generated_markdown).to include('Test API documentation')
      expect(generated_markdown).to include('**Version:** 1.0.0')
      expect(generated_markdown).to include('**Base URL:** `https://api.test.com`')
    end

    it 'includes table of contents' do
      expect(generated_markdown).to include('## Table of Contents')
      expect(generated_markdown).to include('- [GET /users](#get-users) - Get all users')
      expect(generated_markdown).to include('- [GET /users/:id](#get-usersid) - Get user by ID')
      expect(generated_markdown).to include('- [POST /users](#post-users) - Create user')
    end

    it 'includes endpoint documentation' do
      expect(generated_markdown).to include('## GET /users')
      expect(generated_markdown).to include('**Get all users**')
      expect(generated_markdown).to include('Retrieve a list of all users')
    end

    it 'includes parameter documentation' do
      expect(generated_markdown).to include('### Path Parameters')
      expect(generated_markdown).to include('| `id` | integer | No description |')
      expect(generated_markdown).to include('### Query Parameters')
      expect(generated_markdown).to include('| `q` | string | Yes |')
      expect(generated_markdown).to include('| `limit` | integer | No |')
    end

    it 'includes request body documentation' do
      expect(generated_markdown).to include('### Request Body')
      expect(generated_markdown).to include('**Content-Type:** `application/json`')
      expect(generated_markdown).to include('**Schema:**')
    end

    it 'includes response documentation' do
      expect(generated_markdown).to include('### Response')
      expect(generated_markdown).to include('```json')
    end

    it 'includes examples when enabled' do
      expect(generated_markdown).to include('### Example')
      expect(generated_markdown).to include('**Request:**')
      expect(generated_markdown).to include('```bash')
      expect(generated_markdown).to include('curl -X GET')
    end

    it 'includes footer' do
      expect(generated_markdown).to include('*Generated by RapiTapir Documentation Generator*')
    end
  end

  describe '#save_to_file' do
    let(:temp_file) { Tempfile.new(['test-docs', '.md']) }

    after { temp_file.unlink }

    it 'saves generated markdown to file' do
      generator.save_to_file(temp_file.path)

      content = File.read(temp_file.path)
      expect(content).to include('# Test API')
      expect(content).to include('## GET /users')
    end
  end

  describe 'private methods' do
    describe '#format_type' do
      it 'formats basic types correctly' do
        expect(generator.send(:format_type, :string)).to eq('string')
        expect(generator.send(:format_type, :integer)).to eq('integer')
        expect(generator.send(:format_type, :boolean)).to eq('boolean')
        expect(generator.send(:format_type, Hash)).to eq('object')
        expect(generator.send(:format_type, Array)).to eq('array')
      end
    end

    describe '#generate_example_value' do
      it 'generates appropriate example values' do
        expect(generator.send(:generate_example_value, :string)).to eq('"example string"')
        expect(generator.send(:generate_example_value, :integer)).to eq('123')
        expect(generator.send(:generate_example_value, :boolean)).to eq('true')
        expect(generator.send(:generate_example_value, :date)).to eq('"2025-01-15"')
      end
    end

    describe '#generate_anchor' do
      it 'generates valid HTML anchors' do
        expect(generator.send(:generate_anchor, 'GET', '/users')).to eq('get-users')
        expect(generator.send(:generate_anchor, 'POST', '/users/:id')).to eq('post-usersid')
      end
    end
  end

  describe 'configuration options' do
    context 'when table of contents is disabled' do
      let(:config) { { include_toc: false } }

      it 'does not include table of contents' do
        markdown = generator.generate
        expect(markdown).not_to include('## Table of Contents')
      end
    end

    context 'when examples are disabled' do
      let(:config) { { include_examples: false } }

      it 'does not include examples' do
        markdown = generator.generate
        expect(markdown).not_to include('### Example')
        expect(markdown).not_to include('curl -X')
      end
    end
  end
end
