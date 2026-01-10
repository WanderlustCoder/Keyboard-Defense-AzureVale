#!/usr/bin/env python3
"""
Function Length Checker

Finds functions that are too long (maintainability concern):
- Functions exceeding line count threshold
- Functions with high statement density
- Suggests refactoring candidates

Usage:
    python scripts/check_func_length.py              # Full report
    python scripts/check_func_length.py --threshold 50  # Custom threshold
    python scripts/check_func_length.py --file game/main.gd  # Single file
    python scripts/check_func_length.py --json       # JSON output
"""

import json
import re
import sys
from dataclasses import dataclass, field
from pathlib import Path
from typing import Dict, List, Optional, Tuple

# Project paths
SCRIPT_DIR = Path(__file__).parent
PROJECT_ROOT = SCRIPT_DIR.parent

# Thresholds
DEFAULT_LINE_THRESHOLD = 50
WARNING_LINE_THRESHOLD = 30
STATEMENT_DENSITY_THRESHOLD = 0.8  # statements per line


@dataclass
class FunctionInfo:
    """Information about a function."""
    name: str
    file: str
    line_start: int
    line_end: int
    line_count: int
    statement_count: int
    is_private: bool
    complexity_hint: str = ""


@dataclass
class LengthReport:
    """Function length report."""
    files_checked: int = 0
    functions_checked: int = 0
    over_threshold: int = 0
    over_warning: int = 0
    longest_function: Optional[FunctionInfo] = None
    functions: List[FunctionInfo] = field(default_factory=list)
    by_severity: Dict[str, List[FunctionInfo]] = field(default_factory=lambda: {"long": [], "warning": [], "ok": []})
    avg_length: float = 0.0


def count_statements(lines: List[str]) -> int:
    """Count executable statements in lines."""
    count = 0
    for line in lines:
        stripped = line.strip()
        # Skip empty lines, comments, and pure structural lines
        if not stripped:
            continue
        if stripped.startswith("#"):
            continue
        if stripped in ("pass", "else:", "elif:", "try:", "except:", "finally:"):
            continue
        if stripped.endswith(":") and not "=" in stripped:
            # Control structure, don't count as statement
            continue
        count += 1
    return count


