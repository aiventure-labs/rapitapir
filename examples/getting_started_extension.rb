# frozen_string_literal: true

# RapiTapir Sinatra Extension - Getting Started Example
#
# This minimal example shows how easy it is to create an enterprise-grade
# API with the RapiTapir Sinatra Extension - zero boilerplate!

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

# Only require extension if Sinatra is available
require_relative '../lib/rapitapir/sinatra/extension' if SINATRA_AVAILABLE

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

  def self.update(id, attrs)
    book = find(id)
    return nil unless book

    attrs.each { |key, value| book[key] = value }
    book
  end

  def self.delete(id)
    @@books.reject! { |book| book[:id] == id.to_i }
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

# Your API application - incredibly simple!
if SINATRA_AVAILABLE
  class BookstoreAPI < Sinatra::Base
    register RapiTapir::Sinatra::Extension

    # One-line configuration for the entire API
    rapitapir do
      info(
        title: 'Bookstore API',
        description: 'A simple bookstore API built with RapiTapir Extension',
        version: '1.0.0'
      )

      development_defaults! # Sets up CORS, rate limiting, docs, etc.
      public_paths('/health', '/books') # No auth required for these
    end

    # Health check - super simple
    endpoint(
      RapiTapir.get('/health')
        .summary('Health check')
        .ok(RapiTapir::Types.hash({ 'status' => RapiTapir::Types.string }))
        .build
    ) { { status: 'healthy' } }

    # Full RESTful books resource - one block!
    api_resource '/books', schema: BOOK_SCHEMA do
      # Custom endpoint: published books only (define BEFORE crud to avoid route conflicts)
      custom(:get, 'published',
             summary: 'Get published books',
             configure: ->(endpoint) { endpoint.ok(RapiTapir::Types.array(BOOK_SCHEMA)) }) do
        BookStore.all.select { |book| book[:published] }
      end

      crud(except: [:destroy]) do # All CRUD except delete
        index { BookStore.all }

        show do |inputs|
          book = BookStore.find(inputs[:id])
          halt 404, { error: 'Book not found' }.to_json unless book
          book
        end

        create do |inputs|
          BookStore.create(inputs[:body].transform_keys(&:to_sym))
        end

        update do |inputs|
          book = BookStore.find(inputs[:id])
          halt 404, { error: 'Book not found' }.to_json unless book

          BookStore.update(inputs[:id], inputs[:body].transform_keys(&:to_sym))
        end
      end
    end

    configure :development do
      puts "\n📚 Bookstore API with RapiTapir Extension"
      puts '🌐 Documentation: http://localhost:4567/docs'
      puts '📋 OpenAPI: http://localhost:4567/openapi.json'
      puts '❤️  Health: http://localhost:4567/health'
      puts '📖 Books: http://localhost:4567/books'
      puts "\n✨ Zero boilerplate, full enterprise features!"
    end
  end

  BookstoreAPI.run! if __FILE__ == $PROGRAM_NAME
else
  # Demo mode when Sinatra is not available
  puts "\n📚 RapiTapir Sinatra Extension - Demo Mode"
  puts '=' * 50

  puts "\n✅ Successfully loaded:"
  puts '   • RapiTapir core'
  puts '   • Type system'
  puts '   • Book schema'

  puts "\n📊 This API would provide:"
  puts '   GET    /health           - Health check'
  puts '   GET    /books            - List all books'
  puts '   GET    /books/:id        - Get book by ID'
  puts '   POST   /books            - Create new book'
  puts '   PUT    /books/:id        - Update book'
  puts '   GET    /books/published  - Published books only'
  puts '   GET    /docs             - Swagger UI documentation'
  puts '   GET    /openapi.json     - OpenAPI 3.0 specification'

  puts "\n🎯 Extension features:"
  puts '   • Zero boilerplate configuration'
  puts '   • RESTful resource builder (crud block)'
  puts '   • Built-in authentication helpers'
  puts '   • Auto-generated OpenAPI documentation'
  puts '   • Production middleware (CORS, rate limiting, security)'
  puts '   • Custom endpoints with configure block'

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
