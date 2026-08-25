#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

TEAM_ID=3U2U533484
APP_CERT="Apple Distribution: LEE SINSEONG ($TEAM_ID)"
PKG_CERT="3rd Party Mac Developer Installer: LEE SINSEONG ($TEAM_ID)"

swift build -c release

APP=MarkView.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources/renderer"
cp Info.plist "$APP/Contents/"
cp Credits.rtf "$APP/Contents/Resources/"
cp AppIcon.icns "$APP/Contents/Resources/"
cp embedded.provisionprofile "$APP/Contents/"
cp .build/release/MarkView "$APP/Contents/MacOS/MarkView"
cp resources/renderer/* "$APP/Contents/Resources/renderer/"

codesign --force --entitlements MarkView.entitlements --sign "$APP_CERT" "$APP"
codesign --verify --deep --strict "$APP"

VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" Info.plist)
PKG="MarkView-$VERSION.pkg"
rm -f "$PKG"
productbuild --component "$APP" /Applications --sign "$PKG_CERT" "$PKG"

echo "Built $PWD/$PKG"
