# Profiling

## CPU Profiling

### Go
```go
import (
    "os"
    "runtime/pprof"
)

f, _ := os.Create("cpu.prof")
pprof.StartCPUProfile(f)
defer pprof.StopCPUProfile()

// Run workload

// Analyze
// go tool pprof -http=:8080 cpu.prof
```

### Python
```python
import cProfile
import pstats

# Profile function
cProfile.run('my_function()', 'output.prof')

# Analyze
stats = pstats.Stats('output.prof')
stats.sort_stats('cumulative')
stats.print_stats(20)

# Or use py-spy for production
# py-spy record -o profile.svg -- python myapp.py
```

### Node.js
```javascript
// Start with --inspect
// node --inspect app.js

// Or use clinic
// clinic doctor -- node app.js
```

## Memory Profiling

### Go
```go
import "runtime/pprof"

f, _ := os.Create("mem.prof")
pprof.WriteHeapProfile(f)

// go tool pprof mem.prof
```

### Python
```python
from memory_profiler import profile

@profile
def my_function():
    data = [i for i in range(1000000)]
    return data

# Or use tracemalloc
import tracemalloc
tracemalloc.start()
# ... code ...
snapshot = tracemalloc.take_snapshot()
top_stats = snapshot.statistics('lineno')
```

## Flame Graphs

```bash
# Linux perf
perf record -g ./myapp
perf script | stackcollapse-perf.pl | flamegraph.pl > flame.svg

# Go
go tool pprof -http=:8080 cpu.prof
# Click "Flame Graph"

# Python with py-spy
py-spy record -o flame.svg -- python myapp.py
```

## Continuous Profiling

- Datadog Continuous Profiler
- Pyroscope
- Google Cloud Profiler
- Parca

## What to Look For

| Issue | Indicator |
|-------|-----------|
| Hot function | Wide bar in flame graph |
| Memory leak | Growing heap over time |
| GC pressure | High GC time |
| Lock contention | Blocked goroutines/threads |
