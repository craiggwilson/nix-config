# Kafka Consumers

## Basic Consumer

```java
Properties props = new Properties();
props.put("bootstrap.servers", "localhost:9092");
props.put("group.id", "my-consumer-group");
props.put("key.deserializer", StringDeserializer.class);
props.put("value.deserializer", StringDeserializer.class);

KafkaConsumer<String, String> consumer = new KafkaConsumer<>(props);
consumer.subscribe(Arrays.asList("topic"));

while (true) {
    ConsumerRecords<String, String> records = consumer.poll(Duration.ofMillis(100));
    for (ConsumerRecord<String, String> record : records) {
        process(record);
    }
    consumer.commitSync();
}
```

## Key Configuration

| Config | Description | Recommended |
|--------|-------------|-------------|
| `group.id` | Consumer group | Required |
| `auto.offset.reset` | Start position | `earliest` or `latest` |
| `enable.auto.commit` | Auto commit | `false` for control |
| `max.poll.records` | Records per poll | `500` |
| `session.timeout.ms` | Heartbeat timeout | `45000` |

## Offset Management

```java
// Manual commit
props.put("enable.auto.commit", false);

// Commit after processing
for (ConsumerRecord<String, String> record : records) {
    process(record);
}
consumer.commitSync();

// Commit specific offsets
Map<TopicPartition, OffsetAndMetadata> offsets = new HashMap<>();
offsets.put(new TopicPartition("topic", 0), 
    new OffsetAndMetadata(lastOffset + 1));
consumer.commitSync(offsets);
```

## Consumer Groups

```
Topic: orders (3 partitions)

Consumer Group: order-processors
├── Consumer 1 → Partition 0
├── Consumer 2 → Partition 1
└── Consumer 3 → Partition 2
```

## Rebalancing

```java
consumer.subscribe(topics, new ConsumerRebalanceListener() {
    public void onPartitionsRevoked(Collection<TopicPartition> partitions) {
        consumer.commitSync();  // Commit before losing partitions
    }
    
    public void onPartitionsAssigned(Collection<TopicPartition> partitions) {
        // Initialize state for new partitions
    }
});
```

## Best Practices

- Use consumer groups for scaling
- Commit offsets after processing
- Handle rebalancing gracefully
- Set appropriate poll timeout
- Process records idempotently
