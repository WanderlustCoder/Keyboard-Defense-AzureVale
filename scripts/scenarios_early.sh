#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET="$SCRIPT_DIR/scenarios.sh"

if [[ ! -f "$TARGET" ]]; then
  echo "Missing script: $TARGET" >&2
  exit 1
fi

echo "Early scenario tier is not split in MonoGame yet; running full scenario regression set."
bash "$TARGET" "$@"
