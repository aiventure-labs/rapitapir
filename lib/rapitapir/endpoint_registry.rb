# frozen_string_literal: true

module RapiTapir
  # Global endpoint registry for collecting and managing endpoints
  # Provides a central place to register and discover endpoints for CLI operations
  class EndpointRegistry
    @endpoints = []
    @mutex = Mutex.new

    class << self
      # Register an endpoint in the global registry
      def register(endpoint)
        @mutex.synchronize do
          @endpoints << endpoint unless @endpoints.include?(endpoint)
        end
      end

      # Get all registered endpoints
      def all
        @mutex.synchronize { @endpoints.dup }
      end

      # Get only endpoints marked for MCP export
      def mcp_endpoints
        @mutex.synchronize { @endpoints.select(&:mcp_export?) }
      end

      # Clear all registered endpoints (useful for testing)
      def clear!
        @mutex.synchronize { @endpoints.clear }
      end

      # Register multiple endpoints at once
      def register_all(endpoints)
        endpoints.each { |endpoint| register(endpoint) }
      end

      # Find endpoints by method and path pattern
      def find_by(method: nil, path: nil)
        results = all
        results = results.select { |ep| ep.method == method } if method
        results = results.select { |ep| ep.path&.include?(path) } if path
        results
      end
    end
  end
end
