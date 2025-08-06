# Rails 8 + RapiTapir Quick Start Guide

## 🚀 How to Fix the `uninitialized constant RapiTapir::Server::Rails::ControllerBase` Error

The error you're encountering is due to the **loading order**. RapiTapir's Rails integration requires Rails to be loaded first.

### ✅ **Solution: Correct Loading Order**

In your Rails application, ensure this loading order:

#### 1. In your `Gemfile`:
```ruby
source 'https://rubygems.org'
ruby '3.2.0'

gem 'rails', '~> 8.0.0'  # Rails 8
gem 'rapitapir', '~> 1.0'  # RapiTapir after Rails

# Other gems...
gem 'sqlite3'
gem 'puma'
```

#### 2. In your application (or initializer):
```ruby
# This is already handled by Rails bundler, but if you need manual loading:

# 1. Rails loads first (via bundle/require in application.rb)
require 'rails/all'

# 2. RapiTapir loads after Rails
require 'rapitapir'  # Usually handled by bundler

# 3. Now you can use RapiTapir classes
class ApplicationController < RapiTapir::Server::Rails::ControllerBase
  # This works!
end
```

### 🧪 **Test with Our Runnable Example**

The easiest way to verify everything works:

```bash
cd examples/rails
ruby traditional_app_runnable.rb
```

This should start successfully and show:
```
🚀 Starting Traditional Rails App with RapiTapir on http://localhost:3000
📚 API Documentation: http://localhost:3000/docs
📋 OpenAPI Spec: http://localhost:3000/openapi.json
🏥 Health Check: http://localhost:3000/health
```

### 🔧 **For New Rails 8 Applications**

#### 1. Create Rails App
```bash
rails new my_api --api
cd my_api
```

#### 2. Add RapiTapir to Gemfile
```ruby
# Gemfile
gem 'rapitapir', '~> 1.0'
```

#### 3. Install
```bash
bundle install
```

#### 4. Update ApplicationController
```ruby
# app/controllers/application_controller.rb
class ApplicationController < RapiTapir::Server::Rails::ControllerBase
  rapitapir do
    development_defaults! if Rails.env.development?
    
    # Global error responses
    error_out(json_body(error: T.string), 404)
    error_out(json_body(error: T.string, errors: T.array(T.string).optional), 422)
    
    # Health endpoint
    GET('/health')
      .out(json_body(status: T.string, timestamp: T.string))
      .summary("Health check")
  end
  
  def health_check
    { status: 'ok', timestamp: Time.current.iso8601 }
  end
end
```

#### 5. Create API Controllers
```ruby
# app/controllers/api/v1/users_controller.rb
class Api::V1::UsersController < ApplicationController
  rapitapir do
    user_type = T.hash(id: T.integer, name: T.string, email: T.string)
    
    GET('/api/v1/users')
      .out(json_body(users: T.array(user_type)))
      .summary("List users")
      .tag("Users")
  end
  
  def list_users
    { users: [{ id: 1, name: "Test User", email: "test@example.com" }] }
  end
end
```

#### 6. Update Routes
```ruby
# config/routes.rb
Rails.application.routes.draw do
  rapitapir_routes_for ApplicationController
  
  namespace :api do
    namespace :v1 do
      rapitapir_routes_for 'Api::V1::UsersController'
    end
  end
end
```

#### 7. Start Server
```bash
rails server
```

Visit:
- 🏥 Health: http://localhost:3000/health  
- 📚 Docs: http://localhost:3000/docs
- 👥 Users: http://localhost:3000/api/v1/users

### ⚠️ **Common Issues & Solutions**

#### Issue: `uninitialized constant RapiTapir::Server::Rails::ControllerBase`
**Solution**: Make sure Rails is loaded before RapiTapir. In most Rails apps, this happens automatically via bundler.

#### Issue: `NoMethodError: undefined method 'rapitapir_routes_for'`
**Solution**: Ensure RapiTapir's Rails integration is loaded. Add to `config/application.rb`:
```ruby
require 'rapitapir'
```

#### Issue: Documentation not showing up
**Solution**: Make sure you have `development_defaults!` in your rapitapir block.

### 🎉 **Benefits of Rails 8 + RapiTapir**

- ✅ **Modern Rails**: Latest Rails 8 features and performance
- ✅ **Type Safety**: Automatic input validation and output schemas  
- ✅ **Auto Documentation**: Swagger UI and OpenAPI 3.0 specs
- ✅ **Clean Syntax**: Sinatra-like DSL in Rails controllers
- ✅ **Zero Config**: Works out of the box with `development_defaults!`
- ✅ **Production Ready**: Error handling, health checks, monitoring

The combination of Rails 8 and RapiTapir gives you the best of both worlds: Rails' maturity and ecosystem with RapiTapir's elegant API design! 🚀
