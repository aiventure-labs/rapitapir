# frozen_string_literal: true

# Example Rails routes configuration for RapiTapir controllers
# Place this in your config/routes.rb file

Rails.application.routes.draw do
  # Option 1: Auto-discover and register all RapiTapir controllers (Recommended)
  # This will automatically find any controller that inherits from ControllerBase
  # or includes the Rails::Controller module
  rapitapir_auto_routes

  # Option 2: Register specific controllers manually
  # rapitapir_routes_for EnhancedUsersController
  # rapitapir_routes_for BooksController
  # rapitapir_routes_for OrdersController

  # Option 3: Traditional Rails routes (still works if you prefer manual control)
  # resources :enhanced_users, only: [:index, :show, :create, :update, :destroy] do
  #   collection do
  #     get :active
  #     post :bulk
  #     get :search
  #   end
  # end

  # Example of mixed approach - some auto, some manual
  # rapitapir_routes_for EnhancedUsersController
  # 
  # resources :admin_users, controller: 'admin/users' do
  #   # Manual routes for admin section
  # end

  # The rapitapir_auto_routes method will generate routes like:
  # 
  # For EnhancedUsersController with api_resource '/users':
  # GET    /users           enhanced_users#index
  # GET    /users/:id       enhanced_users#show  
  # POST   /users           enhanced_users#create
  # PUT    /users/:id       enhanced_users#update
  # DELETE /users/:id       enhanced_users#destroy
  # GET    /users/active    enhanced_users#active
  # POST   /users/bulk      enhanced_users#bulk
  # GET    /users/search    enhanced_users#search
  
  # For documentation and OpenAPI endpoints (coming soon):
  # GET    /docs            rapitapir#docs
  # GET    /openapi.json    rapitapir#openapi
end
