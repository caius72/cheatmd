#!/bin/sh
# Renders docs/icon.svg (the scalable source) into the app icon set. Needs rsvg-convert
# (brew install librsvg). Run after editing the SVG.
set -eu
cd "$(dirname "$0")/.."
SET=cheatmd/Assets.xcassets/AppIcon.appiconset
for size in 16 32 128 256 512; do
    rsvg-convert -w "$size" -h "$size" docs/icon.svg -o "$SET/icon_${size}.png"
    rsvg-convert -w "$((size * 2))" -h "$((size * 2))" docs/icon.svg -o "$SET/icon_${size}@2x.png"
done
