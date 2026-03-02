# Property-Based Testing

## Hypothesis (Python)

```python
from hypothesis import given, strategies as st

@given(st.integers(), st.integers())
def test_addition_commutative(a, b):
    assert a + b == b + a

@given(st.lists(st.integers()))
def test_sort_idempotent(lst):
    assert sorted(sorted(lst)) == sorted(lst)

@given(st.text())
def test_encode_decode_roundtrip(s):
    assert s.encode('utf-8').decode('utf-8') == s
```

## Custom Strategies

```python
from hypothesis import given, strategies as st
from dataclasses import dataclass

@dataclass
class User:
    name: str
    age: int
    email: str

user_strategy = st.builds(
    User,
    name=st.text(min_size=1, max_size=50),
    age=st.integers(min_value=0, max_value=150),
    email=st.emails()
)

@given(user_strategy)
def test_user_serialization(user):
    serialized = user.to_json()
    deserialized = User.from_json(serialized)
    assert deserialized == user
```

## fast-check (TypeScript)

```typescript
import fc from 'fast-check';

test('sort is idempotent', () => {
  fc.assert(
    fc.property(fc.array(fc.integer()), (arr) => {
      const sorted = [...arr].sort((a, b) => a - b);
      const sortedTwice = [...sorted].sort((a, b) => a - b);
      return JSON.stringify(sorted) === JSON.stringify(sortedTwice);
    })
  );
});

test('JSON roundtrip', () => {
  fc.assert(
    fc.property(fc.jsonValue(), (value) => {
      const roundtrip = JSON.parse(JSON.stringify(value));
      return JSON.stringify(roundtrip) === JSON.stringify(value);
    })
  );
});
```

## Common Properties

| Property | Description |
|----------|-------------|
| Roundtrip | encode(decode(x)) == x |
| Idempotent | f(f(x)) == f(x) |
| Commutative | f(a, b) == f(b, a) |
| Associative | f(f(a, b), c) == f(a, f(b, c)) |
| Invariant | property holds for all inputs |

## When to Use

- Serialization/deserialization
- Parsers
- Data transformations
- Mathematical operations
- State machines
- API contracts

## Shrinking

```python
# Hypothesis automatically shrinks failing cases
@given(st.lists(st.integers()))
def test_no_duplicates(lst):
    # If this fails, Hypothesis finds minimal example
    assert len(lst) == len(set(lst))

# Might report: [0, 0] as minimal failing case
```
