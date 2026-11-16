#!/bin/bash
set -e

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="YouTube"
APP_BUNDLE="$PROJECT_DIR/$APP_NAME.app"
CONTENTS_DIR="$APP_BUNDLE/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

echo "=== Building $APP_NAME.app ==="

# 1. Clean previous build
rm -rf "$APP_BUNDLE"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

# 2. Generate Icon if needed
if [ ! -f "$PROJECT_DIR/AppIcon.icns" ]; then
    echo "-> Generating icon..."
    ICONSET_DIR="$PROJECT_DIR/AppIcon.iconset"
    rm -rf "$ICONSET_DIR"
    mkdir -p "$ICONSET_DIR"

    swift "$PROJECT_DIR/generate_icon.swift" "$PROJECT_DIR/icon_1024.png"

    sips -z 16 16     "$PROJECT_DIR/icon_1024.png" --out "$ICONSET_DIR/icon_16x16.png" > /dev/null
    sips -z 32 32     "$PROJECT_DIR/icon_1024.png" --out "$ICONSET_DIR/icon_16x16@2x.png" > /dev/null
    sips -z 32 32     "$PROJECT_DIR/icon_1024.png" --out "$ICONSET_DIR/icon_32x32.png" > /dev/null
    sips -z 64 64     "$PROJECT_DIR/icon_1024.png" --out "$ICONSET_DIR/icon_32x32@2x.png" > /dev/null
    sips -z 128 128   "$PROJECT_DIR/icon_1024.png" --out "$ICONSET_DIR/icon_128x128.png" > /dev/null
    sips -z 256 256   "$PROJECT_DIR/icon_1024.png" --out "$ICONSET_DIR/icon_128x128@2x.png" > /dev/null
    sips -z 256 256   "$PROJECT_DIR/icon_1024.png" --out "$ICONSET_DIR/icon_256x256.png" > /dev/null
    sips -z 512 512   "$PROJECT_DIR/icon_1024.png" --out "$ICONSET_DIR/icon_256x256@2x.png" > /dev/null
    sips -z 512 512   "$PROJECT_DIR/icon_1024.png" --out "$ICONSET_DIR/icon_512x512.png" > /dev/null
    sips -z 1024 1024 "$PROJECT_DIR/icon_1024.png" --out "$ICONSET_DIR/icon_512x512@2x.png" > /dev/null

    iconutil -c icns "$ICONSET_DIR" -o "$PROJECT_DIR/AppIcon.icns"
    rm -rf "$ICONSET_DIR" "$PROJECT_DIR/icon_1024.png"
fi
cp "$PROJECT_DIR/AppIcon.icns" "$RESOURCES_DIR/AppIcon.icns"

# 3. Copy Info.plist
echo "-> Copying Info.plist..."
cp "$PROJECT_DIR/Info.plist" "$CONTENTS_DIR/Info.plist"

# 4. Compile Swift Binary
echo "-> Compiling Swift binary..."
swiftc -O \
    -target arm64-apple-macosx12.0 \
    -framework Cocoa \
    -framework WebKit \
    "$PROJECT_DIR/Sources/main.swift" \
    -o "$MACOS_DIR/$APP_NAME"

# 5. Ad-hoc Codesign
echo "-> Signing App Bundle..."
codesign --force --deep --sign - "$APP_BUNDLE"

echo "=== Build Complete: $APP_BUNDLE ==="
