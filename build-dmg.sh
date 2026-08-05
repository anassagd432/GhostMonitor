#!/bin/bash
set -e

APP_NAME="Ghost Monitor"
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_BUNDLE="$PROJECT_DIR/build/$APP_NAME.app"
DMG_NAME="GhostMonitor.dmg"
DMG_PATH="$PROJECT_DIR/build/$DMG_NAME"

if [ ! -d "$APP_BUNDLE" ]; then
    echo "Error: App bundle not found at $APP_BUNDLE. Please run ./build-release.sh first."
    exit 1
fi

echo "Creating DMG Installer for $APP_NAME..."

# Create a temporary staging directory
STAGING_DIR="$PROJECT_DIR/build/dmg_staging"
rm -rf "$STAGING_DIR"
mkdir -p "$STAGING_DIR"

# Copy the app to the staging directory
cp -R "$APP_BUNDLE" "$STAGING_DIR/"

# Create a symlink to Applications
ln -s /Applications "$STAGING_DIR/Applications"

# Remove existing DMG if it exists
rm -f "$DMG_PATH"

# Create the DMG using hdiutil
hdiutil create -volname "Ghost Monitor Installer" -srcfolder "$STAGING_DIR" -ov -format UDZO "$DMG_PATH"

rm -rf "$STAGING_DIR"

echo "========================================="
echo "Successfully created Ghost Monitor Installer!"
echo "Location: $DMG_PATH"
echo "========================================="
