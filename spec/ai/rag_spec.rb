# frozen_string_literal: true

require 'spec_helper'
require_relative '../../lib/rapitapir/ai/rag'
require_relative '../../lib/rapitapir/core/endpoint'

RSpec.describe RapiTapir::AI::RAG do
  include RapiTapir::DSL

  describe 'LLM Providers' do
    describe RapiTapir::AI::RAG::OpenAIProvider do
      let(:provider) { described_class.new(api_key: 'mock') }

      it 'generates responses with mock API key' do
        result = provider.generate('What is AI?', { user_id: '123' })
        expect(result).to include('AI Response')
        expect(result).to include('What is AI?')
      end
    end
  end

  describe 'Retrieval Backends' do
    describe RapiTapir::AI::RAG::MemoryBackend do
      let(:documents) do
        [
          { content: 'Ruby is a programming language', metadata: { type: 'definition' } },
          { content: 'Rails is a web framework for Ruby', metadata: { type: 'framework' } }
        ]
      end
      let(:backend) { described_class.new(documents: documents) }

      it 'retrieves relevant documents' do
        results = backend.retrieve('Ruby programming', [:user_id])
        expect(results).not_to be_empty
        expect(results.first[:content]).to include('Ruby')
        expect(results.first).to have_key(:score)
      end

      it 'returns empty array for non-matching queries' do
        results = backend.retrieve('Python programming', [])
        expect(results).to be_empty
      end
    end
  end

  describe 'RAG Pipeline' do
    let(:documents) do
      [
        { content: 'RapiTapir is a Ruby API framework', metadata: { category: 'docs' } },
        { content: 'RAG combines retrieval with generation', metadata: { category: 'ai' } }
      ]
    end

    let(:pipeline) do
      described_class::Pipeline.new(
        llm: :openai,
        retrieval: :memory,
        config: {
          llm: { api_key: 'mock' },
          retrieval: { documents: documents }
        }
      )
    end

    it 'processes queries through the complete pipeline' do
      result = pipeline.process('What is RapiTapir?', context_fields: [:user_id])
      
      expect(result).to include(
        :answer,
        :sources,
        :context,
        :query
      )
      
      expect(result[:query]).to eq('What is RapiTapir?')
      expect(result[:sources]).to be_an(Array)
      expect(result[:answer]).to be_a(String)
    end

    it 'includes retrieved documents in response' do
      result = pipeline.process('RapiTapir framework')
      
      expect(result[:sources]).not_to be_empty
      expect(result[:sources].first[:content]).to include('RapiTapir')
    end
  end

  describe 'Endpoint RAG Integration' do
    let(:rag_endpoint) do
      RapiTapir::Core::Endpoint.post('/ask')
        .in(RapiTapir::IO.json_body(RapiTapir::Types.hash({ 'question' => RapiTapir::Types.string })))
        .out(RapiTapir::IO.json_body(RapiTapir::Types.hash({ 'answer' => RapiTapir::Types.string })))
        .rag_inference(
          llm: :openai,
          retrieval: :memory,
          context_fields: [:user_id],
          config: { llm: { api_key: 'test' } }
        )
    end

    let(:regular_endpoint) do
      RapiTapir::Core::Endpoint.get('/users')
        .out(RapiTapir::IO.json_body(RapiTapir::Types.hash({ 'users' => RapiTapir::Types.array })))
    end

    it 'correctly identifies RAG-enabled endpoints' do
      expect(rag_endpoint.rag_inference?).to be true
      expect(regular_endpoint.rag_inference?).to be false
    end

    it 'stores RAG configuration in metadata' do
      config = rag_endpoint.rag_config
      
      expect(config).to include(
        llm: :openai,
        retrieval: :memory,
        context_fields: [:user_id],
        config: { llm: { api_key: 'test' } }
      )
    end

    it 'allows chaining with other DSL methods' do
      endpoint = RapiTapir::Core::Endpoint.post('/chat')
        .in(RapiTapir::IO.json_body(RapiTapir::Types.hash({ 'message' => RapiTapir::Types.string })))
        .rag_inference(llm: :openai, retrieval: :memory)
        .summary('Chat with AI')
        .mcp_export

      expect(endpoint.rag_inference?).to be true
      expect(endpoint.mcp_export?).to be true
      expect(endpoint.metadata[:summary]).to eq('Chat with AI')
    end
  end

  describe 'RAG Middleware' do
    let(:app) { ->(env) { [200, {}, ['original response']] } }
    let(:middleware) { RapiTapir::AI::RAG::Middleware.new(app) }
    let(:rag_endpoint) do
      RapiTapir::Core::Endpoint.post('/ask')
        .rag_inference(llm: :openai, retrieval: :memory, config: { llm: { api_key: 'mock' } })
    end

    it 'passes through non-RAG requests' do
      env = { 'rapitapir.endpoint' => nil }
      status, headers, body = middleware.call(env)
      
      expect(status).to eq(200)
      expect(body).to eq(['original response'])
    end

    it 'handles RAG requests' do
      env = {
        'rapitapir.endpoint' => rag_endpoint,
        'CONTENT_TYPE' => 'application/json',
        'rack.input' => StringIO.new('{"question": "What is AI?"}')
      }
      
      status, headers, body = middleware.call(env)
      
      expect(status).to eq(200)
      expect(headers['Content-Type']).to eq('application/json')
      
      response = JSON.parse(body.first)
      expect(response).to include('answer', 'sources', 'metadata')
    end
  end
end
