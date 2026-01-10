#!/usr/bin/env python3
"""
Godot Patterns Checker

Finds common Godot anti-patterns and potential issues:
- Deprecated API usage
- Common mistakes (yield vs await, connect syntax)
- Performance anti-patterns
- Node lifecycle issues

Usage:
    python scripts/check_godot_patterns.py              # Full report
    python scripts/check_godot_patterns.py --file game/main.gd  # Single file
    python scripts/check_godot_patterns.py --strict     # More patterns
    python scripts/check_godot_patterns.py --json       # JSON output
"""

import json
import re
import sys
from collections import defaultdict
from dataclasses import dataclass, field
from pathlib import Path
from typing import Dict, List, Optional, Tuple

# Project paths
SCRIPT_DIR = Path(__file__).parent
PROJECT_ROOT = SCRIPT_DIR.parent

# Pattern definitions
PATTERNS = {
    # Deprecated in Godot 4
    "deprecated": [
        (r'\byield\s*\(', "yield() is deprecated, use await instead", "error"),
        (r'\.connect\s*\(\s*["\']', "String-based connect() is deprecated, use Callable", "warning"),
        (r'\.disconnect\s*\(\s*["\']', "String-based disconnect() is deprecated", "warning"),
        (r'\binstance\s*\(\s*\)', "instance() is deprecated, use instantiate()", "error"),
        (r'\bget_tree\(\)\.change_scene\s*\(', "change_scene() is deprecated, use change_scene_to_file()", "warning"),
        (r'\bget_viewport\(\)\.size', "Use get_viewport_rect().size instead", "info"),
        (r'\bKinematicBody', "KinematicBody is deprecated, use CharacterBody2D/3D", "error"),
        (r'\bRigidBody\b(?!2D|3D)', "RigidBody without suffix is deprecated", "warning"),
        (r'\bArea\b(?!2D|3D)', "Area without suffix is deprecated", "warning"),
        (r'\bSpatial\b', "Spatial is deprecated, use Node3D", "error"),
        (r'\bToolButton\b', "ToolButton is deprecated, use Button", "warning"),
        (r'\.rect_position\b', "rect_position is deprecated, use position", "warning"),
        (r'\.rect_size\b', "rect_size is deprecated, use size", "warning"),
        (r'\.rect_min_size\b', "rect_min_size is deprecated, use custom_minimum_size", "warning"),
        (r'\bmargin_left\b', "margin_* is deprecated, use offset_*", "info"),
        (r'\bmargin_right\b', "margin_* is deprecated, use offset_*", "info"),
        (r'\bmargin_top\b', "margin_* is deprecated, use offset_*", "info"),
        (r'\bmargin_bottom\b', "margin_* is deprecated, use offset_*", "info"),
    ],

    # Common mistakes
    "mistakes": [
        (r'if\s+\w+\s*==\s*null\s*:', "Use 'is null' or 'if not var:' for null checks", "info"),
        (r'if\s+\w+\s*!=\s*null\s*:', "Use 'is not null' or 'if var:' for null checks", "info"),
        (r'\.emit\(\)(?!\s*#)', "Signal emit without parameters - verify this is intentional", "info"),
        (r'func\s+_ready\s*\([^)]+\)', "_ready() should not have parameters", "error"),
        (r'func\s+_process\s*\(\s*\)', "_process() must have delta parameter", "error"),
        (r'func\s+_physics_process\s*\(\s*\)', "_physics_process() must have delta parameter", "error"),
        (r'func\s+_input\s*\(\s*\)', "_input() must have event parameter", "error"),
        (r'\.queue_free\(\).*\.', "Accessing object after queue_free() is unsafe", "warning"),
        (r'return\s+await\s', "return await may not work as expected in some contexts", "info"),
    ],

    # Performance patterns
    "performance": [
        (r'for\s+\w+\s+in\s+get_children\(\)', "Cache get_children() result if iterating frequently", "info"),
        (r'for\s+\w+\s+in\s+get_tree\(\)', "Cache get_tree() calls in hot paths", "info"),
        (r'\.find_child\s*\([^)]+\)\s*\n.*\.find_child', "Multiple find_child() calls - consider caching", "info"),
        (r'str\s*\([^)]+\)\s*\+\s*str\s*\(', "Multiple str() concatenations - use % or format()", "info"),
        (r'\.size\(\)\s*==\s*0', "Use .is_empty() instead of .size() == 0", "info"),
        (r'\.size\(\)\s*>\s*0', "Use not .is_empty() instead of .size() > 0", "info"),
        (r'\.size\(\)\s*!=\s*0', "Use not .is_empty() instead of .size() != 0", "info"),
        (r'len\s*\([^)]+\)\s*==\s*0', "Use .is_empty() instead of len() == 0", "info"),
    ],

    # Node lifecycle
    "lifecycle": [
        (r'func\s+_init\s*\(.*\).*:\s*\n.*\$', "Accessing $node in _init() - nodes not ready yet", "error"),
        (r'@onready.*=.*\$.*\$', "Nested $node paths in @onready may fail", "warning"),
        (r'get_node\s*\([^)]+\)\s*\n.*_init', "get_node() in _init() - scene tree not ready", "warning"),
        (r'add_child\s*\(.*\).*\n.*queue_free', "Adding then immediately freeing child is suspicious", "warning"),
    ],

    # Strict patterns (only with --strict)
    "strict": [
        (r'print\s*\(', "Debug print statement", "info"),
        (r'printt\s*\(', "Debug printt statement", "info"),
        (r'prints\s*\(', "Debug prints statement", "info"),
        (r'printerr\s*\(', "Error print - ensure this is intentional", "info"),
        (r'breakpoint', "Breakpoint in code", "warning"),
        (r'assert\s*\(', "Assert statement - may be disabled in release", "info"),
        (r'OS\.is_debug_build', "Debug build check - ensure fallback exists", "info"),
    ]
}


