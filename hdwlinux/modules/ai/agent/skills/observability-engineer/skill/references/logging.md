# Structured Logging

## Log Format

```json
{
  "timestamp": "2024-01-15T10:30:00.123Z",
  "level": "info",
  "message": "Request processed",
  "service": "api",
  "correlation_id": "abc-123",
  "user_id": "user-456",
  "duration_ms": 45,
  "status_code": 200
}
```

## Log Levels

| Level | Use For |
|-------|---------|
| DEBUG | Detailed diagnostic info |
| INFO | Normal operations |
| WARN | Potential issues |
| ERROR | Failures requiring attention |
| FATAL | System cannot continue |

## Python Example

```python
import structlog

logger = structlog.get_logger()

logger.info(
    "request_processed",
    correlation_id=correlation_id,
    user_id=user_id,
    duration_ms=duration,
    status_code=200
)

# With context
logger = logger.bind(correlation_id=correlation_id)
logger.info("step_1_complete")
logger.info("step_2_complete")
```

## Go Example

```go
import "go.uber.org/zap"

logger, _ := zap.NewProduction()
defer logger.Sync()

logger.Info("request processed",
    zap.String("correlation_id", correlationID),
    zap.String("user_id", userID),
    zap.Int("duration_ms", duration),
    zap.Int("status_code", 200),
)
```

## Best Practices

### DO
- Use structured logging (JSON)
- Include correlation IDs
- Log at appropriate levels
- Include context (user, request)
- Use consistent field names

### DON'T
- Log sensitive data (passwords, tokens)
- Log at wrong level (INFO for errors)
- Use string interpolation for fields
- Log too much (performance impact)
- Forget correlation IDs

## Correlation

```python
# Middleware to propagate correlation ID
def correlation_middleware(request, next):
    correlation_id = request.headers.get(
        "X-Correlation-ID",
        str(uuid.uuid4())
    )
    
    # Bind to logger context
    structlog.contextvars.bind_contextvars(
        correlation_id=correlation_id
    )
    
    response = next(request)
    response.headers["X-Correlation-ID"] = correlation_id
    return response
```
