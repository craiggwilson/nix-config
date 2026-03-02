# Python Patterns

## Dataclasses

```python
from dataclasses import dataclass, field
from datetime import datetime

@dataclass
class User:
    id: int
    name: str
    email: str
    created_at: datetime = field(default_factory=datetime.now)
    tags: list[str] = field(default_factory=list)

@dataclass(frozen=True)  # Immutable
class Point:
    x: float
    y: float

@dataclass(slots=True)  # Memory efficient
class Event:
    name: str
    timestamp: float
```

## Context Managers

```python
from contextlib import contextmanager
from typing import Iterator

@contextmanager
def managed_resource(name: str) -> Iterator[Resource]:
    resource = acquire_resource(name)
    try:
        yield resource
    finally:
        resource.release()

# Class-based
class DatabaseTransaction:
    def __init__(self, conn: Connection) -> None:
        self.conn = conn

    def __enter__(self) -> Cursor:
        self.cursor = self.conn.cursor()
        return self.cursor

    def __exit__(self, exc_type, exc_val, exc_tb) -> bool:
        if exc_type is None:
            self.conn.commit()
        else:
            self.conn.rollback()
        self.cursor.close()
        return False
```

## Decorators

```python
from functools import wraps
from typing import Callable, TypeVar, ParamSpec

P = ParamSpec('P')
R = TypeVar('R')

def retry(max_attempts: int = 3) -> Callable[[Callable[P, R]], Callable[P, R]]:
    def decorator(func: Callable[P, R]) -> Callable[P, R]:
        @wraps(func)
        def wrapper(*args: P.args, **kwargs: P.kwargs) -> R:
            for attempt in range(max_attempts):
                try:
                    return func(*args, **kwargs)
                except Exception as e:
                    if attempt == max_attempts - 1:
                        raise
            raise RuntimeError("Unreachable")
        return wrapper
    return decorator

@retry(max_attempts=3)
def flaky_operation() -> str:
    return "success"
```

## Protocols

```python
from typing import Protocol

class Serializable(Protocol):
    def to_dict(self) -> dict[str, Any]: ...
    
    @classmethod
    def from_dict(cls, data: dict[str, Any]) -> Self: ...

class JsonSerializable(Protocol):
    def to_json(self) -> str: ...

def save(obj: Serializable) -> None:
    data = obj.to_dict()
    # save data...
```

## Factory Pattern

```python
from abc import ABC, abstractmethod

class Notification(ABC):
    @abstractmethod
    def send(self, message: str) -> None: ...

class EmailNotification(Notification):
    def send(self, message: str) -> None:
        print(f"Email: {message}")

class SMSNotification(Notification):
    def send(self, message: str) -> None:
        print(f"SMS: {message}")

def create_notification(type_: str) -> Notification:
    match type_:
        case "email":
            return EmailNotification()
        case "sms":
            return SMSNotification()
        case _:
            raise ValueError(f"Unknown type: {type_}")
```

## Dependency Injection

```python
from dataclasses import dataclass

@dataclass
class Config:
    database_url: str
    api_key: str

@dataclass
class Dependencies:
    config: Config
    db: Database
    cache: Cache

def create_dependencies(config: Config) -> Dependencies:
    db = Database(config.database_url)
    cache = Cache()
    return Dependencies(config=config, db=db, cache=cache)

class UserService:
    def __init__(self, deps: Dependencies) -> None:
        self.db = deps.db
        self.cache = deps.cache
```

## Result Pattern

```python
from dataclasses import dataclass
from typing import Generic, TypeVar

T = TypeVar('T')
E = TypeVar('E', bound=Exception)

@dataclass
class Ok(Generic[T]):
    value: T

@dataclass
class Err(Generic[E]):
    error: E

Result = Ok[T] | Err[E]

def divide(a: int, b: int) -> Result[float, ValueError]:
    if b == 0:
        return Err(ValueError("Division by zero"))
    return Ok(a / b)

# Usage
match divide(10, 2):
    case Ok(value):
        print(f"Result: {value}")
    case Err(error):
        print(f"Error: {error}")
```
