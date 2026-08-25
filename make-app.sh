#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

swift build -c release

APP=MarkView.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources/renderer" "$APP/Contents/Resources/skins"
cp Info.plist "$APP/Contents/"
cp Credits.rtf "$APP/Contents/Resources/"
cp AppIcon.icns "$APP/Contents/Resources/"
cp .build/release/MarkView "$APP/Contents/MacOS/MarkView"
cp resources/renderer/* "$APP/Contents/Resources/renderer/"
cp resources/skins/* "$APP/Contents/Resources/skins/"
codesign --force --sign - "$APP" 2>/dev/null || true

echo "Built $PWD/$APP"
