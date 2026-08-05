#!/bin/bash
set -e

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
SYS_APP="/Applications/Ghost Monitor.app"
LOCAL_APP="$PROJECT_DIR/build/Ghost Monitor.app"

if [ -d "$SYS_APP" ]; then
    echo "Launching Ghost Monitor from /Applications..."
    open "$SYS_APP"
elif [ -d "$LOCAL_APP" ]; then
    echo "Launching Ghost Monitor from local build..."
    open "$LOCAL_APP"
else
    echo "Release bundle not found. Building and installing application first..."
    bash "$PROJECT_DIR/build-release.sh"
    open "/Applications/Ghost Monitor.app"
fi