@dataclass
class PatternIssue:
    """A pattern issue."""
    file: str
    line: int
    pattern_type: str
    message: str
    severity: str  # "error", "warning", "info"
    context: str


@dataclass
class PatternReport:
    """Pattern analysis report."""
    files_checked: int = 0
    total_issues: int = 0
    errors: int = 0
    warnings: int = 0
    info: int = 0
    issues: List[PatternIssue] = field(default_factory=list)
    by_file: Dict[str, List[PatternIssue]] = field(default_factory=lambda: defaultdict(list))
    by_type: Dict[str, int] = field(default_factory=lambda: defaultdict(int))
    by_pattern: Dict[str, int] = field(default_factory=lambda: defaultdict(int))


def analyze_file(file_path: Path, rel_path: str, strict: bool) -> List[PatternIssue]:
    """Analyze a file for Godot patterns."""
    issues = []

    try:
        content = file_path.read_text(encoding='utf-8')
        lines = content.split('\n')
    except Exception:
        return issues

    # Determine which pattern categories to check
    categories = ["deprecated", "mistakes", "performance", "lifecycle"]
    if strict:
        categories.append("strict")

    for category in categories:
        if category not in PATTERNS:
            continue

        for pattern, message, severity in PATTERNS[category]:
            for i, line in enumerate(lines):
                # Skip comments
                stripped = line.strip()
                if stripped.startswith('#'):
                    continue

                # Remove inline comments for matching
                code_part = line.split('#')[0]

                if re.search(pattern, code_part):
                    issues.append(PatternIssue(
                        file=rel_path,
                        line=i + 1,
                        pattern_type=category,
                        message=message,
                        severity=severity,
                        context=stripped[:60]
                    ))

    return issues


def check_godot_patterns(target_file: Optional[str] = None, strict: bool = False) -> PatternReport:
    """Check for Godot patterns across the project."""
    report = PatternReport()

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
            report.total_issues += 1
            report.by_type[issue.pattern_type] += 1
            report.by_pattern[issue.message] += 1

            if issue.severity == "error":
                report.errors += 1
            elif issue.severity == "warning":
                report.warnings += 1
            else:
                report.info += 1

    return report


