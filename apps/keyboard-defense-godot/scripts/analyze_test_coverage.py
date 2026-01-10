#!/usr/bin/env python3
"""
Test Coverage Analyzer

Analyzes test coverage by comparing test functions to implementation code:
- Finds which sim/ functions have corresponding tests
- Identifies untested functions and files
- Reports coverage percentage by layer
- Suggests test priorities

Usage:
    python scripts/analyze_test_coverage.py              # Full report
    python scripts/analyze_test_coverage.py --layer sim  # Sim layer only
    python scripts/analyze_test_coverage.py --json       # JSON output
    python scripts/analyze_test_coverage.py --untested   # Show only untested
"""

import json
import re
import sys
from dataclasses import dataclass, field
from pathlib import Path
from typing import Dict, List, Set, Optional, Tuple

# Project paths
SCRIPT_DIR = Path(__file__).parent
PROJECT_ROOT = SCRIPT_DIR.parent

# Test file location
TEST_FILE = PROJECT_ROOT / "tests" / "run_tests.gd"


@dataclass
class FunctionInfo:
    """Information about a function."""
    name: str
    file: str
    line: int
    is_static: bool = False
    is_private: bool = False
    class_name: str = ""
    has_test: bool = False


@dataclass
class CoverageReport:
    """Test coverage report."""
    functions: List[FunctionInfo] = field(default_factory=list)
    tested_count: int = 0
    untested_count: int = 0
    coverage_percent: float = 0.0
    by_file: Dict[str, Dict] = field(default_factory=dict)
    by_layer: Dict[str, Dict] = field(default_factory=dict)
    test_functions: List[str] = field(default_factory=list)
    untested_priorities: List[FunctionInfo] = field(default_factory=list)


def get_layer(filepath: str) -> str:
    """Determine which architectural layer a file belongs to."""
    if filepath.startswith("sim/"):
        return "sim"
    elif filepath.startswith("game/"):
        return "game"
    elif filepath.startswith("ui/"):
        return "ui"
    elif filepath.startswith("scripts/"):
        return "scripts"
    elif filepath.startswith("tests/"):
        return "tests"
    elif filepath.startswith("tools/"):
        return "tools"
    return "other"


def extract_functions(filepath: Path) -> List[FunctionInfo]:
    """Extract function definitions from a GDScript file."""
    functions = []
    rel_path = str(filepath.relative_to(PROJECT_ROOT))

    try:
        content = filepath.read_text(encoding="utf-8")
        lines = content.split('\n')
    except Exception:
        return functions

    current_class = ""

    for i, line in enumerate(lines):
        # Check for class_name
        class_match = re.match(r'^class_name\s+(\w+)', line)
        if class_match:
            current_class = class_match.group(1)

        # Check for inner class
        inner_class_match = re.match(r'^class\s+(\w+)', line)
        if inner_class_match:
            current_class = inner_class_match.group(1)

        # Check for function definition
        func_match = re.match(r'^(static\s+)?func\s+(\w+)\s*\(', line)
        if func_match:
            is_static = func_match.group(1) is not None
            func_name = func_match.group(2)
            is_private = func_name.startswith('_')

            functions.append(FunctionInfo(
                name=func_name,
                file=rel_path,
                line=i + 1,
                is_static=is_static,
                is_private=is_private,
                class_name=current_class
            ))

    return functions


def extract_test_functions(test_file: Path) -> Tuple[List[str], Set[str]]:
    """Extract test function names and what they might be testing."""
    test_functions = []
    tested_items = set()

    if not test_file.exists():
        return test_functions, tested_items

    try:
        content = test_file.read_text(encoding="utf-8")
        lines = content.split('\n')
    except Exception:
        return test_functions, tested_items

    for line in lines:
        # Find test function definitions
        func_match = re.match(r'^func\s+(test_\w+)\s*\(', line)
        if func_match:
            test_name = func_match.group(1)
            test_functions.append(test_name)

            # Extract what it's testing from name
            # test_something_does_x -> something
            parts = test_name.replace('test_', '').split('_')
            if parts:
                # Add various forms that might match
                tested_items.add(parts[0])
                tested_items.add('_'.join(parts[:2]) if len(parts) > 1 else parts[0])
                tested_items.add('_'.join(parts))

        # Also look for direct function calls to sim functions
        call_matches = re.findall(r'(\w+)\.(\w+)\s*\(', line)
        for class_name, method_name in call_matches:
            if class_name.startswith('Sim') or class_name == 'state':
                tested_items.add(method_name)

        # Look for SimX.function() patterns
        sim_calls = re.findall(r'Sim\w+\.(\w+)\s*\(', line)
        tested_items.update(sim_calls)

    return test_functions, tested_items


