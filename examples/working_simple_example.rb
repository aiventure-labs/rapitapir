# frozen_string_literal: true

# RapiTapir Sinatra Working Example
# Using the original SinatraAdapter approach that we know works

require_relative '../lib/rapitapir'

# Check for Sinatra availability
begin
  require 'sinatra/base'
  require_relative '../lib/rapitapir/server/sinatra_adapter'
  require_relative '../lib/rapitapir/openapi/schema_generator'
  require_relative '../lib/rapitapir/sinatra/swagger_ui_generator'
  SINATRA_AVAILABLE = true
rescue LoadError
  SINATRA_AVAILABLE = false
  puts '⚠️  Sinatra not available. Install with: gem install sinatra'
  puts '🔄 Running in demo mode instead...'
end

# Simple in-memory data store
class BookStore
  @@books = [
    { id: 1, title: 'The Ruby Programming Language', author: 'Matz', isbn: '978-0596516178', published: true },
    { id: 2, title: 'Metaprogramming Ruby', author: 'Paolo Perrotta', isbn: '978-1934356470', published: true }
  ]
  @@next_id = 3

  def self.all
    @@books
  end

  def self.find(id)
    @@books.find { |book| book[:id] == id.to_i }
  end

  def self.create(attrs)
    book = attrs.merge(id: @@next_id)
    @@next_id += 1
    @@books << book
    book
  end

  def self.published
    @@books.select { |book| book[:published] }
  end
end

# Define the book schema
BOOK_SCHEMA = RapiTapir::Types.hash({
                                      'id' => RapiTapir::Types.integer,
                                      'title' => RapiTapir::Types.string,
                                      'author' => RapiTapir::Types.string,
                                      'isbn' => RapiTapir::Types.string,
                                      'published' => RapiTapir::Types.boolean
                                    })

# Working Bookstore API using direct SinatraAdapter
if SINATRA_AVAILABLE
  class WorkingBookstoreAPI < Sinatra::Base
    configure do
      # Create the RapiTapir adapter
      set :rapitapir, RapiTapir::Server::SinatraAdapter.new(self)
    end

    # OpenAPI JSON endpoint - clean and simple
    get '/openapi.json' do
      content_type :json
      endpoints = settings.rapitapir.endpoints.map { |ep_data| ep_data[:endpoint] }

      generator = RapiTapir::OpenAPI::SchemaGenerator.new(
        endpoints: endpoints,
        info: {
          title: 'Working Bookstore API',
          description: 'A simple bookstore API built with RapiTapir and Sinatra',
          version: '1.0.0'
        },
        servers: [{ url: 'http://localhost:4567', description: 'Development server' }]
      )

      generator.to_json
    end

    # Swagger UI documentation endpoint - clean and simple
    get '/docs' do
      content_type :html
      api_info = {
        title: 'Working Bookstore API',
        description: 'A simple bookstore API built with RapiTapir and Sinatra'
      }

      RapiTapir::Sinatra::SwaggerUIGenerator.new('/openapi.json', api_info).generate
    end

    # Health endpoint
    health_endpoint = RapiTapir.get('/health')
                               .summary('Health check')
                               .ok(RapiTapir::Types.hash({ 'status' => RapiTapir::Types.string }))
                               .build

    settings.rapitapir.register_endpoint(health_endpoint) do |_inputs|
      { status: 'healthy' }
    end

    # List books endpoint
    list_books_endpoint = RapiTapir.get('/books')
                                   .summary('List all books')
                                   .ok(RapiTapir::Types.array(BOOK_SCHEMA))
                                   .build

    settings.rapitapir.register_endpoint(list_books_endpoint) do |_inputs|
      BookStore.all
    end

    # Get book by ID endpoint
    get_book_endpoint = RapiTapir.get('/books/:id')
                                 .summary('Get book by ID')
                                 .path_param(:id, RapiTapir::Types.integer, description: 'Book ID')
                                 .ok(BOOK_SCHEMA)
                                 .build

    settings.rapitapir.register_endpoint(get_book_endpoint) do |inputs|
      book = BookStore.find(inputs[:id])
      halt 404, { error: 'Book not found' }.to_json unless book
      book
    end

    # Create book endpoint
    create_book_endpoint = RapiTapir.post('/books')
                                    .summary('Create new book')
                                    .json_body(BOOK_SCHEMA)
                                    .created(BOOK_SCHEMA)
                                    .build

    settings.rapitapir.register_endpoint(create_book_endpoint) do |inputs|
      BookStore.create(inputs[:body].transform_keys(&:to_sym))
    end

    # Published books endpoint
    published_books_endpoint = RapiTapir.get('/books/published')
                                        .summary('Get published books only')
                                        .ok(RapiTapir::Types.array(BOOK_SCHEMA))
                                        .build

    settings.rapitapir.register_endpoint(published_books_endpoint) do |_inputs|
      BookStore.published
    end

    configure :development do
      puts "\n📚 Working Bookstore API"
      puts '🌐 Health: http://localhost:4567/health'
      puts '📖 Books: http://localhost:4567/books'
      puts '📋 Published: http://localhost:4567/books/published'
      puts '📚 Documentation: http://localhost:4567/docs'
      puts '📋 OpenAPI: http://localhost:4567/openapi.json'
      puts "\n✅ Using direct SinatraAdapter integration"
      puts '📖 Full OpenAPI 3.0 documentation auto-generated!'
    end
  end

  WorkingBookstoreAPI.run! if __FILE__ == $PROGRAM_NAME
else
  # Demo mode when Sinatra is not available
  puts "\n📚 Working Bookstore API - Demo Mode"
  puts '=' * 45

  puts "\n✅ Successfully loaded:"
  puts '   • RapiTapir core'
  puts '   • Type system'
  puts '   • Book schema and store'

  puts "\n📊 This API provides:"
  puts '   GET    /health           - Health check'
  puts '   GET    /books            - List all books'
  puts '   GET    /books/:id        - Get book by ID'
  puts '   POST   /books            - Create new book'
  puts '   GET    /books/published  - Published books only'

  puts "\n🔧 Direct SinatraAdapter integration:"
  puts '   • Uses settings.rapitapir.register_endpoint()'
  puts '   • Standard RapiTapir endpoint definitions'
  puts '   • No complex extension magic'
  puts '   • Just works!'

  puts "\n💡 To run the actual server:"
  puts '   gem install sinatra'
  puts "   ruby #{__FILE__}"

  puts "\n📖 Sample usage with curl:"
  puts '   curl http://localhost:4567/books'
  puts '   curl http://localhost:4567/books/1'
  puts '   curl -X POST http://localhost:4567/books \\'
  puts "        -H 'Content-Type: application/json' \\"
  puts "        -d '{\"title\":\"New Book\",\"author\":\"Author\",\"isbn\":\"123\",\"published\":true}'"
end
