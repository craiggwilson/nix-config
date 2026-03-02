# Metrics

## Metric Types

| Type | Use Case | Example |
|------|----------|---------|
| Counter | Cumulative count | Requests total |
| Gauge | Current value | Temperature |
| Histogram | Distribution | Request duration |
| Summary | Percentiles | Response time |

## RED Method (Services)

- **R**ate - Requests per second
- **E**rrors - Failed requests per second
- **D**uration - Request latency

```promql
# Rate
rate(http_requests_total[5m])

# Errors
rate(http_requests_total{status=~"5.."}[5m])

# Duration (p99)
histogram_quantile(0.99, rate(http_request_duration_seconds_bucket[5m]))
```

## USE Method (Resources)

- **U**tilization - % time busy
- **S**aturation - Queue depth
- **E**rrors - Error count

```promql
# CPU Utilization
1 - avg(rate(node_cpu_seconds_total{mode="idle"}[5m]))

# Memory Saturation
node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes
```

## Prometheus Instrumentation

```python
from prometheus_client import Counter, Histogram, Gauge

# Counter
requests_total = Counter(
    'http_requests_total',
    'Total HTTP requests',
    ['method', 'endpoint', 'status']
)
requests_total.labels(method='GET', endpoint='/api', status='200').inc()

# Histogram
request_duration = Histogram(
    'http_request_duration_seconds',
    'Request duration',
    ['endpoint'],
    buckets=[0.01, 0.05, 0.1, 0.5, 1.0, 5.0]
)
with request_duration.labels(endpoint='/api').time():
    process_request()

# Gauge
active_connections = Gauge('active_connections', 'Active connections')
active_connections.inc()
active_connections.dec()
```

## Cardinality

```python
# Bad - high cardinality
requests.labels(user_id=user_id)  # Millions of users

# Good - bounded cardinality
requests.labels(endpoint=endpoint, method=method)
```
