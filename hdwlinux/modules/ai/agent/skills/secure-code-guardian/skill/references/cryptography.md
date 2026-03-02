# Cryptography

## Password Hashing

```python
# Recommended: Argon2
from argon2 import PasswordHasher

ph = PasswordHasher()
hash = ph.hash("password")
ph.verify(hash, "password")

# Alternative: bcrypt
import bcrypt

hash = bcrypt.hashpw(password.encode(), bcrypt.gensalt())
bcrypt.checkpw(password.encode(), hash)
```

## Symmetric Encryption

```python
from cryptography.fernet import Fernet

# Generate key (store securely!)
key = Fernet.generate_key()
cipher = Fernet(key)

# Encrypt
encrypted = cipher.encrypt(b"secret data")

# Decrypt
decrypted = cipher.decrypt(encrypted)
```

## Asymmetric Encryption

```python
from cryptography.hazmat.primitives.asymmetric import rsa, padding
from cryptography.hazmat.primitives import hashes

# Generate key pair
private_key = rsa.generate_private_key(
    public_exponent=65537,
    key_size=2048,
)
public_key = private_key.public_key()

# Encrypt with public key
ciphertext = public_key.encrypt(
    plaintext,
    padding.OAEP(
        mgf=padding.MGF1(algorithm=hashes.SHA256()),
        algorithm=hashes.SHA256(),
        label=None
    )
)

# Decrypt with private key
plaintext = private_key.decrypt(ciphertext, padding.OAEP(...))
```

## Digital Signatures

```python
from cryptography.hazmat.primitives.asymmetric import padding
from cryptography.hazmat.primitives import hashes

# Sign
signature = private_key.sign(
    message,
    padding.PSS(
        mgf=padding.MGF1(hashes.SHA256()),
        salt_length=padding.PSS.MAX_LENGTH
    ),
    hashes.SHA256()
)

# Verify
public_key.verify(signature, message, padding.PSS(...), hashes.SHA256())
```

## Secure Random

```python
import secrets

# Generate secure token
token = secrets.token_urlsafe(32)

# Generate secure integer
number = secrets.randbelow(100)

# Secure comparison (timing-safe)
secrets.compare_digest(a, b)
```

## What NOT to Use

| Don't Use | Use Instead |
|-----------|-------------|
| MD5, SHA1 | SHA-256, SHA-3 |
| DES, 3DES | AES-256 |
| ECB mode | GCM, CBC with HMAC |
| Custom crypto | Standard libraries |
| `random` | `secrets` |
