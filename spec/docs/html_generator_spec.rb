# frozen_string_literal: true

require 'spec_helper'
require 'tempfile'

RSpec.describe RapiTapir::Docs::HtmlGenerator do
  include RapiTapir::DSL

  let(:endpoints) do
    [
      RapiTapir.get('/users')
               .ok(RapiTapir::Types.array(RapiTapir::Types.hash({ 'id' => RapiTapir::Types.integer,
                                                                  'name' => RapiTapir::Types.string })))
               .summary('Get all users')
               .description('Retrieve a list of all users')
               .build,

      RapiTapir.post('/users')
               .json_body(RapiTapir::Types.hash({ 'name' => RapiTapir::Types.string,
                                                  'email' => RapiTapir::Types.string }))
               .ok(RapiTapir::Types.hash({ 'id' => RapiTapir::Types.integer, 'name' => RapiTapir::Types.string,
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
      theme: 'light',
      include_try_it: true
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
      expect(simple_generator.config[:include_try_it]).to be(true)
    end
  end

  describe '#generate' do
    let(:generated_html) { generator.generate }

    it 'generates valid HTML' do
      expect(generated_html).to be_a(String)
      expect(generated_html).not_to be_empty
      expect(generated_html).to include('<!DOCTYPE html>')
      expect(generated_html).to include('</html>')
    end

    it 'includes HTML structure' do
      expect(generated_html).to include('<html lang="en">')
      expect(generated_html).to include('<head>')
      expect(generated_html).to include('<body>')
      expect(generated_html).to include('<title>Test API</title>')
    end

    it 'includes CSS styles' do
      expect(generated_html).to include('<style>')
      expect(generated_html).to include('font-family:')
      expect(generated_html).to include('.container')
      expect(generated_html).to include('.endpoint')
    end

    it 'includes header information' do
      expect(generated_html).to include('<h1>Test API</h1>')
      expect(generated_html).to include('Version: 1.0.0')
      expect(generated_html).to include('Base URL: <code>https://api.test.com</code>')
    end

    it 'includes sidebar navigation' do
      expect(generated_html).to include('<div class="sidebar">')
      expect(generated_html).to include('<h3>Endpoints</h3>')
      expect(generated_html).to include('method-badge method-get')
      expect(generated_html).to include('method-badge method-post')
    end

    it 'includes endpoint documentation' do
      expect(generated_html).to include('<div class="endpoint"')
      expect(generated_html).to include('Get all users')
      expect(generated_html).to include('Create user')
      expect(generated_html).to include('/users')
    end

    it 'includes parameter tables' do
      expect(generated_html).to include('<table class="params-table">')
      expect(generated_html).to include('<th>Parameter</th>')
      expect(generated_html).to include('<th>Type</th>')
      expect(generated_html).to include('<th>Required</th>')
    end

    it 'includes try-it-out forms when enabled' do
      expect(generated_html).to include('<div class="try-it-section">')
      expect(generated_html).to include('<h4>Try it out</h4>')
      expect(generated_html).to include('<form class="try-it-form"')
      expect(generated_html).to include('Send Request')
    end

    it 'includes JavaScript functionality' do
      expect(generated_html).to include('<script>')
      expect(generated_html).to include('async function tryRequest')
      expect(generated_html).to include('fetch(url, options)')
    end

    it 'includes proper method badges' do
      expect(generated_html).to include('method-badge method-get')
      expect(generated_html).to include('method-badge method-post')
    end

    it 'includes code blocks' do
      expect(generated_html).to include('<div class="code-block">')
      expect(generated_html).to include('application/json')
    end
  end

  describe '#save_to_file' do
    let(:temp_file) { Tempfile.new(['test-docs', '.html']) }

    after { temp_file.unlink }

    it 'saves generated HTML to file' do
      generator.save_to_file(temp_file.path)

      content = File.read(temp_file.path)
      expect(content).to include('<!DOCTYPE html>')
      expect(content).to include('<title>Test API</title>')
      expect(content).to include('Get all users')
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
        expect(generator.send(:generate_example_value, :string)).to eq('example string')
        expect(generator.send(:generate_example_value, :integer)).to eq(123)
        expect(generator.send(:generate_example_value, :boolean)).to eq(true)
        expect(generator.send(:generate_example_value, :date)).to eq('2025-01-15')
      end
    end

    describe '#generate_anchor' do
      it 'generates valid HTML anchors' do
        expect(generator.send(:generate_anchor, 'GET', '/users')).to eq('get-users')
        expect(generator.send(:generate_anchor, 'POST', '/users/:id')).to eq('post-usersid')
      end
    end

    describe '#html_escape' do
      it 'escapes HTML characters' do
        expect(generator.send(:html_escape, '<script>')).to eq('&lt;script&gt;')
        expect(generator.send(:html_escape, 'A & B')).to eq('A &amp; B')
        expect(generator.send(:html_escape, '"quoted"')).to eq('&quot;quoted&quot;')
      end
    end
  end

  describe 'configuration options' do
    context 'when try-it-out is disabled' do
      let(:disabled_config) { { include_try_it: false } }
      let(:disabled_generator) { described_class.new(endpoints: endpoints, config: disabled_config) }

      it 'does not include try-it-out forms' do
        html = disabled_generator.generate
        expect(html).not_to include('<div class="try-it-section">')
        expect(html).not_to include('<h4>Try it out</h4>')
        expect(html).not_to include('Send Request')
      end
    end

    context 'with different theme' do
      let(:theme_config) { { theme: 'dark' } }
      let(:theme_generator) { described_class.new(endpoints: endpoints, config: theme_config) }

      it 'includes the theme in config' do
        expect(theme_generator.config[:theme]).to eq('dark')
      end
    end
  end

  describe 'responsive design elements' do
    let(:generated_html) { generator.generate }

    it 'includes viewport meta tag' do
      expect(generated_html).to include('<meta name="viewport" content="width=device-width, initial-scale=1.0">')
    end

    it 'includes responsive CSS classes' do
      expect(generated_html).to include('container')
      expect(generated_html).to include('sidebar')
      expect(generated_html).to include('main-content')
    end
  end
end
