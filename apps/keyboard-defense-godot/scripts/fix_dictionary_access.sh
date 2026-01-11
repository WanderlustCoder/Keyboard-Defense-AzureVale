#!/bin/bash
# Dictionary Access Fixer
# Wrapper script for fix_dictionary_access.py

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT"

# Check for Python
if ! command -v python3 &> /dev/null; then
    echo "ERROR: python3 not found"
    exit 1
fi

# Run the fixer
python3 scripts/fix_dictionary_access.py "$@"
