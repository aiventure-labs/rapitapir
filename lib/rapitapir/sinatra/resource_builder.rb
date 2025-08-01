# frozen_string_literal: true

module RapiTapir
  module Sinatra
    # Resource builder for creating RESTful API endpoints
    # Follows Open/Closed Principle - extensible for new resource types
    class ResourceBuilder
      def initialize(app, base_path, schema, **options)
        @app = app
        @base_path = base_path.chomp('/')
        @schema = schema
        @options = options
        @endpoints = []
      end

      # Enable standard CRUD operations
      def crud(except: [], only: nil, **handlers, &block)
        operations = only || [:index, :show, :create, :update, :destroy]
        operations = operations - except if except.any?

        # If a block is given, evaluate it in the context of this ResourceBuilder
        # This allows method calls like: index { BookStore.all }
        if block_given?
          instance_eval(&block)
        else
          # Legacy style with handlers hash
          operations.each do |operation|
            send(operation, &handlers[operation]) if respond_to?(operation, true)
          end
        end
      end

      # List all resources (GET /resources)
      def index(**options, &handler)
        handler ||= proc { [] }
        
        endpoint = RapiTapir.get(@base_path)
          .summary(options[:summary] || "List all #{resource_name}")
          .description(options[:description] || "Retrieve a list of #{resource_name}")
          .query(:limit, RapiTapir::Types.optional(RapiTapir::Types.integer), description: 'Maximum number of results')
          .query(:offset, RapiTapir::Types.optional(RapiTapir::Types.integer), description: 'Number of results to skip')
          .ok(RapiTapir::Types.array(@schema))
          .build
        
        @app.endpoint(endpoint, &handler)
      end

      # Get specific resource (GET /resources/:id)
      def show(**options, &handler)
        handler ||= proc { {} }
        
        endpoint = RapiTapir.get("#{@base_path}/:id")
          .summary(options[:summary] || "Get #{resource_name}")
          .description(options[:description] || "Retrieve a specific #{resource_name} by ID")
          .path_param(:id, RapiTapir::Types.integer, description: "#{resource_name.capitalize} ID")
          .ok(@schema)
          .build
        
        @app.endpoint(endpoint, &handler)
      end

      # Create new resource (POST /resources)
      def create(**options, &handler)
        handler ||= proc { {} }
        
        endpoint = RapiTapir.post(@base_path)
          .summary(options[:summary] || "Create #{resource_name}")
          .description(options[:description] || "Create a new #{resource_name}")
          .json_body(@schema)
          .created(@schema)
          .build
        
        @app.endpoint(endpoint, &handler)
      end

      # Update resource (PUT /resources/:id)
      def update(**options, &handler)
        handler ||= proc { {} }
        
        endpoint = RapiTapir.put("#{@base_path}/:id")
          .summary(options[:summary] || "Update #{resource_name}")
          .description(options[:description] || "Update an existing #{resource_name}")
          .path_param(:id, RapiTapir::Types.integer, description: "#{resource_name.capitalize} ID")
          .json_body(@schema)
          .ok(@schema)
          .build
        
        @app.endpoint(endpoint, &handler)
      end

      # Delete resource (DELETE /resources/:id)
      def destroy(**options, &handler)
        handler ||= proc { status 204 }
        
        endpoint = RapiTapir.delete("#{@base_path}/:id")
          .summary(options[:summary] || "Delete #{resource_name}")
          .description(options[:description] || "Delete a #{resource_name}")
          .path_param(:id, RapiTapir::Types.integer, description: "#{resource_name.capitalize} ID")
          .no_content
          .build
        
        @app.endpoint(endpoint, &handler)
      end

      # Custom endpoint within the resource
      def custom(method, path, summary: nil, configure: nil, **options, &handler)
        full_path = path.start_with?('/') ? path : "#{@base_path}/#{path}"
        
        endpoint = RapiTapir.send(method, full_path)
        endpoint = endpoint.summary(summary) if summary
        endpoint = configure.call(endpoint) if configure
        
        @app.endpoint(endpoint.build, &handler)
      end

      private

      def resource_name
        @resource_name ||= @base_path.split('/').last.singularize
      end
    end
  end
end

# String extensions for pluralization/singularization
class String
  def pluralize
    case self
    when /s$/ then self
    when /y$/ then sub(/y$/, 'ies')
    when /(ch|sh|x|z)$/ then self + 'es'
    else self + 's'
    end
  end

  def singularize
    case self
    when /ies$/ then sub(/ies$/, 'y')
    when /s$/ then chomp('s')
    else self
    end
  end
end
