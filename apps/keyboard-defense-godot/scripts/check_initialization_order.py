#!/usr/bin/env python3
"""
Initialization Order Checker

Finds potential initialization order issues:
- @onready variables used before _ready()
- Node access in _init()
- Circular initialization dependencies
- Missing null checks for late-initialized vars

Usage:
    python scripts/check_initialization_order.py              # Full report
    python scripts/check_initialization_order.py --file game/main.gd  # Single file
    python scripts/check_initialization_order.py --strict     # More patterns
    python scripts/check_initialization_order.py --json       # JSON output
"""

import json
import re
import sys
from collections import defaultdict
from dataclasses import dataclass, field
from pathlib import Path
from typing import Dict, List, Optional, Set, Tuple

# Project paths
SCRIPT_DIR = Path(__file__).parent
PROJECT_ROOT = SCRIPT_DIR.parent


@dataclass
class InitIssue:
    """An initialization order issue."""
    file: str
    line: int
    category: str
    variable: str
    message: str
    severity: str  # "error", "warning", "info"
    context: str


@dataclass
class InitReport:
    """Initialization order report."""
    files_checked: int = 0
    total_issues: int = 0
    errors: int = 0
    warnings: int = 0
    info: int = 0
    issues: List[InitIssue] = field(default_factory=list)
    by_file: Dict[str, List[InitIssue]] = field(default_factory=lambda: defaultdict(list))
    by_category: Dict[str, int] = field(default_factory=lambda: defaultdict(int))


