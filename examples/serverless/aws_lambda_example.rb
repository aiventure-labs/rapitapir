# frozen_string_literal: true

require 'rapitapir'
require 'json'

# AWS Lambda handler for SinatraRapiTapir
# This example shows how to deploy a RapiTapir API as an AWS Lambda function
class BookAPILambda < SinatraRapiTapir
  # Configure for serverless deployment
  rapitapir do
    info(
      title: 'Serverless Book API',
      description: 'A book management API deployed on AWS Lambda',
      version: '1.0.0'
    )
    
    # Serverless-optimized configuration
    configure do
      set :environment, :production
      set :logging, true
      set :dump_errors, false
      set :raise_errors, true
      
      # Disable features that don't work well in Lambda
      set :sessions, false
      set :static, false
    end
    
    # Enable essential features
    development_defaults!
  end

  # Book schema optimized for serverless
  BOOK_SCHEMA = T.hash({
    "id" => T.integer,
    "title" => T.string(min_length: 1, max_length: 255),
    "author" => T.string(min_length: 1, max_length: 255),
    "isbn" => T.optional(T.string(pattern: /^\d{10}(\d{3})?$/)),
    "published_year" => T.optional(T.integer(minimum: 1000, maximum: 3000)),
    "available" => T.boolean,
    "created_at" => T.optional(T.datetime),
    "updated_at" => T.optional(T.datetime)
  })

  # Mock data for demonstration (in production, use DynamoDB or RDS)
  @@books = [
    {
      id: 1,
      title: "The Ruby Programming Language",
      author: "Matz, Flanagan",
      isbn: "9780596516178",
      published_year: 2008,
      available: true,
      created_at: Time.now - 86400,
      updated_at: Time.now - 86400
    },
    {
      id: 2,
      title: "Effective Ruby",
      author: "Peter J. Jones",
      isbn: "9780134456478", 
      published_year: 2014,
      available: true,
      created_at: Time.now - 43200,
      updated_at: Time.now - 43200
    }
  ]

  # Health check endpoint
  endpoint(
    GET('/health')
      .summary('Health check for Lambda function')
      .description('Returns the health status of the serverless function')
      .tags('Health')
      .ok(T.hash({
        "status" => T.string,
        "timestamp" => T.datetime,
        "lambda_context" => T.optional(T.hash({}))
      }))
      .build
  ) do
    {
      status: 'healthy',
      timestamp: Time.now,
      lambda_context: {
        function_name: ENV['AWS_LAMBDA_FUNCTION_NAME'],
        function_version: ENV['AWS_LAMBDA_FUNCTION_VERSION'],
        memory_limit: ENV['AWS_LAMBDA_FUNCTION_MEMORY_SIZE']
      }
    }
  end

  # List all books
  endpoint(
    GET('/books')
      .summary('List all books')
      .description('Retrieve all books from the serverless database')
      .query(:limit, T.optional(T.integer(minimum: 1, maximum: 100)), description: 'Limit number of results')
      .query(:available_only, T.optional(T.boolean), description: 'Filter only available books')
      .tags('Books')
      .ok(T.hash({
        "books" => T.array(BOOK_SCHEMA),
        "total" => T.integer,
        "limit" => T.optional(T.integer)
      }))
      .build
  ) do |inputs|
    books = @@books.dup
    
    # Filter by availability if requested
    books = books.select { |book| book[:available] } if inputs[:available_only]
    
    # Apply limit
    limit = inputs[:limit]
    books = books.first(limit) if limit
    
    {
      books: books,
      total: books.length,
      limit: limit
    }
  end

  # Get a specific book
  endpoint(
    GET('/books/:id')
      .path_param(:id, T.integer, description: 'Book ID')
      .summary('Get book by ID')
      .description('Retrieve a specific book by its ID')
      .tags('Books')
      .ok(BOOK_SCHEMA)
      .error_response(404, T.hash({ "error" => T.string, "book_id" => T.integer }))
      .build
  ) do |inputs|
    book = @@books.find { |b| b[:id] == inputs[:id] }
    
    if book
      book
    else
      halt 404, { error: 'Book not found', book_id: inputs[:id] }.to_json
    end
  end

  # Create a new book
  endpoint(
    POST('/books')
      .summary('Create a new book')
      .description('Add a new book to the collection')
      .body(T.hash({
        "title" => T.string(min_length: 1, max_length: 255),
        "author" => T.string(min_length: 1, max_length: 255),
        "isbn" => T.optional(T.string(pattern: /^\d{10}(\d{3})?$/)),
        "published_year" => T.optional(T.integer(minimum: 1000, maximum: 3000)),
        "available" => T.optional(T.boolean)
      }))
      .tags('Books')
      .ok(BOOK_SCHEMA)
      .error_response(400, T.hash({ "error" => T.string, "details" => T.optional(T.array(T.string)) }))
      .build
  ) do |inputs|
    book_data = inputs[:body]
    
    # Generate new ID
    new_id = (@@books.map { |b| b[:id] }.max || 0) + 1
    
    # Create new book with timestamps
    new_book = {
      id: new_id,
      title: book_data[:title] || book_data['title'],
      author: book_data[:author] || book_data['author'],
      isbn: book_data[:isbn] || book_data['isbn'],
      published_year: book_data[:published_year] || book_data['published_year'],
      available: book_data.key?(:available) ? book_data[:available] : (book_data.key?('available') ? book_data['available'] : true),
      created_at: Time.now,
      updated_at: Time.now
    }
    
    @@books << new_book
    
    status 201
    new_book
  end

  # Lambda-specific endpoints
  endpoint(
    GET('/lambda/info')
      .summary('AWS Lambda runtime information')
      .description('Get information about the Lambda runtime environment')
      .tags('Lambda', 'Info')
      .ok(T.hash({
        "runtime" => T.string,
        "handler" => T.string,
        "memory_size" => T.string,
        "timeout" => T.string,
        "version" => T.string,
        "log_group" => T.string,
        "request_id" => T.optional(T.string)
      }))
      .build
  ) do
    {
      runtime: ENV['AWS_EXECUTION_ENV'] || 'Unknown',
      handler: ENV['_HANDLER'] || 'Unknown',
      memory_size: ENV['AWS_LAMBDA_FUNCTION_MEMORY_SIZE'] || 'Unknown',
      timeout: ENV['AWS_LAMBDA_FUNCTION_TIMEOUT'] || 'Unknown',
      version: ENV['AWS_LAMBDA_FUNCTION_VERSION'] || 'Unknown',
      log_group: ENV['AWS_LAMBDA_LOG_GROUP_NAME'] || 'Unknown',
      request_id: Thread.current[:lambda_request_id]
    }
  end
