#!/usr/bin/env bash
# Schema validation wrapper script
# Usage: ./scripts/validate.sh [options] [files...]
#
# Options:
#   --quick    Only validate files with schemas (faster)
#
# Examples:
#   ./scripts/validate.sh              # Validate all data files
#   ./scripts/validate.sh --quick      # Only schema-validated files
#   ./scripts/validate.sh lessons map  # Validate specific files

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "${SCRIPT_DIR}/.."

python3 scripts/validate_schemas.py "$@"
