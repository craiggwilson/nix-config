# Authentication

## Password Hashing

```python
# Use argon2 or bcrypt
from passlib.hash import argon2

# Hash password
hashed = argon2.hash(password)

# Verify password
if argon2.verify(password, hashed):
    # Password correct
    pass
```

## Session Management

```python
from secrets import token_urlsafe

# Generate secure session ID
session_id = token_urlsafe(32)

# Session configuration
SESSION_CONFIG = {
    "httponly": True,      # No JavaScript access
    "secure": True,        # HTTPS only
    "samesite": "strict",  # CSRF protection
    "max_age": 3600,       # 1 hour expiry
}
```

## JWT Tokens

```python
import jwt
from datetime import datetime, timedelta

def create_token(user_id: str) -> str:
    payload = {
        "sub": user_id,
        "iat": datetime.utcnow(),
        "exp": datetime.utcnow() + timedelta(hours=1),
    }
    return jwt.encode(payload, SECRET_KEY, algorithm="HS256")

def verify_token(token: str) -> dict:
    try:
        return jwt.decode(token, SECRET_KEY, algorithms=["HS256"])
    except jwt.ExpiredSignatureError:
        raise AuthError("Token expired")
    except jwt.InvalidTokenError:
        raise AuthError("Invalid token")
```

## Multi-Factor Authentication

```python
import pyotp

# Generate secret for user
secret = pyotp.random_base32()

# Generate TOTP
totp = pyotp.TOTP(secret)
current_code = totp.now()

# Verify code
if totp.verify(user_provided_code):
    # Code valid
    pass
```

## Account Lockout

```python
MAX_ATTEMPTS = 5
LOCKOUT_DURATION = timedelta(minutes=15)

def check_login(username: str, password: str):
    attempts = get_failed_attempts(username)
    
    if attempts >= MAX_ATTEMPTS:
        if not lockout_expired(username):
            raise AccountLockedError()
        reset_attempts(username)
    
    if not verify_password(username, password):
        increment_attempts(username)
        raise InvalidCredentialsError()
    
    reset_attempts(username)
    return create_session(username)
```

## Best Practices

- Never store plaintext passwords
- Use secure random for tokens
- Implement rate limiting
- Log authentication events
- Use HTTPS everywhere
- Implement proper logout
