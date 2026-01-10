#!/usr/bin/env python3
"""
Performance Linter

Finds potential performance issues in GDScript code:
- Allocations in hot paths (_process, _physics_process)
- Nested loops
- String concatenation in loops
- get_node() calls in _process
- Unoptimized patterns

Usage:
    python scripts/lint_performance.py              # Full report
    python scripts/lint_performance.py --severity high  # Only high severity
    python scripts/lint_performance.py --file game/main.gd  # Single file
    python scripts/lint_performance.py --json       # JSON output
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


@dataclass
class PerfIssue:
    """A performance issue."""
    file: str
    line: int
    severity: str  # "high", "medium", "low"
    category: str
    message: str
    code_snippet: str = ""


@dataclass
class PerfReport:
    """Performance lint report."""
    issues: List[PerfIssue] = field(default_factory=list)
    by_file: Dict[str, int] = field(default_factory=dict)
    by_category: Dict[str, int] = field(default_factory=dict)
    by_severity: Dict[str, int] = field(default_factory=dict)


# Patterns to detect
PERF_PATTERNS = [
    # High severity - likely performance problems
    {
        "pattern": re.compile(r'get_node\s*\('),
        "in_func": ["_process", "_physics_process", "_draw"],
        "severity": "high",
        "category": "hot_path_lookup",
        "message": "get_node() in hot path - cache with @onready instead"
    },
    {
        "pattern": re.compile(r'\$[A-Za-z]'),
        "in_func": ["_process", "_physics_process", "_draw"],
        "severity": "high",
        "category": "hot_path_lookup",
        "message": "$ node lookup in hot path - cache with @onready instead"
    },
    {
        "pattern": re.compile(r'\.new\s*\('),
        "in_func": ["_process", "_physics_process"],
        "severity": "high",
        "category": "hot_path_alloc",
        "message": "Object allocation in hot path - consider object pooling"
    },
    {
        "pattern": re.compile(r'Array\s*\(\s*\)'),
        "in_func": ["_process", "_physics_process"],
        "severity": "high",
        "category": "hot_path_alloc",
        "message": "Array allocation in _process - reuse array instead"
    },
    {
        "pattern": re.compile(r'Dictionary\s*\(\s*\)'),
        "in_func": ["_process", "_physics_process"],
        "severity": "high",
        "category": "hot_path_alloc",
        "message": "Dictionary allocation in _process - reuse dict instead"
    },

    # Medium severity - potential issues
    {
        "pattern": re.compile(r'for\s+\w+\s+in\s+.*for\s+\w+\s+in'),
        "in_func": None,
        "severity": "medium",
        "category": "nested_loop",
        "message": "Nested loops detected - O(n^2) complexity"
    },
    {
        "pattern": re.compile(r'\+=\s*"'),
        "in_func": None,
        "severity": "medium",
        "category": "string_concat",
        "message": "String concatenation with += - use Array.join() for many strings"
    },
    {
        "pattern": re.compile(r'str\s*\([^)]+\)\s*\+'),
        "in_func": ["_process", "_physics_process"],
        "severity": "medium",
        "category": "hot_path_string",
        "message": "String conversion in hot path - cache if possible"
    },
    {
        "pattern": re.compile(r'\.find\s*\('),
        "in_func": ["_process", "_physics_process"],
        "severity": "medium",
        "category": "hot_path_search",
        "message": "Array.find() in hot path - consider Dictionary for O(1) lookup"
    },
    {
        "pattern": re.compile(r'load\s*\('),
        "in_func": ["_process", "_physics_process", "_ready"],
        "severity": "medium",
        "category": "dynamic_load",
        "message": "load() at runtime - use preload() for static resources"
    },
    {
        "pattern": re.compile(r'\.get_children\s*\('),
        "in_func": ["_process", "_physics_process"],
        "severity": "medium",
        "category": "hot_path_tree",
        "message": "get_children() in hot path - cache children list"
    },

    # Low severity - suggestions
    {
        "pattern": re.compile(r'yield\s*\('),
        "in_func": None,
        "severity": "low",
        "category": "deprecated",
        "message": "yield() is deprecated - use await instead"
    },
    {
        "pattern": re.compile(r'\.size\s*\(\s*\)\s*>\s*0'),
        "in_func": None,
        "severity": "low",
        "category": "style",
        "message": "Use 'not array.is_empty()' instead of 'array.size() > 0'"
    },
    {
        "pattern": re.compile(r'len\s*\([^)]+\)\s*==\s*0'),
        "in_func": None,
        "severity": "low",
        "category": "style",
        "message": "Use '.is_empty()' instead of 'len() == 0'"
    },
    {
        "pattern": re.compile(r'range\s*\(\s*0\s*,'),
        "in_func": None,
        "severity": "low",
        "category": "style",
        "message": "range(0, n) can be simplified to range(n)"
    },
]


def get_current_function(lines: List[str], line_idx: int) -> Optional[str]:
    """Find the function containing this line."""
    indent = len(lines[line_idx]) - len(lines[line_idx].lstrip())

    for i in range(line_idx, -1, -1):
        line = lines[i]
        line_indent = len(line) - len(line.lstrip())
        stripped = line.strip()

        # Found function at same or lower indent
        if line_indent < indent or i == line_idx:
            func_match = re.match(r'^(?:static\s+)?func\s+(\w+)', stripped)
            if func_match:
                return func_match.group(1)

    return None


def check_nested_loops(lines: List[str], start_idx: int) -> Optional[Tuple[int, str]]:
    """Check for nested loops starting from a for/while line."""
    first_line = lines[start_idx].strip()
    if not (first_line.startswith('for ') or first_line.startswith('while ')):
        return None

    base_indent = len(lines[start_idx]) - len(lines[start_idx].lstrip())

    for i in range(start_idx + 1, min(start_idx + 50, len(lines))):
        line = lines[i]
        if not line.strip():
            continue

        current_indent = len(line) - len(line.lstrip())
        if current_indent <= base_indent:
            break

        stripped = line.strip()
        if stripped.startswith('for ') or stripped.startswith('while '):
            return i, stripped

    return None


def analyze_file(filepath: Path) -> List[PerfIssue]:
    """Analyze a file for performance issues."""
    issues = []
    rel_path = str(filepath.relative_to(PROJECT_ROOT))

    try:
        content = filepath.read_text(encoding="utf-8")
        lines = content.split('\n')
    except Exception:
        return issues

    for i, line in enumerate(lines):
        stripped = line.strip()
        if not stripped or stripped.startswith('#'):
            continue

        current_func = get_current_function(lines, i)

        # Check standard patterns
        for pattern_info in PERF_PATTERNS:
            if pattern_info["pattern"].search(stripped):
                # Check if we need to be in specific function
                if pattern_info["in_func"]:
                    if current_func not in pattern_info["in_func"]:
                        continue

                issues.append(PerfIssue(
                    file=rel_path,
                    line=i + 1,
                    severity=pattern_info["severity"],
                    category=pattern_info["category"],
                    message=pattern_info["message"],
                    code_snippet=stripped[:60]
                ))

        # Check for nested loops (special case)
        if stripped.startswith('for ') or stripped.startswith('while '):
            nested = check_nested_loops(lines, i)
            if nested:
                nested_line, nested_code = nested
                issues.append(PerfIssue(
                    file=rel_path,
                    line=i + 1,
                    severity="medium",
                    category="nested_loop",
                    message=f"Nested loop at line {nested_line + 1} - O(n^2) complexity",
                    code_snippet=stripped[:40] + " -> " + nested_code[:30]
                ))

    return issues


def analyze_performance(file_filter: Optional[str] = None,
                        severity_filter: Optional[str] = None) -> PerfReport:
    """Analyze performance across the codebase."""
    report = PerfReport()

    for gd_file in PROJECT_ROOT.glob("**/*.gd"):
        if ".godot" in str(gd_file) or "addons" in str(gd_file):
            continue

        rel_path = str(gd_file.relative_to(PROJECT_ROOT))
        if file_filter and file_filter not in rel_path:
            continue

        issues = analyze_file(gd_file)

        # Apply severity filter
        if severity_filter:
            issues = [i for i in issues if i.severity == severity_filter]

        for issue in issues:
            report.issues.append(issue)
            report.by_file[issue.file] = report.by_file.get(issue.file, 0) + 1
            report.by_category[issue.category] = report.by_category.get(issue.category, 0) + 1
            report.by_severity[issue.severity] = report.by_severity.get(issue.severity, 0) + 1

    # Sort by severity then file
    severity_order = {"high": 0, "medium": 1, "low": 2}
    report.issues.sort(key=lambda x: (severity_order.get(x.severity, 1), x.file, x.line))

    return report


def format_report(report: PerfReport) -> str:
    """Format performance report as text."""
    lines = []
    lines.append("=" * 60)
    lines.append("PERFORMANCE LINTER - KEYBOARD DEFENSE")
    lines.append("=" * 60)
    lines.append("")

    # Summary
    lines.append("## SUMMARY")
    lines.append(f"  Total issues:    {len(report.issues)}")
    lines.append("")

    # By severity
    lines.append("  By severity:")
    for sev in ["high", "medium", "low"]:
        count = report.by_severity.get(sev, 0)
        if count > 0:
            marker = "[!]" if sev == "high" else "   "
            lines.append(f"    {marker} {sev:8} {count}")
    lines.append("")

    # By category
    lines.append("  By category:")
    sorted_cats = sorted(report.by_category.items(), key=lambda x: -x[1])
    for cat, count in sorted_cats:
        lines.append(f"    {cat:20} {count}")
    lines.append("")

    if not report.issues:
        lines.append("No performance issues found!")
        return "\n".join(lines)

    # High severity issues
    high_issues = [i for i in report.issues if i.severity == "high"]
    if high_issues:
        lines.append("## HIGH SEVERITY ISSUES")
        for issue in high_issues[:15]:
            lines.append(f"  {issue.file}:{issue.line}")
            lines.append(f"    {issue.message}")
            lines.append(f"    > {issue.code_snippet}")
        if len(high_issues) > 15:
            lines.append(f"  ... and {len(high_issues) - 15} more high severity issues")
        lines.append("")

    # Medium severity issues
    medium_issues = [i for i in report.issues if i.severity == "medium"]
    if medium_issues:
        lines.append("## MEDIUM SEVERITY ISSUES")
        for issue in medium_issues[:10]:
            lines.append(f"  {issue.file}:{issue.line}")
            lines.append(f"    {issue.message}")
        if len(medium_issues) > 10:
            lines.append(f"  ... and {len(medium_issues) - 10} more")
        lines.append("")

    # Files with most issues
    lines.append("## FILES WITH MOST ISSUES")
    sorted_files = sorted(report.by_file.items(), key=lambda x: -x[1])
    for filepath, count in sorted_files[:10]:
        lines.append(f"  {count:4} issues  {filepath}")
    lines.append("")

    # Health indicators
    lines.append("## HEALTH INDICATORS")
    high_count = report.by_severity.get("high", 0)
    if high_count > 10:
        lines.append(f"  [WARN] {high_count} high severity issues - performance may be impacted")
    elif high_count > 0:
        lines.append(f"  [INFO] {high_count} high severity issues to review")
    else:
        lines.append("  [OK] No high severity performance issues")

    hot_path_count = (
        report.by_category.get("hot_path_lookup", 0) +
        report.by_category.get("hot_path_alloc", 0) +
        report.by_category.get("hot_path_string", 0)
    )
    if hot_path_count > 0:
        lines.append(f"  [INFO] {hot_path_count} hot path issues (_process/_physics_process)")

    lines.append("")
    return "\n".join(lines)


def format_json(report: PerfReport) -> str:
    """Format report as JSON."""
    data = {
        "summary": {
            "total": len(report.issues),
            "by_severity": report.by_severity,
            "by_category": report.by_category
        },
        "issues": [
            {
                "file": i.file,
                "line": i.line,
                "severity": i.severity,
                "category": i.category,
                "message": i.message,
                "code": i.code_snippet
            }
            for i in report.issues
        ],
        "by_file": report.by_file
    }
    return json.dumps(data, indent=2)


def main():
    import argparse

    parser = argparse.ArgumentParser(description="Lint for performance issues")
    parser.add_argument("--json", "-j", action="store_true", help="JSON output")
    parser.add_argument("--file", "-f", type=str, help="Filter by file path")
    parser.add_argument("--severity", "-s", type=str, choices=["high", "medium", "low"],
                        help="Filter by severity")
    args = parser.parse_args()

    report = analyze_performance(args.file, args.severity)

    if args.json:
        print(format_json(report))
    else:
        print(format_report(report))


if __name__ == "__main__":
    main()
