# frozen_string_literal: true

require_relative '../spec_helper'
require_relative '../../aws_lambda_example'

RSpec.describe 'AWS Lambda Example' do
  def app
    BookAPILambda.new
  end

  describe 'HTTP endpoints' do
    describe 'GET /health' do
      it 'returns health status' do
        get '/health'
        
        expect(last_response).to be_ok
        response = expect_json_response(%w[status timestamp lambda_context])
        expect(response['status']).to eq('healthy')
      end
    end

    describe 'GET /books' do
      it 'returns list of books' do
        get '/books'
        
        expect(last_response).to be_ok
        response = expect_json_response(%w[books total])
        expect(response['books']).to be_an(Array)
        expect(response['total']).to be_an(Integer)
      end

      it 'applies limit parameter' do
        get '/books?limit=1'
        
        expect(last_response).to be_ok
        response = expect_json_response(%w[books total limit])
        expect(response['books'].length).to eq(1)
        expect(response['limit']).to eq(1)
      end

      it 'filters available books only' do
        get '/books?available_only=true'
        
        expect(last_response).to be_ok
        response = expect_json_response(%w[books total])
        response['books'].each do |book|
          expect(book['available']).to be true
        end
      end
    end

    describe 'GET /books/:id' do
      it 'returns specific book' do
        get '/books/1'
        
        expect(last_response).to be_ok
        response = expect_json_response(%w[id title author])
        expect(response['id']).to eq(1)
      end

      it 'returns 404 for non-existent book' do
        get '/books/999'
        
        expect(last_response.status).to eq(404)
        response = expect_json_response(%w[error book_id])
        expect(response['book_id']).to eq(999)
      end
    end

    describe 'POST /books' do
      let(:valid_book) do
        {
          title: 'Test Book',
          author: 'Test Author',
          isbn: '9781234567890',
          published_year: 2024,
          available: true
        }
      end

      it 'creates a new book' do
        post '/books', valid_book.to_json, 'CONTENT_TYPE' => 'application/json'
        
        expect(last_response.status).to eq(201)
        response = expect_json_response(%w[id title author created_at updated_at])
        expect(response['title']).to eq('Test Book')
        expect(response['author']).to eq('Test Author')
      end

      it 'validates required fields' do
        invalid_book = { title: '' }
        post '/books', invalid_book.to_json, 'CONTENT_TYPE' => 'application/json'
        
        expect(last_response.status).to eq(400)
      end
    end

    describe 'GET /lambda/info' do
      it 'returns Lambda runtime information' do
        get '/lambda/info'
        
        expect(last_response).to be_ok
        response = expect_json_response(%w[runtime handler memory_size])
      end
    end
  end

  describe 'Lambda handler function' do
    it 'processes API Gateway event' do
      event = {
        'httpMethod' => 'GET',
        'path' => '/health',
        'queryStringParameters' => nil,
        'headers' => {
          'Content-Type' => 'application/json'
        },
        'body' => nil
      }
      
      context = mock_aws_context
      
      response = lambda_handler(event: event, context: context)
      
      expect(response[:statusCode]).to eq(200)
      expect(response[:headers]).to include('Content-Type')
      
      body = JSON.parse(response[:body])
      expect(body['status']).to eq('healthy')
    end

    it 'handles POST requests with body' do
      book_data = {
        title: 'Lambda Book',
        author: 'Lambda Author'
      }
      
      event = {
        'httpMethod' => 'POST',
        'path' => '/books',
        'queryStringParameters' => nil,
        'headers' => {
          'Content-Type' => 'application/json'
        },
        'body' => book_data.to_json
      }
      
      context = mock_aws_context
      
      response = lambda_handler(event: event, context: context)
      
      expect(response[:statusCode]).to eq(201)
      
      body = JSON.parse(response[:body])
      expect(body['title']).to eq('Lambda Book')
    end

    it 'handles errors gracefully' do
      # Simulate an error by passing invalid event
      event = {}
      context = mock_aws_context
      
      response = lambda_handler(event: event, context: context)
      
      expect(response[:statusCode]).to eq(500)
      expect(response[:headers]).to include('Content-Type' => 'application/json')
      
      body = JSON.parse(response[:body])
      expect(body).to have_key('error')
    end
  end

  describe 'Rack environment conversion' do
    it 'converts API Gateway event to Rack env' do
      event = {
        'httpMethod' => 'GET',
        'path' => '/test',
        'queryStringParameters' => { 'param' => 'value' },
        'headers' => {
          'Host' => 'api.example.com',
          'User-Agent' => 'Test'
        },
        'body' => 'test body'
      }
      
      context = mock_aws_context
      rack_env = build_rack_env_from_api_gateway(event, context)
      
      expect(rack_env['REQUEST_METHOD']).to eq('GET')
      expect(rack_env['PATH_INFO']).to eq('/test')
      expect(rack_env['QUERY_STRING']).to eq('param=value')
      expect(rack_env['HTTP_HOST']).to eq('api.example.com')
      expect(rack_env['HTTP_USER_AGENT']).to eq('Test')
      expect(rack_env['CONTENT_LENGTH']).to eq('9')
    end
  end
end
