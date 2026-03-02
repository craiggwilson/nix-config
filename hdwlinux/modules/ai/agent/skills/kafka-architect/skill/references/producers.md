# Kafka Producers

## Basic Producer

```java
Properties props = new Properties();
props.put("bootstrap.servers", "localhost:9092");
props.put("key.serializer", StringSerializer.class);
props.put("value.serializer", StringSerializer.class);

KafkaProducer<String, String> producer = new KafkaProducer<>(props);

ProducerRecord<String, String> record = 
    new ProducerRecord<>("topic", "key", "value");

producer.send(record, (metadata, exception) -> {
    if (exception != null) {
        logger.error("Send failed", exception);
    } else {
        logger.info("Sent to partition {} offset {}", 
            metadata.partition(), metadata.offset());
    }
});

producer.close();
```

## Key Configuration

| Config | Description | Recommended |
|--------|-------------|-------------|
| `acks` | Durability level | `all` for durability |
| `retries` | Retry count | `Integer.MAX_VALUE` |
| `enable.idempotence` | Exactly-once | `true` |
| `compression.type` | Compression | `lz4` or `zstd` |
| `batch.size` | Batch bytes | `16384` (16KB) |
| `linger.ms` | Batch wait time | `5-100` |

## Idempotent Producer

```java
props.put("enable.idempotence", true);
props.put("acks", "all");
props.put("retries", Integer.MAX_VALUE);
props.put("max.in.flight.requests.per.connection", 5);
```

## Transactional Producer

```java
props.put("transactional.id", "my-transactional-id");

producer.initTransactions();

try {
    producer.beginTransaction();
    producer.send(record1);
    producer.send(record2);
    producer.commitTransaction();
} catch (Exception e) {
    producer.abortTransaction();
}
```

## Partitioning

```java
// Default: hash(key) % numPartitions
// Custom partitioner:
public class CustomPartitioner implements Partitioner {
    public int partition(String topic, Object key, byte[] keyBytes,
                        Object value, byte[] valueBytes, Cluster cluster) {
        // Custom logic
        return partitionNumber;
    }
}
```

## Best Practices

- Always use keys for ordering guarantees
- Enable idempotence for exactly-once
- Use compression for throughput
- Handle send failures with callbacks
- Close producer gracefully
