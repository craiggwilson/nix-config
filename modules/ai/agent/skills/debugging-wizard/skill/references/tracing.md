# Distributed Tracing

## Concepts

| Term | Definition |
|------|------------|
| Trace | End-to-end request journey |
| Span | Single operation within a trace |
| Context | Propagated trace information |
| Correlation ID | Unique request identifier |

## OpenTelemetry

```python
from opentelemetry import trace

tracer = trace.get_tracer(__name__)

with tracer.start_as_current_span("process_order") as span:
    span.set_attribute("order_id", order_id)
    span.set_attribute("user_id", user_id)
    
    # Nested span
    with tracer.start_as_current_span("validate_order"):
        validate(order)
    
    with tracer.start_as_current_span("charge_payment"):
        charge(order)
```

## Context Propagation

```python
# HTTP headers
headers = {
    "traceparent": "00-trace_id-span_id-01",
    "tracestate": "vendor=value"
}

# Extract in receiving service
context = extract(request.headers)
with tracer.start_as_current_span("handler", context=context):
    process_request()
```

## Correlation IDs

```python
import uuid

def middleware(request, next):
    correlation_id = request.headers.get(
        "X-Correlation-ID", 
        str(uuid.uuid4())
    )
    
    # Add to logging context
    logger = logger.bind(correlation_id=correlation_id)
    
    response = next(request)
    response.headers["X-Correlation-ID"] = correlation_id
    return response
```

## Debugging with Traces

1. Find trace by correlation ID
2. View span timeline
3. Identify slow spans
4. Check span attributes for context
5. Look for errors in spans
