# Authorization

## Role-Based Access Control (RBAC)

```python
from enum import Enum
from functools import wraps

class Role(Enum):
    ADMIN = "admin"
    MANAGER = "manager"
    USER = "user"

class Permission(Enum):
    READ_USERS = "read:users"
    WRITE_USERS = "write:users"
    DELETE_USERS = "delete:users"

ROLE_PERMISSIONS = {
    Role.ADMIN: [Permission.READ_USERS, Permission.WRITE_USERS, Permission.DELETE_USERS],
    Role.MANAGER: [Permission.READ_USERS, Permission.WRITE_USERS],
    Role.USER: [Permission.READ_USERS],
}

def require_permission(permission: Permission):
    def decorator(func):
        @wraps(func)
        def wrapper(*args, current_user: User, **kwargs):
            user_permissions = ROLE_PERMISSIONS.get(current_user.role, [])
            if permission not in user_permissions:
                raise PermissionDenied()
            return func(*args, current_user=current_user, **kwargs)
        return wrapper
    return decorator

@require_permission(Permission.DELETE_USERS)
def delete_user(user_id: int, current_user: User):
    # Only admins can reach here
    pass
```

## Attribute-Based Access Control (ABAC)

```python
def can_access_resource(user: User, resource: Resource, action: str) -> bool:
    # Check ownership
    if resource.owner_id == user.id:
        return True
    
    # Check organization
    if resource.org_id == user.org_id and action == "read":
        return True
    
    # Check explicit permissions
    if has_explicit_permission(user, resource, action):
        return True
    
    return False
```

## Resource-Level Authorization

```python
@app.get("/documents/{doc_id}")
def get_document(doc_id: int, current_user: User = Depends(get_current_user)):
    document = db.get_document(doc_id)
    
    if not document:
        raise HTTPException(status_code=404)
    
    # Check authorization
    if not can_access_document(current_user, document):
        raise HTTPException(status_code=403)
    
    return document
```

## Principle of Least Privilege

```python
# Bad - overly permissive
def get_all_data(user: User):
    return db.query(Data).all()

# Good - scoped to user's access
def get_user_data(user: User):
    return db.query(Data).filter(
        Data.org_id == user.org_id,
        Data.visibility.in_(get_visible_levels(user))
    ).all()
```

## Authorization Checks

| Check | When |
|-------|------|
| Authentication | Every request |
| Role check | Before action |
| Resource ownership | Before access |
| Field-level | Before returning data |
