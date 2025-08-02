# frozen_string_literal: true

module RapiTapir
  module Server
    module Rails
      # Input processing methods for Rails controller integration
      module InputProcessor
        private

        def extract_rails_inputs(endpoint, request)
          inputs = {}

          endpoint.inputs.each do |input|
            value = extract_input_value(input, request)
            validate_required_input(input, value)
            add_input_to_collection(inputs, input, value)
          end

          inputs
        end

        def extract_input_value(input, request)
          case input.kind
          when :query
            extract_query_value(request, input)
          when :header
            extract_header_value(request, input)
          when :path
            params[input.name.to_s]
          when :body
            parse_rails_body(request, input)
          end
        end

        def extract_query_value(request, input)
          request.query_parameters[input.name.to_s] || params[input.name.to_s]
        end

        def extract_header_value(request, input)
          request.headers[input.name.to_s] || request.headers["HTTP_#{input.name.to_s.upcase}"]
        end

        def validate_required_input(input, value)
          return unless value.nil? && input.required?

          raise ArgumentError, "Required input '#{input.name}' is missing"
        end

        def add_input_to_collection(inputs, input, value)
          return unless value || !input.required?

          inputs[input.name] = input.coerce(value)
        end

        def parse_rails_body(request, input)
          # Rails typically parses JSON automatically into params
          if input.type == Hash || input.type.is_a?(Hash)
            # Try to get from parsed params first
            request.request_parameters.presence ||
              # Fall back to parsing raw body
              begin
                JSON.parse(request.raw_post)
              rescue JSON::ParserError
                raise ArgumentError, 'Invalid JSON in request body'
              end
          else
            request.raw_post
          end
        end
      end
    end
  end
end
