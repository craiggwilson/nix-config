# Resilience Patterns

## Retry with Backoff

```python
import time
import random

def retry_with_backoff(func, max_retries=3, base_delay=1):
    for attempt in range(max_retries):
        try:
            return func()
        except RetryableError:
            if attempt == max_retries - 1:
                raise
            delay = base_delay * (2 ** attempt)
            jitter = random.uniform(0, delay * 0.1)
            time.sleep(delay + jitter)
```

## Timeout

```python
import asyncio

async def with_timeout(coro, timeout_seconds):
    try:
        return await asyncio.wait_for(coro, timeout=timeout_seconds)
    except asyncio.TimeoutError:
        raise ServiceTimeoutError()
```

## Bulkhead

```python
from concurrent.futures import ThreadPoolExecutor

# Isolate resources per service
service_a_pool = ThreadPoolExecutor(max_workers=10)
service_b_pool = ThreadPoolExecutor(max_workers=10)

# Failure in A doesn't exhaust B's resources
```

## Fallback

```python
def get_user_with_fallback(user_id):
    try:
        return user_service.get(user_id)
    except ServiceUnavailable:
        return cache.get(f"user:{user_id}")  # Stale data
    except CacheMiss:
        return User(id=user_id, name="Unknown")  # Default
```

## Health Checks

```python
@app.get("/health")
def health_check():
    checks = {
        "database": check_database(),
        "cache": check_cache(),
        "external_api": check_external_api(),
    }
    
    healthy = all(checks.values())
    return {
        "status": "healthy" if healthy else "unhealthy",
        "checks": checks
    }, 200 if healthy else 503
```

## Graceful Degradation

- Disable non-critical features
- Return cached data
- Queue requests for later
- Show partial results