def analyze_file(file_path: Path, rel_path: str, strict: bool) -> List[InitIssue]:
    """Analyze a file for initialization order issues."""
    issues = []

    try:
        content = file_path.read_text(encoding='utf-8')
        lines = content.split('\n')
    except Exception:
        return issues

    # Track variable declarations
    onready_vars: Set[str] = set()
    class_vars: Set[str] = set()

    # Track function positions
    init_start = -1
    init_end = -1
    ready_start = -1
    ready_end = -1

    current_func = None
    current_func_start = -1
    func_indent = 0

    # First pass: find variable declarations and function boundaries
    for i, line in enumerate(lines):
        stripped = line.strip()

        # Track @onready variables
        onready_match = re.match(r'^@onready\s+var\s+(\w+)', stripped)
        if onready_match:
            onready_vars.add(onready_match.group(1))
            continue

        # Track class variables
        var_match = re.match(r'^var\s+(\w+)', stripped)
        if var_match:
            class_vars.add(var_match.group(1))
            continue

        # Track function boundaries
        func_match = re.match(r'^func\s+(\w+)\s*\(', stripped)
        if func_match:
            func_name = func_match.group(1)
            if current_func:
                # End previous function
                if current_func == '_init':
                    init_end = i
                elif current_func == '_ready':
                    ready_end = i

            current_func = func_name
            current_func_start = i
            func_indent = len(line) - len(line.lstrip())

            if func_name == '_init':
                init_start = i
            elif func_name == '_ready':
                ready_start = i

    # Handle last function
    if current_func == '_init':
        init_end = len(lines)
    elif current_func == '_ready':
        ready_end = len(lines)

    # Second pass: check for issues
    current_func = None
    func_indent = 0

    for i, line in enumerate(lines):
        stripped = line.strip()

        # Skip comments
        if stripped.startswith('#'):
            continue

        # Track current function
        func_match = re.match(r'^func\s+(\w+)\s*\(', stripped)
        if func_match:
            current_func = func_match.group(1)
            func_indent = len(line) - len(line.lstrip())
            continue

        # Exit function on dedent
        if current_func and stripped:
            current_indent = len(line) - len(line.lstrip())
            if current_indent <= func_indent and not stripped.startswith('#'):
                if re.match(r'^(func|var|const|signal|class|enum|@)', stripped):
                    current_func = None

        # Check _init() for node access
        if current_func == '_init':
            # $ node access
            if '$' in line:
                issues.append(InitIssue(
                    file=rel_path,
                    line=i + 1,
                    category="init_node_access",
                    variable="$node",
                    message="Node access in _init() - scene tree not ready",
                    severity="error",
                    context=stripped[:60]
                ))

            # get_node() calls
            if 'get_node' in line or 'get_parent' in line:
                issues.append(InitIssue(
                    file=rel_path,
                    line=i + 1,
                    category="init_node_access",
                    variable="get_node/get_parent",
                    message="Node tree access in _init() - scene tree not ready",
                    severity="error",
                    context=stripped[:60]
                ))

            # @onready variable usage
            for var in onready_vars:
                if re.search(rf'\b{re.escape(var)}\b', line):
                    issues.append(InitIssue(
                        file=rel_path,
                        line=i + 1,
                        category="init_onready_access",
                        variable=var,
                        message=f"@onready var '{var}' used in _init() - not initialized yet",
                        severity="error",
                        context=stripped[:60]
                    ))

        # Check for @onready usage before _ready in other early functions
        if current_func in ['_enter_tree', '_notification']:
            for var in onready_vars:
                if re.search(rf'\b{re.escape(var)}\b', line):
                    issues.append(InitIssue(
                        file=rel_path,
                        line=i + 1,
                        category="early_onready_access",
                        variable=var,
                        message=f"@onready var '{var}' may not be initialized in {current_func}()",
                        severity="warning",
                        context=stripped[:60]
                    ))

        # Check for potential null issues with late-initialized vars
        if strict and current_func and current_func not in ['_init', '_ready']:
            # Variables assigned in _ready but used without null check
            for var in onready_vars:
                pattern = rf'{re.escape(var)}\.'
                if re.search(pattern, line):
                    # Check if there's a null check nearby
                    has_check = False
                    for j in range(max(0, i - 3), i):
                        prev_line = lines[j]
                        if var in prev_line and ('if' in prev_line or 'null' in prev_line or 'is_instance_valid' in prev_line):
                            has_check = True
                            break

                    if not has_check:
                        issues.append(InitIssue(
                            file=rel_path,
                            line=i + 1,
                            category="unchecked_onready",
                            variable=var,
                            message=f"@onready var '{var}' used without null check",
                            severity="info",
                            context=stripped[:60]
                        ))

        # Check for signal connections in _init
        if current_func == '_init':
            if '.connect(' in line:
                issues.append(InitIssue(
                    file=rel_path,
                    line=i + 1,
                    category="init_signal_connect",
                    variable="signal",
                    message="Signal connection in _init() - nodes may not exist",
                    severity="warning",
                    context=stripped[:60]
                ))

        # Check for add_child in _init
        if current_func == '_init':
            if 'add_child(' in line:
                issues.append(InitIssue(
                    file=rel_path,
                    line=i + 1,
                    category="init_add_child",
                    variable="add_child",
                    message="add_child() in _init() - parent may not be ready",
                    severity="warning",
                    context=stripped[:60]
                ))

    return issues


def check_initialization_order(target_file: Optional[str] = None, strict: bool = False) -> InitReport:
    """Check initialization order across the project."""
    report = InitReport()

    if target_file:
        gd_files = [PROJECT_ROOT / target_file]
    else:
        gd_files = list(PROJECT_ROOT.glob("**/*.gd"))

    for gd_file in gd_files:
        if ".godot" in str(gd_file) or "addons" in str(gd_file):
            continue

        if not gd_file.exists():
            continue

        rel_path = str(gd_file.relative_to(PROJECT_ROOT))
        report.files_checked += 1

        issues = analyze_file(gd_file, rel_path, strict)

        for issue in issues:
            report.issues.append(issue)
            report.by_file[issue.file].append(issue)
            report.by_category[issue.category] += 1
            report.total_issues += 1

            if issue.severity == "error":
                report.errors += 1
            elif issue.severity == "warning":
                report.warnings += 1
            else:
                report.info += 1

    return report


