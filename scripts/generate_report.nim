echo report
import std/[strformat, strutils, times]
let raw = readFile("results/latest.txt")
let lines = raw.splitLines()
var report = &"# nimsync-benchmarks\n\n**{now().format(\"yyyy-MM-dd HH:mm:ss\")}**\n\n"

for line in lines:
  if "ops/sec" in line or "Completed" in line or "Peak" in line:
    report.add(&"- {line.strip()}\n")

report.add("\n[Full History](./results/history)\n")
echo report
