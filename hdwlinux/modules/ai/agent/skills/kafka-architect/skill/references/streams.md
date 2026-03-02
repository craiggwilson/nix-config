# Kafka Streams

## Basic Topology

```java
StreamsBuilder builder = new StreamsBuilder();

KStream<String, String> source = builder.stream("input-topic");

source
    .filter((key, value) -> value.length() > 5)
    .mapValues(value -> value.toUpperCase())
    .to("output-topic");

KafkaStreams streams = new KafkaStreams(builder.build(), props);
streams.start();
```

## KStream vs KTable

| KStream | KTable |
|---------|--------|
| Event stream | Changelog |
| All events | Latest per key |
| Unbounded | Compacted |

```java
// KStream - all events
KStream<String, Order> orders = builder.stream("orders");

// KTable - latest state per key
KTable<String, User> users = builder.table("users");
```

## Aggregations

```java
// Count per key
KTable<String, Long> counts = stream
    .groupByKey()
    .count();

// Windowed aggregation
KTable<Windowed<String>, Long> windowedCounts = stream
    .groupByKey()
    .windowedBy(TimeWindows.ofSizeWithNoGrace(Duration.ofMinutes(5)))
    .count();

// Custom aggregation
KTable<String, Stats> stats = stream
    .groupByKey()
    .aggregate(
        Stats::new,
        (key, value, aggregate) -> aggregate.add(value),
        Materialized.with(Serdes.String(), statsSerde)
    );
```

## Joins

```java
// Stream-Table join (enrichment)
KStream<String, EnrichedOrder> enriched = orders.join(
    users,
    (order, user) -> new EnrichedOrder(order, user)
);

// Stream-Stream join (windowed)
KStream<String, Combined> combined = stream1.join(
    stream2,
    (v1, v2) -> new Combined(v1, v2),
    JoinWindows.ofTimeDifferenceWithNoGrace(Duration.ofMinutes(5))
);
```

## State Stores

```java
// Queryable state store
StoreBuilder<KeyValueStore<String, Long>> storeBuilder =
    Stores.keyValueStoreBuilder(
        Stores.persistentKeyValueStore("my-store"),
        Serdes.String(),
        Serdes.Long()
    );

builder.addStateStore(storeBuilder);

// Query from outside
ReadOnlyKeyValueStore<String, Long> store =
    streams.store(StoreQueryParameters.fromNameAndType(
        "my-store", QueryableStoreTypes.keyValueStore()));
```
