# Distributed Tracing

## OpenTelemetry Setup

```python
from opentelemetry import trace
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter

# Setup
provider = TracerProvider()
processor = BatchSpanProcessor(OTLPSpanExporter(endpoint="localhost:4317"))
provider.add_span_processor(processor)
trace.set_tracer_provider(provider)

tracer = trace.get_tracer(__name__)
```

## Creating Spans

```python
# Basic span
with tracer.start_as_current_span("process_order") as span:
    span.set_attribute("order_id", order_id)
    span.set_attribute("user_id", user_id)
    
    # Nested span
    with tracer.start_as_current_span("validate_order"):
        validate(order)
    
    with tracer.start_as_current_span("charge_payment"):
        charge(order)

# Add events
span.add_event("validation_complete", {"items": len(order.items)})

# Record exception
try:
    process()
except Exception as e:
    span.record_exception(e)
    span.set_status(Status(StatusCode.ERROR))
    raise
```

## Context Propagation

```python
from opentelemetry.propagate import inject, extract

# Inject into outgoing request
headers = {}
inject(headers)
requests.get(url, headers=headers)

# Extract from incoming request
context = extract(request.headers)
with tracer.start_as_current_span("handler", context=context):
    handle_request()
```

## Span Attributes

| Attribute | Example |
|-----------|---------|
| `http.method` | GET |
| `http.url` | /api/users |
| `http.status_code` | 200 |
| `db.system` | postgresql |
| `db.statement` | SELECT * FROM users |
| `rpc.service` | UserService |

## Sampling

```python
from opentelemetry.sdk.trace.sampling import TraceIdRatioBased

# Sample 10% of traces
sampler = TraceIdRatioBased(0.1)
provider = TracerProvider(sampler=sampler)
```

## Best Practices

- Propagate context across services
- Add meaningful attributes
- Use semantic conventions
- Sample appropriately in production
- Record exceptions with context