def check_function_tested(func: FunctionInfo, tested_items: Set[str]) -> bool:
    """Check if a function appears to have test coverage."""
    # Direct name match
    if func.name in tested_items:
        return True

    # Without leading underscore
    if func.name.startswith('_') and func.name[1:] in tested_items:
        return True

    # With class prefix
    if func.class_name:
        full_name = f"{func.class_name}_{func.name}"
        if full_name.lower() in {t.lower() for t in tested_items}:
            return True

    return False


def calculate_priority(func: FunctionInfo) -> int:
    """Calculate testing priority (lower = higher priority)."""
    priority = 50

    # Sim functions are highest priority
    if func.file.startswith("sim/"):
        priority -= 30

    # Public functions over private
    if not func.is_private:
        priority -= 10

    # Static functions are more testable
    if func.is_static:
        priority -= 5

    # Core files more important
    core_files = ["types.gd", "apply_intent.gd", "enemies.gd", "buildings.gd"]
    if any(f in func.file for f in core_files):
        priority -= 10

    return priority


def analyze_coverage(layer_filter: Optional[str] = None) -> CoverageReport:
    """Analyze test coverage across the codebase."""
    report = CoverageReport()

    # Get test information
    test_functions, tested_items = extract_test_functions(TEST_FILE)
    report.test_functions = test_functions

    # Scan all GDScript files
    for gd_file in PROJECT_ROOT.glob("**/*.gd"):
        if ".godot" in str(gd_file) or "addons" in str(gd_file):
            continue

        rel_path = str(gd_file.relative_to(PROJECT_ROOT))
        layer = get_layer(rel_path)

        # Skip test files themselves
        if layer == "tests":
            continue

        # Apply layer filter
        if layer_filter and layer != layer_filter:
            continue

        functions = extract_functions(gd_file)

        for func in functions:
            func.has_test = check_function_tested(func, tested_items)
            report.functions.append(func)

            # Update file stats
            if rel_path not in report.by_file:
                report.by_file[rel_path] = {"tested": 0, "untested": 0, "total": 0}
            report.by_file[rel_path]["total"] += 1
            if func.has_test:
                report.by_file[rel_path]["tested"] += 1
            else:
                report.by_file[rel_path]["untested"] += 1

            # Update layer stats
            if layer not in report.by_layer:
                report.by_layer[layer] = {"tested": 0, "untested": 0, "total": 0}
            report.by_layer[layer]["total"] += 1
            if func.has_test:
                report.by_layer[layer]["tested"] += 1
            else:
                report.by_layer[layer]["untested"] += 1

    # Calculate totals
    report.tested_count = sum(1 for f in report.functions if f.has_test)
    report.untested_count = len(report.functions) - report.tested_count
    if report.functions:
        report.coverage_percent = (report.tested_count / len(report.functions)) * 100

    # Prioritize untested functions
    untested = [f for f in report.functions if not f.has_test and not f.is_private]
    untested.sort(key=lambda f: calculate_priority(f))
    report.untested_priorities = untested[:20]

    return report


