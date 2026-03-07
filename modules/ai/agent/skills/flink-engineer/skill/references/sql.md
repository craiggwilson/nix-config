# Flink SQL & Table API

## Table Environment

```java
StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();
StreamTableEnvironment tableEnv = StreamTableEnvironment.create(env);
```

## Creating Tables

```sql
-- From Kafka
CREATE TABLE orders (
    order_id STRING,
    user_id STRING,
    amount DECIMAL(10, 2),
    order_time TIMESTAMP(3),
    WATERMARK FOR order_time AS order_time - INTERVAL '5' SECOND
) WITH (
    'connector' = 'kafka',
    'topic' = 'orders',
    'properties.bootstrap.servers' = 'localhost:9092',
    'format' = 'json'
);

-- From DataStream
Table table = tableEnv.fromDataStream(stream);
```

## Queries

```sql
-- Aggregation
SELECT user_id, SUM(amount) as total
FROM orders
GROUP BY user_id;

-- Windowed aggregation
SELECT 
    user_id,
    TUMBLE_START(order_time, INTERVAL '1' HOUR) as window_start,
    SUM(amount) as total
FROM orders
GROUP BY user_id, TUMBLE(order_time, INTERVAL '1' HOUR);

-- Join
SELECT o.order_id, u.name, o.amount
FROM orders o
JOIN users u ON o.user_id = u.user_id;
```

## Window Functions

```sql
-- Tumbling window
TUMBLE(time_col, INTERVAL '10' MINUTE)

-- Sliding window
HOP(time_col, INTERVAL '5' MINUTE, INTERVAL '10' MINUTE)

-- Session window
SESSION(time_col, INTERVAL '30' MINUTE)
```

## Output to Sink

```sql
CREATE TABLE output (
    user_id STRING,
    total DECIMAL(10, 2)
) WITH (
    'connector' = 'jdbc',
    'url' = 'jdbc:postgresql://localhost:5432/db',
    'table-name' = 'user_totals'
);

INSERT INTO output
SELECT user_id, SUM(amount)
FROM orders
GROUP BY user_id;
```
