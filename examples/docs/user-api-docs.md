# User Management API

Complete API documentation for the User Management system

**Version:** 2.0.0  
**Base URL:** `https://api.example.com/v2`

---


## Table of Contents

- [GET /users](#get-users) - Get all users
- [GET /users/:id](#get-usersid) - Get user by ID
- [POST /users](#post-users) - Create new user
- [PUT /users/:id](#put-usersid) - Update user
- [DELETE /users/:id](#delete-usersid) - Delete user
- [GET /users/search](#get-userssearch) - Search users

---


## GET /users {#get-users}

**Get all users**

Retrieve a paginated list of all users in the system

### Response



**Content-Type:** `application/json`



**Schema:**

```json

[
  {
  "id": 123,
  "name": "example string",
  "email": "example string",
  "created_at": "2025-01-15T10:30:00Z"
}
]

```

### Example

**Request:**
```bash
curl -X GET \\n  -H 'Content-Type: application/json' \\n  -H 'Accept: application/json' \\n  'https://api.example.com/v2/users'
```

**Response:**
```json
[
  {
  "id": 123,
  "name": "example string",
  "email": "example string",
  "created_at": "2025-01-15T10:30:00Z"
}
]
```

---

## GET /users/:id {#get-usersid}

**Get user by ID**

Retrieve a specific user by their unique identifier

### Path Parameters



| Parameter | Type | Description |

|-----------|------|-------------|

| `id` | integer | No description |

### Response



**Content-Type:** `application/json`



**Schema:**

```json

{
  "id": 123,
  "name": "example string",
  "email": "example string",
  "created_at": "2025-01-15T10:30:00Z",
  "updated_at": "2025-01-15T10:30:00Z"
}

```

### Example

**Request:**
```bash
curl -X GET \\n  -H 'Content-Type: application/json' \\n  -H 'Accept: application/json' \\n  'https://api.example.com/v2/users/123'
```

**Response:**
```json
{
  "id": 123,
  "name": "example string",
  "email": "example string",
  "created_at": "2025-01-15T10:30:00Z",
  "updated_at": "2025-01-15T10:30:00Z"
}
```

---

## POST /users {#post-users}

**Create new user**

Create a new user account with the provided information

### Request Body



**Content-Type:** `application/json`



**Schema:**

```json

{
  "name": "example string",
  "email": "example string",
  "password": "example string"
}

```

### Response



**Content-Type:** `application/json`



**Schema:**

```json

{
  "id": 123,
  "name": "example string",
  "email": "example string",
  "created_at": "2025-01-15T10:30:00Z"
}

```

### Example

**Request:**
```bash
curl -X POST \\n  -H 'Content-Type: application/json' \\n  -H 'Accept: application/json' \\n  -d '{
  "name": "example string",
  "email": "example string",
  "password": "example string"
}' \\n  'https://api.example.com/v2/users'
```

**Response:**
```json
{
  "id": 123,
  "name": "example string",
  "email": "example string",
  "created_at": "2025-01-15T10:30:00Z"
}
```

---

## PUT /users/:id {#put-usersid}

**Update user**

Update an existing user's information

### Path Parameters



| Parameter | Type | Description |

|-----------|------|-------------|

| `id` | integer | No description |

### Request Body



**Content-Type:** `application/json`



**Schema:**

```json

{
  "name": "example string",
  "email": "example string"
}

```

### Response



**Content-Type:** `application/json`



**Schema:**

```json

{
  "id": 123,
  "name": "example string",
  "email": "example string",
  "updated_at": "2025-01-15T10:30:00Z"
}

```

### Example

**Request:**
```bash
curl -X PUT \\n  -H 'Content-Type: application/json' \\n  -H 'Accept: application/json' \\n  -d '{
  "name": "example string",
  "email": "example string"
}' \\n  'https://api.example.com/v2/users/123'
```

**Response:**
```json
{
  "id": 123,
  "name": "example string",
  "email": "example string",
  "updated_at": "2025-01-15T10:30:00Z"
}
```

---

## DELETE /users/:id {#delete-usersid}

**Delete user**

Delete a user account permanently

### Path Parameters



| Parameter | Type | Description |

|-----------|------|-------------|

| `id` | integer | No description |

### Response



**Content-Type:** `application/json`



**Schema:**

```json

{
  "success": true,
  "message": "example string"
}

```

### Example

**Request:**
```bash
curl -X DELETE \\n  -H 'Content-Type: application/json' \\n  -H 'Accept: application/json' \\n  'https://api.example.com/v2/users/123'
```

**Response:**
```json
{
  "success": true,
  "message": "example string"
}
```

---

## GET /users/search {#get-userssearch}

**Search users**

Search for users by name or email with pagination support

### Query Parameters



| Parameter | Type | Required | Description |

|-----------|------|----------|-------------|

| `q` | string | Yes | No description |

| `limit` | integer | No | No description |

| `offset` | integer | No | No description |

### Response



**Content-Type:** `application/json`



**Schema:**

```json

{
  "users": [
    {
    "id": 123,
    "name": "example string",
    "email": "example string"
  }
  ],
  "total": 123,
  "limit": 123,
  "offset": 123
}

```

### Example

**Request:**
```bash
curl -X GET \\n  -H 'Content-Type: application/json' \\n  -H 'Accept: application/json' \\n  'https://api.example.com/v2/users/search?q=example&limit=10&offset=10'
```

**Response:**
```json
{
  "users": [
    {
    "id": 123,
    "name": "example string",
    "email": "example string"
  }
  ],
  "total": 123,
  "limit": 123,
  "offset": 123
}
```

---

*Generated by RapiTapir Documentation Generator*
