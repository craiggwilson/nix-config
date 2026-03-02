# Performance Optimization

## Common Optimizations

### Caching
```python
from functools import lru_cache

@lru_cache(maxsize=1000)
def expensive_computation(x):
    return compute(x)

# Or use Redis for distributed caching
cache.set(key, value, ex=3600)
result = cache.get(key)
```

### Connection Pooling
```python
# Database
from sqlalchemy import create_engine
engine = create_engine(
    url,
    pool_size=10,
    max_overflow=20,
    pool_pre_ping=True
)

# HTTP
import httpx
client = httpx.Client(
    limits=httpx.Limits(max_connections=100)
)
```

### Batch Operations
```python
# Bad - N+1 queries
for user_id in user_ids:
    user = db.query(User).get(user_id)

# Good - batch query
users = db.query(User).filter(User.id.in_(user_ids)).all()
```

### Async I/O
```python
import asyncio

# Sequential (slow)
for url in urls:
    result = await fetch(url)

# Concurrent (fast)
results = await asyncio.gather(*[fetch(url) for url in urls])
```

## Data Structure Selection

| Operation | Array | Hash Map | Tree |
|-----------|-------|----------|------|
| Access by index | O(1) | - | - |
| Search | O(n) | O(1) | O(log n) |
| Insert | O(n) | O(1) | O(log n) |
| Ordered iteration | O(n) | O(n log n) | O(n) |

## Memory Optimization

```python
# Use generators for large datasets
def process_large_file(path):
    with open(path) as f:
        for line in f:  # Lazy iteration
            yield process(line)

# Use __slots__ for many objects
class Point:
    __slots__ = ['x', 'y']
    def __init__(self, x, y):
        self.x = x
        self.y = y
```

## Anti-Patterns

| Anti-Pattern | Fix |
|--------------|-----|
| N+1 queries | Batch/join queries |
| String concatenation in loop | StringBuilder/join |
| Synchronous I/O | Async/concurrent |
| No connection pooling | Use pool |
| Premature optimization | Profile first |
