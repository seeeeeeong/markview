#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

swift build -c release

APP=MarkView.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources/renderer"
cp Info.plist "$APP/Contents/"
cp .build/release/MarkView "$APP/Contents/MacOS/MarkView"
cp resources/renderer/* "$APP/Contents/Resources/renderer/"
codesign --force --sign - "$APP" 2>/dev/null || true

echo "Built $PWD/$APP"
