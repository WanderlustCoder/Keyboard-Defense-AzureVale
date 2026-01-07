#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET="${SCRIPT_DIR}/../apps/keyboard-defense-godot/scripts/export_windows.sh"

echo "Delegating to apps/keyboard-defense-godot/scripts/export_windows.sh"
if [[ ! -f "${TARGET}" ]]; then
  echo "Missing export script: ${TARGET}" >&2
  exit 1
fi

if [[ ! -x "${TARGET}" ]]; then
  chmod +x "${TARGET}" 2>/dev/null || true
fi

bash "${TARGET}" "$@"
exit $?
