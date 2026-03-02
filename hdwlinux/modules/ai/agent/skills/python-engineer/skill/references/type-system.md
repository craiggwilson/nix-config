# Python Type System

## Basic Type Annotations

```python
from typing import Any
from collections.abc import Sequence, Mapping

# Function signatures
def process_user(name: str, age: int, active: bool = True) -> dict[str, Any]:
    return {"name": name, "age": age, "active": active}

# Use | for unions (Python 3.10+)
def find_user(user_id: int | str) -> dict[str, Any] | None:
    if isinstance(user_id, int):
        return {"id": user_id}
    return None

# Collections - prefer collections.abc
def process_items(items: Sequence[str]) -> list[str]:
    return [item.upper() for item in items]

def merge_configs(base: Mapping[str, int], override: dict[str, int]) -> dict[str, int]:
    return {**base, **override}
```

## Generic Types

```python
from typing import TypeVar, Generic
from collections.abc import Sequence

T = TypeVar('T')
K = TypeVar('K')
V = TypeVar('V')

# Generic function
def first_element(items: Sequence[T]) -> T | None:
    return items[0] if items else None

# Generic class
class Cache(Generic[K, V]):
    def __init__(self) -> None:
        self._data: dict[K, V] = {}

    def get(self, key: K) -> V | None:
        return self._data.get(key)

    def set(self, key: K, value: V) -> None:
        self._data[key] = value
```

## Protocol for Structural Typing

```python
from typing import Protocol, runtime_checkable

class Drawable(Protocol):
    def draw(self) -> str: ...

    @property
    def color(self) -> str: ...

class Circle:
    def __init__(self, radius: float, color: str) -> None:
        self.radius = radius
        self._color = color

    def draw(self) -> str:
        return f"Drawing {self._color} circle"

    @property
    def color(self) -> str:
        return self._color

# Circle implements Drawable without inheriting
def render(shape: Drawable) -> str:
    return shape.draw()
```

## Advanced Type Features

```python
from typing import Literal, TypeAlias, TypedDict, NotRequired, Self, overload

# Literal types
Mode = Literal["read", "write", "append"]

# Type aliases
JsonDict: TypeAlias = dict[str, Any]
UserId: TypeAlias = int | str

# TypedDict for structured dictionaries
class UserDict(TypedDict):
    id: int
    name: str
    email: str
    age: NotRequired[int]

# Self type for method chaining
class Builder:
    def add(self, n: int) -> Self:
        self._value += n
        return self

# Overload for different signatures
@overload
def process(data: str) -> str: ...
@overload
def process(data: int) -> int: ...

def process(data: str | int) -> str | int:
    if isinstance(data, str):
        return data.upper()
    return data * 2
```

## Callable Types

```python
from collections.abc import Callable
from typing import ParamSpec

P = ParamSpec('P')
R = TypeVar('R')

def logging_decorator(func: Callable[P, R]) -> Callable[P, R]:
    def wrapper(*args: P.args, **kwargs: P.kwargs) -> R:
        print(f"Calling {func.__name__}")
        return func(*args, **kwargs)
    return wrapper
```

## Mypy Configuration

```toml
# pyproject.toml
[tool.mypy]
python_version = "3.11"
strict = true
warn_return_any = true
disallow_untyped_defs = true
disallow_any_generics = true
no_implicit_optional = true
warn_redundant_casts = true
warn_unused_ignores = true
strict_equality = true
```

## Type Narrowing

```python
from typing import assert_never

def process_value(value: int | str | None) -> str:
    if value is None:
        return "null"
    if isinstance(value, int):
        return str(value * 2)
    return value.upper()

def handle_mode(mode: Literal["read", "write"]) -> str:
    if mode == "read":
        return "Reading"
    elif mode == "write":
        return "Writing"
    else:
        assert_never(mode)
```
