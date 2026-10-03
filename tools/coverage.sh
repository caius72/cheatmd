#!/bin/sh
# Fails when CheatCore region coverage drops below the floor. Run after
# `swift test --enable-code-coverage`. The floor only ever rises.
set -eu
COVERAGE_FLOOR=96
cd "$(dirname "$0")/../CheatCore"
python3 - "$(swift test --show-codecov-path)" "$PWD/Sources/" "$COVERAGE_FLOOR" <<'PY'
import json, sys
report, sources, floor = sys.argv[1], sys.argv[2], float(sys.argv[3])
files = [f for f in json.load(open(report))["data"][0]["files"] if f["filename"].startswith(sources)]
count = sum(f["summary"]["regions"]["count"] for f in files)
covered = sum(f["summary"]["regions"]["covered"] for f in files)
pct = 100.0 * covered / count if count else 0.0
print(f"coverage: {pct:.1f}% of {count} regions in {len(files)} files (floor {floor:.0f}%)")
sys.exit(0 if pct >= floor else 1)
PY
