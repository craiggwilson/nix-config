# OWASP Top 10

## A01: Broken Access Control

```python
# Bad - no authorization check
@app.get("/users/{user_id}")
def get_user(user_id: int):
    return db.get_user(user_id)

# Good - verify authorization
@app.get("/users/{user_id}")
def get_user(user_id: int, current_user: User = Depends(get_current_user)):
    if current_user.id != user_id and not current_user.is_admin:
        raise HTTPException(status_code=403)
    return db.get_user(user_id)
```

## A02: Cryptographic Failures

```python
# Bad - weak hashing
password_hash = hashlib.md5(password.encode()).hexdigest()

# Good - proper password hashing
from passlib.hash import argon2
password_hash = argon2.hash(password)
```

## A03: Injection

```python
# Bad - SQL injection
query = f"SELECT * FROM users WHERE name = '{name}'"

# Good - parameterized query
query = "SELECT * FROM users WHERE name = ?"
cursor.execute(query, (name,))
```

## A04: Insecure Design

- Threat model during design
- Use secure design patterns
- Implement defense in depth
- Fail securely

## A05: Security Misconfiguration

```yaml
# Bad - debug mode in production
DEBUG: true
SECRET_KEY: "changeme"

# Good - secure configuration
DEBUG: false
SECRET_KEY: ${SECRET_KEY}  # From environment
```

## A06: Vulnerable Components

```bash
# Check for vulnerabilities
npm audit
pip-audit
cargo audit
```

## A07: Authentication Failures

- Use MFA
- Implement account lockout
- Use secure session management
- Hash passwords properly

## A08: Software and Data Integrity

- Verify signatures
- Use integrity checks
- Secure CI/CD pipeline

## A09: Logging and Monitoring

```python
# Log security events
logger.warning(
    "Failed login attempt",
    extra={"user": username, "ip": request.client.host}
)
```

## A10: Server-Side Request Forgery (SSRF)

```python
# Bad - user-controlled URL
response = requests.get(user_provided_url)

# Good - validate URL
if not is_allowed_url(user_provided_url):
    raise ValueError("URL not allowed")
```
