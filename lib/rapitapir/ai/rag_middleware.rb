# frozen_string_literal: true

require_relative 'rag'

module RapiTapir
  module AI
    module RAG
      # Middleware for handling RAG-enabled endpoints
      # Integrates with RapiTapir server adapters to process RAG requests
      class Middleware
        def initialize(app)
          @app = app
        end

        def call(env)
          # Check if this is a RAG-enabled endpoint
          endpoint = env['rapitapir.endpoint']
          if endpoint&.rag_inference?
            handle_rag_request(env, endpoint)
          else
            @app.call(env)
          end
        end

        private

        def handle_rag_request(env, endpoint)
          # Extract request data
          request_data = extract_request_data(env)

          # Get the query from the request (assuming it's in the body)
          query = request_data[:question] || request_data[:query] || request_data.values.first

          # Create RAG pipeline from endpoint configuration
          rag_config = endpoint.rag_config
          pipeline = create_rag_pipeline(rag_config)

          # Process the query through RAG pipeline
          result = pipeline.process(
            query,
            context_fields: rag_config[:context_fields],
            user_context: extract_user_context(env, rag_config[:context_fields])
          )

          # Return RAG response
          build_rag_response(result)
        rescue StandardError => e
          build_error_response(e)
        end

        def extract_request_data(env)
          # Simple JSON parsing - in real implementation would be more robust
          if env['CONTENT_TYPE']&.include?('application/json')
            body = env['rack.input']&.read || '{}'
            env['rack.input']&.rewind
            JSON.parse(body, symbolize_names: true)
          else
            {}
          end
        rescue JSON::ParserError
          {}
        end

        def extract_user_context(env, context_fields)
          # Extract user context from headers, session, etc.
          context = {}

          context_fields.each do |field|
            case field
            when :user_id
              context[:user_id] = env['HTTP_X_USER_ID'] || env['HTTP_AUTHORIZATION']&.split&.last
            when :session_id
              context[:session_id] = env['HTTP_X_SESSION_ID']
            when :tenant_id
              context[:tenant_id] = env['HTTP_X_TENANT_ID']
            end
          end

          context
        end

        def create_rag_pipeline(config)
          Pipeline.new(
            llm: config[:llm],
            retrieval: config[:retrieval],
            config: config[:config] || {}
          )
        end

        def build_rag_response(result)
          response_body = {
            answer: result[:answer],
            sources: result[:sources],
            metadata: {
              query: result[:query],
              source_count: result[:sources].length,
              timestamp: Time.now.iso8601
            }
          }

          [
            200,
            { 'Content-Type' => 'application/json' },
            [JSON.generate(response_body)]
          ]
        end

        def build_error_response(error)
          response_body = {
            error: 'RAG processing failed',
            message: error.message,
            timestamp: Time.now.iso8601
          }

          [
            500,
            { 'Content-Type' => 'application/json' },
            [JSON.generate(response_body)]
          ]
        end
      end

      # Helper for mounting RAG endpoints in server adapters
      class EndpointHandler
        def self.handle(endpoint, request_data, user_context = {})
          return nil unless endpoint.rag_inference?

          rag_config = endpoint.rag_config
          pipeline = Pipeline.new(
            llm: rag_config[:llm],
            retrieval: rag_config[:retrieval],
            config: rag_config[:config] || {}
          )

          # Extract query from request data
          query = request_data[:question] || request_data[:query] || request_data.to_s

          pipeline.process(
            query,
            context_fields: rag_config[:context_fields],
            user_context: user_context
          )
        end
      end
    end
  end
end
