# Contributing to nimsync Benchmarks

Guidelines for adding and improving performance benchmarks.

## Adding New Benchmarks

### 1. Choose Appropriate Category

Place benchmark in correct directory:

- **`benchmarks/`**: Core runtime operations (channels, tasks, scheduler)
- **`stress/`**: Extreme load, endurance, resource exhaustion
- **`integration/`**: Real-world usage patterns
- **`scenarios/`**: Application-specific workloads

### 2. File Naming Convention

Use descriptive names with `benchmark_` prefix:

```
benchmark_<feature>_<aspect>.nim
```

Examples:
- `benchmark_spsc_throughput.nim`
- `benchmark_taskgroup_spawn.nim`
- `stress_concurrent_channels.nim`

### 3. Benchmark Template

```nim
## Benchmark: <Feature Name>
##
## Measures: <What this benchmark tests>
## Expected: <Target performance>
## Hardware: <Recommended specs>

import nimsync
import std/[times, strformat]

const
  ITERATIONS = 100_000  # Adjust based on operation cost
  WARMUP = 1_000

proc warmup() =
  ## Stabilize CPU frequency and warm caches
  for i in 0..<WARMUP:
    # Simplified version of benchmark operation
    discard

proc benchmark() =
  ## Main benchmark implementation
  var timings: seq[float]
  
  for run in 0..<5:  # 5 independent runs
    let start = cpuTime()
    
    for i in 0..<ITERATIONS:
      # Operation under test
      discard
    
    let elapsed = cpuTime() - start
    timings.add(elapsed)
  
  # Calculate metrics
  timings.sort()
  let medianTime = timings[2]  # Middle of 5 runs
  let opsPerSec = ITERATIONS.float / medianTime
  
  # Report results
  echo &"Throughput: {opsPerSec:.0f} ops/sec"
  echo &"Latency: {medianTime * 1_000_000 / ITERATIONS.float:.2f} ns/op"

when isMainModule:
  echo "## Benchmark: <Feature Name>"
  echo "Iterations: ", ITERATIONS
  warmup()
  benchmark()
```

### 4. Documentation Requirements

Each benchmark must include:

**Header comment:**
```nim
## Benchmark: SPSC Channel Throughput
##
## Measures: Single-producer single-consumer channel performance
## Expected: >50M ops/sec on modern hardware
## Hardware: 4+ cores, 8GB+ RAM recommended
##
## Methodology:
## - Producer sends integers 0..N
## - Consumer receives and validates
## - Measures total throughput
##
## Compilation:
##   nim c -r -d:danger --opt:speed --threads:on benchmark_spsc.nim
```

**README entry:**
Update `benchmarks/README.md` with:
```markdown
### SPSC Channel Throughput

**File**: `benchmark_spsc.nim`
**Category**: Core Performance
**Target**: 50M+ ops/sec

Measures single-producer single-consumer channel throughput using
1024-slot buffer with integer payloads.
```

### 5. Add to Makefile

Update `Makefile` with new target:

```makefile
bench-spsc:
	nim c -r $(NIM_FLAGS) benchmarks/benchmark_spsc.nim
```

## Benchmark Quality Standards

### Accuracy

✅ **Do:**
- Use `cpuTime()` for CPU-bound operations
- Use `getMonoTime()` for wall-clock time
- Run multiple iterations (10K minimum)
- Report median of multiple runs
- Remove warmup iterations

❌ **Don't:**
- Use `epochTime()` (system clock can drift)
- Single-shot measurements
- Include compilation time
- Mix CPU and wall-clock time

### Fairness

✅ **Do:**
- Document all compilation flags
- Use same optimization level across comparisons
- Test equivalent operations
- Run on same hardware
- Account for GC pauses

❌ **Don't:**
- Compare different optimization levels
- Cherry-pick best results
- Compare different operation types
- Ignore environmental factors

### Reproducibility

✅ **Do:**
- Document hardware specifications
- Pin Nim version
- Specify OS and kernel
- List dependencies
- Provide seed values for random data

❌ **Don't:**
- Assume "works on my machine"
- Use undocumented configuration
- Rely on environment variables
- Skip version information

## Performance Targets

### Core Benchmarks

| Benchmark | Target | Excellent | World-Class |
|-----------|--------|-----------|-------------|
| SPSC Throughput | 50M ops/sec | 100M | 200M+ |
| Task Spawn | < 1µs | < 500ns | < 100ns |
| Memory/Channel | < 10KB | < 5KB | < 1KB |
| GC Pause | < 10ms | < 5ms | < 2ms |

