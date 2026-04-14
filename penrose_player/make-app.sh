#!/bin/bash
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

swift build -c release

APP="$SCRIPT_DIR/PenroseTiling.app"
CONTENTS="$APP/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"

rm -rf "$APP"
mkdir -p "$MACOS" "$RESOURCES"

cp .build/release/PenroseTiling "$MACOS/"
cp Info.plist "$CONTENTS/"

# Bundle.module looks for PenroseTiling_PenroseTiling.bundle inside the .app bundle URL
cp -r .build/release/PenroseTiling_PenroseTiling.bundle "$RESOURCES/"

echo "Built: $APP"
echo "Run:   open \"$APP\""
