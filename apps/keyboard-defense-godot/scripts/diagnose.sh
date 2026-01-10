#!/usr/bin/env bash
# Diagnostic script wrapper
# Usage: ./scripts/diagnose.sh [check] [check] ...
#
# Checks: assets, lessons, references, balance, all
#
# Examples:
#   ./scripts/diagnose.sh              # Run all diagnostics
#   ./scripts/diagnose.sh assets       # Check assets only
#   ./scripts/diagnose.sh lessons      # Check lessons only

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "${SCRIPT_DIR}/.."

python3 scripts/diagnose.py "$@"
