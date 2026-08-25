#!/bin/bash
# Builds MdLens.app into the project root.
set -euo pipefail
cd "$(dirname "$0")"

swift build -c release

APP=MdLens.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources/renderer"
cp Info.plist "$APP/Contents/"
cp .build/release/MdLens "$APP/Contents/MacOS/MdLens"
cp resources/renderer/* "$APP/Contents/Resources/renderer/"
codesign --force --sign - "$APP" 2>/dev/null || true

echo "Built $PWD/$APP"
