# frozen_string_literal: true

require 'spec_helper'
require_relative '../../lib/rapitapir/ai/mcp'
require_relative '../../lib/rapitapir/core/endpoint'

RSpec.describe RapiTapir::AI::MCP do
  include RapiTapir::DSL

  describe 'Exporter' do
    let(:endpoints) do
      [
        RapiTapir::Core::Endpoint.get('/users')
          .out(RapiTapir::IO.json_body(RapiTapir::Types.hash({ 'users' => RapiTapir::Types.array })))
          .summary('List all users')
          .mcp_export,
          
        RapiTapir::Core::Endpoint.post('/users')
          .in(RapiTapir::IO.json_body(RapiTapir::Types.hash({ 'name' => RapiTapir::Types.string, 'email' => RapiTapir::Types.string })))
          .out(RapiTapir::IO.json_body(RapiTapir::Types.hash({ 'id' => RapiTapir::Types.string, 'name' => RapiTapir::Types.string, 'email' => RapiTapir::Types.string })))
          .summary('Create a new user'),
          
        RapiTapir::Core::Endpoint.get('/health')
          .out(RapiTapir::IO.json_body(RapiTapir::Types.hash({ 'status' => RapiTapir::Types.string })))
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
      RapiTapir::Core::Endpoint.get('/api/test')
        .out(RapiTapir::IO.json_body(RapiTapir::Types.hash({ 'result' => RapiTapir::Types.string })))
        .mcp_export
    end

    let(:regular_endpoint) do
      RapiTapir::Core::Endpoint.post('/internal/admin')
        .in(RapiTapir::IO.json_body(RapiTapir::Types.hash({ 'action' => RapiTapir::Types.string })))
        .out(RapiTapir::IO.json_body(RapiTapir::Types.hash({ 'success' => RapiTapir::Types.boolean })))
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
      RapiTapir::Core::Endpoint.post('/complex')
        .in(RapiTapir::IO.json_body(RapiTapir::Types.hash({
          'user' => RapiTapir::Types.hash({
            'name' => RapiTapir::Types.string,
            'age' => RapiTapir::Types.integer,
            'active' => RapiTapir::Types.boolean
          }),
          'preferences' => RapiTapir::Types.array
        })))
        .out(RapiTapir::IO.json_body(RapiTapir::Types.hash({
          'success' => RapiTapir::Types.boolean,
          'user_id' => RapiTapir::Types.string,
          'created_at' => RapiTapir::Types.string
        })))
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
