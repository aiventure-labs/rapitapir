# frozen_string_literal: true

# RapiTapir Enhanced DSL Module
# Provides concise HTTP verb methods for more readable endpoint definitions
#
# @example Usage
#   include RapiTapir::DSL::HTTPVerbs
#
#   endpoint = GET('/users')
#     .ok(RapiTapir::Types.array(UserSchema))
#     .summary('Get all users')
#     .build
#
#   endpoint = POST('/users')
#     .body(UserSchema)
#     .created(UserSchema)
#     .summary('Create a user')
#     .build

module RapiTapir
  module DSL
    # HTTP Verbs mixin module
    # Provides concise HTTP verb methods that can be included in any class
    module HTTPVerbs
      # HTTP GET endpoint
      # @param path [String] The endpoint path
      # @return [DSL::FluentEndpointBuilder] Builder for method chaining
      # rubocop:disable Naming/MethodName
      def GET(path)
        RapiTapir.get(path)
      end

      # HTTP POST endpoint
      # @param path [String] The endpoint path
      # @return [DSL::FluentEndpointBuilder] Builder for method chaining
      def POST(path)
        RapiTapir.post(path)
      end

      # HTTP PUT endpoint
      # @param path [String] The endpoint path
      # @return [DSL::FluentEndpointBuilder] Builder for method chaining
      def PUT(path)
        RapiTapir.put(path)
      end

      # HTTP PATCH endpoint
      # @param path [String] The endpoint path
      # @return [DSL::FluentEndpointBuilder] Builder for method chaining
      def PATCH(path)
        RapiTapir.patch(path)
      end

      # HTTP DELETE endpoint
      # @param path [String] The endpoint path
      # @return [DSL::FluentEndpointBuilder] Builder for method chaining
      def DELETE(path)
        RapiTapir.delete(path)
      end

      # HTTP HEAD endpoint
      # @param path [String] The endpoint path
      # @return [DSL::FluentEndpointBuilder] Builder for method chaining
      def HEAD(path)
        RapiTapir.head(path)
      end

      # HTTP OPTIONS endpoint
      # @param path [String] The endpoint path
      # @return [DSL::FluentEndpointBuilder] Builder for method chaining
      def OPTIONS(path)
        RapiTapir.options(path)
      end
      # rubocop:enable Naming/MethodName
    end
  end
end
