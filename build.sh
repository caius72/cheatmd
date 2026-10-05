#!/bin/sh
# Build cheatmd.app for release: Developer ID signed, hardened runtime, notarized and stapled
# when a notarytool keychain profile exists. Output: build/Release/cheatmd.app
# Notary credentials are the team's App Store Connect API key, stored once with
#   xcrun notarytool store-credentials <profile> --key <AuthKey.p8> --key-id <ID> --issuer <UUID>
# (zen stored it as zen-notary; same team, so it is the default here.)
set -eu
cd "$(dirname "$0")"
VERSION="$(cat VERSION)"
xcodebuild -project cheatmd.xcodeproj -scheme cheatmd -configuration Release \
    -destination 'platform=macOS,arch=arm64' \
    SYMROOT="$PWD/build" \
    DEVELOPMENT_TEAM="${CHEATMD_TEAM:-8TJQFP35F5}" \
    CODE_SIGN_IDENTITY="${CHEATMD_SIGN_IDENTITY:-Developer ID Application}" \
    CODE_SIGN_STYLE=Manual \
    ENABLE_HARDENED_RUNTIME=YES \
    OTHER_CODE_SIGN_FLAGS=--timestamp \
    CODE_SIGN_INJECT_BASE_ENTITLEMENTS=NO \
    MARKETING_VERSION="$VERSION" \
    CURRENT_PROJECT_VERSION="$(git rev-list --count HEAD)" \
    -quiet build
APP="$PWD/build/Release/cheatmd.app"
codesign --verify --deep --strict "$APP"
PROFILE="${CHEATMD_NOTARY_PROFILE:-zen-notary}"
if xcrun notarytool history --keychain-profile "$PROFILE" >/dev/null 2>&1; then
    ditto -c -k --keepParent "$APP" "$PWD/build/cheatmd-notarize.zip"
    xcrun notarytool submit "$PWD/build/cheatmd-notarize.zip" --keychain-profile "$PROFILE" --wait
    xcrun stapler staple "$APP"
    echo "Signed, notarized and stapled: $APP"
else
    echo "Signed but NOT notarized: notarytool profile '$PROFILE' is missing or rejected."
    xcrun notarytool history --keychain-profile "$PROFILE" 2>&1 | tail -1
fi
# Unregister the build copy so `open -a cheatmd` (a hotkey's usual command) launches the
# installed /Applications/cheatmd.app, not this one.
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -u "$APP" || true
