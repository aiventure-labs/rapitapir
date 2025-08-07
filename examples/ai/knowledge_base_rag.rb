# frozen_string_literal: true

require 'bundler/setup'

# Add the project root to the load path for development
project_root = File.expand_path('../../', __dir__)
$LOAD_PATH.unshift(File.join(project_root, 'lib')) unless $LOAD_PATH.include?(File.join(project_root, 'lib'))

require 'rapitapir'
require 'rapitapir/ai/rag'
require 'json'

# Example: Knowledge Base API with RAG Support
module KnowledgeBaseAPI
  extend RapiTapir::DSL

  # Type alias for convenience
  T = RapiTapir::Types

  # Define schemas
  ASK_SCHEMA = T.hash({
    'question' => T.string,
    'user_id' => T.string
  }).freeze

  ANSWER_SCHEMA = T.hash({
    'answer' => T.string,
    'sources' => T.array(T.string),
    'timestamp' => T.string
  }).freeze

  CHAT_INPUT_SCHEMA = T.hash({
    'message' => T.string
  }).freeze

  CHAT_OUTPUT_SCHEMA = T.hash({
    'response' => T.string
  }).freeze

  # Ask a question using RAG
  ASK_QUESTION = RapiTapir.post('/ask')
    .json_body(ASK_SCHEMA)
    .ok(ANSWER_SCHEMA)
    .rag_inference(
      llm: :openai,
      retrieval: :memory,
      context_fields: [:user_id],
      config: {
        llm: { api_key: 'mock' },
        retrieval: {
          documents: [
            { content: 'RapiTapir is a Ruby API framework that provides type-safe endpoints.' },
            { content: 'RAG combines document retrieval with LLM text generation.' },
            { content: 'This API demonstrates AI-powered question answering.' }
          ]
        }
      }
    )
    .summary('Ask a question about the knowledge base')
    .mcp_export

  # Simple chat
  CHAT = RapiTapir.post('/chat')
    .json_body(CHAT_INPUT_SCHEMA)
    .ok(CHAT_OUTPUT_SCHEMA)
    .rag_inference(
      llm: :openai,
      retrieval: :memory,
      config: {
        llm: { api_key: 'mock' },
        retrieval: {
          documents: [
            { content: 'RapiTapir supports MCP for AI agent integration.' }
          ]
        }
      }
    )
    .summary('Chat with AI')
    .mcp_export
end

# Endpoints for CLI
knowledge_base_api = [KnowledgeBaseAPI::ASK_QUESTION, KnowledgeBaseAPI::CHAT]
