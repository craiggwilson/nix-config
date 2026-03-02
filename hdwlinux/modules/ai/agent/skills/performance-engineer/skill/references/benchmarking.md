# Benchmarking

## Microbenchmarks

### Go
```go
func BenchmarkProcess(b *testing.B) {
    data := generateTestData()
    b.ResetTimer()
    
    for i := 0; i < b.N; i++ {
        Process(data)
    }
}

// Run: go test -bench=. -benchmem
```

### Python
```python
import timeit

# Simple timing
result = timeit.timeit(
    'my_function()',
    setup='from __main__ import my_function',
    number=1000
)

# With pytest-benchmark
def test_benchmark(benchmark):
    result = benchmark(my_function, arg1, arg2)
    assert result is not None
```

### JavaScript
```javascript
// Using benchmark.js
const Benchmark = require('benchmark');

const suite = new Benchmark.Suite();
suite
  .add('Method A', () => methodA())
  .add('Method B', () => methodB())
  .on('complete', function() {
    console.log('Fastest is ' + this.filter('fastest').map('name'));
  })
  .run();
```

## Load Testing

### k6
```javascript
import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  stages: [
    { duration: '1m', target: 100 },  // Ramp up
    { duration: '5m', target: 100 },  // Stay
    { duration: '1m', target: 0 },    // Ramp down
  ],
  thresholds: {
    http_req_duration: ['p(95)<500'],
    http_req_failed: ['rate<0.01'],
  },
};

export default function() {
  const res = http.get('http://api.example.com/users');
  check(res, { 'status is 200': (r) => r.status === 200 });
  sleep(1);
}
```

### wrk
```bash
wrk -t12 -c400 -d30s http://localhost:8080/api
```

## Metrics to Measure

| Metric | Description |
|--------|-------------|
| Throughput | Requests/second |
| Latency p50 | Median response time |
| Latency p95 | 95th percentile |
| Latency p99 | 99th percentile |
| Error rate | Failed requests % |

## Best Practices

- Warm up before measuring
- Run multiple iterations
- Measure in production-like environment
- Compare against baseline
- Document test conditions
