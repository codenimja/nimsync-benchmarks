# Benchmark Methodology

Standardized approach for measuring nimsync async runtime performance.

## Overview

All benchmarks follow rigorous methodology ensuring:
- **Reproducibility**: Consistent results across runs
- **Comparability**: Valid cross-runtime comparisons
- **Statistical Validity**: Meaningful performance metrics
- **Regression Detection**: Automated performance tracking

## Hardware Documentation

### Required Specifications

Every benchmark run must document:

```yaml
System:
  CPU:
    Model: AMD Ryzen 9 5950X
    Cores: 16 physical, 32 logical
    Base Clock: 3.4 GHz
    Boost Clock: 4.9 GHz
    Cache: L1=1MB, L2=8MB, L3=64MB
  
  Memory:
    Total: 64 GB
    Type: DDR4-3600
    Channels: Dual Channel
  
  Storage:
    Type: NVMe SSD
    Model: Samsung 980 Pro
  
  OS:
    Name: Ubuntu 22.04 LTS
    Kernel: 6.1.0-amd64
    Scheduler: CFS (Completely Fair Scheduler)

Compiler:
  Nim: 2.2.4
  GC: ORC
  Backend: C (GCC 11.4.0)
```

### Capture Script

Use `scripts/capture_hardware.sh`:

```bash
#!/bin/bash
echo "CPU: $(lscpu | grep 'Model name' | cut -d':' -f2 | xargs)"
echo "Cores: $(nproc)"
echo "RAM: $(free -h | grep Mem | awk '{print $2}')"
echo "Kernel: $(uname -r)"
echo "Nim: $(nim --version | head -1)"
```

## Compilation Configuration

### Standard Flags

All benchmarks compiled with:

```bash
nim c \
  -d:danger \           # Remove all runtime checks
  --opt:speed \         # Optimize for throughput
  --threads:on \        # Enable threading
  --mm:orc \           # ORC garbage collector
  --deepcopy:on \      # Enable deep copying
  --panics:on \        # Convert defects to exceptions
  --experimental:strictFuncs  # Stricter function semantics
```

### Rationale

- **`-d:danger`**: Removes bounds checks, overflow checks, nil checks for maximum performance
- **`--opt:speed`**: Prioritizes execution speed over binary size
- **`--threads:on`**: Required for concurrent benchmarks
- **`--mm:orc`**: Modern GC with predictable latency

### Verification

Check actual compilation command:

```bash
nim c --listCmd benchmark_spsc.nim
# Verify flags in output
```

## Statistical Methodology

### Measurement Protocol

1. **Warmup Phase**
   - Run 1,000 iterations (10% of total)
   - Discard results
   - Purpose: Stabilize CPU frequency, warm caches

2. **Measurement Phase**
   - Run 10,000 iterations minimum
   - Record individual timings
   - Capture memory metrics

3. **Cooldown Phase**
   - 100ms pause between benchmark types
   - Allow GC to complete
   - Reset state

### Statistical Analysis

Report multiple percentiles:

```nim
import std/algorithm

var timings: seq[float]
# ... collect timings ...

timings.sort()
let p50 = timings[timings.len div 2]      # Median
let p95 = timings[timings.len * 95 div 100]
let p99 = timings[timings.len * 99 div 100]
```

### Outlier Removal

Remove top/bottom 1%:

```nim
let trimmed = timings[timings.len div 100 .. timings.len * 99 div 100]
```

### Repeatability

Each benchmark runs **5 times independently**:

```bash
for i in 1 2 3 4 5; do
  nim c -r benchmark.nim > results_$i.txt
done
# Report median of 5 runs
```

## Benchmark Types

### Throughput Benchmarks

Measure operations per second:

```nim
import std/times

proc benchmarkThroughput() =
  const iterations = 100_000
  
  let start = cpuTime()
  
  for i in 0..<iterations:
    # Operation under test
    discard
  
  let elapsed = cpuTime() - start
  let opsPerSec = iterations.float / elapsed
  
  echo "Throughput: ", opsPerSec.formatFloat(ffDecimal, 0), " ops/sec"
```

### Latency Benchmarks

Measure individual operation time:

```nim
import std/times

proc benchmarkLatency() =
  var latencies: seq[float]
  
  for i in 0..<10_000:
    let start = cpuTime()
    
    # Single operation
    discard
    
    let elapsed = cpuTime() - start
    latencies.add(elapsed * 1_000_000)  # Convert to microseconds
  
  latencies.sort()
  echo "P50: ", latencies[latencies.len div 2].formatFloat(ffDecimal, 2), " µs"
  echo "P95: ", latencies[latencies.len * 95 div 100].formatFloat(ffDecimal, 2), " µs"
  echo "P99: ", latencies[latencies.len * 99 div 100].formatFloat(ffDecimal, 2), " µs"
```

### Memory Benchmarks

Track allocation patterns:

