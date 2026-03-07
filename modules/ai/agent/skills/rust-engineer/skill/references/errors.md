# Rust Error Handling

## Result Type

```rust
fn divide(a: i32, b: i32) -> Result<i32, String> {
    if b == 0 {
        Err("Division by zero".to_string())
    } else {
        Ok(a / b)
    }
}

// Using Result
match divide(10, 2) {
    Ok(result) => println!("Result: {}", result),
    Err(e) => println!("Error: {}", e),
}

// With ? operator
fn calculate() -> Result<i32, String> {
    let x = divide(10, 2)?;
    let y = divide(x, 2)?;
    Ok(y)
}
```

## thiserror (Libraries)

```rust
use thiserror::Error;

#[derive(Error, Debug)]
pub enum DataError {
    #[error("Failed to read file: {0}")]
    IoError(#[from] std::io::Error),
    
    #[error("Failed to parse data: {0}")]
    ParseError(#[from] serde_json::Error),
    
    #[error("Invalid data: {field} - {message}")]
    ValidationError {
        field: String,
        message: String,
    },
    
    #[error("Resource not found: {0}")]
    NotFound(String),
}

fn load_data(path: &str) -> Result<Data, DataError> {
    let content = std::fs::read_to_string(path)?; // IoError
    let data: Data = serde_json::from_str(&content)?; // ParseError
    Ok(data)
}
```

## anyhow (Applications)

```rust
use anyhow::{Context, Result, bail, ensure};

fn process_file(path: &str) -> Result<()> {
    let content = std::fs::read_to_string(path)
        .context("Failed to read configuration file")?;
    
    let config: Config = serde_json::from_str(&content)
        .context("Failed to parse configuration")?;
    
    ensure!(config.is_valid(), "Invalid configuration");
    
    if config.debug {
        bail!("Debug mode not allowed in production");
    }
    
    Ok(())
}

fn main() -> Result<()> {
    process_file("config.json")?;
    Ok(())
}
```

## Custom Error Types

```rust
#[derive(Debug)]
pub struct AppError {
    pub kind: ErrorKind,
    pub message: String,
    pub source: Option<Box<dyn std::error::Error + Send + Sync>>,
}

#[derive(Debug)]
pub enum ErrorKind {
    NotFound,
    Validation,
    Internal,
}

impl std::fmt::Display for AppError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{:?}: {}", self.kind, self.message)
    }
}

impl std::error::Error for AppError {
    fn source(&self) -> Option<&(dyn std::error::Error + 'static)> {
        self.source.as_ref().map(|e| e.as_ref() as _)
    }
}
```

## Best Practices

- Use `thiserror` for libraries
- Use `anyhow` for applications
- Add context with `.context()`
- Don't use `unwrap()` in library code
- Use `expect()` with descriptive messages
