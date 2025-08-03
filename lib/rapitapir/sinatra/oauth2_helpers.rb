# frozen_string_literal: true

require_relative '../auth/oauth2'

module RapiTapir
  module Sinatra
    # OAuth2 integration helpers for Sinatra applications
    # Provides convenient methods to secure endpoints with OAuth2/Auth0
    module OAuth2Helpers
      # Configure Auth0 OAuth2 authentication
      def auth0_oauth2(scheme_name = :oauth2_auth0, domain:, audience:, **options)
        auth_scheme = RapiTapir::Auth::OAuth2::Auth0Scheme.new(scheme_name, {
          domain: domain,
          audience: audience,
          **options
        })
        
        # Store the auth scheme for use in endpoint protection
        settings.rapitapir_config.add_auth_scheme(scheme_name, auth_scheme)
        
        # Add authentication helper methods
        helpers do
          include OAuth2HelperMethods
        end
        
        auth_scheme
      end

      # Configure generic OAuth2 authentication with token introspection
      def oauth2_introspection(scheme_name = :oauth2, introspection_endpoint:, client_id:, client_secret:, **options)
        auth_scheme = RapiTapir::Auth::OAuth2::GenericScheme.new(scheme_name, {
          introspection_endpoint: introspection_endpoint,
          client_id: client_id,
          client_secret: client_secret,
          **options
        })
        
        settings.rapitapir_config.add_auth_scheme(scheme_name, auth_scheme)
        
        helpers do
          include OAuth2HelperMethods
        end
        
        auth_scheme
      end

      # Protect specific routes with OAuth2 authentication
      def protect_with_oauth2(*paths, scopes: [], scheme: :oauth2_auth0)
        paths.each do |path|
          before path do
            authorize_oauth2!(required_scopes: scopes, scheme: scheme)
          end
        end
      end

      # Protect all routes with OAuth2 authentication
      def protect_all_routes_with_oauth2(scopes: [], scheme: :oauth2_auth0, except: [])
        before do
          # Skip protection for excluded paths
          next if except.any? { |pattern| request.path_info.match?(pattern) }
          
          authorize_oauth2!(required_scopes: scopes, scheme: scheme)
        end
      end
    end

    # Helper methods available in route handlers
    module OAuth2HelperMethods
      # Authenticate and authorize with OAuth2
      def authorize_oauth2!(required_scopes: [], scheme: :oauth2_auth0)
        auth_scheme = settings.rapitapir_config.auth_schemes[scheme]
        
        unless auth_scheme
          halt 500, { error: 'OAuth2 authentication not configured' }.to_json
        end

        begin
          context = auth_scheme.authenticate(request)
          
          unless context
            challenge = auth_scheme.challenge
            headers 'WWW-Authenticate' => challenge
            halt 401, { 
              error: 'unauthorized',
              error_description: 'Access token required' 
            }.to_json
          end

          # Store context for use in route handlers
          request.env['rapitapir.auth.context'] = context

          # Check required scopes if specified
          if required_scopes.any?
            missing_scopes = required_scopes - context.scopes
            
            if missing_scopes.any?
              halt 403, {
                error: 'insufficient_scope',
                error_description: "Missing required scopes: #{missing_scopes.join(', ')}"
              }.to_json
            end
          end

          context
        rescue RapiTapir::Auth::InvalidTokenError => e
          challenge = auth_scheme.challenge
          headers 'WWW-Authenticate' => challenge
          halt 401, {
            error: 'invalid_token',
            error_description: e.message
          }.to_json
        rescue RapiTapir::Auth::AuthenticationError => e
          halt 500, {
            error: 'authentication_failed',
            error_description: e.message
          }.to_json
        end
      end

      # Get current authentication context
      def current_auth_context
        request.env['rapitapir.auth.context']
      end

      # Get current authenticated user
      def current_user
        current_auth_context&.user
      end

      # Check if user is authenticated
      def authenticated?
        !current_auth_context.nil?
      end

      # Check if user has specific scope
      def has_scope?(scope)
        return false unless current_auth_context
        
        current_auth_context.scopes.include?(scope.to_s)
      end

      # Check if user has all required scopes
      def has_scopes?(*scopes)
        return false unless current_auth_context
        
        scopes.all? { |scope| has_scope?(scope) }
      end

      # Check if user has any of the specified scopes
      def has_any_scope?(*scopes)
        return false unless current_auth_context
        
        scopes.any? { |scope| has_scope?(scope) }
      end

      # Require specific scopes for the current request
      def require_scopes!(*scopes)
        missing_scopes = scopes.reject { |scope| has_scope?(scope) }
        
        if missing_scopes.any?
          halt 403, {
            error: 'insufficient_scope',
            error_description: "Missing required scopes: #{missing_scopes.join(', ')}"
          }.to_json
        end
      end

      # Extract token from Authorization header
      def extract_bearer_token
        auth_header = request.env['HTTP_AUTHORIZATION']
        return nil unless auth_header

        match = auth_header.match(/\ABearer\s+(.+)\z/i)
        match ? match[1] : nil
      end

      # Validate token directly (useful for custom logic)
      def validate_oauth2_token(token, scheme: :oauth2_auth0)
        auth_scheme = settings.rapitapir_config.auth_schemes[scheme]
        return nil unless auth_scheme

        begin
          auth_scheme.authenticate(
            OpenStruct.new(env: { 'HTTP_AUTHORIZATION' => "Bearer #{token}" })
          )
        rescue StandardError
          nil
        end
      end
    end

    # DSL extensions for endpoint definitions with OAuth2
    module OAuth2EndpointExtensions
      # Add OAuth2 authentication to an endpoint
      def with_oauth2_auth(scopes: [], scheme: :oauth2_auth0, description: nil)
        auth_scheme_obj = case scheme
                          when Symbol
                            # Will be resolved at runtime
                            OpenStruct.new(name: scheme, scopes: scopes)
                          else
                            scheme
                          end

        security_in(auth_scheme_obj).tap do |endpoint|
          # Add to endpoint metadata for OpenAPI generation
          endpoint.metadata[:security] ||= []
          endpoint.metadata[:security] << {
            scheme: scheme,
            scopes: scopes,
            description: description || "OAuth2 authentication with scopes: #{scopes.join(', ')}"
          }
        end
      end

      # Add Auth0 OAuth2 authentication to an endpoint
      def with_auth0(scopes: [], description: nil)
        with_oauth2_auth(scopes: scopes, scheme: :oauth2_auth0, description: description)
      end

      # Add scope requirement to an endpoint
      def require_scopes(*scopes)
        with_oauth2_auth(scopes: scopes.flatten)
      end
    end
  end
end

# Extend the Sinatra extension with OAuth2 helpers if it exists
if defined?(RapiTapir::Sinatra::Extension)
  RapiTapir::Sinatra::Extension::ClassMethods.include(RapiTapir::Sinatra::OAuth2Helpers)
end

# Extend endpoint building with OAuth2 methods
if defined?(RapiTapir::DSL::FluentEndpointBuilder)
  RapiTapir::DSL::FluentEndpointBuilder.include(RapiTapir::Sinatra::OAuth2EndpointExtensions)
end
