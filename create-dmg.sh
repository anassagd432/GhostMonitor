#!/usr/bin/env bash
set -e

echo "=== Ghost Monitor DMG Packaging Pipeline ==="

PROJECT_DIR="/Users/anassagdi/Documents/GitHub/simple/GhostMonitor"
WEB_DIR="/Users/anassagdi/Documents/GitHub/GhostMonitor-Web"
BUILD_DIR="${PROJECT_DIR}/.build/release"
STAGING_DIR="${PROJECT_DIR}/.dmg_staging"
APP_NAME="Ghost Monitor.app"
DMG_NAME="GhostMonitor-Installer.dmg"

cd "${PROJECT_DIR}"

echo "1. Building Release Binary..."
./build-release.sh

echo "2. Preparing DMG Staging Environment..."
rm -rf "${STAGING_DIR}"
mkdir -p "${STAGING_DIR}"

echo "3. Copying App Bundle to Staging..."
cp -R "/Applications/${APP_NAME}" "${STAGING_DIR}/${APP_NAME}"

echo "4. Creating Applications Link..."
ln -s /Applications "${STAGING_DIR}/Applications"

echo "5. Generating DMG Image..."
rm -f "${PROJECT_DIR}/${DMG_NAME}"
hdiutil create -volname "Ghost Monitor Installer" \
    -srcfolder "${STAGING_DIR}" \
    -ov -format UDZO \
    "${PROJECT_DIR}/${DMG_NAME}"

echo "6. Exporting to Web Downloads Folder..."
mkdir -p "${WEB_DIR}/downloads"
cp "${PROJECT_DIR}/${DMG_NAME}" "${WEB_DIR}/downloads/${DMG_NAME}"

echo "7. Calculating Security Checksum (SHA-256)..."
SHA256=$(shasum -a 256 "${PROJECT_DIR}/${DMG_NAME}" | awk '{print $1}')

echo ""
echo "=========================================="
echo " SUCCESS! Release Installer Generated"
echo " Installer DMG: ${PROJECT_DIR}/${DMG_NAME}"
echo " Web Download:  ${WEB_DIR}/downloads/${DMG_NAME}"
echo " SHA-256 Hash:  ${SHA256}"
echo "=========================================="
