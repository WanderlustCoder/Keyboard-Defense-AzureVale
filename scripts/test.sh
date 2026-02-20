#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SOLUTION_PATH="$REPO_ROOT/apps/keyboard-defense-monogame/KeyboardDefense.sln"

if [[ ! -f "$SOLUTION_PATH" ]]; then
  echo "Missing solution: $SOLUTION_PATH" >&2
  exit 1
fi

dotnet test "$SOLUTION_PATH" --configuration Release "$@"
