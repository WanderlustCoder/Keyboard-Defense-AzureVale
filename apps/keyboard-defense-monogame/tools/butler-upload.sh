#!/usr/bin/env bash
# Upload Keyboard Defense builds to itch.io using butler.
# Prerequisites: install butler from https://itch.io/docs/butler/
# Usage: ./butler-upload.sh <version> [itch_user/game]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MONOGAME_ROOT="$(dirname "$SCRIPT_DIR")"
DIST_DIR="$MONOGAME_ROOT/dist"
GAME_NAME="KeyboardDefense"

VERSION="${1:?Usage: butler-upload.sh <version> [itch_user/game]}"
ITCH_TARGET="${2:-your-username/keyboard-defense}"

if ! command -v butler &>/dev/null; then
    echo "ERROR: butler not found. Install from https://itch.io/docs/butler/"
    exit 1
fi

echo "=== Butler Upload ==="
echo "Version: $VERSION"
echo "Target:  $ITCH_TARGET"
echo ""

# Upload Windows build
WIN_ARCHIVE="$DIST_DIR/$GAME_NAME-$VERSION-win-x64.zip"
if [ -f "$WIN_ARCHIVE" ]; then
    echo "Uploading Windows build..."
    butler push "$WIN_ARCHIVE" "$ITCH_TARGET:windows" --userversion "$VERSION"
else
    echo "SKIP: $WIN_ARCHIVE not found"
fi

# Upload Linux build
LINUX_ARCHIVE="$DIST_DIR/$GAME_NAME-$VERSION-linux-x64.tar.gz"
if [ -f "$LINUX_ARCHIVE" ]; then
    echo "Uploading Linux build..."
    butler push "$LINUX_ARCHIVE" "$ITCH_TARGET:linux" --userversion "$VERSION"
else
    echo "SKIP: $LINUX_ARCHIVE not found"
fi

# Upload macOS build
MAC_ARCHIVE="$DIST_DIR/$GAME_NAME-$VERSION-osx-x64.zip"
if [ -f "$MAC_ARCHIVE" ]; then
    echo "Uploading macOS build..."
    butler push "$MAC_ARCHIVE" "$ITCH_TARGET:macos" --userversion "$VERSION"
else
    echo "SKIP: $MAC_ARCHIVE not found"
fi

echo ""
echo "=== Upload complete ==="
butler status "$ITCH_TARGET"
