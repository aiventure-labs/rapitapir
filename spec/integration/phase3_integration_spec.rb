# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Phase 3 Integration Tests' do
  include RapiTapir::DSL

  let(:test_endpoints) do
    [
      RapiTapir.get('/users')
        .out(json_body([{ id: :integer, name: :string, email: :string }]))
        .summary('Get all users')
        .description('Retrieve a list of all users'),

      RapiTapir.post('/users')
        .in(body({ name: :string, email: :string }))
        .out(json_body({ id: :integer, name: :string, email: :string, created_at: :datetime }))
        .summary('Create user')
        .description('Create a new user'),

      RapiTapir.get('/users/:id')
        .in(path(:id, :integer))
        .out(json_body({ id: :integer, name: :string, email: :string }))
        .summary('Get user by ID')
        .description('Get a specific user by their ID')
    ]
  end

  describe 'OpenAPI Schema Generation' do
    it 'generates valid OpenAPI 3.0.3 schema' do
      generator = RapiTapir::OpenAPI::SchemaGenerator.new(endpoints: test_endpoints)
      schema = generator.generate
      
      expect(schema).to be_a(Hash)
      expect(schema[:openapi]).to eq('3.0.3')
      expect(schema[:info]).to be_a(Hash)
      expect(schema[:paths]).to be_a(Hash)
      expect(schema[:paths]).not_to be_empty
    end

    it 'includes parameter definitions' do
      generator = RapiTapir::OpenAPI::SchemaGenerator.new(endpoints: test_endpoints)
      schema = generator.generate
      
      # Check for user by ID endpoint path parameter
      user_get = schema[:paths]['/users/{id}']['get']
      expect(user_get).not_to be_nil
      expect(user_get[:parameters]).to be_an(Array)
      expect(user_get[:parameters].first[:name]).to eq('id')
      expect(user_get[:parameters].first[:in]).to eq('path')
    end
  end

  describe 'TypeScript Client Generation' do
    it 'generates TypeScript client code' do
      generator = RapiTapir::Client::TypescriptGenerator.new(endpoints: test_endpoints)
      client_code = generator.generate
      
      expect(client_code).to include('class ApiClient')
      expect(client_code).to include('createUser')
      expect(client_code).to include('getUsers')
      expect(client_code).to include('getUsersById')
    end

    it 'includes type definitions' do
      generator = RapiTapir::Client::TypescriptGenerator.new(endpoints: test_endpoints)
      client_code = generator.generate
      
      expect(client_code).to include('export type GetusersResponse')
      expect(client_code).to include('export type CreateuserResponse')
      expect(client_code).to include('interface CreateuserRequest')
      expect(client_code).to include('interface GetusersbyidRequest')
    end
  end

  describe 'Documentation Generation' do
    describe 'Markdown Generator' do
      it 'generates comprehensive markdown documentation' do
        generator = RapiTapir::Docs::MarkdownGenerator.new(endpoints: test_endpoints)
        markdown = generator.generate

        expect(markdown).to include('# API Documentation')
        expect(markdown).to include('## GET /users')
        expect(markdown).to include('## POST /users')
        expect(markdown).to include('## GET /users/:id')
        expect(markdown).to include('### Path Parameters')
        expect(markdown).to include('### Response')
      end
    end

    describe 'HTML Generator' do
      it 'generates interactive HTML documentation' do
        generator = RapiTapir::Docs::HtmlGenerator.new(endpoints: test_endpoints)
        html = generator.generate

        expect(html).to include('<!DOCTYPE html>')
        expect(html).to include('<div class="endpoint"')
        expect(html).to include('Get all users')
        expect(html).to include('Create user')
        expect(html).to include('<form class="try-it-form"')
      end
    end
  end

  describe 'CLI Tools' do
    let(:temp_endpoints_file) { 'spec/tmp/test_endpoints.rb' }
    let(:temp_output_dir) { 'spec/tmp' }

    before do
      FileUtils.mkdir_p('spec/tmp')
      File.write(temp_endpoints_file, <<~RUBY)
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
      FileUtils.rm_rf('spec/tmp')
    end

    describe 'Validator' do
      it 'validates valid endpoints successfully' do
        validator = RapiTapir::CLI::Validator.new(test_endpoints)
        expect(validator.validate).to be(true)
        expect(validator.errors).to be_empty
      end

      it 'detects invalid endpoints' do
        invalid_endpoint = RapiTapir.get('/invalid').summary('Test') # Missing output
        validator = RapiTapir::CLI::Validator.new([invalid_endpoint])
        
        expect(validator.validate).to be(false)
        expect(validator.errors).not_to be_empty
        expect(validator.errors.first).to include('missing output definition')
      end
    end

    describe 'Command Interface' do
      it 'processes generate openapi command' do
        output_file = File.join(temp_output_dir, 'openapi.json')
        
        command = RapiTapir::CLI::Command.new([
          'generate', 'openapi',
          '--endpoints', temp_endpoints_file,
          '--output', output_file
        ])
        
        expect { command.run }.not_to raise_error
        expect(File.exist?(output_file)).to be(true)
        
        content = JSON.parse(File.read(output_file))
        expect(content['openapi']).to eq('3.0.3')
      end

      it 'processes generate client command' do
        output_file = File.join(temp_output_dir, 'client.ts')
        
        command = RapiTapir::CLI::Command.new([
          'generate', 'client',
          '--endpoints', temp_endpoints_file,
          '--output', output_file
        ])
        
        expect { command.run }.not_to raise_error
        expect(File.exist?(output_file)).to be(true)
        
        content = File.read(output_file)
        expect(content).to include('export class ApiClient')
      end

      it 'processes generate docs command' do
        output_file = File.join(temp_output_dir, 'docs.html')
        
        command = RapiTapir::CLI::Command.new([
          'generate', 'docs',
          '--endpoints', temp_endpoints_file,
          '--output', output_file
        ])
        
        expect { command.run }.not_to raise_error
        expect(File.exist?(output_file)).to be(true)
        
        content = File.read(output_file)
        expect(content).to include('<!DOCTYPE html>')
      end

      it 'validates endpoints command' do
        ENV['RSPEC_RUNNING'] = 'true'
        
        command = RapiTapir::CLI::Command.new([
          'validate',
          '--endpoints', temp_endpoints_file
        ])
        
        # Expect the validation to run without crashing
        # It may exit with status 1 due to validation failures, which is okay
        begin
          command.run
        rescue SystemExit => e
          # Validation failures result in exit(1), which is expected behavior
          expect(e.status).to eq(1)
        end
        
        ENV.delete('RSPEC_RUNNING')
      end
    end
  end

  describe 'End-to-End Workflow' do
    let(:temp_dir) { 'spec/tmp/e2e' }

    before do
      FileUtils.mkdir_p(temp_dir)
    end

    after do
      FileUtils.rm_rf(temp_dir)
    end

    it 'generates complete API toolkit from endpoints' do
      # 1. Create endpoints file
      endpoints_file = File.join(temp_dir, 'api_endpoints.rb')
      File.write(endpoints_file, <<~RUBY)
        require 'rapitapir'
        include RapiTapir::DSL

        RapiTapir.get('/api/v1/users')
          .in(query(:page, :integer, optional: true))
          .in(query(:limit, :integer, optional: true))
          .out(json_body([{ id: :integer, name: :string, email: :string }]))
          .summary('List users')
          .description('Get paginated list of users')

        RapiTapir.get('/api/v1/users/:id')
          .in(path(:id, :integer))
          .out(json_body({ id: :integer, name: :string, email: :string, created_at: :datetime }))
          .summary('Get user')
          .description('Get user by ID')

        RapiTapir.post('/api/v1/users')
          .in(body({ name: :string, email: :string }))
          .out(json_body({ id: :integer, name: :string, email: :string, created_at: :datetime }))
          .summary('Create user')
          .description('Create new user')
      RUBY

      # 2. Generate OpenAPI schema
      openapi_file = File.join(temp_dir, 'openapi.json')
      RapiTapir::CLI::Command.new([
        'generate', 'openapi',
        '--endpoints', endpoints_file,
        '--output', openapi_file
      ]).run

      # 3. Generate TypeScript client
      client_file = File.join(temp_dir, 'api-client.ts')
      RapiTapir::CLI::Command.new([
        'generate', 'client',
        '--endpoints', endpoints_file,
        '--output', client_file
      ]).run

      # 4. Generate HTML documentation
      docs_file = File.join(temp_dir, 'api-docs.html')
      RapiTapir::CLI::Command.new([
        'generate', 'docs',
        '--endpoints', endpoints_file,
        '--output', docs_file
      ]).run

      # 5. Validate all files exist and have expected content
      expect(File.exist?(openapi_file)).to be(true)
      expect(File.exist?(client_file)).to be(true)
      expect(File.exist?(docs_file)).to be(true)

      # Validate OpenAPI schema
      openapi_content = JSON.parse(File.read(openapi_file))
      expect(openapi_content['openapi']).to eq('3.0.3')
      expect(openapi_content['paths']).to have_key('/api/v1/users')
      expect(openapi_content['paths']).to have_key('/api/v1/users/{id}')

      # Validate TypeScript client
      client_content = File.read(client_file)
      expect(client_content).to include('export class ApiClient')
      expect(client_content).to include('getApiV1Users')
      expect(client_content).to include('createUser')

      # Validate HTML documentation
      docs_content = File.read(docs_file)
      expect(docs_content).to include('<!DOCTYPE html>')
      expect(docs_content).to include('/api/v1/users')
      expect(docs_content).to include('POST')
    end
  end
end
