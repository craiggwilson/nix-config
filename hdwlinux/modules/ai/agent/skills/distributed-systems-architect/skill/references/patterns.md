# Distributed Systems Patterns

## Circuit Breaker

```python
class CircuitBreaker:
    def __init__(self, failure_threshold=5, reset_timeout=60):
        self.failures = 0
        self.threshold = failure_threshold
        self.reset_timeout = reset_timeout
        self.state = "closed"
        self.last_failure = None
    
    def call(self, func):
        if self.state == "open":
            if time.time() - self.last_failure > self.reset_timeout:
                self.state = "half-open"
            else:
                raise CircuitOpenError()
        
        try:
            result = func()
            self.on_success()
            return result
        except Exception as e:
            self.on_failure()
            raise
```

## Saga Pattern

```python
class OrderSaga:
    def execute(self, order):
        try:
            self.reserve_inventory(order)
            self.charge_payment(order)
            self.ship_order(order)
        except PaymentError:
            self.release_inventory(order)  # Compensate
            raise
        except ShippingError:
            self.refund_payment(order)     # Compensate
            self.release_inventory(order)  # Compensate
            raise
```

## CQRS

```
Commands (Write)          Queries (Read)
     │                         │
     ▼                         ▼
┌─────────┐              ┌─────────┐
│ Command │              │  Query  │
│ Handler │              │ Handler │
└────┬────┘              └────┬────┘
     │                        │
     ▼                        ▼
┌─────────┐              ┌─────────┐
│  Write  │──events──▶   │  Read   │
│   DB    │              │   DB    │
└─────────┘              └─────────┘
```

## Event Sourcing

```python
class Account:
    def __init__(self):
        self.events = []
        self.balance = 0
    
    def deposit(self, amount):
        event = DepositEvent(amount=amount)
        self.apply(event)
        self.events.append(event)
    
    def apply(self, event):
        if isinstance(event, DepositEvent):
            self.balance += event.amount
```
