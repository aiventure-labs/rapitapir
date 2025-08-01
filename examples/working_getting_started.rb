# frozen_string_literal: true

# RapiTapir Sinatra Extension - WORKING Getting Started Example
#
# This is a simplified version that actually works with Sinatra!

# Check for Sinatra availability
begin
  require 'sinatra/base'
  SINATRA_AVAILABLE = true
rescue LoadError
  SINATRA_AVAILABLE = false
  puts '⚠️  Sinatra not available. Install with: gem install sinatra'
  puts '🔄 Running in demo mode instead...'
end

require_relative '../lib/rapitapir'

# Only require SinatraAdapter if Sinatra is available
if SINATRA_AVAILABLE
  require_relative '../lib/rapitapir/server/sinatra_adapter'
  require_relative '../lib/rapitapir/openapi/schema_generator'
  require_relative '../lib/rapitapir/sinatra/swagger_ui_generator'
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

# WORKING Bookstore API - simplified but effective!
if SINATRA_AVAILABLE
  class WorkingBookstoreAPI < Sinatra::Base
    configure do
      # Create the RapiTapir adapter - this is the key!
      set :rapitapir, RapiTapir::Server::SinatraAdapter.new(self)
      puts '📝 RapiTapir integration enabled'
    end

    # OpenAPI JSON endpoint - clean and simple
    get '/openapi.json' do
      content_type :json
      endpoints = settings.rapitapir.endpoints.map { |ep_data| ep_data[:endpoint] }

      generator = RapiTapir::OpenAPI::SchemaGenerator.new(
        endpoints: endpoints,
        info: {
          title: 'WORKING Bookstore API',
          description: 'A simple bookstore API built with RapiTapir and Sinatra - WORKING VERSION!',
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
        title: 'WORKING Bookstore API',
        description: 'A simple bookstore API built with RapiTapir and Sinatra - WORKING VERSION!'
      }

      RapiTapir::Sinatra::SwaggerUIGenerator.new('/openapi.json', api_info).generate
    end

    # Health check - super simple
    health_endpoint = RapiTapir.get('/health')
                               .summary('Health check')
                               .ok(RapiTapir::Types.hash({ 'status' => RapiTapir::Types.string }))
                               .build

    settings.rapitapir.register_endpoint(health_endpoint) { { status: 'healthy' } }

    # List all books
    list_books_endpoint = RapiTapir.get('/books')
                                   .summary('List all books')
                                   .ok(RapiTapir::Types.array(BOOK_SCHEMA))
                                   .build

    settings.rapitapir.register_endpoint(list_books_endpoint) { BookStore.all }

    # Published books only - custom endpoint (define BEFORE :id route)
    published_books_endpoint = RapiTapir.get('/books/published')
                                        .summary('Get published books only')
                                        .ok(RapiTapir::Types.array(BOOK_SCHEMA))
                                        .build

    settings.rapitapir.register_endpoint(published_books_endpoint) { BookStore.published }

    # Get book by ID (must come AFTER specific routes like /books/published)
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

    configure :development do
      puts "\n📚 WORKING Bookstore API with RapiTapir"
      puts '🌐 Health: http://localhost:4567/health'
      puts '📖 Books: http://localhost:4567/books'
      puts '📋 Published: http://localhost:4567/books/published'
      puts '📖 Book by ID: http://localhost:4567/books/1'
      puts '📚 Documentation: http://localhost:4567/docs'
      puts '📋 OpenAPI: http://localhost:4567/openapi.json'
      puts "\n✅ Zero boilerplate, working integration!"
      puts '💡 Key: Direct use of SinatraAdapter.register_endpoint()'
      puts '📖 Full OpenAPI 3.0 documentation auto-generated!'
    end
  end

  WorkingBookstoreAPI.run! if __FILE__ == $PROGRAM_NAME
else
  # Demo mode when Sinatra is not available
  puts "\n📚 RapiTapir Bookstore API - Demo Mode"
  puts '=' * 50

  puts "\n✅ Successfully loaded:"
  puts '   • RapiTapir core'
  puts '   • Type system'
  puts '   • Book schema and store'

  puts "\n📊 This working API provides:"
  puts '   GET    /health           - Health check'
  puts '   GET    /books            - List all books'
  puts '   GET    /books/:id        - Get book by ID'
  puts '   GET    /books/published  - Published books only'

  puts "\n🔧 Working pattern:"
  puts '   • Create SinatraAdapter: RapiTapir::Server::SinatraAdapter.new(self)'
  puts '   • Register endpoints: settings.rapitapir.register_endpoint(endpoint, &handler)'
  puts "   • Build endpoints: RapiTapir.get('/path').summary('...').build"
  puts '   • Simple and effective!'

  puts "\n💡 To run the working server:"
  puts '   gem install sinatra rack'
  puts "   ruby #{__FILE__}"

  puts "\n📖 Sample usage with curl:"
  puts '   curl http://localhost:4567/health'
  puts '   curl http://localhost:4567/books'
  puts '   curl http://localhost:4567/books/1'
  puts '   curl http://localhost:4567/books/published'
end
