# Security Review Patterns

## Input Validation

```python
# Bad
def search(query):
    return db.execute(f"SELECT * FROM users WHERE name = '{query}'")

# Good
def search(query):
    return db.execute("SELECT * FROM users WHERE name = ?", [query])
```

## Authentication Checks

```python
# Verify on every request
@require_auth
def get_user(user_id):
    # Also verify authorization
    if current_user.id != user_id and not current_user.is_admin:
        raise Forbidden()
    return User.get(user_id)
```

## Sensitive Data

- Never log passwords, tokens, or PII
- Mask sensitive data in error messages
- Use secure comparison for secrets
- Encrypt at rest and in transit

## Common Vulnerabilities

| Vulnerability | Check For |
|--------------|-----------|
| SQL Injection | String concatenation in queries |
| XSS | Unescaped user input in HTML |
| CSRF | Missing CSRF tokens |
| IDOR | Missing authorization checks |
| Path Traversal | User input in file paths |

## Secrets

```python
# Bad
API_KEY = "sk-1234567890"

# Good
API_KEY = os.environ.get("API_KEY")
```

## Dependencies

- Check for known vulnerabilities
- Keep dependencies updated
- Review new dependencies
