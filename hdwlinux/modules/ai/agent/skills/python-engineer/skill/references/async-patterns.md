# Python Async Patterns

## Basic Async/Await

```python
import asyncio

async def fetch_data(url: str) -> dict[str, str]:
    await asyncio.sleep(1)  # Simulate I/O
    return {"url": url, "status": "ok"}

async def main() -> None:
    result = await fetch_data("https://api.example.com")
    print(result)

if __name__ == "__main__":
    asyncio.run(main())

# Multiple concurrent operations
async def fetch_all(urls: list[str]) -> list[dict[str, str]]:
    tasks = [fetch_data(url) for url in urls]
    return await asyncio.gather(*tasks)
```

## Task Groups (Python 3.11+)

```python
from asyncio import TaskGroup

async def process_batch(items: list[int]) -> list[int]:
    results: list[int] = []

    async with TaskGroup() as tg:
        tasks = [tg.create_task(process_item(item)) for item in items]

    return [task.result() for task in tasks]

# Error handling with TaskGroup
async def robust_processing(items: list[str]) -> tuple[list[str], list[Exception]]:
    results: list[str] = []
    errors: list[Exception] = []

    try:
        async with TaskGroup() as tg:
            for item in items:
                tg.create_task(process_item_safe(item))
    except ExceptionGroup as eg:
        for exc in eg.exceptions:
            errors.append(exc)

    return results, errors
```

## Async Context Managers

```python
from typing import Self
from collections.abc import AsyncIterator

class AsyncDatabaseConnection:
    async def __aenter__(self) -> Self:
        self._conn = await connect(self.url)
        return self

    async def __aexit__(self, exc_type, exc_val, exc_tb) -> None:
        if self._conn:
            await self._conn.close()

# With contextlib
from contextlib import asynccontextmanager

@asynccontextmanager
async def get_db_session() -> AsyncIterator[Session]:
    session = await create_session()
    try:
        yield session
        await session.commit()
    except Exception:
        await session.rollback()
        raise
    finally:
        await session.close()
```

## Async Generators

```python
from collections.abc import AsyncIterator

async def read_lines(filepath: str) -> AsyncIterator[str]:
    async with aiofiles.open(filepath) as f:
        async for line in f:
            yield line.strip()

async def process_file(filepath: str) -> int:
    count = 0
    async for line in read_lines(filepath):
        await process_line(line)
        count += 1
    return count
```

## Synchronization Primitives

```python
import asyncio

# Lock for critical sections
class SharedResource:
    def __init__(self) -> None:
        self._lock = asyncio.Lock()
        self._data: dict[str, Any] = {}

    async def update(self, key: str, value: Any) -> None:
        async with self._lock:
            current = self._data.get(key, 0)
            self._data[key] = current + value

# Semaphore for rate limiting
class RateLimiter:
    def __init__(self, max_concurrent: int) -> None:
        self._semaphore = asyncio.Semaphore(max_concurrent)

    async def process(self, item: str) -> str:
        async with self._semaphore:
            return await expensive_operation(item)
```

## Async Queue Patterns

```python
from asyncio import Queue

async def producer(queue: Queue[int], n: int) -> None:
    for i in range(n):
        await queue.put(i)

async def consumer(queue: Queue[int]) -> None:
    while True:
        item = await queue.get()
        try:
            await process_item(item)
        finally:
            queue.task_done()

async def run_pipeline(num_items: int, num_workers: int) -> None:
    queue: Queue[int] = Queue(maxsize=10)

    async with TaskGroup() as tg:
        tg.create_task(producer(queue, num_items))
        for i in range(num_workers):
            tg.create_task(consumer(queue))
        await queue.join()
```

## Async Timeouts

```python
async def fetch_with_timeout(url: str, timeout: float) -> dict[str, Any]:
    try:
        async with asyncio.timeout(timeout):
            return await fetch_data(url)
    except TimeoutError:
        return {"error": "timeout"}
```

## Mixing Sync and Async

```python
from concurrent.futures import ThreadPoolExecutor
import functools

async def run_in_executor(func: Callable[..., T], *args: Any) -> T:
    loop = asyncio.get_running_loop()
    return await loop.run_in_executor(None, func, *args)

def to_async(func: Callable[..., T]) -> Callable[..., Coroutine[None, None, T]]:
    @functools.wraps(func)
    async def wrapper(*args: Any, **kwargs: Any) -> T:
        loop = asyncio.get_running_loop()
        return await loop.run_in_executor(
            None,
            functools.partial(func, *args, **kwargs)
        )
    return wrapper
```
