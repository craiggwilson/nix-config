# Service Communication

## Synchronous vs Asynchronous

| Sync (HTTP/gRPC) | Async (Messaging) |
|------------------|-------------------|
| Simple to implement | Decoupled services |
| Immediate response | Better resilience |
| Tight coupling | Eventually consistent |
| Cascading failures | Complex debugging |

## Request-Response (Sync)

```
┌─────────┐  request   ┌─────────┐
│ Service │───────────▶│ Service │
│    A    │◀───────────│    B    │
└─────────┘  response  └─────────┘
```

## Event-Driven (Async)

```
┌─────────┐  publish   ┌─────────┐  consume  ┌─────────┐
│ Service │───────────▶│  Event  │◀──────────│ Service │
│    A    │            │  Broker │           │    B    │
└─────────┘            └─────────┘           └─────────┘
```

## Message Patterns

### Point-to-Point
- One producer, one consumer
- Work queue pattern
- Load balancing

### Publish-Subscribe
- One producer, many consumers
- Event broadcasting
- Decoupled consumers

### Request-Reply
- Async request with correlation
- Temporary reply queue
- Timeout handling

## API Gateway

```
┌──────────┐
│  Client  │
└────┬─────┘
     │
┌────▼─────┐
│   API    │
│ Gateway  │
└────┬─────┘
     │
┌────┴────┬────────┬────────┐
▼         ▼        ▼        ▼
Service  Service  Service  Service
   A        B        C        D
```

## Service Mesh

- Sidecar proxy per service
- mTLS between services
- Traffic management
- Observability built-in