```nim
import std/[strutils, os]

proc getMemoryUsage(): int =
  # Linux-specific
  let statm = readFile("/proc/self/statm").splitWhitespace()
  result = parseInt(statm[1]) * 4096  # RSS in bytes

proc benchmarkMemory() =
  let before = getMemoryUsage()
  
  # Allocate structures
  var channels: seq[Channel[int]]
  for i in 0..<1000:
    channels.add(newChannel[int](1024))
  
  let after = getMemoryUsage()
  let perChannel = (after - before) div 1000
  
  echo "Memory per channel: ", perChannel, " bytes"
```

## Regression Detection

### Baseline Establishment

Store last 10 successful runs:

```bash
results/history/
├── baseline_1.txt
├── baseline_2.txt
...
└── baseline_10.txt
```

### Comparison Algorithm

```nim
proc checkRegression(current: float, baselines: seq[float]): bool =
  let avgBaseline = baselines.sum() / baselines.len.float
  let threshold = avgBaseline * 0.95  # 5% tolerance
  
  if current < threshold:
    echo "⚠️ REGRESSION: ", current, " vs avg ", avgBaseline
    return true
  
  return false
```

### CI Integration

```yaml
- name: Check regression
  run: |
    ./scripts/check_regression.sh
    if [ $? -ne 0 ]; then
      echo "::error::Performance regression detected"
      exit 1
    fi
```

## Cross-Runtime Comparison

### Fair Comparison Principles

1. **Equivalent Operations**: Same logical work
2. **Same Hardware**: Identical test environment
3. **Optimized Builds**: Maximum optimization for each runtime
4. **Multiple Runs**: Average of 5+ runs
5. **Document Differences**: Note implementation variations

### Example: Go Comparison

```go
// go_channel_bench.go
package main

import (
    "time"
)

func main() {
    const iterations = 100_000
    ch := make(chan int, 1024)
    
    start := time.Now()
    
    go func() {
        for i := 0; i < iterations; i++ {
            ch <- i
        }
        close(ch)
    }()
    
    for range ch {
        // Consume
    }
    
    elapsed := time.Since(start).Seconds()
    opsPerSec := float64(iterations) / elapsed
    println("Go channels:", int(opsPerSec), "ops/sec")
}
```

Compile with: `go build -o bench go_channel_bench.go`

### Comparison Table Format

```markdown
| Runtime | Throughput | Notes |
|---------|-----------|-------|
| nimsync | 213M ops/sec | Lock-free SPSC |
| Go | 45M ops/sec | Native channels |
| Tokio | 180M ops/sec | Rust crossbeam |
```

## Environment Setup

### Minimize Interference

**Disable CPU frequency scaling:**
```bash
sudo cpupower frequency-set --governor performance
```

**Stop background services:**
```bash
sudo systemctl stop cron
sudo systemctl stop unattended-upgrades
```

**Pin to specific cores:**
```bash
taskset -c 0-7 ./benchmark
```

**Disable NUMA balancing:**
```bash
echo 0 | sudo tee /proc/sys/kernel/numa_balancing
```

### Verification Checklist

Before running benchmarks:

- [ ] CPU governor set to `performance`
- [ ] No other CPU-intensive processes running
- [ ] Sufficient free RAM (>50% available)
- [ ] No swap usage
- [ ] Thermal throttling disabled
- [ ] Turbo boost enabled
- [ ] Network activity minimal

## Reporting Format

### Markdown Template

```markdown
# Benchmark Report: YYYY-MM-DD

## Environment

- **Hardware**: [CPU model], [RAM size]
- **OS**: [Distribution + Kernel version]
- **Nim**: [Version + GC]
- **Compilation**: `-d:danger --opt:speed --threads:on --mm:orc`

## Results

### SPSC Throughput

| Metric | Value |
|--------|-------|
| Throughput | 213,456,789 ops/sec |
| Latency (P50) | 4.7 ns |
| Latency (P95) | 12.3 ns |
| Latency (P99) | 45.6 ns |

### Analysis

- **vs Previous**: +2.3% improvement
- **vs Target**: 426% of 50M ops/sec goal
- **Anomalies**: None detected
```

## Best Practices

1. **Always document hardware**: Reproducibility requires context
2. **Run multiple iterations**: Single runs are unreliable
3. **Report percentiles**: Mean/average can be misleading
4. **Compare fairly**: Same work, same conditions
5. **Version everything**: Pin Nim version, dependencies
6. **Automate**: CI ensures consistency
7. **Track trends**: Historical data reveals patterns

## References

- [Nim Compiler Options](https://nim-lang.org/docs/nimc.html)
- [Linux perf Tutorial](https://perf.wiki.kernel.org/index.php/Tutorial)
- [Brendan Gregg's Performance Analysis](https://www.brendangregg.com/methodology.html)
- [Statistics for Benchmarking](https://www.cse.unsw.edu.au/~cs9242/current/papers/Fleming_Wallace_86.pdf)
