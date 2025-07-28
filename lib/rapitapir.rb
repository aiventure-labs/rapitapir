# frozen_string_literal: true

require_relative 'rapitapir/version'
require_relative 'rapitapir/types'
require_relative 'rapitapir/schema'
require_relative 'rapitapir/core/endpoint'
require_relative 'rapitapir/core/input'
require_relative 'rapitapir/core/output'
require_relative 'rapitapir/core/request'
require_relative 'rapitapir/core/response'
require_relative 'rapitapir/dsl/endpoint_dsl'

# Enhanced components for Phase 1
require_relative 'rapitapir/core/enhanced_endpoint'
require_relative 'rapitapir/dsl/enhanced_endpoint_dsl'
require_relative 'rapitapir/server/enhanced_rack_adapter'
require_relative 'rapitapir/server/sinatra_integration'
require_relative 'rapitapir/dsl/fluent_dsl'

# Server components (optional, only load if needed)
begin
  require_relative 'rapitapir/server/rack_adapter'
  require_relative 'rapitapir/server/path_matcher'
  require_relative 'rapitapir/server/middleware'
rescue LoadError
  # Server dependencies not available
end

# Framework adapters (optional, only load if framework is available)
begin
  require_relative 'rapitapir/server/sinatra_adapter' if defined?(Sinatra)
rescue LoadError
  # Sinatra not available
end

begin
  require_relative 'rapitapir/server/rails_adapter' if defined?(Rails)
rescue LoadError
  # Rails not available
end

# OpenAPI and client generation (optional)
begin
  require_relative 'rapitapir/openapi/schema_generator'
  require_relative 'rapitapir/client/generator_base'
  require_relative 'rapitapir/client/typescript_generator'
rescue LoadError
  # OpenAPI or client generation dependencies not available
end

# Documentation and CLI tools (optional)
begin
  require_relative 'rapitapir/docs/markdown_generator'
  require_relative 'rapitapir/docs/html_generator'
  require_relative 'rapitapir/cli/command'
  require_relative 'rapitapir/cli/server'
  require_relative 'rapitapir/cli/validator'
rescue LoadError
  # Documentation or CLI dependencies not available
end

module RapiTapir
  # Will be extended with FluentDSL later
  @endpoints = []

  def self.endpoints
    @endpoints
  end

  def self.register_endpoint(endpoint)
    @endpoints << endpoint
    endpoint
  end

  def self.clear_endpoints
    @endpoints.clear
  end

  # Convenience methods for creating endpoints (will be replaced by FluentDSL)
  def self.endpoint
    Core::Endpoint.new
  end
end
