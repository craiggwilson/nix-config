# Flink State Management

## State Types

### ValueState
```java
public class CountFunction extends RichFlatMapFunction<Event, Result> {
    private ValueState<Long> count;
    
    @Override
    public void open(Configuration config) {
        ValueStateDescriptor<Long> descriptor = 
            new ValueStateDescriptor<>("count", Long.class);
        count = getRuntimeContext().getState(descriptor);
    }
    
    @Override
    public void flatMap(Event event, Collector<Result> out) throws Exception {
        Long current = count.value();
        if (current == null) current = 0L;
        count.update(current + 1);
        out.collect(new Result(event.key, current + 1));
    }
}
```

### ListState
```java
ListStateDescriptor<Event> descriptor = 
    new ListStateDescriptor<>("events", Event.class);
ListState<Event> events = getRuntimeContext().getListState(descriptor);

events.add(newEvent);
for (Event e : events.get()) { ... }
```

### MapState
```java
MapStateDescriptor<String, Long> descriptor = 
    new MapStateDescriptor<>("counts", String.class, Long.class);
MapState<String, Long> counts = getRuntimeContext().getMapState(descriptor);

counts.put(key, value);
Long value = counts.get(key);
```

## State Backends

| Backend | Use Case |
|---------|----------|
| HashMapStateBackend | Small state, fast |
| EmbeddedRocksDBStateBackend | Large state, disk-based |

```java
env.setStateBackend(new EmbeddedRocksDBStateBackend());
```

## State TTL

```java
StateTtlConfig ttlConfig = StateTtlConfig
    .newBuilder(Time.hours(24))
    .setUpdateType(StateTtlConfig.UpdateType.OnCreateAndWrite)
    .setStateVisibility(StateTtlConfig.StateVisibility.NeverReturnExpired)
    .build();

ValueStateDescriptor<Long> descriptor = 
    new ValueStateDescriptor<>("count", Long.class);
descriptor.enableTimeToLive(ttlConfig);
```

## Queryable State

```java
// Make state queryable
descriptor.setQueryable("my-queryable-state");

// Query from external client
QueryableStateClient client = new QueryableStateClient(host, port);
CompletableFuture<ValueState<Long>> future = 
    client.getKvState(jobId, "my-queryable-state", key, ...);
```
