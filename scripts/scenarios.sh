#!/usr/bin/env bash
set -euo pipefail
if [[ ! -x "$0" ]]; then
  chmod +x "$0" 2>/dev/null || true
fi

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT_ROOT="${REPO_ROOT}/apps/keyboard-defense-godot"
LOG="${PROJECT_ROOT}/_scenarios.log"
REPORTS_DIR="${PROJECT_ROOT}/Logs/ScenarioReports"
SUMMARY_PATH="${REPORTS_DIR}/last_summary.txt"
mkdir -p "${REPORTS_DIR}"

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
OUT_DIR_ARG="Logs/ScenarioReports"
if [[ "${IS_WINDOWS_EXE}" == true ]] && command -v wslpath >/dev/null 2>&1; then
  PROJECT_PATH="$(wslpath -w "${PROJECT_ROOT}")"
  LOG_PATH="$(wslpath -w "${LOG}")"
fi

# To enforce targets, append: --enforce-targets
"${GODOT}" --headless --path "${PROJECT_PATH}" --script res://tools/run_scenarios.gd --log-file "${LOG_PATH}" --tag p0 --tag balance --exclude-tag long --targets --out-dir "${OUT_DIR_ARG}" 2>&1 | tee "${LOG}" >/dev/null

if [[ -f "${SUMMARY_PATH}" ]]; then
  cat "${SUMMARY_PATH}"
else
  tail -n 200 "${LOG}" | grep -E "\[(scenarios|targets)\]" || true
fi