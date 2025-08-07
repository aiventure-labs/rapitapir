# frozen_string_literal: true

require 'rapitapir'
require 'json'

# Azure Functions handler for SinatraRapiTapir
# This example shows how to deploy a RapiTapir API as an Azure Function
class BookAPIAzureFunction < SinatraRapiTapir
  # Configure for Azure Functions
  rapitapir do
    info(
      title: 'Serverless Book API - Azure Functions',
      description: 'A book management API deployed on Azure Functions',
      version: '1.0.0'
    )
    
    # Azure Functions optimized configuration
    configure do
      set :environment, :production
      set :logging, true
      set :dump_errors, false
      set :raise_errors, true
      
      # Azure Functions specific settings
      set :sessions, false
      set :static, false
      set :protection, except: [:json_csrf]
    end
    
    development_defaults!
  end

  # Book schema for Azure Cosmos DB compatibility
  BOOK_SCHEMA = T.hash({
    "id" => T.string, # Azure Cosmos DB uses string IDs
    "title" => T.string(min_length: 1, max_length: 255),
    "author" => T.string(min_length: 1, max_length: 255),
    "isbn" => T.optional(T.string(pattern: /^\d{10}(\d{3})?$/)),
    "published_year" => T.optional(T.integer(minimum: 1000, maximum: 3000)),
    "available" => T.boolean,
    "category" => T.optional(T.string),
    "created_at" => T.datetime,
    "updated_at" => T.datetime,
    "_rid" => T.optional(T.string), # Cosmos DB resource ID
    "_etag" => T.optional(T.string) # Cosmos DB etag for optimistic concurrency
  })

  # Mock data (in production, use Azure Cosmos DB or SQL Database)
  @@books = [
    {
      id: "azure_book_1",
      title: "Ruby on Azure",
      author: "Cloud Developer",
      isbn: "9781234567890",
      published_year: 2023,
      available: true,
      category: "cloud",
      created_at: Time.now - 86400,
      updated_at: Time.now - 86400
    },
    {
      id: "azure_book_2",
      title: "Serverless Ruby Applications",
      author: "Function Expert",
      isbn: "9789876543210",
      published_year: 2024,
      available: true,
      category: "serverless",
      created_at: Time.now - 43200,
      updated_at: Time.now - 43200
    }
  ]

  # Health check with Azure Functions info
  endpoint(
    GET('/health')
      .summary('Health check for Azure Function')
      .description('Returns the health status of the Azure Function')
      .tags('Health', 'Azure')
      .ok(T.hash({
        "status" => T.string,
        "timestamp" => T.datetime,
        "azure_info" => T.hash({
          "function_app_name" => T.optional(T.string),
          "function_name" => T.optional(T.string),
          "resource_group" => T.optional(T.string),
          "subscription_id" => T.optional(T.string),
          "region" => T.optional(T.string),
          "plan_type" => T.optional(T.string)
        })
      }))
      .build
  ) do
    {
      status: 'healthy',
      timestamp: Time.now,
      azure_info: {
        function_app_name: ENV['WEBSITE_SITE_NAME'],
        function_name: ENV['REQ_HEADERS_FUNCTION_NAME'],
        resource_group: ENV['WEBSITE_RESOURCE_GROUP'],
        subscription_id: ENV['WEBSITE_OWNER_NAME']&.split('+')&.first,
        region: ENV['REGION_NAME'],
        plan_type: ENV['WEBSITE_SKU']
      }
    }
  end

  # List books with Azure-specific features
  endpoint(
    GET('/books')
      .summary('List all books')
      .description('Retrieve books with Azure Cosmos DB style querying')
      .query(:limit, T.optional(T.integer(minimum: 1, maximum: 100)), description: 'Limit results')
      .query(:category, T.optional(T.string), description: 'Filter by category')
      .query(:continuation_token, T.optional(T.string), description: 'Pagination token')
      .tags('Books')
      .ok(T.hash({
        "books" => T.array(BOOK_SCHEMA),
        "count" => T.integer,
        "continuation_token" => T.optional(T.string),
        "request_charge" => T.optional(T.float)
      }))
      .build
  ) do |inputs|
    books = @@books.dup
    
    # Apply category filter
    books = books.select { |book| book[:category] == inputs[:category] } if inputs[:category]
    
    # Simple pagination simulation
    limit = inputs[:limit] || 50
    offset = inputs[:continuation_token] ? inputs[:continuation_token].to_i : 0
    
    paginated_books = books[offset, limit] || []
    next_token = (offset + limit < books.length) ? (offset + limit).to_s : nil
    
    {
      books: paginated_books,
      count: paginated_books.length,
      continuation_token: next_token,
      request_charge: 2.5 # Mock Cosmos DB RU charge
    }
  end

  # Get book by ID
  endpoint(
    GET('/books/:id')
      .path_param(:id, T.string, description: 'Book ID')
      .summary('Get book by ID')
      .description('Retrieve a specific book from Azure storage')
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

  # Create book with Azure optimizations
  endpoint(
    POST('/books')
      .summary('Create a new book')
      .description('Add a book to Azure Cosmos DB')
      .body(T.hash({
        "title" => T.string(min_length: 1, max_length: 255),
        "author" => T.string(min_length: 1, max_length: 255),
        "isbn" => T.optional(T.string(pattern: /^\d{10}(\d{3})?$/)),
        "published_year" => T.optional(T.integer(minimum: 1000, maximum: 3000)),
        "available" => T.optional(T.boolean),
        "category" => T.optional(T.string)
      }))
      .tags('Books')
      .ok(BOOK_SCHEMA)
      .error_response(400, T.hash({ "error" => T.string }))
      .build
  ) do |inputs|
    book_data = inputs[:body]
    
    # Generate Azure-style ID
    new_id = "azure_book_#{SecureRandom.uuid}"
    
    new_book = {
      id: new_id,
      title: book_data[:title] || book_data['title'],
      author: book_data[:author] || book_data['author'],
      isbn: book_data[:isbn] || book_data['isbn'],
      published_year: book_data[:published_year] || book_data['published_year'],
      available: book_data.key?(:available) ? book_data[:available] : (book_data.key?('available') ? book_data['available'] : true),
      category: book_data[:category] || book_data['category'],
      created_at: Time.now,
      updated_at: Time.now,
      _rid: "rid_#{SecureRandom.hex(8)}",
      _etag: "etag_#{SecureRandom.hex(16)}"
    }
    
    @@books << new_book
    
    status 201
    new_book
  end

  # Azure-specific monitoring endpoint
  endpoint(
    GET('/azure/function-metrics')
      .summary('Azure Function performance metrics')
      .description('Get Azure-specific runtime and performance information')
      .tags('Azure', 'Monitoring')
      .ok(T.hash({
        "function_execution" => T.hash({
          "execution_id" => T.optional(T.string),
          "invocation_id" => T.optional(T.string),
          "execution_context" => T.optional(T.string)
        }),
        "azure_environment" => T.hash({
          "app_service_plan" => T.optional(T.string),
          "website_sku" => T.optional(T.string),
          "instance_id" => T.optional(T.string),
          "worker_runtime" => T.optional(T.string)
        }),
        "performance" => T.hash({
          "memory_usage_mb" => T.optional(T.integer),
          "cpu_time_ms" => T.optional(T.integer),
          "cold_start" => T.optional(T.boolean)
        })
      }))
      .build
  ) do
    {
      function_execution: {
        execution_id: ENV['REQ_HEADERS_FUNCTION_EXECUTION_ID'],
        invocation_id: ENV['REQ_HEADERS_FUNCTION_INVOCATION_ID'],
        execution_context: Thread.current[:azure_execution_context]
      },
      azure_environment: {
        app_service_plan: ENV['WEBSITE_SKU'],
        website_sku: ENV['WEBSITE_SKU'],
        instance_id: ENV['WEBSITE_INSTANCE_ID'],
        worker_runtime: ENV['FUNCTIONS_WORKER_RUNTIME']
      },
      performance: {
        memory_usage_mb: get_memory_usage,
        cpu_time_ms: get_cpu_time,
        cold_start: Thread.current[:cold_start]
      }
    }
  end

  # Azure Service Bus integration example
  endpoint(
    POST('/books/:id/notify')
      .path_param(:id, T.string, description: 'Book ID')
      .body(T.hash({
        "event_type" => T.string(enum: %w[borrowed returned reserved cancelled]),
        "user_id" => T.string,
        "message" => T.optional(T.string)
      }))
      .summary('Send book notification')
      .description('Send notification via Azure Service Bus')
      .tags('Books', 'Notifications', 'Azure')
      .ok(T.hash({
        "notification_sent" => T.boolean,
        "message_id" => T.string,
        "queue_name" => T.string
      }))
      .build
  ) do |inputs|
    book = @@books.find { |b| b[:id] == inputs[:id] }
    halt 404, { error: 'Book not found' }.to_json unless book
    
    event_data = inputs[:body]
    
    # Simulate Azure Service Bus message
    message_id = "msg_#{SecureRandom.uuid}"
    queue_name = "book-notifications"
    
    # In production, send to Azure Service Bus
    notification_payload = {
      book_id: inputs[:id],
      book_title: book[:title],
      event_type: event_data[:event_type],
      user_id: event_data[:user_id],
      message: event_data[:message],
      timestamp: Time.now.iso8601
    }
    
    # Mock sending notification
    puts "Sending to Azure Service Bus: #{notification_payload.to_json}"
    
    {
      notification_sent: true,
      message_id: message_id,
      queue_name: queue_name
    }
  end

  private

  def get_memory_usage
    # Mock memory usage (in production, use Azure monitoring)
    rand(100..500)
  end

  def get_cpu_time
    # Mock CPU time (in production, use Azure monitoring)
    rand(50..200)
  end
end

# Azure Functions entry point
def main(context, req)
  # Set Azure execution context
  Thread.current[:azure_execution_context] = context
  Thread.current[:cold_start] = !defined?(@@app_initialized)
  
  # Initialize app (cached after first execution)
  @@app ||= BookAPIAzureFunction.new
  @@app_initialized = true
  
  # Convert Azure Functions request to Rack environment
  rack_env = build_rack_env_from_azure(req, context)
  
  # Process request
  status, headers, body = @@app.call(rack_env)
  
  # Convert response for Azure Functions
  body_content = ''
  body.each { |part| body_content += part }
  
  # Azure Functions response format
  {
    status: status,
    headers: headers,
    body: body_content
  }
rescue => e
  # Error handling for Azure Functions
  {
    status: 500,
    headers: { 'Content-Type' => 'application/json' },
    body: {
      error: 'Internal server error',
      message: e.message,
      timestamp: Time.now.iso8601,
      execution_id: context[:invocation_id]
    }.to_json
  }
ensure
  # Clean up thread variables
  Thread.current[:azure_execution_context] = nil
  Thread.current[:cold_start] = nil
end

# Convert Azure Functions request to Rack environment
def build_rack_env_from_azure(req, context)
  method = req[:method]
  url = req[:url]
  uri = URI.parse(url)
  
  query_string = uri.query || ''
  path = uri.path
  
  # Get request body
  body = req[:body] || ''
  headers = req[:headers] || {}
  
  rack_env = {
    'REQUEST_METHOD' => method,
    'PATH_INFO' => path,
    'QUERY_STRING' => query_string,
    'CONTENT_TYPE' => headers['content-type'] || headers['Content-Type'],
    'CONTENT_LENGTH' => body.bytesize.to_s,
    'rack.input' => StringIO.new(body),
    'rack.errors' => $stderr,
    'rack.version' => [1, 3],
    'rack.url_scheme' => uri.scheme || 'https',
    'rack.multithread' => false,
    'rack.multiprocess' => true,
    'rack.run_once' => true,
    'SERVER_NAME' => uri.host || 'localhost',
    'SERVER_PORT' => (uri.port || 443).to_s,
    'HTTP_HOST' => uri.host || 'localhost'
  }
  
  # Add HTTP headers
  headers.each do |key, value|
    key = key.upcase.gsub('-', '_')
    key = "HTTP_#{key}" unless %w[CONTENT_TYPE CONTENT_LENGTH].include?(key)
    rack_env[key] = value
  end
  
  # Add Azure-specific headers
  rack_env['HTTP_X_AZURE_EXECUTION_ID'] = context[:invocation_id] if context[:invocation_id]
  rack_env['HTTP_X_AZURE_FUNCTION_NAME'] = context[:function_name] if context[:function_name]
  
  rack_env
end

# For local development
if __FILE__ == $0
  BookAPIAzureFunction.run!
end