def analyze_file(file_path: Path, rel_path: str, threshold: int) -> List[FunctionInfo]:
    """Analyze a file for function lengths."""
    functions = []

    try:
        content = file_path.read_text(encoding="utf-8")
        lines = content.split('\n')
    except Exception:
        return functions

    current_func = None
    current_func_start = 0
    current_func_lines: List[str] = []
    base_indent = 0

    for i, line in enumerate(lines):
        line_num = i + 1

        # Check for function definition
        func_match = re.match(r'^(\s*)(static\s+)?func\s+(\w+)', line)
        if func_match:
            # Save previous function if exists
            if current_func:
                line_count = len(current_func_lines)
                statement_count = count_statements(current_func_lines)

                func_info = FunctionInfo(
                    name=current_func,
                    file=rel_path,
                    line_start=current_func_start,
                    line_end=line_num - 1,
                    line_count=line_count,
                    statement_count=statement_count,
                    is_private=current_func.startswith("_")
                )

                # Add complexity hint
                if line_count > threshold:
                    func_info.complexity_hint = "Consider breaking into smaller functions"
                elif statement_count / max(line_count, 1) > STATEMENT_DENSITY_THRESHOLD:
                    func_info.complexity_hint = "High statement density"

                functions.append(func_info)

            # Start new function
            base_indent = len(func_match.group(1))
            current_func = func_match.group(3)
            current_func_start = line_num
            current_func_lines = [line]
            continue

        # Add line to current function if we're in one
        if current_func:
            # Check if we've exited the function (less or equal indent, non-empty)
            stripped = line.strip()
            if stripped and not line.startswith('\t' * (base_indent // 4 + 1)) and not line.startswith(' ' * (base_indent + 1)):
                # Check actual indent
                current_indent = len(line) - len(line.lstrip())
                if current_indent <= base_indent and stripped and not stripped.startswith("#"):
                    # End of function
                    line_count = len(current_func_lines)
                    statement_count = count_statements(current_func_lines)

                    func_info = FunctionInfo(
                        name=current_func,
                        file=rel_path,
                        line_start=current_func_start,
                        line_end=line_num - 1,
                        line_count=line_count,
                        statement_count=statement_count,
                        is_private=current_func.startswith("_")
                    )

                    if line_count > threshold:
                        func_info.complexity_hint = "Consider breaking into smaller functions"
                    elif statement_count / max(line_count, 1) > STATEMENT_DENSITY_THRESHOLD:
                        func_info.complexity_hint = "High statement density"

                    functions.append(func_info)
                    current_func = None
                    current_func_lines = []

                    # Check if this line starts a new function
                    new_func_match = re.match(r'^(\s*)(static\s+)?func\s+(\w+)', line)
                    if new_func_match:
                        base_indent = len(new_func_match.group(1))
                        current_func = new_func_match.group(3)
                        current_func_start = line_num
                        current_func_lines = [line]
                    continue

            current_func_lines.append(line)

    # Handle last function
    if current_func:
        line_count = len(current_func_lines)
        statement_count = count_statements(current_func_lines)

        func_info = FunctionInfo(
            name=current_func,
            file=rel_path,
            line_start=current_func_start,
            line_end=len(lines),
            line_count=line_count,
            statement_count=statement_count,
            is_private=current_func.startswith("_")
        )

        if line_count > threshold:
            func_info.complexity_hint = "Consider breaking into smaller functions"
        elif statement_count / max(line_count, 1) > STATEMENT_DENSITY_THRESHOLD:
            func_info.complexity_hint = "High statement density"

        functions.append(func_info)

    return functions


def check_func_length(threshold: int = DEFAULT_LINE_THRESHOLD, target_file: Optional[str] = None) -> LengthReport:
    """Check function lengths across the project."""
    report = LengthReport()

    if target_file:
        gd_files = [PROJECT_ROOT / target_file]
    else:
        gd_files = list(PROJECT_ROOT.glob("**/*.gd"))

    all_functions: List[FunctionInfo] = []

    for gd_file in gd_files:
        if ".godot" in str(gd_file) or "addons" in str(gd_file):
            continue

        if not gd_file.exists():
            continue

        rel_path = str(gd_file.relative_to(PROJECT_ROOT))
        report.files_checked += 1

        functions = analyze_file(gd_file, rel_path, threshold)
        all_functions.extend(functions)

    report.functions_checked = len(all_functions)

    # Categorize functions
    for func in all_functions:
        if func.line_count > threshold:
            report.by_severity["long"].append(func)
            report.over_threshold += 1
        elif func.line_count > WARNING_LINE_THRESHOLD:
            report.by_severity["warning"].append(func)
            report.over_warning += 1
        else:
            report.by_severity["ok"].append(func)

    # Sort by length (longest first)
    report.by_severity["long"].sort(key=lambda f: -f.line_count)
    report.by_severity["warning"].sort(key=lambda f: -f.line_count)

    # Store long functions for report
    report.functions = report.by_severity["long"] + report.by_severity["warning"][:10]

    # Find longest
    if all_functions:
        report.longest_function = max(all_functions, key=lambda f: f.line_count)
        report.avg_length = sum(f.line_count for f in all_functions) / len(all_functions)

    return report


def format_report(report: LengthReport, threshold: int) -> str:
    """Format length report as text."""
    lines = []
    lines.append("=" * 60)
    lines.append("FUNCTION LENGTH CHECKER - KEYBOARD DEFENSE")
    lines.append("=" * 60)
    lines.append("")

    # Summary
    lines.append("## SUMMARY")
    lines.append(f"  Files checked:      {report.files_checked}")
    lines.append(f"  Functions checked:  {report.functions_checked}")
    lines.append(f"  Over {threshold} lines:     {report.over_threshold}")
    lines.append(f"  Over {WARNING_LINE_THRESHOLD} lines:     {report.over_warning}")
    lines.append(f"  Average length:     {report.avg_length:.1f} lines")
    lines.append("")

    if report.longest_function:
        lines.append(f"  Longest function:   {report.longest_function.name}")
        lines.append(f"                      {report.longest_function.line_count} lines in {report.longest_function.file}")
    lines.append("")

    # Long functions
    if report.by_severity["long"]:
        lines.append(f"## FUNCTIONS OVER {threshold} LINES (Refactor Candidates)")
        for func in report.by_severity["long"][:15]:
            lines.append(f"  {func.file}:{func.line_start}")
            lines.append(f"    {func.name}() - {func.line_count} lines, {func.statement_count} statements")
            if func.complexity_hint:
                lines.append(f"    Hint: {func.complexity_hint}")
        if len(report.by_severity["long"]) > 15:
            lines.append(f"  ... and {len(report.by_severity['long']) - 15} more")
        lines.append("")

    # Warning functions
    if report.by_severity["warning"]:
        lines.append(f"## FUNCTIONS OVER {WARNING_LINE_THRESHOLD} LINES (Watch List)")
        for func in report.by_severity["warning"][:10]:
            lines.append(f"  {func.file}:{func.line_start}")
            lines.append(f"    {func.name}() - {func.line_count} lines")
        if len(report.by_severity["warning"]) > 10:
            lines.append(f"  ... and {len(report.by_severity['warning']) - 10} more")
        lines.append("")

    # Health indicators
    lines.append("## HEALTH INDICATORS")
    if report.over_threshold == 0:
        lines.append(f"  [OK] No functions over {threshold} lines")
    else:
        lines.append(f"  [WARN] {report.over_threshold} functions over {threshold} lines")

    if report.avg_length < 20:
        lines.append(f"  [OK] Good average function length ({report.avg_length:.1f} lines)")
    elif report.avg_length < 30:
        lines.append(f"  [INFO] Moderate average function length ({report.avg_length:.1f} lines)")
    else:
        lines.append(f"  [WARN] High average function length ({report.avg_length:.1f} lines)")

    lines.append("")
    return "\n".join(lines)


def format_json(report: LengthReport, threshold: int) -> str:
    """Format report as JSON."""
    data = {
        "summary": {
            "files_checked": report.files_checked,
            "functions_checked": report.functions_checked,
            "over_threshold": report.over_threshold,
            "over_warning": report.over_warning,
            "threshold": threshold,
            "warning_threshold": WARNING_LINE_THRESHOLD,
            "avg_length": round(report.avg_length, 1)
        },
        "longest_function": {
            "name": report.longest_function.name,
            "file": report.longest_function.file,
            "line_count": report.longest_function.line_count
        } if report.longest_function else None,
        "long_functions": [
            {
                "name": f.name,
                "file": f.file,
                "line_start": f.line_start,
                "line_count": f.line_count,
                "statement_count": f.statement_count,
                "hint": f.complexity_hint
            }
            for f in report.by_severity["long"]
        ],
        "warning_functions": [
            {
                "name": f.name,
                "file": f.file,
                "line_start": f.line_start,
                "line_count": f.line_count
            }
            for f in report.by_severity["warning"][:20]
        ]
    }
    return json.dumps(data, indent=2)


def main():
    import argparse

    parser = argparse.ArgumentParser(description="Check function lengths")
    parser.add_argument("--json", "-j", action="store_true", help="JSON output")
    parser.add_argument("--threshold", "-t", type=int, default=DEFAULT_LINE_THRESHOLD, help="Line count threshold")
    parser.add_argument("--file", "-f", type=str, help="Single file to check")
    args = parser.parse_args()

    report = check_func_length(args.threshold, args.file)

    if args.json:
        print(format_json(report, args.threshold))
    else:
        print(format_report(report, args.threshold))


if __name__ == "__main__":
    main()
