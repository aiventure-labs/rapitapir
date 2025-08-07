# frozen_string_literal: true

require 'rapitapir'
require 'json'

# Vercel serverless function for SinatraRapiTapir
# This example shows how to deploy a RapiTapir API on Vercel
class BookAPIVercel < SinatraRapiTapir
  # Configure for Vercel serverless
  rapitapir do
    info(
      title: 'Serverless Book API - Vercel',
      description: 'A book management API deployed on Vercel Edge Functions',
      version: '1.0.0'
    )
    
    # Vercel optimized configuration
    configure do
      set :environment, :production
      set :logging, true
      set :dump_errors, false
      set :raise_errors, true
      
      # Vercel-specific optimizations
      set :sessions, false
      set :static, false
      set :show_exceptions, false
    end
    
    development_defaults!
  end

  # Book schema optimized for edge computing
  BOOK_SCHEMA = T.hash({
    "id" => T.string,
    "title" => T.string(min_length: 1, max_length: 255),
    "author" => T.string(min_length: 1, max_length: 255),
    "isbn" => T.optional(T.string(pattern: /^\d{10}(\d{3})?$/)),
    "published_year" => T.optional(T.integer(minimum: 1000, maximum: 3000)),
    "available" => T.boolean,
    "tags" => T.optional(T.array(T.string)),
    "rating" => T.optional(T.float(minimum: 0, maximum: 5)),
    "created_at" => T.datetime,
    "updated_at" => T.datetime
  })

  # In-memory storage for demo (use Vercel KV or external DB in production)
  @@books = [
    {
      id: "vercel_book_1",
      title: "Serverless Ruby at the Edge",
      author: "Edge Developer",
      isbn: "9781111111111",
      published_year: 2024,
      available: true,
      tags: ["ruby", "serverless", "edge"],
      rating: 4.8,
      created_at: Time.now - 86400,
      updated_at: Time.now - 86400
    },
    {
      id: "vercel_book_2",
      title: "Building APIs with RapiTapir",
      author: "API Expert",
      isbn: "9782222222222",
      published_year: 2024,
      available: true,
      tags: ["api", "ruby", "rapitapir"],
      rating: 4.9,
      created_at: Time.now - 43200,
      updated_at: Time.now - 43200
    }
  ]

  # Health check with Vercel-specific info
  endpoint(
    GET('/health')
      .summary('Health check for Vercel function')
      .description('Returns health status with Vercel deployment info')
      .tags('Health', 'Vercel')
      .ok(T.hash({
        "status" => T.string,
        "timestamp" => T.datetime,
        "vercel_info" => T.hash({
          "region" => T.optional(T.string),
          "deployment_id" => T.optional(T.string),
          "environment" => T.optional(T.string),
          "branch" => T.optional(T.string),
          "commit_sha" => T.optional(T.string)
        }),
        "performance" => T.hash({
          "cold_start" => T.boolean,
          "edge_location" => T.optional(T.string)
        })
      }))
      .build
  ) do
    {
      status: 'healthy',
      timestamp: Time.now,
      vercel_info: {
        region: ENV['VERCEL_REGION'],
        deployment_id: ENV['VERCEL_DEPLOYMENT_ID'],
        environment: ENV['VERCEL_ENV'],
        branch: ENV['VERCEL_GIT_COMMIT_REF'],
        commit_sha: ENV['VERCEL_GIT_COMMIT_SHA']
      },
      performance: {
        cold_start: Thread.current[:cold_start] || false,
        edge_location: ENV['VERCEL_REGION']
      }
    }
  end

  # Fast book listing for edge performance
  endpoint(
    GET('/books')
      .summary('List books (edge optimized)')
      .description('Fast book listing optimized for edge deployment')
      .query(:limit, T.optional(T.integer(minimum: 1, maximum: 50)), description: 'Limit results')
      .query(:tag, T.optional(T.string), description: 'Filter by tag')
      .query(:min_rating, T.optional(T.float(minimum: 0, maximum: 5)), description: 'Minimum rating')
      .tags('Books')
      .ok(T.hash({
        "books" => T.array(BOOK_SCHEMA),
        "total" => T.integer,
        "edge_cached" => T.boolean,
        "response_time_ms" => T.float
      }))
      .build
  ) do |inputs|
    start_time = Time.now
    books = @@books.dup
    
    # Apply tag filter
    books = books.select { |book| book[:tags]&.include?(inputs[:tag]) } if inputs[:tag]
    
    # Apply rating filter
    books = books.select { |book| (book[:rating] || 0) >= inputs[:min_rating] } if inputs[:min_rating]
    
    # Apply limit
    limit = inputs[:limit] || 20
    books = books.first(limit)
    
    response_time = ((Time.now - start_time) * 1000).round(2)
    
    {
      books: books,
      total: books.length,
      edge_cached: false, # Could be true if using Vercel Edge Config
      response_time_ms: response_time
    }
  end

  # Get book with edge caching headers
  endpoint(
    GET('/books/:id')
      .path_param(:id, T.string, description: 'Book ID')
      .summary('Get book by ID (edge cached)')
      .description('Retrieve a book with aggressive edge caching')
      .tags('Books')
      .ok(BOOK_SCHEMA)
      .error_response(404, T.hash({ "error" => T.string, "book_id" => T.string }))
      .build
  ) do |inputs|
    book = @@books.find { |b| b[:id] == inputs[:id] }
    
    if book
      # Set cache headers for Vercel edge caching
      cache_control 'public, max-age=300, s-maxage=3600' # 5min browser, 1hr edge
      headers 'X-Vercel-Cache' => 'MISS' # Would be set by Vercel
      
      book
    else
      halt 404, { error: 'Book not found', book_id: inputs[:id] }.to_json
    end
  end

  # Fast book creation
  endpoint(
    POST('/books')
      .summary('Create book (edge optimized)')
      .description('Quickly create a new book with edge processing')
      .body(T.hash({
        "title" => T.string(min_length: 1, max_length: 255),
        "author" => T.string(min_length: 1, max_length: 255),
        "isbn" => T.optional(T.string(pattern: /^\d{10}(\d{3})?$/)),
        "published_year" => T.optional(T.integer(minimum: 1000, maximum: 3000)),
        "available" => T.optional(T.boolean),
        "tags" => T.optional(T.array(T.string)),
        "rating" => T.optional(T.float(minimum: 0, maximum: 5))
      }))
      .tags('Books')
      .ok(BOOK_SCHEMA)
      .error_response(400, T.hash({ "error" => T.string }))
      .build
  ) do |inputs|
    book_data = inputs[:body]
    
    # Generate edge-optimized ID
    new_id = "vercel_#{Time.now.to_i}_#{rand(1000)}"
    
    new_book = {
      id: new_id,
      title: book_data[:title] || book_data['title'],
      author: book_data[:author] || book_data['author'],
      isbn: book_data[:isbn] || book_data['isbn'],
      published_year: book_data[:published_year] || book_data['published_year'],
      available: book_data.key?(:available) ? book_data[:available] : (book_data.key?('available') ? book_data['available'] : true),
      tags: book_data[:tags] || book_data['tags'] || [],
      rating: book_data[:rating] || book_data['rating'],
      created_at: Time.now,
      updated_at: Time.now
    }
    
    @@books << new_book
    
    # Set location header
    headers 'Location' => "/books/#{new_id}"
    
    status 201
    new_book
  end

  # Vercel-specific analytics endpoint
  endpoint(
    GET('/vercel/analytics')
      .summary('Vercel deployment analytics')
      .description('Get Vercel-specific deployment and performance data')
      .tags('Vercel', 'Analytics')
      .ok(T.hash({
        "deployment" => T.hash({
          "id" => T.optional(T.string),
          "url" => T.optional(T.string),
          "environment" => T.optional(T.string),
          "created_at" => T.optional(T.datetime)
        }),
        "git_info" => T.hash({
          "branch" => T.optional(T.string),
          "commit_sha" => T.optional(T.string),
          "commit_message" => T.optional(T.string),
          "repo_url" => T.optional(T.string)
        }),
        "edge_performance" => T.hash({
          "region" => T.optional(T.string),
          "cold_starts" => T.integer,
          "avg_response_time" => T.float
        })
      }))
      .build
  ) do
    {
      deployment: {
        id: ENV['VERCEL_DEPLOYMENT_ID'],
        url: ENV['VERCEL_URL'],
        environment: ENV['VERCEL_ENV'],
        created_at: ENV['VERCEL_DEPLOYMENT_ID'] ? Time.now : nil # Mock timestamp
      },
      git_info: {
        branch: ENV['VERCEL_GIT_COMMIT_REF'],
        commit_sha: ENV['VERCEL_GIT_COMMIT_SHA'],
        commit_message: ENV['VERCEL_GIT_COMMIT_MESSAGE'],
        repo_url: ENV['VERCEL_GIT_REPO_SLUG'] ? "https://github.com/#{ENV['VERCEL_GIT_REPO_SLUG']}" : nil
      },
      edge_performance: {
        region: ENV['VERCEL_REGION'],
        cold_starts: 0, # Mock data
        avg_response_time: 45.2 # Mock data
      }
    }
  end

  # Search with edge optimization
  endpoint(
    GET('/books/search')
      .query(:q, T.string(min_length: 1), description: 'Search query')
      .query(:fuzzy, T.optional(T.boolean), description: 'Enable fuzzy search')
      .summary('Search books (edge optimized)')
      .description('Fast search optimized for edge computing')
      .tags('Books', 'Search')
      .ok(T.hash({
        "results" => T.array(BOOK_SCHEMA),
        "query" => T.string,
        "fuzzy_enabled" => T.boolean,
        "search_time_ms" => T.float,
        "edge_region" => T.optional(T.string)
      }))
      .build
  ) do |inputs|
    start_time = Time.now
    query = inputs[:q].downcase
    fuzzy = inputs[:fuzzy] || false
    
    results = @@books.select do |book|
      # Simple text search (could be enhanced with fuzzy matching)
      [book[:title], book[:author], book[:tags]&.join(' ')].compact.any? do |field|
        if fuzzy
          # Simple fuzzy matching (could use more sophisticated algorithms)
          field.downcase.include?(query) || 
          query.chars.all? { |c| field.downcase.include?(c) }
        else
          field.downcase.include?(query)
        end
      end
    end
    
    search_time = ((Time.now - start_time) * 1000).round(2)
    
    # Set edge cache headers
    cache_control 'public, max-age=60, s-maxage=300' # 1min browser, 5min edge
    
    {
      results: results,
      query: inputs[:q],
      fuzzy_enabled: fuzzy,
      search_time_ms: search_time,
      edge_region: ENV['VERCEL_REGION']
    }
  end
