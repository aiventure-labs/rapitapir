#require 'rapitapir' # Only one require needed!
require 'sinatra/base'
require_relative '../../lib/rapitapir'

# Simple Book model for demonstration
class Book
  attr_reader :id, :title, :author, :published, :isbn, :pages
  
  @@books = [
    { id: 1, title: "The Ruby Programming Language", author: "Matz", published: true, isbn: "978-0596516178", pages: 448 },
    { id: 2, title: "Effective Ruby", author: "Peter Jones", published: true, isbn: "978-0134045993", pages: 256 },
    { id: 3, title: "Ruby Under a Microscope", author: "Pat Shaughnessy", published: true, isbn: "978-1593275273", pages: 360 }
  ]
  
  def self.all
    @@books
  end
  
  def self.find(id)
    @@books.find { |book| book[:id] == id.to_i }
  end
  
  def self.create(attributes)
    new_id = (@@books.map { |b| b[:id] }.max || 0) + 1
    new_book = attributes.merge(id: new_id)
    @@books << new_book
    new_book
  end
  
  def self.search(query)
    results = @@books.select do |book|
      book[:title].downcase.include?(query.downcase) || 
      book[:author].downcase.include?(query.downcase)
    end
    BookCollection.new(results)
  end
  
  def self.where(conditions)
    results = @@books.select do |book|
      conditions.all? { |key, value| book[key] == value }
    end
    BookCollection.new(results)
  end
end

# Simple collection class to handle chaining
class BookCollection
  def initialize(books)
    @books = books
  end
  
  def limit(count)
    BookCollection.new(@books.first(count))
  end
  
  def map(&block)
    @books.map(&block)
  end
  
  def to_a
    @books
  end
end

class BookAPI < SinatraRapiTapir
  # Configure API information
  rapitapir do
    info(
      title: 'Book API',
      description: 'A simple book management API',
      version: '1.0.0'
    )
    development_defaults! # Auto CORS, docs, health checks
  end

  # Define your data schema with T shortcut (globally available!)
  BOOK_SCHEMA = T.hash({
    "id" => T.integer,
    "title" => T.string(min_length: 1, max_length: 255),
    "author" => T.string(min_length: 1),
    "published" => T.boolean,
    "isbn" => T.optional(T.string),
    "pages" => T.optional(T.integer(minimum: 1))
  })

  # Define endpoints with the elegant resource DSL and enhanced HTTP verbs
  api_resource '/books', schema: BOOK_SCHEMA do
    crud do
      index { Book.all }
      
      show do |inputs|
        book = Book.find(inputs[:id])
        halt(404, { error: 'Book not found' }.to_json) unless book
        book
      end
      
      create do |inputs|
        Book.create(inputs[:body])
      end
    end
    
    # Custom endpoint using enhanced DSL
    custom :get, 'featured' do
      Book.where(featured: true).to_a
    end
  end

  # Alternative endpoint definition using enhanced HTTP verb DSL
  endpoint(
    GET('/api/books/search')
      .query(:q, T.string(min_length: 1), description: 'Search query')
      .query(:limit, T.optional(T.integer(minimum: 1, maximum: 100)), description: 'Results limit')
      .summary('Search books')
      .description('Search books by title or author')
      .tags('Search')
      .ok(T.array(BOOK_SCHEMA))
      .bad_request(T.hash({ "error" => T.string }), description: 'Invalid search parameters')
      .build
  ) do |inputs|
    query = inputs[:q]
    limit = inputs[:limit] || 20
    
    books = Book.search(query).limit(limit)
    books.to_a
  end

  run! if __FILE__ == $0
end