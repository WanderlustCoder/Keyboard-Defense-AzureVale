#!/bin/bash
# Balance Simulator - Shell Wrapper
# Runs the balance simulator headless

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT"

# Check for Godot
GODOT_CMD="${GODOT_PATH:-godot}"

if ! command -v "$GODOT_CMD" &> /dev/null; then
    echo "WARNING: Godot not found. Using Python fallback simulator."
    echo ""
    python3 scripts/simulate_balance.py "$@"
    exit $?
fi

# Run the GDScript simulator
"$GODOT_CMD" --headless --path . --script res://tools/balance_simulator.gd -- "$@"
