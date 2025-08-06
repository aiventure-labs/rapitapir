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
require_relative 'rapitapir/dsl/http_verbs'

# Observability components (Phase 2.1)
require_relative 'rapitapir/observability'

# Authentication & Security components (Phase 2.2)
require_relative 'rapitapir/auth'

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
  if defined?(Sinatra)
    require_relative 'rapitapir/server/sinatra_adapter'
    require_relative 'rapitapir/sinatra_rapitapir'
  end
rescue LoadError
  # Sinatra not available
end

# Rails integration (load unconditionally since Rails apps will define Rails)
begin
  require_relative 'rapitapir/server/rails_integration'
rescue LoadError => e
  # Rails integration files not available
  warn "Rails integration not available: #{e.message}" if $DEBUG
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

# RapiTapir - A Ruby library for defining HTTP APIs declaratively
#
# Inspired by Scala's Tapir, this library provides type-safe input/output definitions,
# automatic OpenAPI documentation generation, and seamless integration with multiple Ruby stacks.
#
# @example Basic usage
#   endpoint = RapiTapir.get('/users/{id}')
#     .path_param(:id, :integer)
#     .ok(:json, { id: :integer, name: :string })
#     .build
#
# @example Enhanced DSL usage
#   include RapiTapir::DSL::HTTPVerbs
#   endpoint = GET('/users/{id}')
#     .path_param(:id, :integer)
#     .ok(:json, { id: :integer, name: :string })
#     .build
#
# @see https://github.com/riccardomerolla/rapitapir
module RapiTapir
  # Will be extended with FluentDSL later
  @endpoints = []

  # Extend the module with HTTP verbs for global access
  extend DSL::HTTPVerbs

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

  # Observability configuration
  def self.configure
    yield(Observability.configuration) if block_given?

    # Initialize observability components after configuration
    configure_metrics
    configure_tracing
    configure_logging
    configure_health_check
  end

  private_class_method def self.configure_metrics
    return unless Observability.config.metrics.enabled

    Observability::Metrics.configure(
      provider: Observability.config.metrics.provider,
      namespace: Observability.config.metrics.namespace,
      custom_labels: Observability.config.metrics.custom_labels
    )
  end

  private_class_method def self.configure_tracing
    return unless Observability.config.tracing.enabled

    Observability::Tracing.configure(
      service_name: Observability.config.tracing.service_name,
      service_version: Observability.config.tracing.service_version,
      provider: Observability.config.tracing.provider
    )
  end

  private_class_method def self.configure_logging
    return unless Observability.config.logging.enabled

    Observability::Logging.configure(
      level: Observability.config.logging.level,
      format: Observability.config.logging.format,
      structured: Observability.config.logging.structured
    )
  end

  private_class_method def self.configure_health_check
    return unless Observability.config.health_check.enabled

    Observability::HealthCheck.configure(
      endpoint: Observability.config.health_check.endpoint
    )

    # Register custom health checks
    Observability.config.health_check.checks.each do |check|
      Observability::HealthCheck.register(check[:name], &check[:check])
    end
  end

  # Convenience methods for creating endpoints (will be replaced by FluentDSL)
  def self.endpoint
    Core::Endpoint.new
  end
end

# Convenience constant for cleaner type syntax
# Users can use T instead of RapiTapir::Types for shorter, more readable code
T = RapiTapir::Types
