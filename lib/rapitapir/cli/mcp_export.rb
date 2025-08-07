# frozen_string_literal: true

require_relative '../core/endpoint'
require_relative '../ai/mcp'
require 'json'

module RapiTapir
  module CLI
    class MCPExport
      # Exports all endpoints marked for MCP as a JSON file
      def self.run(endpoints, output_path = 'mcp-context.json')
        exporter = RapiTapir::AI::MCP::Exporter.new(endpoints)
        File.write(output_path, JSON.pretty_generate(exporter.as_mcp_context))
        puts "MCP context exported to #{output_path}"
      end
    end
  end
end
