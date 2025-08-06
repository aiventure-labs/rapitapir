# Traditional Rails Application with RapiTapir

This example demonstrates how to structure a **real Rails application** using RapiTapir following Rails conventions and best practices.

## 📁 Clean Structure

```
traditional_app/
├── Gemfile                                   # Dependencies
├── README.md                                 # This file
├── app/
│   └── controllers/
│       ├── application_controller.rb        # Base controller with health check
│       └── api/
│           └── v1/
│               ├── users_controller.rb      # User API endpoints
│               └── posts_controller.rb      # Post API endpoints
└── config/
    └── routes.rb                            # Clean routing with rapitapir_routes_for
```

## 🎯 Key Features

### ✅ **Simplified Architecture**
- **No separate health controller** - health check is an endpoint in ApplicationController
- **No separate documentation controller** - uses RapiTapir's built-in `DocumentationHelpers`
- **Auto-generated routes** - `rapitapir_routes_for` creates routes from endpoint definitions
- **Auto-generated docs** - `development_defaults!` enables `/docs` and `/openapi.json`

### ✅ **Rails Best Practices**
- **Namespaced APIs** - `/api/v1/` structure
- **Global error handling** - Defined once in ApplicationController
- **Standard Rails patterns** - Filters, rescue handlers, etc.
- **Environment-aware** - Documentation only in development

### ✅ **Production Ready**
- **Comprehensive error responses** - 401, 403, 404, 422, 500
- **Type safety** - All inputs/outputs defined and validated
- **Health monitoring** - Database and service status checks
- **API documentation** - Always up-to-date with code

## 🚀 Running the Application

### Option 1: Runnable Demo (Easiest)

For a quick demo, use the standalone runnable version:

```bash
# From the examples/rails directory
ruby traditional_app_runnable.rb

# Visit the endpoints:
# - http://localhost:3000/docs (Swagger UI)
# - http://localhost:3000/health (Health check)
# - http://localhost:3000/api/v1/users (Users API)
# - http://localhost:3000/api/v1/posts (Posts API)
```

This single file demonstrates the complete traditional Rails app structure.

### Option 2: Full Rails Application

To create a complete Rails application using this structure:

#### 1. Create New Rails App
```bash
rails new my_api_app --api
cd my_api_app
```

#### 2. Add RapiTapir to Gemfile
```ruby
gem 'rapitapir', '~> 1.0'
```

#### 3. Copy the Controller Structure
Copy the controllers from this example:
- `app/controllers/application_controller.rb`
- `app/controllers/api/v1/users_controller.rb`
- `app/controllers/api/v1/posts_controller.rb`

#### 4. Update Routes
Copy the routes configuration from `config/routes.rb`

#### 5. Run Standard Rails Commands
```bash
bundle install
rails db:create
rails db:migrate
rails server
```

## 📋 Available Endpoints

### System
- `GET /health` - Health check with database and service status

### Users API (`/api/v1/users`)
- `GET /api/v1/users` - List users (with search, pagination, sorting)
- `GET /api/v1/users/:id` - Get specific user
- `POST /api/v1/users` - Create new user
- `PUT /api/v1/users/:id` - Update user
- `DELETE /api/v1/users/:id` - Delete user
- `GET /api/v1/users/:id/posts` - Get user's posts

### Posts API (`/api/v1/posts`)
- `GET /api/v1/posts` - List posts (with filtering)
- `GET /api/v1/posts/:id` - Get specific post
- `POST /api/v1/posts` - Create new post (requires auth)
- `PUT /api/v1/posts/:id` - Update post (requires auth)
- `DELETE /api/v1/posts/:id` - Delete post (requires auth)
- `PATCH /api/v1/posts/:id/publish` - Toggle publish status (requires auth)

## 🔧 Key Implementation Details

### ApplicationController Pattern
```ruby
class ApplicationController < RapiTapir::Server::Rails::ControllerBase
  rapitapir do
    development_defaults! if Rails.env.development?
    
    # Global error responses
    error_out(json_body(error: T.string), 404)
    error_out(json_body(error: T.string, errors: T.array(T.string).optional), 422)
    
    # Health check endpoint
    GET('/health')
      .out(json_body(status: T.string, timestamp: T.string, ...))
  end
end
```

