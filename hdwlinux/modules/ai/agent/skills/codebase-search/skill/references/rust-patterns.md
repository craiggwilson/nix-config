# Rust Search Patterns

## Definitions

```bash
# Find function definitions
rg -n "^pub fn \w+|^fn \w+" --type rust

# Find async function definitions
rg -n "^pub async fn \w+|^async fn \w+" --type rust

# Find struct definitions
rg -n "^pub struct \w+|^struct \w+" --type rust

# Find enum definitions
rg -n "^pub enum \w+|^enum \w+" --type rust

# Find trait definitions
rg -n "^pub trait \w+|^trait \w+" --type rust

# Find impl blocks
rg -n "^impl(<[^>]+>)? \w+" --type rust

# Find type aliases
rg -n "^pub type \w+|^type \w+" --type rust

# Find const definitions
rg -n "^pub const \w+|^const \w+" --type rust
```

## Usages

```bash
# Find use statements
rg -n "^use " --type rust

# Find specific crate usage
rg -n "use tokio::" --type rust

# Find all files using a crate
rg -l "use serde::" --type rust

# Find function calls
rg -n "function_name\(" --type rust
```

## Patterns

```bash
# Find derive macros
rg -n "#\[derive\(" --type rust

# Find attribute macros
rg -n "#\[(tokio::main|async_trait|test)\]" --type rust

# Find Result returns
rg -n "-> Result<" --type rust

# Find Option returns
rg -n "-> Option<" --type rust

# Find error handling
rg -n "\.unwrap\(\)|\.expect\(|\.ok\(\)|\?" --type rust

# Find unsafe blocks
rg -n "unsafe \{|unsafe fn" --type rust

# Find async/await
rg -n "\.await|async move" --type rust
```

## Entry Points

```bash
# Find main functions
rg -n "^fn main\(\)" --type rust
rg -n "^async fn main\(\)" --type rust

# Find lib.rs exports
rg -n "^pub mod|^pub use" lib.rs

# Find binary entry points
fd "main.rs"

# Find Actix/Axum routes
rg -n "\.route\(|\.get\(|\.post\(" --type rust

# Find CLI commands (clap)
rg -n "#\[command|#\[arg" --type rust
```

## Testing

```bash
# Find test functions
rg -n "#\[test\]" --type rust -A 1

# Find test modules
rg -n "^mod tests" --type rust

# Find async tests
rg -n "#\[tokio::test\]" --type rust

# Find integration tests
fd -p "tests/.*\.rs$"

# Find doc tests
rg -n "/// ```" --type rust
```

## Dependencies

```bash
# View Cargo.toml dependencies
rg "\[dependencies\]" Cargo.toml -A 30

# Find workspace members
rg "members = \[" Cargo.toml -A 10

# Find all Cargo.toml files
fd "Cargo.toml"
```