### Stress Tests

| Test | Pass Criteria |
|------|---------------|
| 24h Endurance | No crashes, stable performance |
| Concurrent Access | Linear scaling to 8 cores |
| Memory Pressure | Graceful degradation at 90% RAM |
| Backpressure | Fair scheduling under load |

## Regression Testing

### Setting Baselines

After validating new benchmark:

```bash
# Run 10 times to establish baseline
for i in {1..10}; do
  make bench-spsc >> results/baseline_spsc.txt
done

# Calculate average
./scripts/calculate_baseline.sh results/baseline_spsc.txt
```

### Automated Checks

Benchmarks should fail CI if:
- Performance drops >10% vs baseline
- Memory usage increases >20%
- New errors or warnings appear
- Test fails to complete

## Cross-Runtime Comparisons

When comparing nimsync to other runtimes:

### Requirements

1. **Equivalent Work**: Same logical operations
2. **Fair Compilation**: Maximum optimization for each runtime
3. **Same Hardware**: Identical test environment
4. **Multiple Runs**: Average of 5+ runs
5. **Document Differences**: Note implementation variations

### Example: Go Comparison

**Nim version:**
```nim
# benchmark_nim_channel.nim
import nimsync

proc benchNimChannel() =
  const N = 100_000
  let ch = newChannel[int](1024)
  
  spawn:
    for i in 0..<N:
      await ch.send(i)
  
  spawn:
    for i in 0..<N:
      discard await ch.recv()
```

**Go version:**
```go
// benchmark_go_channel.go
package main

func benchGoChannel() {
    const N = 100000
    ch := make(chan int, 1024)
    
    go func() {
        for i := 0; i < N; i++ {
            ch <- i
        }
        close(ch)
    }()
    
    for range ch {
        // Consume
    }
}
```

**Comparison Notes:**
```markdown
### Implementation Differences
- Nim: SPSC lock-free channel
- Go: MPMC channel with mutex
- Both: 1024 slot buffer
- Payload: Integer (64-bit)

### Compilation
- Nim: -d:danger --opt:speed --mm:orc
- Go: go build -ldflags="-s -w"

### Results
| Runtime | Throughput | Notes |
|---------|-----------|-------|
| nimsync | 213M ops/sec | Lock-free |
| Go | 45M ops/sec | Native |
```

## Code Review Checklist

Before submitting benchmark PR:

- [ ] Follows naming convention
- [ ] Includes header documentation
- [ ] Added to appropriate category
- [ ] Updated Makefile
- [ ] Updated README
- [ ] Compilation flags documented
- [ ] Multiple runs for statistical validity
- [ ] Results reproducible
- [ ] No debug output in measurements
- [ ] Cleaned up commented code
- [ ] CI passes

## Common Pitfalls

### Issue: Unrealistic Performance

**Symptom**: Benchmark shows impossibly high numbers (e.g., 1B+ ops/sec for I/O)

**Cause**: Compiler optimized away the actual work

**Fix**: Use result or mark operation as side-effect
```nim
var dummy: int
for i in 0..<N:
  dummy = someOperation()  # Force evaluation
```

### Issue: Inconsistent Results

**Symptom**: Performance varies wildly between runs

**Cause**: CPU frequency scaling, thermal throttling, background processes

**Fix**: 
```bash
sudo cpupower frequency-set --governor performance
sudo systemctl stop cron
make verify-env
```

### Issue: GC Skewing Results

**Symptom**: Periodic slowdowns in benchmark

**Cause**: GC collection during timing

**Fix**: Force GC before measurement
```nim
GC_fullCollect()
let start = cpuTime()
# benchmark code
```

## Getting Help

- **Questions**: [GitHub Discussions](https://github.com/codenimja/nimsync/discussions)
- **Issues**: [GitHub Issues](https://github.com/codenimja/nimsync-benchmarks/issues)
- **Methodology**: See [METHODOLOGY.md](METHODOLOGY.md)

## References

- [Nim Performance Tips](https://nim-lang.org/docs/tut3.html)
- [Statistics for Benchmarking](https://www.cse.unsw.edu.au/~cs9242/current/papers/Fleming_Wallace_86.pdf)
- [Brendan Gregg's Methodology](https://www.brendangregg.com/methodology.html)
