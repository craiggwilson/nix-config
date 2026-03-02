# Unit Testing

## Test Structure (AAA)

```python
def test_user_creation():
    # Arrange
    user_data = {"name": "John", "email": "john@example.com"}
    
    # Act
    user = User.create(user_data)
    
    # Assert
    assert user.name == "John"
    assert user.email == "john@example.com"
```

## Assertions

```python
# Equality
assert result == expected
assert result != unexpected

# Truthiness
assert condition
assert not condition

# Collections
assert item in collection
assert len(collection) == 3

# Exceptions
with pytest.raises(ValueError):
    function_that_raises()

# Approximate
assert result == pytest.approx(3.14, rel=0.01)
```

## Mocking

```python
from unittest.mock import Mock, patch, MagicMock

# Simple mock
mock_db = Mock()
mock_db.get_user.return_value = User(id=1, name="Test")

# Patch decorator
@patch('mymodule.external_api')
def test_with_patch(mock_api):
    mock_api.fetch.return_value = {"data": "test"}
    result = my_function()
    mock_api.fetch.assert_called_once()

# Context manager
with patch('mymodule.datetime') as mock_datetime:
    mock_datetime.now.return_value = datetime(2024, 1, 1)
    result = get_current_date()
```

## Fixtures

```python
import pytest

@pytest.fixture
def user():
    return User(id=1, name="Test User")

@pytest.fixture
def db_session():
    session = create_session()
    yield session
    session.rollback()
    session.close()

def test_user_save(user, db_session):
    db_session.add(user)
    db_session.commit()
    assert user.id is not None
```

## Parametrized Tests

```python
@pytest.mark.parametrize("input,expected", [
    ("hello", 5),
    ("world", 5),
    ("", 0),
    ("a", 1),
])
def test_string_length(input, expected):
    assert len(input) == expected
```

## Test Organization

```
tests/
├── unit/
│   ├── test_user.py
│   └── test_order.py
├── integration/
│   └── test_api.py
├── conftest.py
└── fixtures/
    └── data.json
```
