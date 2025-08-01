# frozen_string_literal: true

module RapiTapir
  module Core
    # HTTP request wrapper for RapiTapir endpoints
    # Provides a standardized interface for HTTP request data
    class Request
      attr_reader :method, :path, :headers, :params, :body

      def initialize(method:, path:, headers: {}, params: {}, body: nil)
        @method = method
        @path = path
        @headers = headers.freeze
        @params = params.freeze
        @body = body
      end
    end
  end
end
