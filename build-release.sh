#!/bin/bash
set -e

echo "========================================="
echo "Building Ghost Monitor Release (.app)..."
echo "========================================="

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="Ghost Monitor"
BUNDLE_DIR="$PROJECT_DIR/build/$APP_NAME.app"
CONTENTS_DIR="$BUNDLE_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

cd "$PROJECT_DIR"
swift build -c release

RELEASE_BIN="$PROJECT_DIR/.build/release/GhostMonitor"

if [ ! -f "$RELEASE_BIN" ]; then
    echo "Error: Release binary not found at $RELEASE_BIN"
    exit 1
fi

cp "$RELEASE_BIN" "$MACOS_DIR/$APP_NAME"

cat << 'EOF' > "$CONTENTS_DIR/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>Ghost Monitor</string>
    <key>CFBundleIdentifier</key>
    <string>com.ghostmonitor.mac</string>
    <key>CFBundleName</key>
    <string>Ghost Monitor</string>
    <key>CFBundleDisplayName</key>
    <string>Ghost Monitor</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>LSUIElement</key>
    <true/>
    <key>NSSpeechRecognitionUsageDescription</key>
    <string>Ghost Monitor uses Speech Recognition for JARVIS voice commands and hands-free wake word detection.</string>
    <key>NSMicrophoneUsageDescription</key>
    <string>Ghost Monitor uses the microphone for hands-free JARVIS voice activation and audio controls.</string>
</dict>
</plist>
EOF

chmod +x "$MACOS_DIR/$APP_NAME"
chmod +x "$PROJECT_DIR/build-release.sh"
chmod +x "$PROJECT_DIR/open-app.sh"

# Install to /Applications
SYS_APPS="/Applications"
if [ -w "$SYS_APPS" ]; then
    echo "Installing Ghost Monitor to $SYS_APPS..."
    rm -rf "$SYS_APPS/$APP_NAME.app"
    cp -R "$BUNDLE_DIR" "$SYS_APPS/"
    echo "Installed to $SYS_APPS/$APP_NAME.app"
fi

echo "========================================="
echo "Successfully built & installed Ghost Monitor!"
echo "Location: /Applications/$APP_NAME.app"
echo "========================================="
