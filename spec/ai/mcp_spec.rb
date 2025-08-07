# frozen_string_literal: true

require 'spec_helper'
require_relative '../../lib/rapitapir/ai/mcp'
require_relative '../../lib/rapitapir/core/endpoint'

RSpec.describe RapiTapir::AI::MCP do
  include RapiTapir::DSL

  # Type alias for convenience
  T = RapiTapir::Types

  describe 'Exporter' do
    let(:endpoints) do
      [
        RapiTapir.get('/users')
          .ok(T.hash({ 'users' => T.array(T.hash) }))
          .summary('List all users')
          .description('Returns a list of users for AI agent consumption')
          .mcp_export,
          
        RapiTapir.post('/users')
          .json_body(T.hash({ 'name' => T.string, 'email' => T.string }))
          .ok(T.hash({ 'id' => T.string, 'name' => T.string, 'email' => T.string }))
          .summary('Create a new user'),
          
        RapiTapir.get('/health')
          .ok(T.hash({ 'status' => T.string }))
          .mcp_export
      ]
    end

    let(:exporter) { described_class::Exporter.new(endpoints) }

    describe '#mcp_endpoints' do
      it 'filters only MCP-exportable endpoints' do
        mcp_endpoints = exporter.mcp_endpoints
        
        expect(mcp_endpoints.size).to eq(2)
        expect(mcp_endpoints.all?(&:mcp_export?)).to be true
      end
    end

    describe '#export_context' do
      let(:context) { exporter.export_context }

      it 'includes basic service information' do
        expect(context).to include(
          :service,
          :endpoints,
          :schemas,
          :metadata
        )
        
        expect(context[:service][:name]).to eq('RapiTapir API')
        expect(context[:service][:version]).to eq('1.0.0')
        expect(context[:service][:description]).to include('exported endpoints')
      end

      it 'includes MCP-enabled endpoints only' do
        endpoints_data = context[:endpoints]
        
        expect(endpoints_data.size).to eq(2)
        expect(endpoints_data.map { |e| e[:path] }).to contain_exactly('/users', '/health')
        expect(endpoints_data.map { |e| e[:method] }).to contain_exactly('GET', 'GET')
      end

      it 'includes endpoint summaries and descriptions' do
        users_endpoint = context[:endpoints].find { |e| e[:path] == '/users' }
        
        expect(users_endpoint[:summary]).to eq('List all users')
        expect(users_endpoint[:description]).to include('AI agent')
      end

      it 'includes input/output schemas' do
        schemas = context[:schemas]
        
        expect(schemas).to be_a(Hash)
        expect(schemas.keys).not_to be_empty
      end

      it 'includes generation metadata' do
        metadata = context[:metadata]
        
        expect(metadata).to include(
          :generated_at,
          :generator,
          :mcp_version
        )
        
        expect(metadata[:generator]).to eq('RapiTapir MCP Exporter')
        expect(metadata[:mcp_version]).to eq('1.0')
      end
    end

    describe '#export_json' do
      it 'returns valid JSON' do
        json = exporter.export_json
        
        expect { JSON.parse(json) }.not_to raise_error
        
        parsed = JSON.parse(json)
        expect(parsed).to include('service', 'endpoints', 'schemas', 'metadata')
      end

      it 'includes pretty formatting by default' do
        json = exporter.export_json
        
        expect(json).to include("\n")
        expect(json).to include("  ")
      end

      it 'supports compact formatting' do
        json = exporter.export_json(pretty: false)
        
        expect(json).not_to include("\n  ")
      end
    end
  end

  describe 'Endpoint MCP Integration' do
    let(:mcp_endpoint) do
      RapiTapir.get('/api/test')
        .ok(T.hash({ 'result' => T.string }))
        .mcp_export
    end

    let(:regular_endpoint) do
      RapiTapir.post('/internal/admin')
        .json_body(T.hash({ 'action' => T.string }))
        .ok(T.hash({ 'success' => T.boolean }))
    end

    it 'correctly identifies MCP-exportable endpoints' do
      expect(mcp_endpoint.mcp_export?).to be true
      expect(regular_endpoint.mcp_export?).to be false
    end

    it 'sets MCP metadata flag' do
      expect(mcp_endpoint.metadata[:mcp_export]).to be true
      expect(regular_endpoint.metadata[:mcp_export]).to be_nil
    end

    it 'allows chaining with other DSL methods' do
      chained_endpoint = RapiTapir::Core::Endpoint.get('/chained')
        .summary('Chained endpoint')
        .mcp_export
      
      expect(chained_endpoint.mcp_export?).to be true
      expect(chained_endpoint.metadata[:summary]).to eq('Chained endpoint')
    end
  end

  describe 'Schema Generation' do
    let(:complex_endpoint) do
      RapiTapir.post('/complex')
        .json_body(T.hash({
          'user' => T.hash({
            'name' => T.string,
            'age' => T.integer,
            'active' => T.boolean
          }),
          'preferences' => T.array(T.string)
        }))
        .ok(T.hash({
          'success' => T.boolean,
          'user_id' => T.string,
          'created_at' => T.string
        }))
        .mcp_export
    end

    let(:exporter) { described_class::Exporter.new([complex_endpoint]) }

    it 'generates complex schema structures' do
      context = exporter.export_context
      schemas = context[:schemas]
      
      expect(schemas).to be_a(Hash)
      expect(schemas.keys).not_to be_empty
    end

    it 'preserves type information' do
      context = exporter.export_context
      endpoint_data = context[:endpoints].first
      
      expect(endpoint_data).to include(:input_schema, :output_schema)
    end
  end
end
