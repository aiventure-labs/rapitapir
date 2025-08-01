# frozen_string_literal: true

require_relative 'observability/configuration'
require_relative 'observability/metrics'
require_relative 'observability/tracing'
require_relative 'observability/logging'
require_relative 'observability/health_check'
require_relative 'observability/middleware'

module RapiTapir
  # Observability features for monitoring and debugging APIs
  # Provides metrics collection, logging, tracing, and health checking
  module Observability
    class << self
      attr_accessor :configuration

      def configure
        self.configuration ||= Configuration.new
        yield(configuration) if block_given?
        configuration
      end

      def config
        self.configuration ||= Configuration.new
      end
    end
  end
end
