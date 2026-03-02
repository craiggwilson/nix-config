# API Versioning

## Versioning Strategies

### URL Path Versioning
```
GET /v1/users
GET /v2/users
```
- Most explicit and visible
- Easy to route
- Can run multiple versions simultaneously

### Header Versioning
```
GET /users
Accept: application/vnd.myapi.v1+json
```
- Cleaner URLs
- More RESTful
- Harder to test in browser

### Query Parameter
```
GET /users?version=1
```
- Easy to implement
- Can be optional with default
- Less clean

## Deprecation Strategy

```yaml
# Response headers
Deprecation: true
Sunset: Sat, 31 Dec 2024 23:59:59 GMT
Link: <https://api.example.com/v2/users>; rel="successor-version"
```

## Backward Compatibility

### Safe Changes (Non-breaking)
- Adding new endpoints
- Adding optional fields
- Adding new enum values (if client ignores unknown)
- Adding new error codes

### Breaking Changes
- Removing endpoints
- Removing fields
- Changing field types
- Renaming fields
- Changing required/optional

## Migration Path

1. **Announce** - Document deprecation timeline
2. **Dual Support** - Run both versions
3. **Monitor** - Track v1 usage
4. **Migrate** - Help clients upgrade
5. **Sunset** - Remove old version

## Version Lifecycle

| Phase | Duration | Support |
|-------|----------|---------|
| Current | Ongoing | Full |
| Deprecated | 6-12 months | Security only |
| Sunset | After deprecation | None |
