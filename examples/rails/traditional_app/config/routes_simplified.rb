# frozen_string_literal: true

Rails.application.routes.draw do
  # Use RapiTapir's built-in route generation for all controllers
  rapitapir_routes_for ApplicationController  # This includes /health
  
  # API v1 routes
  namespace :api do
    namespace :v1 do
      rapitapir_routes_for 'Api::V1::UsersController'
      rapitapir_routes_for 'Api::V1::PostsController'
    end
  end
  
  # Documentation routes using RapiTapir's built-in helpers
  if Rails.env.development?
    # These use the DocumentationHelpers module that's already included
    get '/docs', to: proc { |env|
      request = ActionDispatch::Request.new(env)
      html = ApplicationController.new.send(:generate_swagger_ui_html)
      [200, { 'Content-Type' => 'text/html' }, [html]]
    }
    
    get '/openapi.json', to: proc { |env|
      request = ActionDispatch::Request.new(env)
      controllers = [ApplicationController, Api::V1::UsersController, Api::V1::PostsController]
      spec = ApplicationController.new.send(:generate_openapi_spec_for_controllers, controllers)
      [200, { 'Content-Type' => 'application/json' }, [JSON.pretty_generate(spec)]]
    }
  end
  
  # Catch-all for unmatched routes
  match '*path', to: proc { |env|
    [404, { 'Content-Type' => 'application/json' }, [{ error: 'Route not found' }.to_json]]
  }, via: :all
end
