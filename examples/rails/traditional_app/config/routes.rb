# frozen_string_literal: true

Rails.application.routes.draw do
  # Health check (from ApplicationController)
  rapitapir_routes_for ApplicationController
  
  # API v1 routes - RapiTapir auto-generates routes from endpoint definitions
  namespace :api do
    namespace :v1 do
      rapitapir_routes_for 'Api::V1::UsersController'
      rapitapir_routes_for 'Api::V1::PostsController'
    end
  end
  
  # Documentation routes (automatically added by development_defaults! in development)
  # Available at:
  # - GET /docs          -> Swagger UI
  # - GET /openapi.json  -> OpenAPI 3.0 specification
  # - GET /redoc         -> ReDoc alternative UI (if enabled)
  
  # Catch-all for unmatched routes
  match '*path', to: proc { |env|
    [404, { 'Content-Type' => 'application/json' }, [{ error: 'Route not found' }.to_json]]
  }, via: :all
end
