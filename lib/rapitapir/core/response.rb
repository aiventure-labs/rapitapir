# frozen_string_literal: true

module RapiTapir
  module Core
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
