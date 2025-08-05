# RapiTapir Rails Integration

This document provides a complete guide to using RapiTapir with Ruby on Rails, featuring the enhanced developer experience that matches Sinatra's elegance.

## 🆕 Enhanced Rails Integration

RapiTapir now provides a **clean base class** for Rails controllers that delivers the same excellent developer experience as our Sinatra integration.

## 🚀 Quick Start

### 1. Installation

Add to your Gemfile:

```ruby
gem 'rapitapir'
```

### 2. Create Enhanced Controllers

Use the new `ControllerBase` class for the cleanest syntax:

```ruby
# app/controllers/users_controller.rb
require 'rapitapir/server/rails/controller_base'

class UsersController < RapiTapir::Server::Rails::ControllerBase
  rapitapir do
    info(title: 'Users API', version: '1.0.0')
    # development_defaults! # Coming soon
  end

  USER_SCHEMA = T.hash({
    "id" => T.integer,
    "name" => T.string,
    "email" => T.email
  })

  api_resource '/users', schema: USER_SCHEMA do
    crud do
      index { User.all.map(&:attributes) }
      show { |inputs| User.find(inputs[:id]).attributes }
      create { |inputs| User.create!(inputs[:body]).attributes }
    end
  end
end
```

### 3. Auto-Generate Routes

Add to your `config/routes.rb`:

```ruby
Rails.application.routes.draw do
  # Option 1: Auto-generate routes for specific controller
  rapitapir_routes_for UsersController
  
  # Option 2: Auto-discover all RapiTapir controllers
  rapitapir_auto_routes
end
```

### 4. Access Documentation

Start your Rails server and visit:
- Interactive Documentation: `http://localhost:3000/docs`
- OpenAPI Specification: `http://localhost:3000/openapi.json`

## 🏗️ Core Features

### Clean Base Class Syntax

The new `ControllerBase` provides inheritance-based setup:

```ruby
class ApiController < RapiTapir::Server::Rails::ControllerBase
  rapitapir do
    info(title: 'My API', version: '1.0.0')
  end

  # T shortcut automatically available
  # Enhanced HTTP verb DSL automatically available
  # Auto action generation
end
```

### Enhanced HTTP Verb DSL

Use the same fluent DSL as Sinatra:

```ruby
endpoint(
  GET('/books/:id')
    .summary('Get book by ID')
    .path_param(:id, T.integer(minimum: 1))
    .ok(BOOK_SCHEMA)
    .not_found(T.hash({ "error" => T.string }))
    .build
) do |inputs|
  book = Book.find(inputs[:id])
  book ? book.attributes : (render json: {error: 'Not found'}, status: 404)
end
```

### RESTful Resource Builder

Create complete CRUD APIs with minimal code:

```ruby
api_resource '/books', schema: BOOK_SCHEMA do
  crud do
    index do
      books = Book.all
      books = books.where(published: true) if params[:published] == 'true'
      books.limit(params[:limit] || 50).map(&:attributes)
    end
    
    show { |inputs| Book.find(inputs[:id]).attributes }
    
    create do |inputs|
      book = Book.create!(inputs[:body])
      response.status = 201
      book.attributes
    end
    
    update { |inputs| Book.update!(inputs[:id], inputs[:body]).attributes }
    destroy { |inputs| Book.destroy(inputs[:id]); head :no_content }
  end
  
  # Add custom endpoints
  custom :get, 'featured' do
    Book.where(featured: true).map(&:attributes)
  end
end
```

### Automatic Route Generation

Three options for route generation:

#### Option 1: Per-Controller Generation
```ruby
# config/routes.rb
Rails.application.routes.draw do
  rapitapir_routes_for UsersController
  rapitapir_routes_for BooksController
end
```

#### Option 2: Auto-Discovery
```ruby
# config/routes.rb
Rails.application.routes.draw do
  rapitapir_auto_routes  # Finds all RapiTapir controllers
end
```

#### Option 3: Manual Routes (Still Supported)
```ruby
# config/routes.rb
Rails.application.routes.draw do
  resources :users, only: [:index, :show, :create, :update, :destroy]
end
```

