#!/usr/bin/env bash
set -euo pipefail

if [[ ! -x "$0" ]]; then
  chmod +x "$0" 2>/dev/null || true
fi

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT_ROOT="${REPO_ROOT}/apps/keyboard-defense-godot"
LOG="${PROJECT_ROOT}/_test.log"
SUMMARY="${PROJECT_ROOT}/_test_summary.log"
SUMMARY_USER="${HOME}/.local/share/godot/app_userdata/Keyboard Defense/_test_summary.log"

if [[ -n "${GODOT_PATH:-}" ]]; then
  GODOT="${GODOT_PATH}"
elif command -v godot >/dev/null 2>&1; then
  GODOT="$(command -v godot)"
elif command -v godot.exe >/dev/null 2>&1; then
  GODOT="$(command -v godot.exe)"
else
  GODOT="godot"
fi

IS_WINDOWS_EXE=false
if [[ "${GODOT}" == *.exe ]]; then
  IS_WINDOWS_EXE=true
elif command -v file >/dev/null 2>&1; then
  if file "${GODOT}" | grep -qi "PE32"; then
    IS_WINDOWS_EXE=true
  fi
fi

PROJECT_PATH="${PROJECT_ROOT}"
LOG_PATH="${LOG}"
if [[ "${IS_WINDOWS_EXE}" == true ]] && command -v wslpath >/dev/null 2>&1; then
  PROJECT_PATH="$(wslpath -w "${PROJECT_ROOT}")"
  LOG_PATH="$(wslpath -w "${LOG}")"
fi

"${GODOT}" --headless --path "${PROJECT_PATH}" --script res://tests/run_tests.gd --log-file "${LOG_PATH}" 2>&1 | tee "${LOG}" >/dev/null
tail -n 200 "${LOG}" | grep "\[tests\]" || cat "${SUMMARY}" 2>/dev/null || cat "${SUMMARY_USER}" 2>/dev/null || true