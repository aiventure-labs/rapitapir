# frozen_string_literal: true

module RapiTapir
  module Core
    # HTTP response wrapper for RapiTapir endpoints
    # Provides a standardized interface for HTTP response data
    class Response
      attr_reader :status, :headers, :body

      def initialize(status:, headers: {}, body: nil)
        @status = status
        @headers = headers.freeze
        @body = body
      end
    end
  end
end
