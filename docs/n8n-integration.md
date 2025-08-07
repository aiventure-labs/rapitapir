# RapiTapir + n8n Integration Guide

This guide shows how to integrate RapiTapir APIs with n8n workflow automation.

## Prerequisites

1. A RapiTapir API with endpoints marked for MCP export
2. n8n instance (local or cloud)
3. Generated OpenAPI specification

## Integration Methods

### Method 1: Using OpenAPI Import (Recommended)

1. **Generate OpenAPI spec:**
   ```bash
   rapitapir generate openapi --endpoints api.rb --output openapi.json
   ```

2. **Import in n8n:**
   - Open n8n workflow editor
   - Add "HTTP Request" node
   - In node settings, click "Import from URL" or "Import from File"
   - Select your `openapi.json` file
   - n8n will auto-generate the available endpoints

### Method 2: Manual HTTP Request Configuration

For each RapiTapir endpoint:

```javascript
// n8n HTTP Request Node Configuration
{
  "method": "GET",
  "url": "https://your-api.com/users/{{ $json.user_id }}",
  "headers": {
    "Content-Type": "application/json",
    "Authorization": "Bearer {{ $json.auth_token }}"
  },
  "body": {
    // Request body for POST/PUT endpoints
  }
}
```

### Method 3: Using MCP Context (Advanced)

Export MCP context for AI-powered workflow creation:

```bash
rapitapir export mcp --endpoints api.rb --output mcp-context.json
```

Use the MCP context to:
- Auto-generate n8n workflow templates
- Provide API documentation to AI assistants
- Create dynamic workflow suggestions

## Example Workflows

### User Management Workflow

```json
{
  "name": "User Management with RapiTapir",
  "nodes": [
    {
      "name": "Webhook Trigger",
      "type": "n8n-nodes-base.webhook",
      "parameters": {
        "path": "user-signup"
      }
    },
    {
      "name": "Create User",
      "type": "n8n-nodes-base.httpRequest",
      "parameters": {
        "method": "POST",
        "url": "https://your-api.com/users",
        "headers": {
          "Content-Type": "application/json"
        },
        "body": {
          "name": "={{ $json.name }}",
          "email": "={{ $json.email }}"
        }
      }
    },
    {
      "name": "Send Welcome Email",
      "type": "n8n-nodes-base.emailSend",
      "parameters": {
        "toEmail": "={{ $node['Create User'].json.email }}",
        "subject": "Welcome!",
        "text": "Welcome {{ $node['Create User'].json.name }}!"
      }
    }
  ],
  "connections": {
    "Webhook Trigger": {
      "main": [["Create User"]]
    },
    "Create User": {
      "main": [["Send Welcome Email"]]
    }
  }
}
```

### Data Sync Workflow

```json
{
  "name": "Daily User Sync",
  "nodes": [
    {
      "name": "Schedule Trigger",
      "type": "n8n-nodes-base.cron",
      "parameters": {
        "rule": {
          "interval": [{"field": "cronExpression", "value": "0 9 * * *"}]
        }
      }
    },
    {
      "name": "Get Users",
      "type": "n8n-nodes-base.httpRequest",
      "parameters": {
        "method": "GET",
        "url": "https://your-api.com/users?page=1&limit=100"
      }
    },
    {
      "name": "Process Each User",
      "type": "n8n-nodes-base.splitInBatches",
      "parameters": {
        "batchSize": 10
      }
    }
  ]
}
```

## Authentication Setup

### OAuth2 with RapiTapir

1. **Configure OAuth2 in n8n:**
   ```json
   {
     "authentication": "oAuth2Api",
     "oAuth2Api": {
       "authUrl": "https://your-auth-provider.com/oauth/authorize",
       "accessTokenUrl": "https://your-auth-provider.com/oauth/token",
       "clientId": "{{ $credentials.clientId }}",
       "clientSecret": "{{ $credentials.clientSecret }}",
       "scope": "read:users write:users"
     }
   }
   ```

### JWT Authentication

```json
{
  "authentication": "headerAuth",
  "headerAuth": {
    "name": "Authorization",
    "value": "Bearer {{ $credentials.jwt_token }}"
  }
}
```

## Best Practices

1. **Error Handling:**
   - Use n8n's "Error Trigger" node for failed API calls
   - Implement retry logic for transient failures

2. **Rate Limiting:**
   - Add "Wait" nodes between API calls
   - Use n8n's built-in rate limiting features

3. **Data Validation:**
   - Validate input data before sending to RapiTapir endpoints
   - Use n8n's "Set" node to transform data formats

4. **Monitoring:**
   - Enable n8n's execution logging
   - Set up alerts for failed workflows

## Troubleshooting

### Common Issues

1. **CORS Errors:**
   - Ensure RapiTapir API allows n8n's origin
   - Use server-side n8n instance for cross-origin requests

2. **Authentication Failures:**
   - Verify credentials are properly configured
   - Check token expiration and refresh logic

3. **Schema Mismatches:**
   - Keep OpenAPI spec updated with API changes
   - Validate request/response formats

## Resources

- [n8n HTTP Request Node Documentation](https://docs.n8n.io/nodes/n8n-nodes-base.httpRequest/)
- [n8n OAuth2 Authentication](https://docs.n8n.io/credentials/oauth2/)
- [RapiTapir OpenAPI Documentation](../openapi-documentation.md)
