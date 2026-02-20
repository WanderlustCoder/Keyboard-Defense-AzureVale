#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MONO_ROOT="$REPO_ROOT/apps/keyboard-defense-monogame"
PROJECT="$MONO_ROOT/src/KeyboardDefense.Game/KeyboardDefense.Game.csproj"
DIST_DIR="$MONO_ROOT/dist"
PUBLISH_DIR="$DIST_DIR/win-x64"
VERSION_FILE="$MONO_ROOT/VERSION.txt"

if [[ ! -f "$PROJECT" ]]; then
  echo "Missing game project: $PROJECT" >&2
  exit 1
fi

VERSION="dev"
if [[ -f "$VERSION_FILE" ]]; then
  RAW_VERSION="$(head -n 1 "$VERSION_FILE" | tr -d '\r\n')"
  if [[ -n "$RAW_VERSION" ]]; then
    VERSION="$RAW_VERSION"
  fi
fi

rm -rf "$PUBLISH_DIR"
mkdir -p "$PUBLISH_DIR"

dotnet publish "$PROJECT" \
  -c Release \
  -r win-x64 \
  --self-contained true \
  -p:PublishTrimmed=false \
  -o "$PUBLISH_DIR" \
  "$@"

echo "$VERSION" > "$PUBLISH_DIR/version.txt"

ZIP_PATH="$DIST_DIR/KeyboardDefense-${VERSION}-win-x64.zip"
rm -f "$ZIP_PATH"
(cd "$PUBLISH_DIR" && zip -qr "$ZIP_PATH" .)

echo "Created $ZIP_PATH"
