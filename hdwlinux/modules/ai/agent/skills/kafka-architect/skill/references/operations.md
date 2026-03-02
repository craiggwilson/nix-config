# Kafka Operations

## Topic Management

```bash
# Create topic
kafka-topics.sh --create \
  --bootstrap-server localhost:9092 \
  --topic my-topic \
  --partitions 12 \
  --replication-factor 3

# List topics
kafka-topics.sh --list --bootstrap-server localhost:9092

# Describe topic
kafka-topics.sh --describe \
  --bootstrap-server localhost:9092 \
  --topic my-topic

# Alter partitions
kafka-topics.sh --alter \
  --bootstrap-server localhost:9092 \
  --topic my-topic \
  --partitions 24
```

## Consumer Groups

```bash
# List groups
kafka-consumer-groups.sh --list \
  --bootstrap-server localhost:9092

# Describe group (show lag)
kafka-consumer-groups.sh --describe \
  --bootstrap-server localhost:9092 \
  --group my-group

# Reset offsets
kafka-consumer-groups.sh --reset-offsets \
  --bootstrap-server localhost:9092 \
  --group my-group \
  --topic my-topic \
  --to-earliest \
  --execute
```

## Monitoring Metrics

| Metric | Description |
|--------|-------------|
| `UnderReplicatedPartitions` | Partitions below replication factor |
| `OfflinePartitionsCount` | Unavailable partitions |
| `ConsumerLag` | Messages behind |
| `BytesInPerSec` | Throughput |
| `RequestsPerSec` | Request rate |

## Performance Tuning

### Broker
```properties
num.io.threads=8
num.network.threads=3
socket.send.buffer.bytes=102400
socket.receive.buffer.bytes=102400
```

### Producer
```properties
batch.size=32768
linger.ms=5
compression.type=lz4
buffer.memory=67108864
```

### Consumer
```properties
fetch.min.bytes=1024
fetch.max.wait.ms=500
max.poll.records=500
```

## Disaster Recovery

- Cross-datacenter replication (MirrorMaker 2)
- Regular backup of consumer offsets
- Monitor under-replicated partitions
- Test failover procedures
