# OAuth2 Examples

This directory contains examples demonstrating OAuth2 integration with RapiTapir.

## Examples

### 1. Songs API with Auth0 (`songs_api_with_auth0.rb`)

A complete example using Auth0 for OAuth2 authentication. Demonstrates:

- Auth0-specific JWT validation with JWKS
- Scope-based authorization
- Protected endpoints with different permission levels
- Comprehensive error handling
- Rate limiting integration

**Features:**
- Public endpoints (health check, song list)
- Protected endpoints requiring authentication
- Admin endpoints requiring special scopes
- Token introspection and validation
- JWKS caching for performance

**Setup:**
```bash
# Set Auth0 environment variables
export AUTH0_DOMAIN="your-tenant.auth0.com"
export AUTH0_CLIENT_ID="your-client-id"
export AUTH0_CLIENT_SECRET="your-client-secret"
export AUTH0_AUDIENCE="your-api-identifier"

# Run the example
ruby songs_api_with_auth0.rb
```

### 2. Generic OAuth2 API (`generic_oauth2_api.rb`)

A simpler example using generic OAuth2 token introspection. Demonstrates:

- Token introspection with any OAuth2 provider
- Basic scope validation
- User information retrieval
- Authentication status checking

**Features:**
- Generic OAuth2 provider support
- Token introspection endpoint
- Basic scope-based authorization
- User context access

**Setup:**
```bash
# Set OAuth2 provider environment variables
export OAUTH2_INTROSPECTION_ENDPOINT="https://your-oauth-server/introspect"
export OAUTH2_CLIENT_ID="your-client-id"
export OAUTH2_CLIENT_SECRET="your-client-secret"

# Run the example
ruby generic_oauth2_api.rb
```

## Authentication Flow

### Auth0 Example
1. Client obtains JWT token from Auth0
2. Client includes token in `Authorization: Bearer <token>` header
3. RapiTapir validates JWT signature using JWKS
4. Endpoint handler receives authenticated user context

### Generic OAuth2 Example
1. Client obtains access token from OAuth2 provider
2. Client includes token in `Authorization: Bearer <token>` header
3. RapiTapir introspects token with OAuth2 provider
4. Endpoint handler receives authenticated user context

## Testing the APIs

### Using curl with Auth0

```bash
# Get a token (example with Auth0 Client Credentials flow)
TOKEN=$(curl -s -X POST "https://YOUR_DOMAIN.auth0.com/oauth/token" \
  -H "Content-Type: application/json" \
  -d '{
    "client_id": "YOUR_CLIENT_ID",
    "client_secret": "YOUR_CLIENT_SECRET", 
    "audience": "YOUR_API_IDENTIFIER",
    "grant_type": "client_credentials"
  }' | jq -r '.access_token')

# Test protected endpoint
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:4567/songs
```

### Using curl with Generic OAuth2

```bash
# Assuming you have an access token from your OAuth2 provider
TOKEN="your-access-token"

# Test protected endpoint
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:4567/tasks
```

## Available Endpoints

### Songs API (Auth0)
- `GET /` - Public welcome message
- `GET /health` - Health check with auth status
- `GET /songs` - List songs (requires authentication)
- `POST /songs` - Create song (requires `write:songs` scope)
- `PUT /songs/:id` - Update song (requires `write:songs` scope)
- `DELETE /songs/:id` - Delete song (requires `admin:songs` scope)
- `GET /admin/stats` - Admin statistics (requires `admin:songs` scope)

### Generic OAuth2 API
- `GET /tasks` - List tasks (public)
- `GET /health` - Health check with auth status
- `POST /tasks` - Create task (requires `write` scope)
- `PUT /tasks/:id` - Update task (requires `write` scope)
- `DELETE /tasks/:id` - Delete task (requires `admin` scope)
- `GET /me` - Get user information (requires authentication)

## Documentation

Both examples include automatic OpenAPI documentation:
- Auth0 Example: http://localhost:4567/docs
- Generic OAuth2 Example: http://localhost:4567/docs

## Error Handling

Both examples demonstrate comprehensive error handling:

- **401 Unauthorized**: Missing or invalid token
- **403 Forbidden**: Token valid but insufficient scopes
- **404 Not Found**: Resource not found
- **422 Unprocessable Entity**: Invalid request data

## Security Features

- **JWT Validation**: Signature verification and claims validation
- **Scope Authorization**: Granular permission control
- **Token Caching**: JWKS and token introspection caching
- **Rate Limiting**: Built-in rate limiting support
- **Secure Headers**: Automatic security headers
- **CORS Support**: Cross-origin resource sharing

## Production Considerations

1. **Environment Variables**: Never hardcode credentials
2. **HTTPS Only**: Always use HTTPS in production
3. **Token Expiration**: Handle token refresh properly
4. **Error Logging**: Log authentication failures securely
5. **Rate Limiting**: Implement appropriate rate limits
6. **Monitoring**: Monitor authentication metrics

## Integration Patterns

### Middleware Integration
```ruby
# Automatic authentication for all endpoints
rapitapir do
  default_auth oauth2_auth(scopes: ['read'])
end
```

### Conditional Authentication
```ruby
# Different auth requirements per endpoint
endpoint(
  GET('/public').build
) { "Public data" }

endpoint(
  GET('/private').with_oauth2_auth.build
) { "Private data" }
```

### Custom Scope Validation
```ruby
# Custom authorization logic
def admin_required!
  context = authorize_oauth2!(required_scopes: ['admin'])
  halt 403 unless context.metadata[:role] == 'admin'
end
```

## Troubleshooting

### Common Issues

1. **JWKS Fetch Errors**: Check Auth0 domain and network connectivity
2. **Token Validation Failures**: Verify audience and issuer claims
3. **Scope Mismatches**: Ensure client has required scopes
4. **Environment Variables**: Double-check all required variables are set

### Debug Mode

Set `RACK_ENV=development` to enable detailed error messages and logging.

### Testing Without OAuth2

Both examples include public endpoints that don't require authentication, useful for testing basic functionality.