### Auto-Generated Routes
```ruby
# config/routes.rb
Rails.application.routes.draw do
  rapitapir_routes_for ApplicationController  # Generates /health
  
  namespace :api do
    namespace :v1 do
      rapitapir_routes_for 'Api::V1::UsersController'  # Auto-generates all user routes
      rapitapir_routes_for 'Api::V1::PostsController'  # Auto-generates all post routes
    end
  end
end
```

### Type-Safe Controllers
```ruby
class Api::V1::UsersController < ApplicationController
  rapitapir do
    GET('/api/v1/users')
      .in(query(:page, T.integer.default(1)))
      .in(query(:search, T.string.optional))
      .out(json_body(users: T.array(user_type), pagination: pagination_type))
  end
  
  def list_users
    # inputs[:page] and inputs[:search] are automatically validated
    users = User.where(conditions).page(inputs[:page])
    { users: users.map(&method(:serialize_user)) }
  end
end
```

## 🆚 Comparison with Standard Rails

### Before (Standard Rails)
```ruby
# Multiple controllers for health/docs
class HealthController < ApplicationController
  def check
    # Custom health check logic
  end
end

class DocumentationController < ApplicationController  
  def swagger_ui
    # Custom Swagger UI rendering
  end
end

# Manual route definitions
Rails.application.routes.draw do
  get '/health', to: 'health#check'
  get '/docs', to: 'documentation#swagger_ui'
  
  resources :users  # Generic CRUD, no type safety
end

# Manual parameter handling
class UsersController < ApplicationController
  def index
    page = params[:page]&.to_i || 1  # Manual validation
    users = User.page(page)
    render json: { users: users }    # No output type safety
  end
end
```

### After (RapiTapir)
```ruby
# Single ApplicationController with health endpoint
class ApplicationController < RapiTapir::Server::Rails::ControllerBase
  rapitapir do
    development_defaults!  # Auto docs
    GET('/health').out(json_body(...))  # Type-safe health endpoint
  end
end

# Auto-generated routes
Rails.application.routes.draw do
  rapitapir_routes_for ApplicationController  # Health + docs
  rapitapir_routes_for 'Api::V1::UsersController'  # All user routes
end

# Type-safe controllers
class Api::V1::UsersController < ApplicationController
  rapitapir do
    GET('/api/v1/users')
      .in(query(:page, T.integer.default(1)))  # Auto validation
      .out(json_body(users: T.array(user_type)))  # Type-safe output
  end
  
  def list_users
    users = User.page(inputs[:page])  # inputs guaranteed valid
    { users: users.map(&method(:serialize_user)) }  # Return data, not render
  end
end
```

## 🏗️ Benefits for Real Rails Apps

1. **Fewer Files**: No separate health/docs controllers
2. **Less Boilerplate**: Auto-generated routes and validation
3. **Type Safety**: Input/output validation with clear error messages
4. **Always Up-to-date Docs**: Documentation reflects actual code
5. **Rails Ecosystem**: Works with existing gems, middleware, and patterns
6. **Testing**: Standard Rails testing patterns work perfectly
7. **Performance**: No overhead, just cleaner organization

## 🧪 Testing Example

```ruby
# spec/controllers/api/v1/users_controller_spec.rb
RSpec.describe Api::V1::UsersController, type: :controller do
  describe 'GET #list_users' do
    it 'validates page parameter' do
      get :list_users, params: { page: "invalid" }
      expect(response).to have_http_status(:unprocessable_entity)
    end
    
    it 'returns paginated users' do
      create_list(:user, 15)
      get :list_users, params: { page: 2 }
      
      expect(response).to have_http_status(:ok)
      expect(json_response[:users]).to be_an(Array)
      expect(json_response[:pagination][:page]).to eq(2)
    end
  end
end
```

This example shows how RapiTapir makes Rails APIs cleaner, safer, and more maintainable while preserving all the Rails patterns you know and love! 🎉
