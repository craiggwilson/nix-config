# Profiling

## CPU Profiling

### Go
```go
import "runtime/pprof"

f, _ := os.Create("cpu.prof")
pprof.StartCPUProfile(f)
defer pprof.StopCPUProfile()

// Run code to profile

// Analyze
// go tool pprof cpu.prof
```

### Python
```python
import cProfile
import pstats

profiler = cProfile.Profile()
profiler.enable()

# Run code to profile

profiler.disable()
stats = pstats.Stats(profiler)
stats.sort_stats('cumulative')
stats.print_stats(20)
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
    # Code to profile
    pass
```

## Flame Graphs

```bash
# Generate flame graph
perf record -g ./myapp
perf script | stackcollapse-perf.pl | flamegraph.pl > flame.svg
```

## Key Metrics

| Metric | Tool |
|--------|------|
| CPU time | pprof, perf |
| Memory allocation | pprof, valgrind |
| I/O wait | iostat, strace |
| Network | tcpdump, wireshark |

## Profiling Tips

- Profile in production-like environment
- Use realistic data volumes
- Profile hot paths first
- Compare before/after
- Look for unexpected allocations
