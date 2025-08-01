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
      def crud(except: [], only: nil, **handlers)
        operations = only || [:index, :show, :create, :update, :destroy]
        operations = operations - except if except.any?

        operations.each do |operation|
          send(operation, &handlers[operation]) if respond_to?(operation, true)
        end
      end

      # List all resources (GET /resources)
      def index(scopes: ['read'], **options, &handler)
        handler ||= default_index_handler
        
        endpoint = RapiTapir.get(@base_path)
          .summary(options[:summary] || "List all #{resource_name.pluralize}")
          .description(options[:description] || "Retrieve a list of #{resource_name.pluralize}")
          .query(:limit, RapiTapir::Types.optional(RapiTapir::Types.integer), description: 'Maximum number of results')
          .query(:offset, RapiTapir::Types.optional(RapiTapir::Types.integer), description: 'Number of results to skip')
          .ok(RapiTapir::Types.array(@schema))
          
        add_auth_requirements(endpoint, scopes)
        add_common_errors(endpoint)
        
        @app.endpoint(endpoint.build, &wrap_handler(handler, scopes))
      end

      # Get specific resource (GET /resources/:id)
      def show(scopes: ['read'], **options, &handler)
        handler ||= default_show_handler
        
        endpoint = RapiTapir.get("#{@base_path}/:id")
          .summary(options[:summary] || "Get #{resource_name}")
          .description(options[:description] || "Retrieve a specific #{resource_name} by ID")
          .path_param(:id, RapiTapir::Types.integer, description: "#{resource_name.capitalize} ID")
          .ok(@schema)
          
        add_auth_requirements(endpoint, scopes)
        add_common_errors(endpoint)
        endpoint.error_response(404, error_schema, description: "#{resource_name.capitalize} not found")
        
        @app.endpoint(endpoint.build, &wrap_handler(handler, scopes))
      end

      # Create new resource (POST /resources)
      def create(scopes: ['write'], **options, &handler)
        handler ||= default_create_handler
        create_schema = options[:schema] || @schema
        
        endpoint = RapiTapir.post(@base_path)
          .summary(options[:summary] || "Create #{resource_name}")
          .description(options[:description] || "Create a new #{resource_name}")
          .json_body(create_schema)
          .created(@schema)
          
        add_auth_requirements(endpoint, scopes)
        add_common_errors(endpoint)
        endpoint.error_response(400, error_schema, description: 'Validation error')
        
        @app.endpoint(endpoint.build, &wrap_handler(handler, scopes))
      end

      # Update resource (PUT /resources/:id)
      def update(scopes: ['write'], **options, &handler)
        handler ||= default_update_handler
        update_schema = options[:schema] || make_optional_schema(@schema)
        
        endpoint = RapiTapir.put("#{@base_path}/:id")
          .summary(options[:summary] || "Update #{resource_name}")
          .description(options[:description] || "Update an existing #{resource_name}")
          .path_param(:id, RapiTapir::Types.integer, description: "#{resource_name.capitalize} ID")
          .json_body(update_schema)
          .ok(@schema)
          
        add_auth_requirements(endpoint, scopes)
        add_common_errors(endpoint)
        endpoint.error_response(404, error_schema, description: "#{resource_name.capitalize} not found")
        endpoint.error_response(400, error_schema, description: 'Validation error')
        
        @app.endpoint(endpoint.build, &wrap_handler(handler, scopes))
      end

      # Delete resource (DELETE /resources/:id)
      def destroy(scopes: ['delete'], **options, &handler)
        handler ||= default_destroy_handler
        
        endpoint = RapiTapir.delete("#{@base_path}/:id")
          .summary(options[:summary] || "Delete #{resource_name}")
          .description(options[:description] || "Delete a #{resource_name}")
          .path_param(:id, RapiTapir::Types.integer, description: "#{resource_name.capitalize} ID")
          .no_content(description: "#{resource_name.capitalize} deleted successfully")
          
        add_auth_requirements(endpoint, scopes)
        add_common_errors(endpoint)
        endpoint.error_response(404, error_schema, description: "#{resource_name.capitalize} not found")
        
        @app.endpoint(endpoint.build, &wrap_handler(handler, scopes))
      end

      # Custom endpoint within the resource
      def custom(method, path = '', **options, &handler)
        full_path = path.empty? ? @base_path : "#{@base_path}/#{path.sub(/^\//, '')}"
        
        endpoint = RapiTapir.send(method.downcase, full_path)
        
        if options[:summary]
          endpoint = endpoint.summary(options[:summary])
        end
        
        if options[:description]
          endpoint = endpoint.description(options[:description])
        end
        
        # Allow custom configuration
        endpoint = options[:configure].call(endpoint) if options[:configure]
        
        scopes = options[:scopes] || ['read']
        add_auth_requirements(endpoint, scopes)
        add_common_errors(endpoint)
        
        @app.endpoint(endpoint.build, &wrap_handler(handler, scopes))
      end

      private

      def resource_name
        @resource_name ||= @base_path.split('/').last.singularize
      end

      def error_schema
        @error_schema ||= RapiTapir::Types.hash({
          "error" => RapiTapir::Types.string,
          "message" => RapiTapir::Types.optional(RapiTapir::Types.string)
        })
      end

      def add_auth_requirements(endpoint, scopes)
        return endpoint unless scopes.any?
        
        scopes.each do |scope|
          endpoint.error_response(401, error_schema, description: 'Authentication required')
          endpoint.error_response(403, error_schema, description: 'Insufficient permissions')
        end
        
        endpoint
      end

      def add_common_errors(endpoint)
        endpoint.error_response(500, error_schema, description: 'Internal server error')
      end

      def wrap_handler(handler, scopes)
        proc do |inputs|
          # Check authentication and scopes
          @app.require_authentication! if scopes.any?
          scopes.each { |scope| @app.require_scope!(scope) }
          
          # Call the actual handler
          instance_exec(inputs, &handler)
        end
      end

      def make_optional_schema(schema)
        # Convert a schema to have all optional fields for updates
        # This is a simplified version - in production, you'd want more sophisticated logic
        if schema.respond_to?(:properties)
          optional_props = {}
          schema.properties.each do |key, type|
            optional_props[key] = RapiTapir::Types.optional(type)
          end
          RapiTapir::Types.hash(optional_props)
        else
          schema
        end
      end

      # Default handlers - can be overridden
      def default_index_handler
        proc do |inputs|
          halt 501, { error: 'Index handler not implemented' }.to_json
        end
      end

      def default_show_handler
        proc do |inputs|
          halt 501, { error: 'Show handler not implemented' }.to_json
        end
      end

      def default_create_handler
        proc do |inputs|
          halt 501, { error: 'Create handler not implemented' }.to_json
        end
      end

      def default_update_handler
        proc do |inputs|
          halt 501, { error: 'Update handler not implemented' }.to_json
        end
      end

      def default_destroy_handler
        proc do |inputs|
          halt 501, { error: 'Destroy handler not implemented' }.to_json
        end
      end
    end
  end
end

# String extensions for resource naming
class String
  def pluralize
    case self
    when /y$/
      sub(/y$/, 'ies')
    when /s$/, /sh$/, /ch$/, /x$/, /z$/
      self + 'es'
    else
      self + 's'
    end
  end

  def singularize
    case self
    when /ies$/
      sub(/ies$/, 'y')
    when /ses$/, /shes$/, /ches$/, /xes$/, /zes$/
      sub(/es$/, '')
    when /s$/
      sub(/s$/, '')
    else
      self
    end
  end
end