## 📋 Migration from Legacy Approach

### Before (Verbose)

```ruby
class UsersController < ApplicationController
  include RapiTapir::Server::Rails::Controller

  rapitapir_endpoint :index, RapiTapir.get('/users')
                                      .summary('List all users')
                                      .out(RapiTapir::Core::Output.new(
                                             kind: :json, type: { users: Array }
                                           )) do |_inputs|
    { users: @users.values }
  end

  def index
    process_rapitapir_endpoint
  end
end
```

### After (Clean)

```ruby
class UsersController < RapiTapir::Server::Rails::ControllerBase
  rapitapir do
    info(title: 'Users API', version: '1.0.0')
  end

  USER_SCHEMA = T.hash({ "id" => T.integer, "name" => T.string })

  api_resource '/users', schema: USER_SCHEMA do
    crud do
      index { User.all.map(&:attributes) }
    end
  end
end
```

## 🔧 Advanced Features

### Custom Endpoints with Full Type Safety

```ruby
endpoint(
  POST('/users/bulk')
    .summary('Create multiple users')
    .json_body(T.array(USER_CREATE_SCHEMA))
    .created(T.array(USER_SCHEMA))
    .bad_request(ERROR_SCHEMA)
    .build
) do |inputs|
  users = inputs[:body].map { |user_data| User.create!(user_data) }
  response.status = 201
  users.map(&:attributes)
end
```

### Search Endpoints

```ruby
endpoint(
  GET('/users/search')
    .summary('Search users')
    .query(:q, T.string(min_length: 1))
    .query(:limit, T.optional(T.integer(minimum: 1, maximum: 100)))
    .ok(T.array(USER_SCHEMA))
    .build
) do |inputs|
  results = User.where("name ILIKE ?", "%#{inputs[:q]}%")
  results = results.limit(inputs[:limit]) if inputs[:limit]
  results.map(&:attributes)
end
```

### Error Handling

```ruby
show do |inputs|
  user = User.find_by(id: inputs[:id])
  
  if user.nil?
    render json: { error: 'User not found' }, status: :not_found
    return
  end
  
  user.attributes
end
```

## 📖 Complete Example

Here's a full-featured Rails controller using all the enhanced features:

```ruby
# app/controllers/books_controller.rb
require 'rapitapir/server/rails/controller_base'

class BooksController < RapiTapir::Server::Rails::ControllerBase
  rapitapir do
    info(
      title: 'Books API',
      description: 'A comprehensive book management API',
      version: '1.0.0'
    )
  end

  BOOK_SCHEMA = T.hash({
    "id" => T.integer,
    "title" => T.string(min_length: 1, max_length: 255),
    "author" => T.string(min_length: 1),
    "published" => T.boolean,
    "isbn" => T.optional(T.string),
    "pages" => T.optional(T.integer(minimum: 1)),
    "created_at" => T.datetime,
    "updated_at" => T.datetime
  })

  BOOK_CREATE_SCHEMA = T.hash({
    "title" => T.string(min_length: 1, max_length: 255),
    "author" => T.string(min_length: 1),
    "published" => T.optional(T.boolean),
    "isbn" => T.optional(T.string),
    "pages" => T.optional(T.integer(minimum: 1))
  })

  # CRUD operations with enhanced resource builder
  api_resource '/books', schema: BOOK_SCHEMA do
    crud do
      index do
        books = Book.includes(:author)
        books = books.where(published: true) if params[:published] == 'true'
        books = books.where('title ILIKE ?', "%#{params[:search]}%") if params[:search]
        
        limit = params[:limit]&.to_i || 20
        offset = params[:offset]&.to_i || 0
        
        books.offset(offset).limit(limit).map(&:attributes)
      end
      
      show do |inputs|
        book = Book.find_by(id: inputs[:id])
        book ? book.attributes : (render json: {error: 'Book not found'}, status: 404)
      end
      
      create do |inputs|
        book = Book.create!(inputs[:body])
        response.status = 201
        book.attributes
      end
      
      update do |inputs|
        book = Book.find_by(id: inputs[:id])
        
        if book.nil?
          render json: { error: 'Book not found' }, status: 404
          return
        end
        
        book.update!(inputs[:body])
        book.attributes
      end
      
      destroy do |inputs|
        book = Book.find_by(id: inputs[:id])
        
        if book.nil?
          render json: { error: 'Book not found' }, status: 404
          return
        end
        
        book.destroy!
        head :no_content
      end
    end
    
    # Custom endpoints
    custom :get, 'featured' do
      Book.where(featured: true).map(&:attributes)
    end
  end

  # Additional custom endpoints
  endpoint(
    GET('/books/search')
      .summary('Advanced book search')
      .query(:q, T.string(min_length: 1), description: 'Search query')
      .query(:author, T.optional(T.string), description: 'Filter by author')
      .query(:published, T.optional(T.boolean), description: 'Filter by published status')
      .query(:limit, T.optional(T.integer(minimum: 1, maximum: 100)), description: 'Results limit')
      .ok(T.array(BOOK_SCHEMA))
      .build
  ) do |inputs|
    query = inputs[:q]
    books = Book.where('title ILIKE ? OR description ILIKE ?', "%#{query}%", "%#{query}%")
    books = books.joins(:author).where('authors.name ILIKE ?', "%#{inputs[:author]}%") if inputs[:author]
    books = books.where(published: inputs[:published]) if inputs.key?(:published)
    books = books.limit(inputs[:limit] || 20)
    
    books.map(&:attributes)
  end
end
```

