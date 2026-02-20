#!/usr/bin/env bash
# Build release packages for Keyboard Defense (MonoGame) for all platforms.
# Usage: ./publish.sh [version] [output_dir]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MONOGAME_ROOT="$(dirname "$SCRIPT_DIR")"
GAME_PROJ="$MONOGAME_ROOT/src/KeyboardDefense.Game/KeyboardDefense.Game.csproj"
GAME_NAME="KeyboardDefense"

VERSION="${1:-}"
OUTPUT_DIR="${2:-$MONOGAME_ROOT/dist}"
RIDS="win-x64 linux-x64 osx-x64"

# Resolve version from git if not provided
if [ -z "$VERSION" ]; then
    VERSION=$(git -C "$MONOGAME_ROOT" describe --tags --always 2>/dev/null || echo "dev")
fi

echo "=== Keyboard Defense Release Builder ==="
echo "Version: $VERSION"
echo "Output:  $OUTPUT_DIR"
echo ""

# Clean and create output dir
rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

for RID in $RIDS; do
    echo "--- Building $RID ---"

    PUBLISH_DIR="$OUTPUT_DIR/publish/$RID"

    dotnet publish "$GAME_PROJ" \
        -c Release \
        -r "$RID" \
        --self-contained true \
        -p:PublishTrimmed=false \
        -o "$PUBLISH_DIR"

    # Write version.txt
    echo "$VERSION" > "$PUBLISH_DIR/version.txt"

    ARCHIVE_NAME="$GAME_NAME-$VERSION-$RID"

    if [[ "$RID" == linux-* ]]; then
        TAR_PATH="$OUTPUT_DIR/$ARCHIVE_NAME.tar.gz"
        echo "Packaging $TAR_PATH"
        tar -czf "$TAR_PATH" -C "$PUBLISH_DIR" .
    else
        ZIP_PATH="$OUTPUT_DIR/$ARCHIVE_NAME.zip"
        echo "Packaging $ZIP_PATH"
        (cd "$PUBLISH_DIR" && zip -qr "$ZIP_PATH" .)
    fi

    echo "Done: $RID"
    echo ""
done

# Clean up publish intermediates
rm -rf "$OUTPUT_DIR/publish"

echo "=== All platforms built ==="
echo "Archives in: $OUTPUT_DIR"
ls -lh "$OUTPUT_DIR"
