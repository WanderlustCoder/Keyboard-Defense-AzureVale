#!/bin/bash
# Preload Patterns Checker
# Wrapper script for check_preload_patterns.py

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT"

# Check for Python
if ! command -v python3 &> /dev/null; then
    echo "ERROR: python3 not found"
    exit 1
fi

# Run the checker
python3 scripts/check_preload_patterns.py "$@"
