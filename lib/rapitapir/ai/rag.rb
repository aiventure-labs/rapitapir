# frozen_string_literal: true

# RapiTapir::AI::RAG
#
# Provides Retrieval-Augmented Generation (RAG) pipeline support for RapiTapir endpoints.
#
# Usage:
#   - Use `.rag_inference(llm:, retrieval:, context_fields:)` in endpoint DSL
#   - Configure LLM and retrieval backends
#   - Process user queries with retrieved context

module RapiTapir
  module AI
    module RAG
      # Base class for LLM providers
      class LLMProvider
        def initialize(config = {})
          @config = config
        end

        def generate(prompt, context = {})
          raise NotImplementedError, 'Subclasses must implement #generate'
        end
      end

      # OpenAI LLM provider
      class OpenAIProvider < LLMProvider
        def initialize(config = {})
          super
          @api_key = config[:api_key] || ENV.fetch('OPENAI_API_KEY', nil)
          @model = config[:model] || 'gpt-3.5-turbo'
          @base_url = config[:base_url] || 'https://api.openai.com/v1'
        end

        def generate(prompt, context = {})
          # Mock implementation for now - replace with actual OpenAI API call
          if @api_key && @api_key != 'mock'
            make_openai_request(prompt, context)
          else
            mock_response(prompt, context)
          end
        end

        private

        def make_openai_request(prompt, context)
          # This would make actual HTTP request to OpenAI
          # For now, return a mock response
          mock_response(prompt, context)
        end

        def mock_response(prompt, context)
          "AI Response: Based on the query '#{prompt}' and context #{context.keys.join(', ')}, here is a generated response."
        end
      end

      # Base class for retrieval backends
      class RetrievalBackend
        def initialize(config = {})
          @config = config
        end

        def retrieve(query, context_fields = [])
          raise NotImplementedError, 'Subclasses must implement #retrieve'
        end
      end

      # PostgreSQL retrieval backend
      class PostgresBackend < RetrievalBackend
        def initialize(config = {})
          super
          @connection_config = config[:connection] || {}
          @table = config[:table] || 'documents'
          @search_column = config[:search_column] || 'content'
        end

        def retrieve(query, context_fields = [])
          # Mock implementation - replace with actual DB query
          mock_retrieval(query, context_fields)
        end

        private

        def mock_retrieval(query, context_fields)
          [
            {
              content: "Sample document content related to: #{query}",
              metadata: context_fields.to_h { |field| [field, "sample_#{field}_value"] },
              score: 0.85
            },
            {
              content: "Another relevant document for: #{query}",
              metadata: context_fields.to_h { |field| [field, "another_#{field}_value"] },
              score: 0.72
            }
          ]
        end
      end

      # Memory/hash-based retrieval backend for testing
      class MemoryBackend < RetrievalBackend
        def initialize(config = {})
          super
          @documents = config[:documents] || []
        end

        def retrieve(query, _context_fields = [])
          # Simple text matching for demo purposes
          matching_docs = @documents.select do |doc|
            doc[:content]&.downcase&.include?(query.downcase)
          end

          matching_docs.map.with_index do |doc, index|
            {
              content: doc[:content],
              metadata: doc[:metadata] || {},
              score: 1.0 - (index * 0.1) # Simple scoring
            }
          end
        end
      end

      # RAG Pipeline orchestrator
      class Pipeline
        attr_reader :llm_provider, :retrieval_backend

        def initialize(llm:, retrieval:, config: {})
          @llm_provider = create_llm_provider(llm, config[:llm] || {})
          @retrieval_backend = create_retrieval_backend(retrieval, config[:retrieval] || {})
          @config = config
        end

        def process(query, context_fields: [], user_context: {})
          # Step 1: Retrieve relevant documents
          retrieved_docs = @retrieval_backend.retrieve(query, context_fields)

          # Step 2: Build context for LLM
          llm_context = build_llm_context(retrieved_docs, user_context, context_fields)

          # Step 3: Generate response using LLM
          prompt = build_prompt(query, llm_context)
          response = @llm_provider.generate(prompt, llm_context)

          # Step 4: Return structured result
          {
            answer: response,
            sources: retrieved_docs,
            context: llm_context,
            query: query
          }
        end

        private

        def create_llm_provider(type, config)
          case type.to_sym
          when :openai
            OpenAIProvider.new(config)
          else
            raise ArgumentError, "Unknown LLM provider: #{type}"
          end
        end

        def create_retrieval_backend(type, config)
          case type.to_sym
          when :postgres, :postgresql
            PostgresBackend.new(config)
          when :memory
            MemoryBackend.new(config)
          else
            raise ArgumentError, "Unknown retrieval backend: #{type}"
          end
        end

        def build_llm_context(retrieved_docs, user_context, context_fields)
          {
            retrieved_documents: retrieved_docs,
            user_context: user_context,
            context_fields: context_fields,
            document_count: retrieved_docs.length
          }
        end

        def build_prompt(query, context)
          documents_text = context[:retrieved_documents]
                           .map { |doc| doc[:content] }
                           .join("\n\n")

          <<~PROMPT
            You are an AI assistant that answers questions based on the provided context.

            Context Documents:
            #{documents_text}

            User Question: #{query}

            Please provide a helpful and accurate answer based on the context provided.
            If the context doesn't contain enough information, say so clearly.
          PROMPT
        end
      end

      # Rack middleware for handling RAG inference requests
      class Middleware
        def initialize(app)
          @app = app
        end

        def call(env)
          endpoint = env['rapitapir.endpoint']

          # Pass through if not a RAG endpoint
          return @app.call(env) unless endpoint&.rag_inference?

          # Process RAG request
          process_rag_request(env, endpoint)
        end

        private

        def process_rag_request(env, endpoint)
          # Parse request body
          request_body = env['rack.input']&.read
          env['rack.input']&.rewind if env['rack.input'].respond_to?(:rewind)

          query_data = request_body ? JSON.parse(request_body) : {}
          question = query_data['question'] || query_data[:question]

          # Get RAG config from endpoint
          rag_config = endpoint.metadata[:rag_inference]

          # Create RAG pipeline
          pipeline = Pipeline.new(
            llm: rag_config[:llm],
            retrieval: rag_config[:retrieval],
            config: rag_config[:config] || {}
          )

          # Process the query
          result = pipeline.process(
            question,
            context_fields: rag_config[:context_fields] || [],
            user_context: extract_user_context(env)
          )

          # Return JSON response
          response_body = JSON.generate(
            answer: result[:answer],
            sources: result[:sources],
            metadata: {
              query: result[:query],
              context_fields: result[:context][:context_fields],
              document_count: result[:context][:document_count]
            }
          )

          [
            200,
            { 'Content-Type' => 'application/json' },
            [response_body]
          ]
        rescue StandardError => e
          error_response = JSON.generate(
            error: 'RAG processing failed',
            message: e.message
          )

          [
            500,
            { 'Content-Type' => 'application/json' },
            [error_response]
          ]
        end

        def extract_user_context(env)
          # Extract relevant context from request environment
          {
            user_agent: env['HTTP_USER_AGENT'],
            remote_ip: env['REMOTE_ADDR'],
            method: env['REQUEST_METHOD'],
            path: env['PATH_INFO']
          }
        end
      end
    end
  end
end
