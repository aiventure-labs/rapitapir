# frozen_string_literal: true

require 'rapitapir'
require 'functions_framework'
require 'json'

# Google Cloud Functions handler for SinatraRapiTapir
# This example shows how to deploy a RapiTapir API as a Google Cloud Function
class BookAPICloudFunction < SinatraRapiTapir
  # Configure for Google Cloud Functions
  rapitapir do
    info(
      title: 'Serverless Book API - Google Cloud Functions',
      description: 'A book management API deployed on Google Cloud Functions',
      version: '1.0.0'
    )
    
    # Cloud Functions optimized configuration
    configure do
      set :environment, :production
      set :logging, true
      set :dump_errors, false
      set :raise_errors, true
      
      # Disable features that don't work well in Cloud Functions
      set :sessions, false
      set :static, false
      set :protection, except: [:json_csrf] # Cloud Functions handles CSRF
    end
    
    # Enable essential features for serverless
    development_defaults!
  end

  # Book schema
  BOOK_SCHEMA = T.hash({
    "id" => T.string, # Using string IDs for Firestore compatibility
    "title" => T.string(min_length: 1, max_length: 255),
    "author" => T.string(min_length: 1, max_length: 255),
    "isbn" => T.optional(T.string(pattern: /^\d{10}(\d{3})?$/)),
    "published_year" => T.optional(T.integer(minimum: 1000, maximum: 3000)),
    "available" => T.boolean,
    "created_at" => T.datetime,
    "updated_at" => T.datetime,
    "metadata" => T.optional(T.hash({}))
  })

  # Mock data (in production, use Firestore or Cloud SQL)
  @@books = [
    {
      id: "book_1",
      title: "The Ruby Programming Language",
      author: "Matz, Flanagan",
      isbn: "9780596516178",
      published_year: 2008,
      available: true,
      created_at: Time.now - 86400,
      updated_at: Time.now - 86400,
      metadata: { category: "programming", difficulty: "intermediate" }
    },
    {
      id: "book_2", 
      title: "Effective Ruby",
      author: "Peter J. Jones",
      isbn: "9780134456478",
      published_year: 2014,
      available: true,
      created_at: Time.now - 43200,
      updated_at: Time.now - 43200,
      metadata: { category: "programming", difficulty: "advanced" }
    }
  ]

  # Health check with Cloud Functions specific info
  endpoint(
    GET('/health')
      .summary('Health check for Cloud Function')
      .description('Returns the health status of the Google Cloud Function')
      .tags('Health', 'Cloud Functions')
      .ok(T.hash({
        "status" => T.string,
        "timestamp" => T.datetime,
        "function_info" => T.hash({
          "name" => T.optional(T.string),
          "region" => T.optional(T.string),
          "project" => T.optional(T.string),
          "memory" => T.optional(T.string),
          "timeout" => T.optional(T.string)
        })
      }))
      .build
  ) do
    {
      status: 'healthy',
      timestamp: Time.now,
      function_info: {
        name: ENV['FUNCTION_NAME'],
        region: ENV['FUNCTION_REGION'],
        project: ENV['GCP_PROJECT'] || ENV['GOOGLE_CLOUD_PROJECT'],
        memory: ENV['FUNCTION_MEMORY_MB'],
        timeout: ENV['FUNCTION_TIMEOUT_SEC']
      }
    }
  end

  # List books with Cloud Functions optimizations
  endpoint(
    GET('/books')
      .summary('List all books')
      .description('Retrieve all books with optional filtering')
      .query(:limit, T.optional(T.integer(minimum: 1, maximum: 100)), description: 'Limit results')
      .query(:category, T.optional(T.string), description: 'Filter by category')
      .query(:available_only, T.optional(T.boolean), description: 'Show only available books')
      .tags('Books')
      .ok(T.hash({
        "books" => T.array(BOOK_SCHEMA),
        "total" => T.integer,
        "limit" => T.optional(T.integer),
        "filters_applied" => T.hash({})
      }))
      .build
  ) do |inputs|
    books = @@books.dup
    filters_applied = {}
    
    # Apply category filter
    if inputs[:category]
      books = books.select { |book| book[:metadata]&.dig(:category) == inputs[:category] }
      filters_applied[:category] = inputs[:category]
    end
    
    # Apply availability filter
    if inputs[:available_only]
      books = books.select { |book| book[:available] }
      filters_applied[:available_only] = true
    end
    
    # Apply limit
    limit = inputs[:limit]
    books = books.first(limit) if limit
    
    {
      books: books,
      total: books.length,
      limit: limit,
      filters_applied: filters_applied
    }
  end

  # Get specific book
  endpoint(
    GET('/books/:id')
      .path_param(:id, T.string, description: 'Book ID')
      .summary('Get book by ID')
      .description('Retrieve a specific book')
      .tags('Books')
      .ok(BOOK_SCHEMA)
      .error_response(404, T.hash({ "error" => T.string, "book_id" => T.string }))
      .build
  ) do |inputs|
    book = @@books.find { |b| b[:id] == inputs[:id] }
    
    if book
      book
    else
      halt 404, { error: 'Book not found', book_id: inputs[:id] }.to_json
    end
  end

  # Create book
  endpoint(
    POST('/books')
      .summary('Create a new book')
      .description('Add a new book to the collection')
      .body(T.hash({
        "title" => T.string(min_length: 1, max_length: 255),
        "author" => T.string(min_length: 1, max_length: 255),
        "isbn" => T.optional(T.string(pattern: /^\d{10}(\d{3})?$/)),
        "published_year" => T.optional(T.integer(minimum: 1000, maximum: 3000)),
        "available" => T.optional(T.boolean),
        "metadata" => T.optional(T.hash({}))
      }))
      .tags('Books')
      .ok(BOOK_SCHEMA)
      .error_response(400, T.hash({ "error" => T.string, "details" => T.optional(T.array(T.string)) }))
      .build
  ) do |inputs|
    book_data = inputs[:body]
    
    # Generate new ID (in production, use Firestore auto-generated IDs)
    new_id = "book_#{Time.now.to_i}_#{rand(1000)}"
    
    new_book = {
      id: new_id,
      title: book_data[:title] || book_data['title'],
      author: book_data[:author] || book_data['author'],
      isbn: book_data[:isbn] || book_data['isbn'],
      published_year: book_data[:published_year] || book_data['published_year'],
      available: book_data.key?(:available) ? book_data[:available] : (book_data.key?('available') ? book_data['available'] : true),
      metadata: book_data[:metadata] || book_data['metadata'] || {},
      created_at: Time.now,
      updated_at: Time.now
    }
    
    @@books << new_book
    
    status 201
    new_book
  end

  # Cloud Functions specific endpoints
  endpoint(
    GET('/gcp/function-info')
      .summary('Google Cloud Function runtime info')
      .description('Get detailed information about the Cloud Function environment')
      .tags('GCP', 'Info')
      .ok(T.hash({
        "function" => T.hash({
          "name" => T.optional(T.string),
          "region" => T.optional(T.string),
          "project" => T.optional(T.string),
          "memory_mb" => T.optional(T.string),
          "timeout_sec" => T.optional(T.string),
          "runtime" => T.optional(T.string)
        }),
        "request" => T.hash({
          "execution_id" => T.optional(T.string),
          "trace_id" => T.optional(T.string)
        }),
        "environment" => T.hash({
          "ruby_version" => T.string,
          "rack_env" => T.optional(T.string)
        })
      }))
      .build
  ) do
    {
      function: {
        name: ENV['FUNCTION_NAME'],
        region: ENV['FUNCTION_REGION'], 
        project: ENV['GCP_PROJECT'] || ENV['GOOGLE_CLOUD_PROJECT'],
        memory_mb: ENV['FUNCTION_MEMORY_MB'],
        timeout_sec: ENV['FUNCTION_TIMEOUT_SEC'],
        runtime: ENV['FUNCTION_RUNTIME']
      },
      request: {
        execution_id: ENV['FUNCTION_EXECUTION_ID'],
        trace_id: request.env['HTTP_X_CLOUD_TRACE_CONTEXT']&.split('/')&.first
      },
      environment: {
        ruby_version: RUBY_VERSION,
        rack_env: ENV['RACK_ENV']
      }
    }
  end

  # Search with Cloud Functions optimizations
  endpoint(
    GET('/books/search')
      .query(:q, T.string(min_length: 1), description: 'Search query')
      .query(:fields, T.optional(T.array(T.string(enum: %w[title author isbn]))), description: 'Fields to search')
      .summary('Search books')
      .description('Search books by title, author, or ISBN')
      .tags('Books', 'Search')
      .ok(T.hash({
        "results" => T.array(BOOK_SCHEMA),
        "query" => T.string,
        "fields_searched" => T.array(T.string),
        "total_matches" => T.integer
      }))
      .build
  ) do |inputs|
    query = inputs[:q].downcase
    fields = inputs[:fields] || %w[title author isbn]
    
    results = @@books.select do |book|
      fields.any? do |field|
        book[field.to_sym]&.to_s&.downcase&.include?(query)
      end
    end
    
    {
      results: results,
      query: inputs[:q],
      fields_searched: fields,
      total_matches: results.length
    }
  end