## 🛣️ Routes Configuration

```ruby
# config/routes.rb
Rails.application.routes.draw do
  # Auto-generate all RapiTapir routes
  rapitapir_auto_routes
  
  # Or generate for specific controllers
  # rapitapir_routes_for BooksController
  # rapitapir_routes_for UsersController
end
```

## 🎯 Benefits

### Compared to Legacy Rails Integration

| Feature | Legacy Approach | Enhanced Approach |
|---------|----------------|-------------------|
| **Base Class** | Manual include | Clean inheritance |
| **HTTP Verbs** | Verbose `RapiTapir.get()` | Clean `GET()` |
| **Type Shortcuts** | `RapiTapir::Types.string` | `T.string` |
| **Action Generation** | Manual `def action; process_rapitapir_endpoint; end` | Automatic |
| **Route Generation** | Manual Rails routes | Auto-generated |
| **CRUD Operations** | Individual endpoint definitions | `api_resource` with `crud` block |
| **Configuration** | Scattered setup | Single `rapitapir` block |

### Compared to Sinatra

| Feature | Sinatra | Enhanced Rails | Status |
|---------|---------|----------------|---------|
| **Clean Inheritance** | ✅ `< SinatraRapiTapir` | ✅ `< ControllerBase` | **Achieved** |
| **HTTP Verb DSL** | ✅ `GET()`, `POST()` | ✅ `GET()`, `POST()` | **Achieved** |
| **Resource Builder** | ✅ `api_resource` | ✅ `api_resource` | **Achieved** |
| **T Shortcuts** | ✅ `T.string` | ✅ `T.string` | **Achieved** |
| **Auto Routes** | ✅ Automatic | ✅ `rapitapir_auto_routes` | **Achieved** |
| **Documentation** | ✅ `/docs` | 🚧 Coming soon | **In Progress** |

## 🚧 Coming Soon

- **Development Defaults**: Auto CORS, health checks, documentation
- **Built-in Documentation**: `/docs` endpoint for Rails apps  
- **Authentication Helpers**: Bearer token, OAuth2 integration
- **Observability**: Metrics and tracing integration
- **Generator**: Rails generator for RapiTapir controllers

## 📚 See Also

- [Enhanced Users Controller Example](enhanced_users_controller.rb)
- [Legacy Users Controller Example](users_controller.rb) (for comparison)
- [Sinatra Integration Guide](../docs/SINATRA_EXTENSION.md)
- [Type System Documentation](../docs/types.md)
