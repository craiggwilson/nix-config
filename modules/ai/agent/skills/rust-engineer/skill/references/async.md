# Async Rust

## Tokio Basics

```rust
use tokio;

#[tokio::main]
async fn main() {
    let result = fetch_data().await;
    println!("{:?}", result);
}

async fn fetch_data() -> Result<String, reqwest::Error> {
    let response = reqwest::get("https://api.example.com/data").await?;
    let body = response.text().await?;
    Ok(body)
}
```

## Spawning Tasks

```rust
use tokio::task;

#[tokio::main]
async fn main() {
    // Spawn concurrent tasks
    let handle1 = task::spawn(async {
        fetch_users().await
    });
    
    let handle2 = task::spawn(async {
        fetch_orders().await
    });
    
    // Wait for both
    let (users, orders) = tokio::join!(handle1, handle2);
}

// Spawn blocking task (for CPU-bound work)
let result = task::spawn_blocking(|| {
    expensive_computation()
}).await?;
```

## Channels

```rust
use tokio::sync::mpsc;

#[tokio::main]
async fn main() {
    let (tx, mut rx) = mpsc::channel(100);
    
    // Producer
    tokio::spawn(async move {
        for i in 0..10 {
            tx.send(i).await.unwrap();
        }
    });
    
    // Consumer
    while let Some(value) = rx.recv().await {
        println!("Received: {}", value);
    }
}
```

## Select

```rust
use tokio::select;
use tokio::time::{sleep, Duration};

async fn with_timeout() -> Option<String> {
    select! {
        result = fetch_data() => Some(result),
        _ = sleep(Duration::from_secs(5)) => None,
    }
}
```

## Streams

```rust
use tokio_stream::StreamExt;

async fn process_stream() {
    let mut stream = tokio_stream::iter(vec![1, 2, 3, 4, 5]);
    
    while let Some(value) = stream.next().await {
        println!("Value: {}", value);
    }
}
```

## Error Handling

```rust
use anyhow::Result;

async fn fetch_and_process() -> Result<()> {
    let data = fetch_data().await?;
    let processed = process(data).await?;
    save(processed).await?;
    Ok(())
}
```

## Best Practices

- Don't block the async runtime
- Use `spawn_blocking` for CPU-bound work
- Prefer bounded channels
- Handle cancellation gracefully
- Use `select!` for timeouts