def format_report(report: CoverageReport, show_untested_only: bool = False) -> str:
    """Format coverage report as text."""
    lines = []
    lines.append("=" * 60)
    lines.append("TEST COVERAGE ANALYZER - KEYBOARD DEFENSE")
    lines.append("=" * 60)
    lines.append("")

    # Summary
    lines.append("## SUMMARY")
    lines.append(f"  Total functions:    {len(report.functions)}")
    lines.append(f"  Tested:             {report.tested_count}")
    lines.append(f"  Untested:           {report.untested_count}")
    lines.append(f"  Coverage:           {report.coverage_percent:.1f}%")
    lines.append(f"  Test functions:     {len(report.test_functions)}")
    lines.append("")

    # Coverage bar
    bar_width = 40
    filled = int(bar_width * report.coverage_percent / 100)
    bar = "[" + "=" * filled + " " * (bar_width - filled) + "]"
    lines.append(f"  {bar} {report.coverage_percent:.1f}%")
    lines.append("")

    # By layer
    lines.append("## COVERAGE BY LAYER")
    for layer in ["sim", "game", "ui", "tools", "other"]:
        stats = report.by_layer.get(layer, {"tested": 0, "untested": 0, "total": 0})
        if stats["total"] > 0:
            pct = (stats["tested"] / stats["total"]) * 100
            bar_filled = int(20 * pct / 100)
            mini_bar = "[" + "=" * bar_filled + " " * (20 - bar_filled) + "]"
            lines.append(f"  {layer:10} {mini_bar} {pct:5.1f}% ({stats['tested']}/{stats['total']})")
    lines.append("")

    if show_untested_only:
        # Show all untested public functions
        lines.append("## UNTESTED FUNCTIONS")
        untested = [f for f in report.functions if not f.has_test and not f.is_private]
        untested.sort(key=lambda f: (f.file, f.line))

        current_file = ""
        for func in untested:
            if func.file != current_file:
                current_file = func.file
                lines.append(f"\n  {current_file}:")
            static_mark = "[static] " if func.is_static else ""
            lines.append(f"    {static_mark}{func.name}() line {func.line}")
        lines.append("")
    else:
        # Priority testing suggestions
        lines.append("## TESTING PRIORITIES (Top 20)")
        lines.append("  Functions most in need of tests:")
        lines.append("")
        for i, func in enumerate(report.untested_priorities[:20], 1):
            static_mark = "[S] " if func.is_static else "    "
            lines.append(f"  {i:2}. {static_mark}{func.file}:{func.line}")
            lines.append(f"       {func.name}()")
        lines.append("")

        # Files with lowest coverage
        lines.append("## FILES NEEDING TESTS")
        file_coverage = []
        for filepath, stats in report.by_file.items():
            if stats["total"] >= 3:  # Only files with 3+ functions
                pct = (stats["tested"] / stats["total"]) * 100
                file_coverage.append((filepath, pct, stats["untested"]))

        file_coverage.sort(key=lambda x: (x[1], -x[2]))  # Low coverage first
        for filepath, pct, untested in file_coverage[:15]:
            lines.append(f"  {pct:5.1f}%  ({untested} untested)  {filepath}")
        lines.append("")

    # Test function inventory
    lines.append("## EXISTING TESTS")
    lines.append(f"  Found {len(report.test_functions)} test functions in run_tests.gd:")
    for i, test_name in enumerate(report.test_functions[:10]):
        lines.append(f"    {test_name}")
    if len(report.test_functions) > 10:
        lines.append(f"    ... and {len(report.test_functions) - 10} more")
    lines.append("")

    # Health indicators
    lines.append("## HEALTH INDICATORS")
    if report.coverage_percent < 20:
        lines.append("  [WARN] Very low test coverage")
    elif report.coverage_percent < 50:
        lines.append("  [INFO] Test coverage could be improved")
    else:
        lines.append("  [OK] Reasonable test coverage")

    sim_stats = report.by_layer.get("sim", {"tested": 0, "total": 1})
    sim_pct = (sim_stats["tested"] / max(sim_stats["total"], 1)) * 100
    if sim_pct < 30:
        lines.append("  [WARN] Sim layer needs more tests (critical for game logic)")
    else:
        lines.append(f"  [OK] Sim layer at {sim_pct:.0f}% coverage")

    lines.append("")
    return "\n".join(lines)


def format_json(report: CoverageReport) -> str:
    """Format report as JSON."""
    data = {
        "summary": {
            "total_functions": len(report.functions),
            "tested": report.tested_count,
            "untested": report.untested_count,
            "coverage_percent": round(report.coverage_percent, 1),
            "test_count": len(report.test_functions)
        },
        "by_layer": {
            layer: {
                "tested": stats["tested"],
                "untested": stats["untested"],
                "total": stats["total"],
                "percent": round((stats["tested"] / max(stats["total"], 1)) * 100, 1)
            }
            for layer, stats in report.by_layer.items()
        },
        "by_file": {
            filepath: {
                "tested": stats["tested"],
                "untested": stats["untested"],
                "total": stats["total"],
                "percent": round((stats["tested"] / max(stats["total"], 1)) * 100, 1)
            }
            for filepath, stats in report.by_file.items()
        },
        "untested_priorities": [
            {
                "name": f.name,
                "file": f.file,
                "line": f.line,
                "is_static": f.is_static,
                "class_name": f.class_name
            }
            for f in report.untested_priorities
        ],
        "test_functions": report.test_functions
    }
    return json.dumps(data, indent=2)


def main():
    import argparse

    parser = argparse.ArgumentParser(description="Analyze test coverage")
    parser.add_argument("--json", "-j", action="store_true", help="JSON output")
    parser.add_argument("--layer", "-l", type=str, help="Filter by layer (sim, game, ui)")
    parser.add_argument("--untested", "-u", action="store_true", help="Show only untested functions")
    args = parser.parse_args()

    report = analyze_coverage(args.layer)

    if args.json:
        print(format_json(report))
    else:
        print(format_report(report, args.untested))


if __name__ == "__main__":
    main()
