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
  extend DSL

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

  # Convenience methods for creating endpoints
  def self.endpoint
    Core::Endpoint.new
  end

  def self.get(path = nil)
    register_endpoint(Core::Endpoint.get(path))
  end

  def self.post(path = nil)
    register_endpoint(Core::Endpoint.post(path))
  end

  def self.put(path = nil)
    register_endpoint(Core::Endpoint.put(path))
  end

  def self.patch(path = nil)
    register_endpoint(Core::Endpoint.patch(path))
  end

  def self.delete(path = nil)
    register_endpoint(Core::Endpoint.delete(path))
  end

  def self.options(path = nil)
    register_endpoint(Core::Endpoint.options(path))
  end

  def self.head(path = nil)
    register_endpoint(Core::Endpoint.head(path))
  end
end
