# Rust Testing

## Unit Tests

```rust
pub fn add(a: i32, b: i32) -> i32 {
    a + b
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_add() {
        assert_eq!(add(2, 3), 5);
    }

    #[test]
    fn test_add_negative() {
        assert_eq!(add(-1, 1), 0);
    }

    #[test]
    #[should_panic(expected = "overflow")]
    fn test_overflow() {
        add(i32::MAX, 1);
    }

    #[test]
    fn test_result() -> Result<(), String> {
        let result = divide(10, 2)?;
        assert_eq!(result, 5);
        Ok(())
    }
}
```

## Integration Tests

```rust
// tests/integration_test.rs
use mylib::process;

#[test]
fn test_full_workflow() {
    let input = "test data";
    let result = process(input);
    assert!(result.is_ok());
}
```

## Doc Tests

```rust
/// Adds two numbers together.
///
/// # Examples
///
/// ```
/// use mylib::add;
/// assert_eq!(add(2, 3), 5);
/// ```
///
/// # Panics
///
/// Panics if the result overflows.
pub fn add(a: i32, b: i32) -> i32 {
    a.checked_add(b).expect("overflow")
}
```

## Test Organization

```rust
#[cfg(test)]
mod tests {
    use super::*;

    mod add {
        use super::*;

        #[test]
        fn positive_numbers() { ... }

        #[test]
        fn negative_numbers() { ... }
    }

    mod subtract {
        use super::*;

        #[test]
        fn basic() { ... }
    }
}
```

## Mocking with mockall

```rust
use mockall::automock;

#[automock]
trait Database {
    fn get_user(&self, id: u64) -> Option<User>;
}

#[test]
fn test_with_mock() {
    let mut mock = MockDatabase::new();
    mock.expect_get_user()
        .with(eq(1))
        .returning(|_| Some(User { id: 1, name: "Test".into() }));

    let service = UserService::new(mock);
    let user = service.get_user(1);
    assert!(user.is_some());
}
```

## Async Tests

```rust
#[tokio::test]
async fn test_async_function() {
    let result = fetch_data().await;
    assert!(result.is_ok());
}
```

## Running Tests

```bash
# Run all tests
cargo test

# Run specific test
cargo test test_add

# Run with output
cargo test -- --nocapture

# Run ignored tests
cargo test -- --ignored
```
