# Enterprise Sinatra API with RapiTapir

This is a production-ready enterprise-grade Sinatra application demonstrating RapiTapir's Phase 2.2 Authentication & Security features with OpenAPI 3.0 documentation.

## 🚀 Features

- **Bearer Token Authentication** with role-based access control
- **OpenAPI 3.0 Documentation** with Swagger UI
- **Rate Limiting** (100 requests/minute, 2000/hour)
- **CORS Support** for cross-origin requests
- **Security Headers** (XSS, CSRF protection, etc.)
- **Request/Response Validation**
- **Structured Error Handling**
- **Health Check Endpoint**
- **Admin-only Endpoints**
- **User Profile Management**

## 📋 API Endpoints

### System
- `GET /health` - Health check (public)
- `GET /docs` - Swagger UI documentation
- `GET /openapi.json` - OpenAPI specification

### Tasks
- `GET /api/v1/tasks` - List all tasks (requires `read` scope)
- `GET /api/v1/tasks/{id}` - Get specific task (requires `read` scope)
- `POST /api/v1/tasks` - Create new task (requires `write` scope)
- `PUT /api/v1/tasks/{id}` - Update task (requires `write` scope)
- `DELETE /api/v1/tasks/{id}` - Delete task (requires `admin` scope)

### Users
- `GET /api/v1/profile` - Get current user profile (authenticated)
- `GET /api/v1/admin/users` - List all users (requires `admin` scope)

## 🔑 Authentication

The API uses Bearer Token authentication. Include your token in the Authorization header:

```bash
Authorization: Bearer your-token-here
```

### Available Test Tokens

| Token | User | Role | Scopes |
|-------|------|------|--------|
| `user-token-123` | John Doe | user | read, write |
| `admin-token-456` | Jane Admin | admin | read, write, admin, delete |
| `readonly-token-789` | Bob Reader | readonly | read |

## 🏃‍♂️ Running the Application

### Prerequisites

```bash
# Install dependencies
bundle install
```

### Start the Server

```bash
# From the examples directory
ruby enterprise_sinatra_api.rb
```

The server will start on `http://localhost:4567`

### Available URLs

- **API Documentation**: http://localhost:4567/docs
- **OpenAPI Spec**: http://localhost:4567/openapi.json
- **Health Check**: http://localhost:4567/health

## 📖 Example API Calls

### Health Check (Public)
```bash
curl http://localhost:4567/health
```

### List Tasks (Authenticated)
```bash
curl -H "Authorization: Bearer user-token-123" \
     http://localhost:4567/api/v1/tasks
```

### Create Task
```bash
curl -X POST \
  -H "Authorization: Bearer user-token-123" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "New Task",
    "description": "Task description",
    "status": "pending",
    "assignee_id": 1
  }' \
  http://localhost:4567/api/v1/tasks
```

### Get User Profile
```bash
curl -H "Authorization: Bearer user-token-123" \
     http://localhost:4567/api/v1/profile
```

### Admin: List All Users
```bash
curl -H "Authorization: Bearer admin-token-456" \
     http://localhost:4567/api/v1/admin/users
```

### Filter Tasks by Status
```bash
curl -H "Authorization: Bearer user-token-123" \
     "http://localhost:4567/api/v1/tasks?status=in_progress&limit=10"
```

## 🔒 Security Features

### Authentication & Authorization
- Bearer token validation
- Scope-based access control
- Role-based permissions
- Thread-safe context management

### Security Middleware
- **Rate Limiting**: Prevents API abuse
- **CORS**: Configurable cross-origin support
- **Security Headers**: XSS, CSRF, and other protections
- **Request Validation**: Input sanitization and validation

### Security Headers Applied
- `X-Content-Type-Options: nosniff`
- `X-Frame-Options: DENY`
- `X-XSS-Protection: 1; mode=block`
- `Strict-Transport-Security: max-age=31536000; includeSubDomains`
- `Referrer-Policy: strict-origin-when-cross-origin`

## 📊 Response Formats

### Success Response
```json
{
  "id": 1,
  "title": "Setup CI/CD Pipeline",
  "description": "Configure automated testing and deployment",
  "status": "in_progress",
  "assignee_id": 1,
  "created_at": "2025-07-29T10:30:00Z"
}
```

### Error Response
```json
{
  "error": "Authentication required"
}
```

### Validation Error
```json
{
  "error": "Title is required"
}
```

## 🏗️ Architecture

The application demonstrates enterprise-grade patterns:

1. **Separation of Concerns**: Database, authentication, and API logic are separated
2. **Middleware Stack**: Security, authentication, and rate limiting middleware
3. **Error Handling**: Structured error responses with appropriate HTTP status codes
4. **Documentation**: Self-documenting API with OpenAPI 3.0
5. **Validation**: Input validation and sanitization
6. **Monitoring**: Health check and structured logging

## 🧪 Testing the API

### Using curl
```bash
# Test authentication
curl -v -H "Authorization: Bearer invalid-token" \
     http://localhost:4567/api/v1/tasks

# Test rate limiting (run multiple times quickly)
for i in {1..150}; do
  curl -H "Authorization: Bearer user-token-123" \
       http://localhost:4567/api/v1/tasks
done

# Test CORS preflight
curl -X OPTIONS \
  -H "Origin: http://localhost:3000" \
  -H "Access-Control-Request-Method: POST" \
  -H "Access-Control-Request-Headers: Authorization, Content-Type" \
  http://localhost:4567/api/v1/tasks
```

### Using the Swagger UI
1. Open http://localhost:4567/docs
2. Click "Authorize" and enter a bearer token
3. Try out the API endpoints interactively

## 🚀 Production Deployment

For production deployment, consider:

1. **Database**: Replace in-memory databases with PostgreSQL, MySQL, etc.
2. **Authentication**: Integrate with OAuth2, JWT, or your auth provider
3. **Caching**: Add Redis for rate limiting and session storage
4. **Monitoring**: Add structured logging and metrics
5. **Configuration**: Use environment variables for secrets
6. **SSL/TLS**: Enable HTTPS with proper certificates
7. **Load Balancing**: Use nginx or similar for production traffic

## 📈 Performance

The application includes several performance optimizations:

- **Rate Limiting**: Prevents API abuse and ensures fair usage
- **Pagination**: Built-in pagination for large datasets
- **Efficient Authentication**: Fast token validation
- **Minimal Dependencies**: Lightweight Sinatra framework
- **Thread Safety**: Context management is thread-safe

This enterprise example showcases how RapiTapir can be used to build production-ready APIs with comprehensive security, documentation, and monitoring capabilities.
