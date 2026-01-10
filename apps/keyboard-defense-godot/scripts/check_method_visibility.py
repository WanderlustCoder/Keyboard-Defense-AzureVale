#!/usr/bin/env python3
"""
Method Visibility Checker

Finds methods that should potentially be private:
- Methods only called from within the same file
- Helper methods with generic names
- Methods that appear to be internal implementation

Usage:
    python scripts/check_method_visibility.py              # Full report
    python scripts/check_method_visibility.py --file game/main.gd  # Single file
    python scripts/check_method_visibility.py --strict     # More patterns
    python scripts/check_method_visibility.py --json       # JSON output
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

# Helper method name patterns (often should be private)
HELPER_PATTERNS = [
    r'^do_',
    r'^handle_',
    r'^process_',
    r'^compute_',
    r'^calculate_',
    r'^internal_',
    r'^helper_',
    r'^impl_',
    r'_impl$',
    r'_internal$',
    r'_helper$',
]


@dataclass
class MethodInfo:
    """Information about a method."""
    file: str
    line: int
    name: str
    is_private: bool
    is_static: bool
    call_count_internal: int = 0
    call_count_external: int = 0
    callers: List[str] = field(default_factory=list)


@dataclass
class VisibilityIssue:
    """A method visibility issue."""
    file: str
    line: int
    method: str
    issue_type: str
    message: str
    severity: str  # "warning", "info"


@dataclass
class VisibilityReport:
    """Method visibility report."""
    files_checked: int = 0
    total_methods: int = 0
    public_methods: int = 0
    private_methods: int = 0
    issues_found: int = 0
    methods: Dict[str, List[MethodInfo]] = field(default_factory=lambda: defaultdict(list))
    issues: List[VisibilityIssue] = field(default_factory=list)
    by_file: Dict[str, List[VisibilityIssue]] = field(default_factory=lambda: defaultdict(list))


def extract_methods(file_path: Path, rel_path: str) -> List[MethodInfo]:
    """Extract method declarations from a file."""
    methods = []

    try:
        content = file_path.read_text(encoding='utf-8')
        lines = content.split('\n')
    except Exception:
        return methods

    for i, line in enumerate(lines):
        stripped = line.strip()

        func_match = re.match(r'^(static\s+)?func\s+(\w+)\s*\(', stripped)
        if func_match:
            is_static = func_match.group(1) is not None
            func_name = func_match.group(2)
            is_private = func_name.startswith('_')

            methods.append(MethodInfo(
                file=rel_path,
                line=i + 1,
                name=func_name,
                is_private=is_private,
                is_static=is_static
            ))

    return methods


def find_method_calls(file_path: Path, rel_path: str, all_methods: Dict[str, Set[str]]) -> Dict[str, List[str]]:
    """Find method calls in a file."""
    calls = defaultdict(list)  # method_name -> list of files calling it

    try:
        content = file_path.read_text(encoding='utf-8')
    except Exception:
        return calls

    for method_name in all_methods.get(rel_path, set()):
        # Count calls to this method
        # Look for method_name( pattern
        pattern = rf'\b{re.escape(method_name)}\s*\('
        if re.search(pattern, content):
            calls[method_name].append(rel_path)

    # Also check other files calling methods from this file
    for other_file, methods in all_methods.items():
        if other_file == rel_path:
            continue
        for method_name in methods:
            pattern = rf'\b{re.escape(method_name)}\s*\('
            if re.search(pattern, content):
                calls[method_name].append(rel_path)

    return calls


def check_method_visibility(target_file: Optional[str] = None, strict: bool = False) -> VisibilityReport:
    """Check method visibility across the project."""
    report = VisibilityReport()

    if target_file:
        gd_files = [PROJECT_ROOT / target_file]
    else:
        gd_files = list(PROJECT_ROOT.glob("**/*.gd"))

    # First pass: collect all methods
    all_methods: Dict[str, Set[str]] = defaultdict(set)
    method_info: Dict[str, Dict[str, MethodInfo]] = defaultdict(dict)

    for gd_file in gd_files:
        if ".godot" in str(gd_file) or "addons" in str(gd_file):
            continue

        if not gd_file.exists():
            continue

        rel_path = str(gd_file.relative_to(PROJECT_ROOT))
        report.files_checked += 1

        methods = extract_methods(gd_file, rel_path)
        for method in methods:
            all_methods[rel_path].add(method.name)
            method_info[rel_path][method.name] = method
            report.methods[rel_path].append(method)
            report.total_methods += 1

            if method.is_private:
                report.private_methods += 1
            else:
                report.public_methods += 1

    # Second pass: find calls
    call_locations: Dict[str, Dict[str, List[str]]] = defaultdict(lambda: defaultdict(list))

    for gd_file in gd_files:
        if ".godot" in str(gd_file) or "addons" in str(gd_file):
            continue

        if not gd_file.exists():
            continue

        rel_path = str(gd_file.relative_to(PROJECT_ROOT))

        try:
            content = gd_file.read_text(encoding='utf-8')
        except Exception:
            continue

        # Check each method in each file
        for file_with_methods, methods in all_methods.items():
            for method_name in methods:
                # Skip private methods and built-in callbacks
                if method_name.startswith('_'):
                    continue

                pattern = rf'\b{re.escape(method_name)}\s*\('
                if re.search(pattern, content):
                    call_locations[file_with_methods][method_name].append(rel_path)

    # Analyze visibility issues
    for file_path, methods in method_info.items():
        for method_name, method in methods.items():
            # Skip private methods
            if method.is_private:
                continue

            # Skip Godot callbacks
            if method_name in ['_ready', '_process', '_physics_process', '_input', '_draw',
                               '_enter_tree', '_exit_tree', '_notification', '_init']:
                continue

            callers = call_locations[file_path].get(method_name, [])
            method.callers = callers

            # Check if only called internally
            external_callers = [c for c in callers if c != file_path]
            internal_callers = [c for c in callers if c == file_path]

            method.call_count_internal = len(internal_callers)
            method.call_count_external = len(external_callers)

            # Issue: Public method only called internally
            if len(callers) > 0 and len(external_callers) == 0:
                report.issues.append(VisibilityIssue(
                    file=file_path,
                    line=method.line,
                    method=method_name,
                    issue_type="internal_only",
                    message=f"Public method '{method_name}' only called within same file",
                    severity="info"
                ))
                report.by_file[file_path].append(report.issues[-1])

            # Issue: Helper-like name but public
            for pattern in HELPER_PATTERNS:
                if re.match(pattern, method_name):
                    report.issues.append(VisibilityIssue(
                        file=file_path,
                        line=method.line,
                        method=method_name,
                        issue_type="helper_pattern",
                        message=f"Method '{method_name}' has helper-like name but is public",
                        severity="info"
                    ))
                    report.by_file[file_path].append(report.issues[-1])
                    break

            # Issue: Never called (dead code)
            if len(callers) == 0 and strict:
                # Skip common entry points
                if method_name not in ['setup', 'initialize', 'run', 'start', 'main']:
                    report.issues.append(VisibilityIssue(
                        file=file_path,
                        line=method.line,
                        method=method_name,
                        issue_type="never_called",
                        message=f"Public method '{method_name}' appears to never be called",
                        severity="warning"
                    ))
                    report.by_file[file_path].append(report.issues[-1])

    report.issues_found = len(report.issues)
    return report


def format_report(report: VisibilityReport) -> str:
    """Format visibility report as text."""
    lines = []
    lines.append("=" * 60)
    lines.append("METHOD VISIBILITY CHECKER - KEYBOARD DEFENSE")
    lines.append("=" * 60)
    lines.append("")

    # Summary
    lines.append("## SUMMARY")
    lines.append(f"  Files checked:      {report.files_checked}")
    lines.append(f"  Total methods:      {report.total_methods}")
    lines.append(f"  Public methods:     {report.public_methods}")
    lines.append(f"  Private methods:    {report.private_methods}")
    lines.append(f"  Issues found:       {report.issues_found}")
    if report.total_methods > 0:
        private_pct = report.private_methods / report.total_methods * 100
        lines.append(f"  Private ratio:      {private_pct:.0f}%")
    lines.append("")

    # Issues by type
    by_type: Dict[str, List] = defaultdict(list)
    for issue in report.issues:
        by_type[issue.issue_type].append(issue)

    if by_type:
        lines.append("## ISSUES BY TYPE")
        for issue_type, issues in sorted(by_type.items(), key=lambda x: -len(x[1])):
            lines.append(f"  {issue_type}: {len(issues)}")
        lines.append("")

    # Issues
    if report.issues:
        lines.append("## VISIBILITY ISSUES")

        sorted_issues = sorted(report.issues, key=lambda x: (0 if x.severity == "warning" else 1, x.file, x.line))

        for issue in sorted_issues[:40]:
            severity_marker = "[WARN]" if issue.severity == "warning" else "[INFO]"
            lines.append(f"  {severity_marker} {issue.file}:{issue.line}")
            lines.append(f"    {issue.message}")

        if len(report.issues) > 40:
            lines.append(f"  ... and {len(report.issues) - 40} more issues")
        lines.append("")

    # Files with most issues
    if report.by_file:
        lines.append("## FILES WITH MOST VISIBILITY ISSUES")
        sorted_files = sorted(report.by_file.items(), key=lambda x: -len(x[1]))[:10]
        for file_path, issues in sorted_files:
            lines.append(f"  {file_path}: {len(issues)}")
        lines.append("")

    # Health indicators
    lines.append("## HEALTH INDICATORS")

    if report.total_methods > 0:
        private_pct = report.private_methods / report.total_methods * 100
        if private_pct >= 40:
            lines.append(f"  [OK] Good encapsulation ({private_pct:.0f}% private)")
        elif private_pct >= 20:
            lines.append(f"  [INFO] Moderate encapsulation ({private_pct:.0f}% private)")
        else:
            lines.append(f"  [WARN] Low encapsulation ({private_pct:.0f}% private)")

    internal_only = sum(1 for i in report.issues if i.issue_type == "internal_only")
    if internal_only > 0:
        lines.append(f"  [INFO] {internal_only} public methods only called internally")

    lines.append("")
    return "\n".join(lines)


def format_json(report: VisibilityReport) -> str:
    """Format report as JSON."""
    data = {
        "summary": {
            "files_checked": report.files_checked,
            "total_methods": report.total_methods,
            "public_methods": report.public_methods,
            "private_methods": report.private_methods,
            "issues_found": report.issues_found
        },
        "issues": [
            {
                "file": i.file,
                "line": i.line,
                "method": i.method,
                "type": i.issue_type,
                "message": i.message,
                "severity": i.severity
            }
            for i in report.issues[:100]
        ],
        "files_with_most_issues": [
            {"file": f, "count": len(issues)}
            for f, issues in sorted(report.by_file.items(), key=lambda x: -len(x[1]))[:20]
        ]
    }
    return json.dumps(data, indent=2)


def main():
    import argparse

    parser = argparse.ArgumentParser(description="Check method visibility")
    parser.add_argument("--json", "-j", action="store_true", help="JSON output")
    parser.add_argument("--file", "-f", type=str, help="Single file to check")
    parser.add_argument("--strict", "-s", action="store_true", help="Include dead code checks")
    args = parser.parse_args()

    report = check_method_visibility(args.file, args.strict)

    if args.json:
        print(format_json(report))
    else:
        print(format_report(report))


if __name__ == "__main__":
    main()