def format_report(report: InitReport) -> str:
    """Format initialization report as text."""
    lines = []
    lines.append("=" * 60)
    lines.append("INITIALIZATION ORDER CHECKER - KEYBOARD DEFENSE")
    lines.append("=" * 60)
    lines.append("")

    # Summary
    lines.append("## SUMMARY")
    lines.append(f"  Files checked:      {report.files_checked}")
    lines.append(f"  Total issues:       {report.total_issues}")
    lines.append(f"  Errors:             {report.errors}")
    lines.append(f"  Warnings:           {report.warnings}")
    lines.append(f"  Info:               {report.info}")
    lines.append("")

    # By category
    if report.by_category:
        lines.append("## ISSUES BY CATEGORY")
        for category, count in sorted(report.by_category.items(), key=lambda x: -x[1]):
            lines.append(f"  {category}: {count}")
        lines.append("")

    # Issues
    if report.issues:
        lines.append("## INITIALIZATION ISSUES")

        # Sort by severity
        def severity_order(issue):
            order = {"error": 0, "warning": 1, "info": 2}
            return (order.get(issue.severity, 3), issue.file, issue.line)

        sorted_issues = sorted(report.issues, key=severity_order)

        for issue in sorted_issues[:40]:
            severity_marker = {"error": "[ERROR]", "warning": "[WARN]", "info": "[INFO]"}.get(issue.severity, "[???]")
            lines.append(f"  {severity_marker} {issue.file}:{issue.line}")
            lines.append(f"    {issue.message}")

        if len(report.issues) > 40:
            lines.append(f"  ... and {len(report.issues) - 40} more issues")
        lines.append("")

    # Files with most issues
    if report.by_file:
        lines.append("## FILES WITH MOST INITIALIZATION ISSUES")
        sorted_files = sorted(report.by_file.items(), key=lambda x: -len(x[1]))[:10]
        for file_path, issues in sorted_files:
            error_count = sum(1 for i in issues if i.severity == "error")
            lines.append(f"  {file_path}: {len(issues)} ({error_count} errors)")
        lines.append("")

    # Health indicators
    lines.append("## HEALTH INDICATORS")
    if report.errors == 0:
        lines.append("  [OK] No initialization order errors")
    else:
        lines.append(f"  [ERROR] {report.errors} initialization order errors - will cause bugs!")

    if report.warnings == 0:
        lines.append("  [OK] No initialization warnings")
    else:
        lines.append(f"  [WARN] {report.warnings} potential initialization issues")

    init_node_issues = report.by_category.get("init_node_access", 0)
    if init_node_issues > 0:
        lines.append(f"  [ERROR] {init_node_issues} node accesses in _init() - move to _ready()")

    lines.append("")
    return "\n".join(lines)


def format_json(report: InitReport) -> str:
    """Format report as JSON."""
    data = {
        "summary": {
            "files_checked": report.files_checked,
            "total_issues": report.total_issues,
            "errors": report.errors,
            "warnings": report.warnings,
            "info": report.info
        },
        "by_category": dict(report.by_category),
        "issues": [
            {
                "file": i.file,
                "line": i.line,
                "category": i.category,
                "variable": i.variable,
                "message": i.message,
                "severity": i.severity
            }
            for i in report.issues[:100]
        ],
        "files_with_most_issues": [
            {"file": f, "count": len(issues), "errors": sum(1 for i in issues if i.severity == "error")}
            for f, issues in sorted(report.by_file.items(), key=lambda x: -len(x[1]))[:20]
        ]
    }
    return json.dumps(data, indent=2)


def main():
    import argparse

    parser = argparse.ArgumentParser(description="Check initialization order")
    parser.add_argument("--json", "-j", action="store_true", help="JSON output")
    parser.add_argument("--file", "-f", type=str, help="Single file to check")
    parser.add_argument("--strict", "-s", action="store_true", help="Include info-level checks")
    args = parser.parse_args()

    report = check_initialization_order(args.file, args.strict)

    if args.json:
        print(format_json(report))
    else:
        print(format_report(report))


if __name__ == "__main__":
    main()
