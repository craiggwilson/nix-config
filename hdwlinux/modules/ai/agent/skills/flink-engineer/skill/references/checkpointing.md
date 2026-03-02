# Flink Checkpointing

## Configuration

```java
StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();

// Enable checkpointing every 10 seconds
env.enableCheckpointing(10000);

// Exactly-once semantics
env.getCheckpointConfig().setCheckpointingMode(CheckpointingMode.EXACTLY_ONCE);

// Minimum time between checkpoints
env.getCheckpointConfig().setMinPauseBetweenCheckpoints(5000);

// Timeout
env.getCheckpointConfig().setCheckpointTimeout(60000);

// Max concurrent checkpoints
env.getCheckpointConfig().setMaxConcurrentCheckpoints(1);

// Tolerate failures
env.getCheckpointConfig().setTolerableCheckpointFailureNumber(3);
```

## Checkpoint Storage

```java
// FileSystem (for production)
env.getCheckpointConfig().setCheckpointStorage("s3://bucket/checkpoints");

// RocksDB incremental checkpoints
env.setStateBackend(new EmbeddedRocksDBStateBackend(true));
```

## Savepoints

```bash
# Trigger savepoint
flink savepoint <jobId> s3://bucket/savepoints

# Cancel with savepoint
flink cancel -s s3://bucket/savepoints <jobId>

# Resume from savepoint
flink run -s s3://bucket/savepoints/savepoint-xxx app.jar
```

## Unaligned Checkpoints

```java
// For high backpressure scenarios
env.getCheckpointConfig().enableUnalignedCheckpoints();
```

## Recovery

| Scenario | Behavior |
|----------|----------|
| Task failure | Restart from last checkpoint |
| Job restart | Resume from savepoint |
| Cluster failure | Recover from checkpoint storage |

## Best Practices

- Use incremental checkpoints for large state
- Store checkpoints in durable storage (S3, HDFS)
- Monitor checkpoint duration
- Set appropriate intervals (balance latency vs overhead)
- Always take savepoint before upgrades
