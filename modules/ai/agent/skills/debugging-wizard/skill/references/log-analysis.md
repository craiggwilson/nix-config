# Log Analysis

## Structured Logging

```json
{
  "timestamp": "2024-01-15T10:30:00Z",
  "level": "error",
  "message": "Failed to process order",
  "correlation_id": "abc-123",
  "user_id": "user-456",
  "order_id": "order-789",
  "error": "connection timeout"
}
```

## Command Line Tools

### grep
```bash
# Find errors
grep -i "error" app.log

# Context around match
grep -B 5 -A 5 "exception" app.log

# Multiple patterns
grep -E "error|exception|failed" app.log
```

### jq for JSON logs
```bash
# Filter by level
cat app.log | jq 'select(.level == "error")'

# Extract fields
cat app.log | jq '{time: .timestamp, msg: .message}'

# Filter by time
cat app.log | jq 'select(.timestamp > "2024-01-15T10:00:00Z")'
```

### awk for patterns
```bash
# Count errors per hour
awk '/ERROR/ {print substr($1,1,13)}' app.log | sort | uniq -c
```

## Correlation

```bash
# Find all logs for a request
grep "correlation_id.*abc-123" *.log

# Follow a user's journey
grep "user_id.*user-456" app.log | jq -s 'sort_by(.timestamp)'
```

## Log Levels

| Level | Use For |
|-------|---------|
| DEBUG | Detailed diagnostic info |
| INFO | Normal operations |
| WARN | Potential issues |
| ERROR | Failures requiring attention |
| FATAL | System cannot continue |
