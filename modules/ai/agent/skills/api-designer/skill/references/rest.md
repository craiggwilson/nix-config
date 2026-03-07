# REST API Design

## Resource Naming

```
# Good - nouns, plural
GET /users
GET /users/123
GET /users/123/orders

# Bad - verbs
GET /getUsers
POST /createUser
```

## HTTP Methods

| Method | Purpose | Idempotent |
|--------|---------|------------|
| GET | Read resource | Yes |
| POST | Create resource | No |
| PUT | Replace resource | Yes |
| PATCH | Partial update | No |
| DELETE | Remove resource | Yes |

## Status Codes

### Success
- `200 OK` - Successful GET, PUT, PATCH
- `201 Created` - Successful POST
- `204 No Content` - Successful DELETE

### Client Errors
- `400 Bad Request` - Invalid input
- `401 Unauthorized` - Authentication required
- `403 Forbidden` - Insufficient permissions
- `404 Not Found` - Resource doesn't exist
- `409 Conflict` - Resource conflict
- `422 Unprocessable Entity` - Validation error

### Server Errors
- `500 Internal Server Error` - Unexpected error
- `503 Service Unavailable` - Temporary unavailability

## Pagination

```json
GET /users?page=2&per_page=20

{
  "data": [...],
  "pagination": {
    "page": 2,
    "per_page": 20,
    "total": 100,
    "total_pages": 5
  }
}
```

## Filtering and Sorting

```
GET /users?status=active&role=admin
GET /users?sort=created_at&order=desc
GET /users?fields=id,name,email
```

## Error Response Format

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid input",
    "details": [
      {
        "field": "email",
        "message": "Invalid email format"
      }
    ]
  }
}
```
