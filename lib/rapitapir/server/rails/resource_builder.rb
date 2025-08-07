# frozen_string_literal: true

module RapiTapir
  module Server
    module Rails
      # Resource builder for creating RESTful API endpoints in Rails controllers
      # Provides the same functionality as Sinatra::ResourceBuilder but adapted for Rails
      class ResourceBuilder
        attr_reader :endpoints

        def initialize(controller_class, base_path, schema, **options)
          @controller_class = controller_class
          @base_path = base_path.chomp('/')
          @schema = schema
          @options = options
          @endpoints = []
        end

        # Enable standard CRUD operations
        # @param except [Array<Symbol>] Operations to exclude
        # @param only [Array<Symbol>] Only include these operations
        # @param block [Proc] Block defining the CRUD handlers
        def crud(except: [], only: nil, **handlers, &block)
          operations = only || %i[index show create update destroy]
          operations -= except if except.any?

          # If a block is given, evaluate it in the context of this ResourceBuilder
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
        # @param options [Hash] Endpoint options
        # @param handler [Proc] Request handler
        def index(**options, &handler)
          handler ||= proc { [] }

          endpoint_def = @controller_class.GET(@base_path)
                                          .summary(options[:summary] || "List all #{resource_name}")
                                          .description(options[:description] || "Retrieve a list of #{resource_name}")
                                          .then { |ep| add_pagination_params(ep) }
                                          .ok(RapiTapir::Types.array(@schema))
                                          .build

          @endpoints << [endpoint_def, handler]
        end

        # Get specific resource (GET /resources/:id)
        # @param options [Hash] Endpoint options
        # @param handler [Proc] Request handler
        def show(**options, &handler)
          handler ||= proc { {} }

          endpoint_def = @controller_class.GET("#{@base_path}/:id")
                                          .summary(options[:summary] || "Get #{resource_name}")
                                          .description(options[:description] || "Retrieve a specific #{resource_name} by ID")
                                          .path_param(:id, :integer, description: "#{resource_name.capitalize} ID")
                                          .ok(@schema)
                                          .not_found(error_schema, description: "#{resource_name.capitalize} not found")
                                          .build

          @endpoints << [endpoint_def, handler]
        end

        # Create new resource (POST /resources)
        # @param options [Hash] Endpoint options
        # @param handler [Proc] Request handler
        def create(**options, &handler)
          handler ||= proc { {} }

          endpoint_def = @controller_class.POST(@base_path)
                                          .summary(options[:summary] || "Create #{resource_name}")
                                          .description(options[:description] || "Create a new #{resource_name}")
                                          .json_body(@schema)
                                          .created(@schema)
                                          .bad_request(validation_error_schema, description: 'Validation error')
                                          .build

          @endpoints << [endpoint_def, handler]
        end

        # Update resource (PUT /resources/:id)
        # @param options [Hash] Endpoint options
        # @param handler [Proc] Request handler
        def update(**options, &handler)
          handler ||= proc { {} }

          endpoint_def = @controller_class.PUT("#{@base_path}/:id")
                                          .summary(options[:summary] || "Update #{resource_name}")
                                          .description(options[:description] || "Update an existing #{resource_name}")
                                          .path_param(:id, RapiTapir::Types.integer, description: "#{resource_name.capitalize} ID")
                                          .json_body(@schema)
                                          .ok(@schema)
                                          .not_found(error_schema, description: "#{resource_name.capitalize} not found")
                                          .bad_request(validation_error_schema, description: 'Validation error')
                                          .build

          @endpoints << [endpoint_def, handler]
        end

        # Delete resource (DELETE /resources/:id)
        # @param options [Hash] Endpoint options
        # @param handler [Proc] Request handler
        def destroy(**options, &handler)
          handler ||= proc { head :no_content }

          endpoint_def = @controller_class.DELETE("#{@base_path}/:id")
                                          .summary(options[:summary] || "Delete #{resource_name}")
                                          .description(options[:description] || "Delete a #{resource_name}")
                                          .path_param(:id, :integer, description: "#{resource_name.capitalize} ID")
                                          .no_content
                                          .not_found(error_schema, description: "#{resource_name.capitalize} not found")
                                          .build

          @endpoints << [endpoint_def, handler]
        end

        # Add custom endpoint to the resource
        # @param method [Symbol] HTTP method
        # @param path_suffix [String] Path suffix to append to base path
        # @param options [Hash] Endpoint options
        # @param handler [Proc] Request handler
        def custom(method, path_suffix, **options, &handler)
          full_path = path_suffix.start_with?('/') ? path_suffix : "#{@base_path}/#{path_suffix}"

          endpoint_def = @controller_class.public_send(method.to_s.upcase, full_path)
                                          .summary(options[:summary] || "Custom #{method.upcase} #{path_suffix}")
                                          .description(options[:description] || "Custom endpoint for #{resource_name}")

          # Apply any custom configuration
          endpoint_def = options[:configure].call(endpoint_def) if options[:configure]

          endpoint_def = endpoint_def.build

          @endpoints << [endpoint_def, handler]
        end

        private

        # Add pagination query parameters to an endpoint
        # @param endpoint [RapiTapir::DSL::FluentEndpointBuilder] The endpoint builder
        # @return [RapiTapir::DSL::FluentEndpointBuilder] The modified endpoint builder
        def add_pagination_params(endpoint)
          endpoint.query(:limit, RapiTapir::Types.optional(RapiTapir::Types.integer(minimum: 1, maximum: 100)),
                         description: 'Maximum number of results')
                  .query(:offset, RapiTapir::Types.optional(RapiTapir::Types.integer(minimum: 0)),
                         description: 'Number of results to skip')
        end

        # Get the singular resource name from the base path
        # @return [String] The singular resource name
        def resource_name
          @resource_name ||= @base_path.split('/').last.chomp('s')
        end

        # Standard error schema for 404 responses
        # @return [RapiTapir::Types::Hash] Error schema
        def error_schema
          RapiTapir::Types.hash({
                                  'error' => RapiTapir::Types.string
                                })
        end

        # Validation error schema for 400 responses
        # @return [RapiTapir::Types::Hash] Validation error schema
        def validation_error_schema
          RapiTapir::Types.hash({
                                  'error' => RapiTapir::Types.string,
                                  'details' => RapiTapir::Types.optional(RapiTapir::Types.array(RapiTapir::Types.string))
                                })
        end
      end
    end
  end
end
