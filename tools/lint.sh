#!/bin/sh
# SwiftLint, pinned. Downloads the portable binary into .tools/ on first use, locally and in CI.
set -eu
VERSION=0.65.1
cd "$(dirname "$0")/.."
BIN=".tools/swiftlint-$VERSION/swiftlint"
if [ ! -x "$BIN" ]; then
    mkdir -p ".tools/swiftlint-$VERSION"
    curl -fsSL -o .tools/swiftlint.zip \
        "https://github.com/realm/SwiftLint/releases/download/$VERSION/portable_swiftlint.zip"
    unzip -oq .tools/swiftlint.zip -d ".tools/swiftlint-$VERSION"
    rm .tools/swiftlint.zip
fi
"$BIN" lint --quiet --config .swiftlint.yml
