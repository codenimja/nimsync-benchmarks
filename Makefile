.PHONY: bench report clean

bench:
	@echo "Running benchmarks..."
	@./scripts/run_all.sh > results/latest.txt

report: bench
	@echo "Generating report..."
	@nim c -r scripts/generate_report.nim > results/latest.md
	@cp results/latest.md results/history/$(shell date +%Y-%m-%d_%H%M%S).md
	@./scripts/make_badge.sh > results/badge.json

clean:
	rm -f results/latest.*
