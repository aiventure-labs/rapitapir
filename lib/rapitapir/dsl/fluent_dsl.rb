# frozen_string_literal: true

require_relative '../core/endpoint'
require_relative 'fluent_endpoint_builder'

# RapiTapir Ruby library for building type-safe HTTP APIs
# Provides a declarative way to define REST APIs with automatic validation
module RapiTapir
  # Fluent DSL for defining HTTP endpoints
  # Provides chainable methods for declarative API definition
  #
  # @example Basic usage
  #   RapiTapir.get('/users')
  #     .ok(RapiTapir::Types.array(RapiTapir::Types.hash({"id" => RapiTapir::Types.integer})))
  #     .summary('Get all users')
  #     .build
  #
  # @example With parameters
  #   RapiTapir.get('/users/{id}')
  #     .path_param(:id, RapiTapir::Types.integer)
  #     .ok(RapiTapir::Types.hash({"id" => RapiTapir::Types.integer, "name" => RapiTapir::Types.string}))
  #     .build

  # HTTP GET endpoint
  # @param path [String] The endpoint path
  # @return [DSL::FluentEndpointBuilder] Builder for method chaining
  def self.get(path)
    DSL::FluentEndpointBuilder.new(:get, path)
  end

  # HTTP POST endpoint
  # @param path [String] The endpoint path
  # @return [DSL::FluentEndpointBuilder] Builder for method chaining
  def self.post(path)
    DSL::FluentEndpointBuilder.new(:post, path)
  end

  # HTTP PUT endpoint
  # @param path [String] The endpoint path
  # @return [DSL::FluentEndpointBuilder] Builder for method chaining
  def self.put(path)
    DSL::FluentEndpointBuilder.new(:put, path)
  end

  # HTTP PATCH endpoint
  # @param path [String] The endpoint path
  # @return [DSL::FluentEndpointBuilder] Builder for method chaining
  def self.patch(path)
    DSL::FluentEndpointBuilder.new(:patch, path)
  end

  # HTTP DELETE endpoint
  # @param path [String] The endpoint path
  # @return [DSL::FluentEndpointBuilder] Builder for method chaining
  def self.delete(path)
    DSL::FluentEndpointBuilder.new(:delete, path)
  end

  # HTTP HEAD endpoint
  # @param path [String] The endpoint path
  # @return [DSL::FluentEndpointBuilder] Builder for method chaining
  def self.head(path)
    DSL::FluentEndpointBuilder.new(:head, path)
  end

  # HTTP OPTIONS endpoint
  # @param path [String] The endpoint path
  # @return [DSL::FluentEndpointBuilder] Builder for method chaining
  def self.options(path)
    DSL::FluentEndpointBuilder.new(:options, path)
  end
end
