.PHONY: all bench bench-all bench-core bench-stress bench-concurrent bench-integration report clean help

# Nim compilation flags for benchmarks
NIM_FLAGS = -d:danger --opt:speed --threads:on --mm:orc

# Default target
all: help

help:
	@echo "nimsync Benchmark Suite"
	@echo ""
	@echo "Targets:"
	@echo "  bench-all         - Run complete benchmark suite"
	@echo "  bench-core        - Core performance benchmarks"
	@echo "  bench-stress      - Stress and endurance tests"
	@echo "  bench-concurrent  - Concurrency limit tests"
	@echo "  bench-integration - Integration scenarios"
	@echo "  report            - Generate performance report"
	@echo "  clean             - Remove build artifacts"
	@echo "  verify-env        - Check benchmark environment"
	@echo ""

# Run all benchmarks
bench-all: bench-core bench-stress bench-concurrent bench-integration

# Core performance benchmarks
bench-core:
	@echo "Running core benchmarks..."
	@cd benchmarks && nim c -r $(NIM_FLAGS) benchmark_spsc.nim
	@cd benchmarks && nim c -r $(NIM_FLAGS) benchmark_select.nim
	@cd benchmarks && nim c -r $(NIM_FLAGS) benchmark_stress.nim

# Stress testing
bench-stress:
	@echo "Running stress tests..."
	@cd stress && for f in *.nim; do \
		echo "Testing: $$f"; \
		nim c -r $(NIM_FLAGS) $$f || true; \
	done

# Concurrent access benchmarks
bench-concurrent:
	@echo "Running concurrency tests..."
	@cd performance && for f in *.nim; do \
		nim c -r $(NIM_FLAGS) $$f || true; \
	done

# Integration scenarios
bench-integration:
	@echo "Running integration tests..."
	@cd integration && for f in *.nim; do \
		nim c -r $(NIM_FLAGS) $$f || true; \
	done

# Traditional bench target (kept for compatibility)
bench: bench-core
	@echo "Running benchmarks..."
	@mkdir -p results
	@./scripts/run_all.sh > results/latest.txt 2>&1 || true

# Generate comprehensive report
report: bench
	@echo "Generating report..."
	@mkdir -p results/history
	@if [ -f scripts/generate_report.nim ]; then \
		nim c -r scripts/generate_report.nim > results/latest.md; \
	else \
		cp results/latest.txt results/latest.md; \
	fi
	@cp results/latest.md results/history/$(shell date +%Y-%m-%d_%H%M%S).md
	@if [ -f scripts/make_badge.sh ]; then \
		./scripts/make_badge.sh > results/badge.json; \
	fi
	@echo "Report saved to results/latest.md"

# Verify benchmark environment
verify-env:
	@echo "Checking benchmark environment..."
	@echo "CPU Governor: $$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || echo 'N/A')"
	@echo "CPU Cores: $$(nproc)"
	@echo "Free Memory: $$(free -h | grep Mem | awk '{print $$4}')"
	@echo "Nim Version: $$(nim --version | head -1)"
	@echo "Swap Usage: $$(free -h | grep Swap | awk '{print $$3}')"
	@if [ "$$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null)" != "performance" ]; then \
		echo "⚠️  WARNING: CPU not in performance mode"; \
		echo "   Run: sudo cpupower frequency-set --governor performance"; \
	fi

# Clean build artifacts and temporary files
clean:
	@echo "Cleaning..."
	@rm -f results/latest.*
	@find . -name "*.o" -delete
	@find . -name "nimcache" -type d -exec rm -rf {} + 2>/dev/null || true
	@find benchmarks -type f -executable -delete 2>/dev/null || true
	@find stress -type f -executable -delete 2>/dev/null || true
	@find integration -type f -executable -delete 2>/dev/null || true
	@echo "Clean complete"

# Quick SPSC benchmark only
quick:
	@nim c -r $(NIM_FLAGS) benchmarks/benchmark_spsc.nim
