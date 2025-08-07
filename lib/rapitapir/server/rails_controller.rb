# frozen_string_literal: true

require_relative 'rails_input_processor'
require_relative 'rails_response_handler'

module RapiTapir
  module Server
    module Rails
      # Rails controller concern for RapiTapir integration
      module Controller
        extend ActiveSupport::Concern
        include InputProcessor
        include ResponseHandler

        included do
          class_attribute :rapitapir_endpoints, default: {}
        end

        class_methods do
          # Register an endpoint for this controller
          def rapitapir_endpoint(action_name, endpoint, &handler)
            raise ArgumentError, 'Endpoint must be a RapiTapir::Core::Endpoint' unless endpoint.is_a?(RapiTapir::Core::Endpoint)

            endpoint.validate!

            self.rapitapir_endpoints = rapitapir_endpoints.merge(
              action_name.to_sym => {
                endpoint: endpoint,
                handler: handler
              }
            )
          end
        end

        private

        # Process a RapiTapir endpoint within a Rails action
        def process_rapitapir_endpoint(action_name = nil)
          action_name ||= params[:action]&.to_sym || :index
          endpoint_config = find_endpoint_config(action_name)

          return render_endpoint_not_configured_error unless endpoint_config

          process_configured_endpoint(endpoint_config)
        end

        def find_endpoint_config(action_name)
          self.class.rapitapir_endpoints[action_name.to_sym]
        end

        def render_endpoint_not_configured_error
          render json: { error: 'Endpoint not configured' }, status: 500
        end

        def process_configured_endpoint(endpoint_config)
          endpoint = endpoint_config[:endpoint]
          handler = endpoint_config[:handler]

          processed_inputs = extract_rails_inputs(endpoint, request)
          result = instance_exec(processed_inputs, &handler)
          render_rapitapir_response(result, endpoint)
        rescue ArgumentError => e
          render json: { error: e.message }, status: 400
        rescue StandardError => e
          render json: { error: 'Internal Server Error', message: e.message }, status: 500
        end
      end
    end
  end
end
