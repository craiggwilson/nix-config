# Python Testing Patterns

## Pytest Basics

```python
import pytest

def test_simple():
    assert 1 + 1 == 2

def test_exception():
    with pytest.raises(ValueError, match="invalid"):
        raise ValueError("invalid input")

def test_approximate():
    assert 0.1 + 0.2 == pytest.approx(0.3)
```

## Fixtures

```python
import pytest
from typing import Iterator

@pytest.fixture
def user() -> User:
    return User(id=1, name="Test User")

@pytest.fixture
def db_session() -> Iterator[Session]:
    session = create_session()
    yield session
    session.rollback()
    session.close()

@pytest.fixture(scope="module")
def expensive_resource() -> Iterator[Resource]:
    resource = create_expensive_resource()
    yield resource
    resource.cleanup()

def test_with_fixtures(user: User, db_session: Session) -> None:
    db_session.add(user)
    assert db_session.query(User).count() == 1
```

## Parametrize

```python
@pytest.mark.parametrize("input,expected", [
    ("hello", "HELLO"),
    ("world", "WORLD"),
    ("", ""),
])
def test_uppercase(input: str, expected: str) -> None:
    assert input.upper() == expected

@pytest.mark.parametrize("a,b,expected", [
    (1, 2, 3),
    (-1, 1, 0),
    (0, 0, 0),
])
def test_add(a: int, b: int, expected: int) -> None:
    assert add(a, b) == expected
```

## Mocking

```python
from unittest.mock import Mock, patch, MagicMock, AsyncMock

def test_with_mock():
    mock_repo = Mock(spec=UserRepository)
    mock_repo.get_user.return_value = User(id=1, name="Test")
    
    service = UserService(mock_repo)
    user = service.get_user(1)
    
    assert user.name == "Test"
    mock_repo.get_user.assert_called_once_with(1)

@patch("mymodule.external_api")
def test_with_patch(mock_api: Mock) -> None:
    mock_api.fetch.return_value = {"status": "ok"}
    result = my_function()
    assert result == "ok"

# Async mocking
@pytest.mark.asyncio
async def test_async_mock():
    mock_client = AsyncMock()
    mock_client.fetch.return_value = {"data": "test"}
    
    result = await process(mock_client)
    assert result == "test"
```

## Async Testing

```python
import pytest

@pytest.mark.asyncio
async def test_async_function():
    result = await async_fetch("url")
    assert result["status"] == "ok"

@pytest.fixture
async def async_client() -> AsyncIterator[Client]:
    client = await create_client()
    yield client
    await client.close()

@pytest.mark.asyncio
async def test_with_async_fixture(async_client: Client) -> None:
    result = await async_client.get("/users")
    assert len(result) > 0
```

## Test Organization

```
tests/
├── conftest.py          # Shared fixtures
├── unit/
│   ├── test_models.py
│   └── test_services.py
├── integration/
│   ├── conftest.py      # Integration fixtures
│   └── test_api.py
└── e2e/
    └── test_workflows.py
```

## Coverage

```bash
# Run with coverage
pytest --cov=mypackage --cov-report=html

# Fail if coverage below threshold
pytest --cov=mypackage --cov-fail-under=90
```

## Markers

```python
@pytest.mark.slow
def test_slow_operation():
    ...

@pytest.mark.integration
def test_database():
    ...

@pytest.mark.skip(reason="Not implemented yet")
def test_future_feature():
    ...

@pytest.mark.skipif(sys.platform == "win32", reason="Unix only")
def test_unix_specific():
    ...
```

```ini
# pytest.ini
[pytest]
markers =
    slow: marks tests as slow
    integration: marks tests as integration tests
```
