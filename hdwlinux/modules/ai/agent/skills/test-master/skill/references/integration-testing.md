# Integration Testing

## API Testing

```python
import pytest
from fastapi.testclient import TestClient
from myapp import app

@pytest.fixture
def client():
    return TestClient(app)

def test_create_user(client):
    response = client.post("/users", json={
        "name": "John",
        "email": "john@example.com"
    })
    
    assert response.status_code == 201
    assert response.json()["name"] == "John"

def test_get_user(client):
    response = client.get("/users/1")
    
    assert response.status_code == 200
    assert "email" in response.json()
```

## Database Testing

```python
import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

@pytest.fixture(scope="function")
def db_session():
    engine = create_engine("sqlite:///:memory:")
    Base.metadata.create_all(engine)
    Session = sessionmaker(bind=engine)
    session = Session()
    
    yield session
    
    session.close()

def test_user_repository(db_session):
    repo = UserRepository(db_session)
    
    user = repo.create(name="John", email="john@example.com")
    
    assert user.id is not None
    assert repo.get(user.id).name == "John"
```

## TestContainers

```python
import pytest
from testcontainers.postgres import PostgresContainer

@pytest.fixture(scope="module")
def postgres():
    with PostgresContainer("postgres:15") as postgres:
        yield postgres

@pytest.fixture
def db_url(postgres):
    return postgres.get_connection_url()

def test_with_real_postgres(db_url):
    engine = create_engine(db_url)
    # Test with real PostgreSQL
```

## HTTP Mocking

```python
import responses

@responses.activate
def test_external_api():
    responses.add(
        responses.GET,
        "https://api.example.com/users/1",
        json={"id": 1, "name": "John"},
        status=200
    )
    
    result = fetch_user(1)
    
    assert result["name"] == "John"
    assert len(responses.calls) == 1
```

## Message Queue Testing

```python
@pytest.fixture
def mock_queue():
    queue = []
    
    def publish(message):
        queue.append(message)
    
    def consume():
        return queue.pop(0) if queue else None
    
    return Mock(publish=publish, consume=consume)

def test_message_processing(mock_queue):
    mock_queue.publish({"type": "order", "id": 1})
    
    process_messages(mock_queue)
    
    assert mock_queue.consume() is None  # All processed
```
