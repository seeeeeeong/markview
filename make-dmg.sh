#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

./make-app.sh

VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" Info.plist)
DMG="MarkView-$VERSION.dmg"
STAGE=$(mktemp -d)

cp -R MarkView.app "$STAGE/"
ln -s /Applications "$STAGE/Applications"
rm -f "$DMG"
hdiutil create -volname "MarkView" -srcfolder "$STAGE" -ov -format UDZO "$DMG" >/dev/null
rm -rf "$STAGE"

echo "Built $PWD/$DMG"