end

# Initialize the Sinatra app instance
APP = BookAPICloudFunction.new

# Google Cloud Functions entry point using Functions Framework
FunctionsFramework.http('rapitapir_book_api') do |request|
  # Convert Cloud Functions request to Rack environment
  rack_env = build_rack_env_from_cloud_functions(request)
  
  # Process through Sinatra app
  status, headers, body = APP.call(rack_env)
  
  # Convert response for Cloud Functions
  body_content = ''
  body.each { |part| body_content += part }
  
  # Create Cloud Functions response
  response = Rack::Response.new(body_content, status, headers)
  response.finish
rescue => e
  # Error handling
  error_response = {
    error: 'Internal server error',
    message: e.message,
    timestamp: Time.now.iso8601
  }
  
  [500, { 'Content-Type' => 'application/json' }, [error_response.to_json]]
end

# Convert Cloud Functions request to Rack environment
def build_rack_env_from_cloud_functions(request)
  # Extract method and path
  method = request.request_method
  path = request.path
  query_string = request.query_string
  
  # Get request body
  body = request.body.read if request.body
  request.body.rewind if request.body&.respond_to?(:rewind)
  
  rack_env = {
    'REQUEST_METHOD' => method,
    'PATH_INFO' => path,
    'QUERY_STRING' => query_string || '',
    'CONTENT_TYPE' => request.content_type,
    'CONTENT_LENGTH' => body ? body.bytesize.to_s : '0',
    'rack.input' => StringIO.new(body || ''),
    'rack.errors' => $stderr,
    'rack.version' => [1, 3],
    'rack.url_scheme' => 'https',
    'rack.multithread' => false,
    'rack.multiprocess' => true,
    'rack.run_once' => true,
    'SERVER_NAME' => request.host,
    'SERVER_PORT' => request.port.to_s,
    'HTTP_HOST' => request.host
  }
  
  # Add HTTP headers
  request.headers.each do |key, value|
    key = key.upcase.gsub('-', '_')
    key = "HTTP_#{key}" unless %w[CONTENT_TYPE CONTENT_LENGTH].include?(key)
    rack_env[key] = value.is_a?(Array) ? value.join(',') : value
  end
  
  # Add Cloud Functions specific headers
  rack_env['HTTP_X_FORWARDED_FOR'] = request.headers['x-forwarded-for'] if request.headers['x-forwarded-for']
  rack_env['HTTP_X_CLOUD_TRACE_CONTEXT'] = request.headers['x-cloud-trace-context'] if request.headers['x-cloud-trace-context']
  
  rack_env
end

# For local development
if __FILE__ == $0
  # Run locally for testing
  BookAPICloudFunction.run!
end
