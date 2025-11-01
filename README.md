# nimsync Benchmarks

[![Benchmark CI](https://github.com/codenimja/nimsync-benchmarks/actions/workflows/benchmark.yml/badge.svg)](https://github.com/codenimja/nimsync-benchmarks/actions/workflows/benchmark.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

**Continuous performance validation suite for [nimsync](https://github.com/codenimja/nimsync) async runtime**

> Comprehensive benchmarking infrastructure measuring throughput, latency, concurrency limits, and stress test capabilities with automated regression detection.

## Performance Summary

Latest validated benchmarks on Linux x86_64 with Nim 2.2.4:

| **Benchmark** | **Current** | **Target** | **Status** |
|--------------|------------|------------|------------|
| **SPSC Throughput** | **213M ops/sec** | 50M ops/sec | ✓ **426%** |
| **Task Spawn Latency** | **< 100ns** | < 1µs | ✓ **10x faster** |
| **Memory per Channel** | **< 1KB** | < 10KB | ✓ **Memory efficient** |
| **Concurrent Access** | **31M ops/sec** | 10M ops/sec | ✓ **310%** |
| **GC Pauses** | **< 2ms** | < 10ms | ✓ **Low latency** |

## Benchmark Categories

### Core Performance (`benchmarks/`)
Foundational async runtime operations:

- **SPSC Channels** (`benchmark_spsc.nim`): Single-producer single-consumer throughput testing
- **Channel Select** (`benchmark_select.nim`): Multi-channel selection performance
- **Task Spawning**: Scheduler latency and task creation overhead
- **Memory Efficiency**: Allocation patterns and ORC GC pressure analysis

### Stress Testing (`stress/`)
Extreme load and endurance validation:

- **Concurrent Access**: 10 channels × 10K operations simultaneous load
- **Backpressure Avalanche**: Buffer overflow and flow control behavior
- **Producer/Consumer Contention**: High-contention scenarios
- **IO-Bound Simulation**: Network-like workload patterns
- **Endurance Tests**: 24-hour continuous operation validation

### Integration Testing (`integration/`)
Real-world usage patterns:

- **TaskGroup Operations**: Structured concurrency at scale
- **Actor Supervision**: Fault tolerance and recovery
- **Stream Processing**: Backpressure-aware data pipelines

### Scenarios (`scenarios/`)
Application-specific workload simulations:

- **Web Server**: HTTP request handling patterns
- **Message Queue**: Broker-like message routing
- **Data Processing**: ETL pipeline simulations

## Quick Start

### Run All Benchmarks

```bash
# Complete benchmark suite
make bench-all

# Generate performance report
make report

# View latest results
cat results/latest.md
```

### Individual Benchmark Suites

```bash
# Core performance benchmarks
make bench-core

# Stress testing only
make bench-stress

# Concurrency limits
make bench-concurrent

# Integration scenarios
make bench-integration
```

### Specific Benchmarks

```bash
# SPSC channel throughput
nim c -r -d:danger --opt:speed --threads:on benchmarks/benchmark_spsc.nim

# Channel select performance
nim c -r -d:danger --opt:speed --threads:on benchmarks/benchmark_select.nim

# Full stress test suite
cd stress && make stress-all
```

## Benchmark Methodology

### Hardware Specification

All benchmarks documented with:
- **CPU**: Architecture, core count, frequency
- **Memory**: Total RAM, allocation limits
- **OS**: Linux kernel version, scheduler
- **Nim Version**: Compiler version and GC mode

Example:
```
CPU: AMD Ryzen 9 5950X (16 cores @ 3.4GHz)
RAM: 64GB DDR4-3600
OS: Linux 6.1.0 (Ubuntu 22.04)
Nim: 2.2.4 (ORC GC)
```

### Compilation Flags

Consistent optimization across all benchmarks:

```bash
-d:danger          # Maximum optimization, no checks
--opt:speed        # Optimize for throughput
--threads:on       # Enable threading
--mm:orc           # ORC garbage collector
```

### Statistical Rigor

- **Iterations**: Minimum 10,000 operations per benchmark
- **Warmup**: 1,000 iterations before measurement
- **Percentiles**: Report 50th, 95th, 99th percentiles
- **Outliers**: Remove top/bottom 1% for stable results
- **Repeatability**: Each benchmark runs 5 times, median reported

### Regression Detection

Automated performance regression checks:
- **Threshold**: 5% degradation triggers warning
- **Baseline**: Compare against last 10 runs
- **CI Integration**: Fails PR if regression > 10%

## Results & Visualization

### Historical Trends

Performance trends over time stored in `results/history/`:

```
results/history/
├── 2025-11-01_120000.md
├── 2025-10-31_120000.md
└── 2025-10-30_120000.md
```

### Latest Report

Current benchmark results: [`results/latest.md`](results/latest.md)

### Comparative Analysis

Cross-runtime performance comparison:
- **Go channels**: Baseline comparison
- **Chronos only**: nimsync overhead measurement
- **Tokio (Rust)**: Industry standard reference

## Project Structure

```
nimsync-benchmarks/
├── benchmarks/           # Core performance benchmarks
│   ├── benchmark_spsc.nim
│   ├── benchmark_select.nim
│   ├── benchmark_stress.nim
│   └── metrics.nim       # Performance measurement utilities
├── stress/              # Extreme load testing
│   ├── concurrent_access.nim
│   ├── backpressure_avalanche.nim
│   └── endurance_24h.nim
├── integration/         # Real-world scenario tests
│   ├── taskgroup_scale.nim
│   ├── actor_supervision.nim
│   └── stream_pipeline.nim
├── scenarios/           # Application workload simulations
│   ├── web_server.nim
│   ├── message_queue.nim
│   └── data_pipeline.nim
├── scripts/             # Automation and reporting
│   ├── run_all.sh
│   ├── generate_report.nim
│   ├── make_badge.sh
│   └── check_regression.sh
└── results/             # Benchmark outputs
    ├── latest.md        # Most recent results
    ├── badge.json       # Performance badge data
    └── history/         # Historical trend data
```

## CI/CD Integration

### GitHub Actions

Automated benchmarking on:
- **Push to master**: Full benchmark suite
- **Pull Requests**: Core benchmarks only
- **Nightly**: Complete stress tests + trends

See: [`.github/workflows/benchmark.yml`](.github/workflows/benchmark.yml)

### Performance Badges

Dynamic badges showing current performance:

```markdown
![SPSC Throughput](https://img.shields.io/badge/SPSC-213M%20ops/sec-success)
![Task Spawn](https://img.shields.io/badge/Task%20Spawn-<100ns-success)
```

## Adding New Benchmarks

### 1. Create Benchmark File

```nim
# benchmarks/benchmark_new_feature.nim
import nimsync
import std/times

proc benchmarkNewFeature() =
  const iterations = 10_000
  
  let start = cpuTime()
  for i in 0..<iterations:
    # Your benchmark code
    discard
  
  let elapsed = cpuTime() - start
  let opsPerSec = iterations.float / elapsed
  
  echo "New Feature: ", opsPerSec.int, " ops/sec"

when isMainModule:
  benchmarkNewFeature()
```

### 2. Add to Makefile

```makefile
bench-new:
	nim c -r -d:danger --opt:speed benchmarks/benchmark_new_feature.nim
```

### 3. Update Documentation

Add benchmark description to this README and `benchmarks/README.md`

## Troubleshooting

### Low Performance Results

**Check compilation flags:**
```bash
nim c --listCmd yourfile.nim
# Should show: -d:danger --opt:speed --threads:on --mm:orc
```

**Verify CPU governor:**
```bash
cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
# Should be "performance" not "powersave"
```

**Disable CPU frequency scaling:**
```bash
sudo cpupower frequency-set --governor performance
```

### Inconsistent Results

- **System load**: Close other applications
- **Thermal throttling**: Monitor CPU temperature
- **Background tasks**: Stop cron jobs, system updates
- **Swap usage**: Ensure sufficient RAM

## Contributing

Contributions welcome! Please ensure:

1. **Benchmarks are reproducible**: Document hardware and environment
2. **Follow naming conventions**: `benchmark_<feature>.nim`
3. **Add documentation**: Explain what the benchmark measures
4. **Include baselines**: Compare against previous results
5. **CI passes**: All regression checks must pass

See [CONTRIBUTING.md](https://github.com/codenimja/nimsync/blob/main/docs/CONTRIBUTING.md) in main repository.

## License

MIT License - see [LICENSE](LICENSE) for details.

Part of the [nimsync](https://github.com/codenimja/nimsync) project.

---

**Links**: [nimsync](https://github.com/codenimja/nimsync) • [Issues](https://github.com/codenimja/nimsync-benchmarks/issues) • [Latest Results](results/latest.md)