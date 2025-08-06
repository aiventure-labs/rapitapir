# frozen_string_literal: true

module RapiTapir
  module Server
    module Rails
      # Rails routes integration module
      # Provides helpers for automatically generating routes from RapiTapir endpoint definitions
      module Routes
        # Generate routes for a RapiTapir Rails controller
        # @param controller_class [Class] The controller class with RapiTapir endpoints
        # @example
        #   Rails.application.routes.draw do
        #     rapitapir_routes_for UsersController
        #   end
        def rapitapir_routes_for(controller_class)
          unless controller_class.respond_to?(:rapitapir_endpoints)
            raise ArgumentError, "#{controller_class} must include RapiTapir::Server::Rails::Controller"
          end

          controller_name = controller_class.controller_name

          controller_class.rapitapir_endpoints.each do |action, endpoint_config|
            endpoint_def = endpoint_config[:endpoint]
            method = endpoint_def.method.downcase
            path = convert_rapitapir_path_to_rails(endpoint_def.path)
            
            # Generate the Rails route
            public_send(method, path, to: "#{controller_name}##{action}", as: route_name(controller_name, action, method))
          end
        end

        # Generate all routes for multiple controllers
        # @param controllers [Array<Class>] Array of controller classes
        # @example
        #   Rails.application.routes.draw do
        #     rapitapir_routes_for_all [UsersController, BooksController, OrdersController]
        #   end
        def rapitapir_routes_for_all(controllers)
          controllers.each do |controller_class|
            rapitapir_routes_for(controller_class)
          end
        end

        # Auto-discover and register all RapiTapir controllers in the application
        # @example
        #   Rails.application.routes.draw do
        #     rapitapir_auto_routes
        #   end
        def rapitapir_auto_routes
          # Find all controllers that include RapiTapir
          controllers = ApplicationController.descendants.select do |klass|
            klass.included_modules.include?(RapiTapir::Server::Rails::Controller) ||
              klass < RapiTapir::Server::Rails::ControllerBase
          end

          rapitapir_routes_for_all(controllers)
        end

        private

        # Convert RapiTapir path format to Rails route format
        # @param rapitapir_path [String] Path with RapiTapir parameter syntax
        # @return [String] Path with Rails parameter syntax
        # @example
        #   convert_rapitapir_path_to_rails('/users/:id')     # => '/users/:id'
        #   convert_rapitapir_path_to_rails('/users/{id}')    # => '/users/:id'
        def convert_rapitapir_path_to_rails(rapitapir_path)
          # Convert {id} format to :id format for Rails
          rapitapir_path.gsub(/\{(\w+)\}/, ':\1')
        end

        # Generate a route name for the endpoint
        # @param controller_name [String] The controller name
        # @param action [Symbol] The action name
        # @param method [String] The HTTP method
        # @return [Symbol] The route name
        def route_name(controller_name, action, method)
          base_name = controller_name.chomp('_controller')
          
          case action
          when :index
            base_name.to_sym
          when :show
            singularize_name(base_name).to_sym
          when :create
            base_name.to_sym
          when :update
            singularize_name(base_name).to_sym
          when :destroy
            singularize_name(base_name).to_sym
          else
            "#{method}_#{base_name}_#{action}".to_sym
          end
        end

        # Simple singularization for route names
        # @param name [String] The plural name
        # @return [String] The singular name
        def singularize_name(name)
          # Simple singularization logic
          if name.end_with?('ies')
            name.chomp('ies') + 'y'
          elsif name.end_with?('s')
            name.chomp('s')
          else
            name
          end
        end
      end
    end
  end
end

# Note: Rails routes extension is handled in the rails_integration.rb file
# to ensure proper timing with Rails application initialization
