#!/bin/sh
# Every gate, in CI order. CI runs exactly this script.
set -eux
cd "$(dirname "$0")/.."
python3 tools/check_traceability.py Requirements_Specification.md tests/Test_Plan.md CheatCore/Tests
swift format lint --strict --recursive CheatCore/Package.swift CheatCore/Sources CheatCore/Tests cheatmd
tools/lint.sh
swift test --package-path CheatCore --enable-code-coverage
tools/coverage.sh
swift test --package-path CheatCore -c release --filter Performance
xcodebuild -project cheatmd.xcodeproj -scheme cheatmd -destination 'platform=macOS,arch=arm64' -quiet build \
    CODE_SIGNING_ALLOWED=NO
