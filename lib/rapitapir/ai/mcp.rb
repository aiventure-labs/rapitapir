# frozen_string_literal: true

# RapiTapir::AI::MCP
#
# Provides Model Context Protocol (MCP) export capabilities for RapiTapir endpoints.
#
# Usage:
#   - Use `.mcp_export` in endpoint DSL to mark endpoints for MCP context export.
#   - Use MCPExporter to generate MCP-compatible JSON for all marked endpoints.

module RapiTapir
  module AI
    module MCP
      # Collects and serializes endpoint context for LLM/agent consumption
      class Exporter
        def initialize(endpoints)
          @endpoints = endpoints
        end

        # Returns a hash representing the MCP context for all marked endpoints
        def as_mcp_context
          mcp_endpoints = @endpoints.select(&:mcp_export?)

          context = {
            service: {
              name: 'RapiTapir API',
              version: '1.0.0',
              description: 'RapiTapir API with exported endpoints for MCP context'
            },
            endpoints: [],
            schemas: extract_all_schemas(mcp_endpoints),
            metadata: {
              generated_at: Time.now.iso8601,
              generator: 'RapiTapir MCP Exporter',
              mcp_version: '1.0'
            }
          }

          context[:endpoints] = mcp_endpoints.map do |ep|
            {
              name: endpoint_name(ep),
              method: ep.method&.to_s&.upcase,
              path: ep.path,
              summary: ep.metadata[:summary],
              description: ep.metadata[:description],
              input_schema: extract_input_schema(ep),
              output_schema: extract_output_schema(ep),
              examples: ep.metadata[:examples] || []
            }
          end

          context
        end

        # Test-compatible methods (aliases and wrappers)
        def export_context
          as_mcp_context
        end

        def export_json(pretty: true)
          context = as_mcp_context
          if pretty
            JSON.pretty_generate(context)
          else
            JSON.generate(context)
          end
        end

        def mcp_endpoints
          @endpoints.select(&:mcp_export?)
        end

        private

        def endpoint_name(endpoint)
          # Generate a readable name from method and path
          method = endpoint.method&.to_s || 'unknown'
          path = endpoint.path&.gsub(%r{[{}/]}, '_')&.gsub(/_+/, '_')&.strip || 'unknown'
          "#{method}_#{path}".downcase
        end

        def extract_input_schema(endpoint)
          return {} unless endpoint.inputs

          schema = {}
          endpoint.inputs.each do |input|
            next unless input.respond_to?(:name)

            # Handle both old and new input structures
            required = if input.respond_to?(:required?)
                         input.required?
                       elsif input.respond_to?(:options) && input.options
                         input.options[:required] != false
                       else
                         true # default to required
                       end

            schema[input.name] = {
              type: input.type,
              kind: input.kind,
              required: required
            }
          end
          schema
        end

        def extract_output_schema(endpoint)
          return {} unless endpoint.outputs

          schema = {}
          endpoint.outputs.each do |output|
            schema[output.kind] = {
              type: output.type
            }
          end
          schema
        end

        def extract_all_schemas(endpoints)
          schemas = {}
          endpoints.each do |endpoint|
            input_schema = extract_input_schema(endpoint)
            output_schema = extract_output_schema(endpoint)

            schemas["#{endpoint_name(endpoint)}_input"] = input_schema unless input_schema.empty?

            schemas["#{endpoint_name(endpoint)}_output"] = output_schema unless output_schema.empty?
          end
          schemas
        end
      end
    end
  end
end