end

# Vercel handler function
def handler(request:, response:)
  # Mark as cold start on first execution
  Thread.current[:cold_start] = !defined?(@@vercel_app_initialized)
  
  # Initialize app (cached after first execution)  
  @@vercel_app ||= BookAPIVercel.new
  @@vercel_app_initialized = true
  
  # Convert Vercel request to Rack environment
  rack_env = build_rack_env_from_vercel(request)
  
  # Process request
  status, headers, body = @@vercel_app.call(rack_env)
  
  # Convert response for Vercel
  body_content = ''
  body.each { |part| body_content += part }
  
  # Set Vercel response
  response.status = status
  headers.each { |key, value| response[key] = value }
  response.write(body_content)
  
rescue => e
  # Error handling for Vercel
  response.status = 500
  response['Content-Type'] = 'application/json'
  response.write({
    error: 'Internal server error',
    message: e.message,
    timestamp: Time.now.iso8601,
    region: ENV['VERCEL_REGION']
  }.to_json)
ensure
  Thread.current[:cold_start] = nil
end

# Convert Vercel request to Rack environment
def build_rack_env_from_vercel(request)
  method = request.method
  url = request.url
  uri = URI.parse(url)
  
  # Get request body
  body = request.body || ''
  
  rack_env = {
    'REQUEST_METHOD' => method,
    'PATH_INFO' => uri.path,
    'QUERY_STRING' => uri.query || '',
    'CONTENT_TYPE' => request.headers['content-type'],
    'CONTENT_LENGTH' => body.bytesize.to_s,
    'rack.input' => StringIO.new(body),
    'rack.errors' => $stderr,
    'rack.version' => [1, 3],
    'rack.url_scheme' => uri.scheme || 'https',
    'rack.multithread' => false,
    'rack.multiprocess' => true,
    'rack.run_once' => true,
    'SERVER_NAME' => uri.host,
    'SERVER_PORT' => (uri.port || 443).to_s,
    'HTTP_HOST' => uri.host
  }
  
  # Add HTTP headers
  request.headers.each do |key, value|
    key = key.upcase.gsub('-', '_')
    key = "HTTP_#{key}" unless %w[CONTENT_TYPE CONTENT_LENGTH].include?(key)
    rack_env[key] = value
  end
  
  # Add Vercel-specific headers
  rack_env['HTTP_X_VERCEL_DEPLOYMENT_ID'] = ENV['VERCEL_DEPLOYMENT_ID']
  rack_env['HTTP_X_VERCEL_REGION'] = ENV['VERCEL_REGION']
  
  rack_env
end

# For local development
if __FILE__ == $0
  BookAPIVercel.run!
end
