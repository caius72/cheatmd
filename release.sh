#!/bin/sh
# Build, notarize and publish a release: GitHub release with the stapled cheatmd.app zip, then
# update the Homebrew cask in the tap checkout (CHEATMD_TAP_DIR, default ~/repos/homebrew-cheatmd).
# Bump VERSION through a pull request first; releases come from main.
set -eu
cd "$(dirname "$0")"
VERSION="$(cat VERSION)"
TAP="${CHEATMD_TAP_DIR:-$HOME/repos/homebrew-cheatmd}"
CASK="$TAP/Casks/cheatmd.rb"
[ -f "$CASK" ] || { echo "Tap checkout not found at $TAP (set CHEATMD_TAP_DIR)"; exit 1; }
[ -z "$(git status --porcelain)" ] || { echo "Commit or stash changes before releasing"; exit 1; }
[ "$(git rev-parse --abbrev-ref HEAD)" = main ] || { echo "Release from main"; exit 1; }
xcrun notarytool history --keychain-profile "${CHEATMD_NOTARY_PROFILE:-zen-notary}" >/dev/null 2>&1 \
    || { echo "Notarization profile missing or rejected; releases must be notarized"; exit 1; }
./build.sh
APP="$PWD/build/Release/cheatmd.app"
ZIP="$PWD/build/cheatmd-$VERSION.zip"
spctl --assess --type execute "$APP"
xcrun stapler validate "$APP" >/dev/null
rm -f "$ZIP" && ditto -c -k --keepParent "$APP" "$ZIP"
SHA="$(shasum -a 256 "$ZIP" | cut -d' ' -f1)"
# A version is released once: an existing tag must already point here (a re-run after a failure).
git tag "v$VERSION" 2>/dev/null || [ "$(git rev-list -n 1 "v$VERSION")" = "$(git rev-parse HEAD)" ] \
    || { echo "v$VERSION is tagged elsewhere; bump VERSION"; exit 1; }
git push -q origin "v$VERSION"
gh release create "v$VERSION" "$ZIP" --title "cheatmd $VERSION" \
    --notes "Notarized cheatmd.app for macOS 26 and later on Apple Silicon. Install with: brew install --cask caius72/cheatmd/cheatmd" \
    || gh release upload "v$VERSION" "$ZIP" --clobber
sed -i '' -e "s/^  version \".*\"/  version \"$VERSION\"/" -e "s/^  sha256 \".*\"/  sha256 \"$SHA\"/" "$CASK"
git -C "$TAP" add Casks/cheatmd.rb
git -C "$TAP" commit -q -m "cheatmd $VERSION" && git -C "$TAP" push -q origin main
echo "Released v$VERSION ($SHA); cask updated in $TAP"
