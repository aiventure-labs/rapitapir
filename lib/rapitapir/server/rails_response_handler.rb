# frozen_string_literal: true

module RapiTapir
  module Server
    module Rails
      # Response handling methods for Rails controller integration
      module ResponseHandler
        private

        def render_rapitapir_response(result, endpoint)
          # Extract custom status code if provided
          status_code = 200
          response_data = result

          if result.is_a?(Hash) && result.key?(:_status)
            status_code = result[:_status]
            response_data = result.except(:_status)
          elsif result.is_a?(Hash) && result.key?('_status')
            status_code = result['_status']
            response_data = result.except('_status')
          else
            status_code = determine_rails_status_code(endpoint)
          end

          output = endpoint.outputs.find { |o| o.kind == :json } || endpoint.outputs.first

          if output&.kind == :xml
            render xml: response_data, status: status_code
          else
            # Default to JSON for nil output, :json kind, or unknown kinds
            render json: response_data, status: status_code
          end
        end

        def determine_rails_status_code(endpoint)
          status_output = endpoint.outputs.find { |o| o.kind == :status }
          status_output ? status_output.type : 200
        end
      end
    end
  end
end
