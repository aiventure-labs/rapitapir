# frozen_string_literal: true

module RapiTapir
  module Server
    module Rails
      # Response handling methods for Rails controller integration
      module ResponseHandler
        private

        def render_rapitapir_response(result, endpoint)
          output = endpoint.outputs.find { |o| o.kind == :json } || endpoint.outputs.first
          status_code = determine_rails_status_code(endpoint)

          if output&.kind == :xml
            render xml: result, status: status_code
          else
            # Default to JSON for nil output, :json kind, or unknown kinds
            render json: result, status: status_code
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