end

# AWS Lambda handler function
def lambda_handler(event:, context:)
  # Store Lambda context for access in endpoints
  Thread.current[:lambda_context] = context
  Thread.current[:lambda_request_id] = context.aws_request_id
  
  # Convert API Gateway event to Rack environment
  rack_env = build_rack_env_from_api_gateway(event, context)
  
  # Process request through Sinatra app
  app = BookAPILambda.new
  status, headers, body = app.call(rack_env)
  
  # Convert Rack response to API Gateway format
  build_api_gateway_response(status, headers, body)
rescue => e
  # Error handling for Lambda
  {
    statusCode: 500,
    headers: { 'Content-Type' => 'application/json' },
    body: {
      error: 'Internal server error',
      message: e.message,
      request_id: context&.aws_request_id
    }.to_json
  }
ensure
  # Clean up thread variables
  Thread.current[:lambda_context] = nil
  Thread.current[:lambda_request_id] = nil
end

# Convert API Gateway event to Rack environment
def build_rack_env_from_api_gateway(event, context)
  method = event['httpMethod'] || event['requestContext']['http']['method']
  path = event['path'] || event['rawPath']
  query_string = event['queryStringParameters'] || {}
  headers = event['headers'] || {}
  body = event['body']
  
  # Build query string
  query_string_formatted = query_string.map { |k, v| "#{k}=#{v}" }.join('&') if query_string.any?
  
  rack_env = {
    'REQUEST_METHOD' => method,
    'PATH_INFO' => path,
    'QUERY_STRING' => query_string_formatted || '',
    'CONTENT_TYPE' => headers['content-type'] || headers['Content-Type'],
    'CONTENT_LENGTH' => body ? body.bytesize.to_s : '0',
    'rack.input' => StringIO.new(body || ''),
    'rack.errors' => $stderr,
    'rack.version' => [1, 3],
    'rack.url_scheme' => 'https',
    'rack.multithread' => false,
    'rack.multiprocess' => true,
    'rack.run_once' => true,
    'SERVER_NAME' => headers['host'] || 'localhost',
    'SERVER_PORT' => '443',
    'HTTP_HOST' => headers['host'] || 'localhost'
  }
  
  # Add HTTP headers
  headers.each do |key, value|
    key = key.upcase.gsub('-', '_')
    key = "HTTP_#{key}" unless %w[CONTENT_TYPE CONTENT_LENGTH].include?(key)
    rack_env[key] = value
  end
  
  rack_env
end

# Convert Rack response to API Gateway format
def build_api_gateway_response(status, headers, body)
  # Combine body parts if it's an array
  body_content = ''
  body.each { |part| body_content += part }
  
  # Determine if response should be base64 encoded
  is_base64 = !body_content.encoding.ascii_compatible? || 
              headers['Content-Type']&.include?('image/') ||
              headers['Content-Type']&.include?('application/pdf')
  
  {
    statusCode: status,
    headers: headers,
    body: is_base64 ? Base64.encode64(body_content) : body_content,
    isBase64Encoded: is_base64
  }
end

# For local development
if __FILE__ == $0
  # Run locally for testing
  BookAPILambda.run!
end