def format_report(report: PatternReport) -> str:
    """Format pattern report as text."""
    lines = []
    lines.append("=" * 60)
    lines.append("GODOT PATTERNS CHECKER - KEYBOARD DEFENSE")
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

    # By type
    if report.by_type:
        lines.append("## ISSUES BY CATEGORY")
        for pattern_type, count in sorted(report.by_type.items(), key=lambda x: -x[1]):
            lines.append(f"  {pattern_type}: {count}")
        lines.append("")

    # Most common patterns
    if report.by_pattern:
        lines.append("## MOST COMMON PATTERNS")
        for pattern, count in sorted(report.by_pattern.items(), key=lambda x: -x[1])[:15]:
            lines.append(f"  {count}x: {pattern[:50]}")
        lines.append("")

    # Issues (errors and warnings first)
    if report.issues:
        lines.append("## PATTERN ISSUES")

        # Sort by severity then file
        def severity_order(issue):
            order = {"error": 0, "warning": 1, "info": 2}
            return (order.get(issue.severity, 3), issue.file, issue.line)

        sorted_issues = sorted(report.issues, key=severity_order)

        for issue in sorted_issues[:50]:
            severity_marker = {
                "error": "[ERROR]",
                "warning": "[WARN]",
                "info": "[INFO]"
            }.get(issue.severity, "[???]")

            lines.append(f"  {severity_marker} {issue.file}:{issue.line}")
            lines.append(f"    {issue.message}")

        if len(report.issues) > 50:
            lines.append(f"  ... and {len(report.issues) - 50} more issues")
        lines.append("")

    # Files with most issues
    if report.by_file:
        lines.append("## FILES WITH MOST ISSUES")
        sorted_files = sorted(report.by_file.items(), key=lambda x: -len(x[1]))[:10]
        for file_path, issues in sorted_files:
            error_count = sum(1 for i in issues if i.severity == "error")
            warning_count = sum(1 for i in issues if i.severity == "warning")
            lines.append(f"  {file_path}: {len(issues)} ({error_count} errors, {warning_count} warnings)")
        lines.append("")

    # Health indicators
    lines.append("## HEALTH INDICATORS")
    if report.errors == 0:
        lines.append("  [OK] No Godot pattern errors")
    else:
        lines.append(f"  [ERROR] {report.errors} pattern errors - need fixing")

    if report.warnings == 0:
        lines.append("  [OK] No pattern warnings")
    elif report.warnings < 20:
        lines.append(f"  [INFO] {report.warnings} pattern warnings")
    else:
        lines.append(f"  [WARN] {report.warnings} pattern warnings - consider reviewing")

    deprecated_count = report.by_type.get("deprecated", 0)
    if deprecated_count > 0:
        lines.append(f"  [WARN] {deprecated_count} deprecated API usages")

    lines.append("")
    return "\n".join(lines)


def format_json(report: PatternReport) -> str:
    """Format report as JSON."""
    data = {
        "summary": {
            "files_checked": report.files_checked,
            "total_issues": report.total_issues,
            "errors": report.errors,
            "warnings": report.warnings,
            "info": report.info
        },
        "by_type": dict(report.by_type),
        "by_pattern": dict(sorted(report.by_pattern.items(), key=lambda x: -x[1])[:30]),
        "issues": [
            {
                "file": i.file,
                "line": i.line,
                "type": i.pattern_type,
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

    parser = argparse.ArgumentParser(description="Check Godot patterns")
    parser.add_argument("--json", "-j", action="store_true", help="JSON output")
    parser.add_argument("--file", "-f", type=str, help="Single file to check")
    parser.add_argument("--strict", "-s", action="store_true", help="Include debug prints")
    args = parser.parse_args()

    report = check_godot_patterns(args.file, args.strict)

    if args.json:
        print(format_json(report))
    else:
        print(format_report(report))


if __name__ == "__main__":
    main()
