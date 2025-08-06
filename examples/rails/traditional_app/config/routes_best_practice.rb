# frozen_string_literal: true

# Simplified Rails application using RapiTapir best practices
# No separate health or documentation controllers needed!

Rails.application.routes.draw do
  # Health check and docs are handled by RapiTapir automatically
  rapitapir_routes_for ApplicationController
  
  # API endpoints
  namespace :api do
    namespace :v1 do
      rapitapir_routes_for 'Api::V1::UsersController'
      rapitapir_routes_for 'Api::V1::PostsController'
    end
  end
  
  # RapiTapir provides documentation routes automatically in development
  if Rails.env.development?
    # These are automatically added by development_defaults!
    # /docs -> Swagger UI
    # /openapi.json -> OpenAPI spec
    # /redoc -> ReDoc alternative UI
  end
end
