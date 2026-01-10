#!/usr/bin/env bash
# Pre-commit validation script
# Run this before committing to catch common issues early
#
# Usage: ./scripts/precommit.sh [options]
#
# Options:
#   --quick     Skip slow checks (headless tests)
#   --no-tests  Skip headless tests only
#   --verbose   Show detailed output
#
# Exit codes:
#   0 - All checks passed
#   1 - Validation failed
#   2 - Script error

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="${SCRIPT_DIR}/.."
cd "${PROJECT_DIR}"

# Parse arguments
QUICK=false
SKIP_TESTS=false
VERBOSE=false

for arg in "$@"; do
    case $arg in
        --quick)
            QUICK=true
            SKIP_TESTS=true
            ;;
        --no-tests)
            SKIP_TESTS=true
            ;;
        --verbose)
            VERBOSE=true
            ;;
    esac
done

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

passed=0
failed=0
skipped=0

print_header() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

print_result() {
    if [ "$1" = "pass" ]; then
        echo -e "  ${GREEN}✓${NC} $2"
        ((passed++))
    elif [ "$1" = "fail" ]; then
        echo -e "  ${RED}✗${NC} $2"
        ((failed++))
    elif [ "$1" = "skip" ]; then
        echo -e "  ${YELLOW}○${NC} $2 (skipped)"
        ((skipped++))
    fi
}

print_header "KEYBOARD DEFENSE - PRE-COMMIT VALIDATION"
echo "  Project: ${PROJECT_DIR}"
echo "  Date: $(date '+%Y-%m-%d %H:%M:%S')"

# ─────────────────────────────────────────────────────────────
# Check 1: JSON Syntax Validation
# ─────────────────────────────────────────────────────────────
print_header "CHECK 1: JSON Syntax"

json_errors=0
for json_file in data/*.json; do
    if [ -f "$json_file" ]; then
        if python3 -c "import json; json.load(open('$json_file'))" 2>/dev/null; then
            if [ "$VERBOSE" = true ]; then
                print_result "pass" "$(basename "$json_file")"
            fi
        else
            print_result "fail" "$(basename "$json_file") - invalid JSON"
            ((json_errors++))
        fi
    fi
done

if [ $json_errors -eq 0 ]; then
    print_result "pass" "All JSON files are valid"
else
    print_result "fail" "$json_errors JSON file(s) have syntax errors"
fi

# ─────────────────────────────────────────────────────────────
# Check 2: Schema Validation
# ─────────────────────────────────────────────────────────────
print_header "CHECK 2: Schema Validation"

if command -v python3 &> /dev/null; then
    # Check if jsonschema is installed
    if python3 -c "import jsonschema" 2>/dev/null; then
        if python3 scripts/validate_schemas.py --quick > /tmp/schema_validation.log 2>&1; then
            print_result "pass" "All schemas validated"
            if [ "$VERBOSE" = true ]; then
                cat /tmp/schema_validation.log
            fi
        else
            print_result "fail" "Schema validation errors found"
            cat /tmp/schema_validation.log
        fi
    else
        print_result "skip" "jsonschema not installed (pip install jsonschema)"
    fi
else
    print_result "skip" "Python 3 not available"
fi

# ─────────────────────────────────────────────────────────────
# Check 3: Sim Layer Architecture
# ─────────────────────────────────────────────────────────────
print_header "CHECK 3: Sim Layer Architecture"

sim_errors=0
forbidden_patterns=("extends Node" "extends Control" "extends Node2D" "extends Node3D" "extends CanvasItem")

for gd_file in sim/*.gd; do
    if [ -f "$gd_file" ]; then
        for pattern in "${forbidden_patterns[@]}"; do
            if grep -q "$pattern" "$gd_file"; then
                print_result "fail" "$(basename "$gd_file") contains '$pattern'"
                ((sim_errors++))
            fi
        done
    fi
done

if [ $sim_errors -eq 0 ]; then
    print_result "pass" "sim/ layer is Node-free"
fi

# ─────────────────────────────────────────────────────────────
# Check 4: GDScript Syntax Check
# ─────────────────────────────────────────────────────────────
print_header "CHECK 4: GDScript Syntax"

if command -v godot &> /dev/null; then
    # Quick syntax check by attempting to load scripts
    if [ "$SKIP_TESTS" = false ]; then
        if timeout 30 godot --headless --path . --quit 2>&1 | grep -i "error" > /tmp/gdscript_errors.log; then
            if [ -s /tmp/gdscript_errors.log ]; then
                print_result "fail" "GDScript errors detected"
                head -20 /tmp/gdscript_errors.log
            else
                print_result "pass" "GDScript syntax OK"
            fi
        else
            print_result "pass" "GDScript syntax OK"
        fi
    else
        print_result "skip" "GDScript syntax (--quick mode)"
    fi
else
    print_result "skip" "Godot not in PATH"
fi

# ─────────────────────────────────────────────────────────────
# Check 5: Headless Tests
# ─────────────────────────────────────────────────────────────
print_header "CHECK 5: Headless Tests"

if [ "$SKIP_TESTS" = true ]; then
    print_result "skip" "Headless tests (--quick or --no-tests)"
else
    if command -v godot &> /dev/null; then
        echo "  Running tests (this may take a moment)..."
        if timeout 120 godot --headless --path . --script res://tests/run_tests.gd 2>&1 | tee /tmp/test_output.log | tail -5; then
            # Check for test failures in output
            if grep -q "FAILED" /tmp/test_output.log; then
                print_result "fail" "Some tests failed"
            elif grep -q "PASSED" /tmp/test_output.log || grep -q "All tests passed" /tmp/test_output.log; then
                print_result "pass" "All tests passed"
            else
                print_result "pass" "Tests completed (check output)"
            fi
        else
            print_result "fail" "Test runner failed or timed out"
        fi
    else
        print_result "skip" "Godot not in PATH"
    fi
fi

# ─────────────────────────────────────────────────────────────
# Check 6: Common Mistakes
# ─────────────────────────────────────────────────────────────
print_header "CHECK 6: Common Mistakes"

mistakes=0

# Check for debug prints left in code
if grep -r "print(" sim/*.gd game/*.gd scripts/*.gd 2>/dev/null | grep -v "# DEBUG" | grep -v "_debug" > /tmp/debug_prints.log; then
    debug_count=$(wc -l < /tmp/debug_prints.log)
    if [ "$debug_count" -gt 20 ]; then
        echo -e "  ${YELLOW}!${NC} Many print() statements found ($debug_count) - consider cleanup"
    fi
fi

# Check for TODO/FIXME comments
todo_count=$(grep -r "TODO\|FIXME\|HACK\|XXX" sim/*.gd game/*.gd scripts/*.gd 2>/dev/null | wc -l || echo "0")
if [ "$todo_count" -gt 0 ]; then
    echo -e "  ${YELLOW}!${NC} Found $todo_count TODO/FIXME comments"
fi

print_result "pass" "Common mistake check complete"

# ─────────────────────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────────────────────
print_header "SUMMARY"

total=$((passed + failed + skipped))
echo ""
echo -e "  ${GREEN}Passed:${NC}  $passed"
echo -e "  ${RED}Failed:${NC}  $failed"
echo -e "  ${YELLOW}Skipped:${NC} $skipped"
echo ""

if [ $failed -gt 0 ]; then
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${RED}  VALIDATION FAILED - Fix errors before committing${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    exit 1
else
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}  ALL CHECKS PASSED - Ready to commit${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    exit 0
fi
