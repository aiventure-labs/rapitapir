# frozen_string_literal: true

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

module RapiTapir
  extend DSL

  # Convenience methods for creating endpoints
  def self.endpoint
    Core::Endpoint.new
  end

  def self.get(path = nil)
    Core::Endpoint.get(path)
  end

  def self.post(path = nil)
    Core::Endpoint.post(path)
  end

  def self.put(path = nil)
    Core::Endpoint.put(path)
  end

  def self.patch(path = nil)
    Core::Endpoint.patch(path)
  end

  def self.delete(path = nil)
    Core::Endpoint.delete(path)
  end

  def self.options(path = nil)
    Core::Endpoint.options(path)
  end

  def self.head(path = nil)
    Core::Endpoint.head(path)
  end
end
