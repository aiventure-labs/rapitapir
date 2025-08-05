# frozen_string_literal: true

# Example routes configuration for Hello World Rails API
# Place this in your config/routes.rb file

Rails.application.routes.draw do
  # Option 1: Auto-generate routes from RapiTapir endpoints (Recommended)
  rapitapir_routes_for HelloWorldController
  
  # This will automatically generate:
  # GET  /hello                  hello_world#hello  
  # GET  /greet/:language        hello_world#greet
  # POST /greetings              hello_world#greetings
  # GET  /health                 hello_world#health

  # Option 2: Manual routes (if you prefer explicit control)
  # get '/hello', to: 'hello_world#hello'
  # get '/greet/:language', to: 'hello_world#greet'
  # post '/greetings', to: 'hello_world#create'
  # get '/health', to: 'hello_world#health'
  
  # Welcome page (custom action not defined by RapiTapir)
  root 'hello_world#welcome'
  
  # Future: Auto-generated documentation endpoints
  # get '/docs', to: 'rapitapir_docs#index'
  # get '/openapi.json', to: 'rapitapir_docs#openapi'
end
