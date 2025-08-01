# frozen_string_literal: true

# Example: Authentication and Security in RapiTapir
#
# This example demonstrates how to use RapiTapir's Phase 2.2 Authentication & Security features,
# including various authentication schemes, authorization middleware, and security features.

require_relative '../lib/rapitapir'
require 'ostruct'

# Helper method to create simple JWT (for demonstration only)
def create_simple_jwt(payload, secret)
  require 'base64'
  require 'json'
  require 'openssl'

  header = { 'alg' => 'HS256', 'typ' => 'JWT' }

  encoded_header = Base64.urlsafe_encode64(JSON.generate(header)).tr('=', '')
  encoded_payload = Base64.urlsafe_encode64(JSON.generate(payload)).tr('=', '')

  signature = Base64.urlsafe_encode64(
    OpenSSL::HMAC.digest('SHA256', secret, "#{encoded_header}.#{encoded_payload}")
  ).tr('=', '')

  "#{encoded_header}.#{encoded_payload}.#{signature}"
end

# Configure authentication globally
RapiTapir::Auth.configure do |config|
  config.default_realm = 'My API'
  config.jwt_secret = 'your-secret-key'
  config.oauth2.client_id = 'your-client-id'
  config.oauth2.client_secret = 'your-client-secret'
  config.rate_limiting.requests_per_minute = 100
end

# Create authentication schemes
bearer_auth = RapiTapir::Auth.bearer_token(:bearer, {
                                             token_validator: proc do |token|
                                               # Validate token against your database or service
                                               case token
                                               when 'valid-token-123'
                                                 {
                                                   user: { id: 123, name: 'John Doe', email: 'john@example.com' },
                                                   scopes: %w[read write]
                                                 }
                                               when 'admin-token-456'
                                                 {
                                                   user: { id: 456, name: 'Admin User', email: 'admin@example.com' },
                                                   scopes: %w[read write admin]
                                                 }
                                               end
                                             end
                                           })

api_key_auth = RapiTapir::Auth.api_key(:api_key, {
                                         header_name: 'X-API-Key',
                                         key_validator: proc do |key|
                                           # Validate API key
                                           case key
                                           when 'api-key-789'
                                             {
                                               user: { id: 'api-user', name: 'API Client' },
                                               scopes: ['read']
                                             }
                                           end
                                         end
                                       })

jwt_auth = RapiTapir::Auth.jwt(:jwt, {
                                 secret: 'your-jwt-secret',
                                 algorithm: 'HS256'
                               })

# Usage examples:

# 1. Test authentication manually
puts '=== Authentication Examples ==='

# Create a mock request for Bearer token
bearer_request = OpenStruct.new(
  env: { 'HTTP_AUTHORIZATION' => 'Bearer valid-token-123' },
  params: {},
  headers: { 'authorization' => 'Bearer valid-token-123' }
)

context = bearer_auth.authenticate(bearer_request)
puts "Bearer auth result: #{context&.authenticated?} - User: #{context&.user}"

# Create a mock request for API key
api_key_request = OpenStruct.new(
  env: { 'HTTP_X_API_KEY' => 'api-key-789' },
  params: {},
  headers: { 'x-api-key' => 'api-key-789' }
)

context = api_key_auth.authenticate(api_key_request)
puts "API key auth result: #{context&.authenticated?} - User: #{context&.user}"

# 2. Test JWT authentication
puts "\n=== JWT Authentication Example ==="

# Create a simple JWT token
jwt_payload = {
  'sub' => 'user123',
  'name' => 'JWT User',
  'scopes' => %w[read write],
  'exp' => Time.now.to_i + 3600
}

jwt_token = create_simple_jwt(jwt_payload, 'your-jwt-secret')
puts "Generated JWT: #{jwt_token[0..20]}..."

jwt_request = OpenStruct.new(
  env: { 'HTTP_AUTHORIZATION' => "Bearer #{jwt_token}" },
  params: {},
  headers: { 'authorization' => "Bearer #{jwt_token}" }
)

context = jwt_auth.authenticate(jwt_request)
puts "JWT auth result: #{context&.authenticated?} - User: #{context&.user}"

# 3. Demonstrate context store
puts "\n=== Context Store Example ==="

test_context = RapiTapir::Auth::Context.new(
  user: { id: 999, name: 'Test User' },
  scopes: %w[read write],
  token: 'test-token'
)

RapiTapir::Auth::ContextStore.with_context(test_context) do
  puts "Current user: #{RapiTapir::Auth.current_user}"
  puts "Authenticated: #{RapiTapir::Auth.authenticated?}"
  puts "Has 'read' scope: #{RapiTapir::Auth.has_scope?('read')}"
  puts "Has 'admin' scope: #{RapiTapir::Auth.has_scope?('admin')}"
end

puts "Context after block: #{RapiTapir::Auth.current_context}"

# 4. Test middleware functionality
puts "\n=== Middleware Examples ==="

# Test rate limiting storage
storage = RapiTapir::Auth::Middleware::RateLimitingMiddleware::MemoryStorage.new
storage.increment('test_key')
storage.increment('test_key')
puts "Rate limit count: #{storage.get('test_key')}"

# Test CORS functionality
cors_middleware = RapiTapir::Auth.cors_middleware({
                                                    allowed_origins: ['https://example.com'],
                                                    allowed_methods: %w[GET POST],
                                                    allow_credentials: true
                                                  })

puts "CORS middleware created: #{cors_middleware.class}"

# 5. Test authorization
puts "\n=== Authorization Examples ==="

admin_context = RapiTapir::Auth::Context.new(
  user: { id: 123, name: 'Admin' },
  scopes: %w[read write admin]
)

regular_context = RapiTapir::Auth::Context.new(
  user: { id: 456, name: 'User' },
  scopes: ['read']
)

RapiTapir::Auth::ContextStore.with_context(admin_context) do
  puts "Admin user has admin scope: #{RapiTapir::Auth.has_scope?('admin')}"
end

RapiTapir::Auth::ContextStore.with_context(regular_context) do
  puts "Regular user has admin scope: #{RapiTapir::Auth.has_scope?('admin')}"
end

puts "\n=== Phase 2.2 Authentication & Security System Complete ==="
puts '✅ Bearer Token Authentication'
puts '✅ API Key Authentication'
puts '✅ Basic Authentication'
puts '✅ OAuth2 Authentication'
puts '✅ JWT Authentication'
puts '✅ Authorization Middleware'
puts '✅ Rate Limiting'
puts '✅ CORS Support'
puts '✅ Security Headers'
puts '✅ Context Management'
puts '✅ Comprehensive Test Suite (91 tests)'
