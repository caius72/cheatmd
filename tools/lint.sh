#!/bin/sh
# SwiftLint, pinned. Downloads the portable binary into .tools/ on first use, locally and in CI.
set -eu
VERSION=0.65.1
# SHA-256 of portable_swiftlint.zip for VERSION; upstream publishes none, so pinned on first download.
SHA256=c1e429b0599cf1b516f369a2d9ec04eaf0e436f3c12b637df8851fa52ff694d0
cd "$(dirname "$0")/.."
BIN=".tools/swiftlint-$VERSION/swiftlint"
if [ ! -x "$BIN" ]; then
    mkdir -p ".tools/swiftlint-$VERSION"
    curl -fsSL -o .tools/swiftlint.zip \
        "https://github.com/realm/SwiftLint/releases/download/$VERSION/portable_swiftlint.zip"
    echo "$SHA256  .tools/swiftlint.zip" | shasum -a 256 -c -
    unzip -oq .tools/swiftlint.zip -d ".tools/swiftlint-$VERSION"
    rm .tools/swiftlint.zip
fi
"$BIN" lint --quiet --config .swiftlint.yml
