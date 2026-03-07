# Flink DataStream API

## Basic Operations

```java
DataStream<String> input = env.fromSource(source, watermarkStrategy, "source");

// Map
DataStream<Integer> lengths = input.map(String::length);

// Filter
DataStream<String> filtered = input.filter(s -> s.length() > 10);

// FlatMap
DataStream<String> words = input.flatMap((String line, Collector<String> out) -> {
    for (String word : line.split(" ")) {
        out.collect(word);
    }
});
```

## Keyed Streams

```java
DataStream<Event> events = ...;

KeyedStream<Event, String> keyed = events.keyBy(Event::getUserId);

// Reduce
DataStream<Event> reduced = keyed.reduce((e1, e2) -> 
    new Event(e1.getUserId(), e1.getValue() + e2.getValue()));
```

## Windowing

```java
// Tumbling window
keyed.window(TumblingEventTimeWindows.of(Time.minutes(5)))
     .sum("value");

// Sliding window
keyed.window(SlidingEventTimeWindows.of(Time.minutes(10), Time.minutes(5)))
     .sum("value");

// Session window
keyed.window(EventTimeSessionWindows.withGap(Time.minutes(30)))
     .sum("value");
```

## Joins

```java
// Window join
stream1.join(stream2)
    .where(e1 -> e1.key)
    .equalTo(e2 -> e2.key)
    .window(TumblingEventTimeWindows.of(Time.seconds(10)))
    .apply((e1, e2) -> new JoinedEvent(e1, e2));

// Interval join
stream1.keyBy(e -> e.key)
    .intervalJoin(stream2.keyBy(e -> e.key))
    .between(Time.minutes(-5), Time.minutes(5))
    .process(new ProcessJoinFunction<>() { ... });
```

## Side Outputs

```java
OutputTag<Event> lateTag = new OutputTag<>("late-events"){};

SingleOutputStreamOperator<Result> result = input
    .process(new ProcessFunction<>() {
        public void processElement(Event e, Context ctx, Collector<Result> out) {
            if (isLate(e)) {
                ctx.output(lateTag, e);
            } else {
                out.collect(process(e));
            }
        }
    });

DataStream<Event> lateEvents = result.getSideOutput(lateTag);
```
