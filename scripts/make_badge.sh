#!/usr/bin/env bash
OPS=$(grep -o '[0-9.]\+ ops/sec' results/latest.txt | head -1 | cut -d' ' -f1)
echo "{\"schemaVersion\":1,\"label\":\"SPSC\",\"message\":\"${OPS} ops/sec\",\"color\":\"brightgreen\"}" > results/badge.json
