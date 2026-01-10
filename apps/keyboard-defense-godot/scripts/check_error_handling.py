#!/usr/bin/env python3
"""
Error Handling Checker

Finds missing error handling patterns:
- File operations without null checks
- JSON parsing without error handling
- Dictionary access without .get() or has()
- Array access without bounds checking
- Signal connections without validation

Usage:
    python scripts/check_error_handling.py              # Full report
    python scripts/check_error_handling.py --file game/main.gd  # Single file
    python scripts/check_error_handling.py --strict     # More patterns
    python scripts/check_error_handling.py --json       # JSON output
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
class ErrorHandlingIssue:
    """An error handling issue."""
    file: str
    line: int
    category: str
    pattern: str
    suggestion: str
    severity: str  # "warning", "info"
    context: str


@dataclass
class ErrorHandlingReport:
    """Error handling report."""
    files_checked: int = 0
    total_issues: int = 0
    warnings: int = 0
    info: int = 0
    issues: List[ErrorHandlingIssue] = field(default_factory=list)
    by_file: Dict[str, List[ErrorHandlingIssue]] = field(default_factory=lambda: defaultdict(list))
    by_category: Dict[str, int] = field(default_factory=lambda: defaultdict(int))


def analyze_file(file_path: Path, rel_path: str, strict: bool) -> List[ErrorHandlingIssue]:
    """Analyze a file for error handling issues."""
    issues = []

    try:
        content = file_path.read_text(encoding='utf-8')
        lines = content.split('\n')
    except Exception:
        return issues

    # Track context for multi-line analysis
    prev_lines: List[str] = []

    for i, line in enumerate(lines):
        stripped = line.strip()

        # Skip comments
        if stripped.startswith('#'):
            prev_lines.append(stripped)
            continue

        code_part = line.split('#')[0]  # Remove inline comments

        # File operations without null checks
        # FileAccess.open without checking result
        if re.search(r'FileAccess\.open\s*\(', code_part):
            # Check if next few lines have a null check
            has_check = False
            for j in range(max(0, i-2), min(len(lines), i+3)):
                check_line = lines[j]
                if 'if' in check_line and ('null' in check_line or 'not' in check_line or '!' in check_line):
                    has_check = True
                    break
                if '.get_error()' in check_line or 'OK' in check_line:
                    has_check = True
                    break

            if not has_check:
                issues.append(ErrorHandlingIssue(
                    file=rel_path,
                    line=i + 1,
                    category="file_io",
                    pattern="FileAccess.open without null check",
                    suggestion="Check if file != null before using",
                    severity="warning",
                    context=stripped[:60]
                ))

        # DirAccess.open without null check
        if re.search(r'DirAccess\.open\s*\(', code_part):
            has_check = False
            for j in range(max(0, i-2), min(len(lines), i+3)):
                check_line = lines[j]
                if 'if' in check_line and ('null' in check_line or 'not' in check_line):
                    has_check = True
                    break

            if not has_check:
                issues.append(ErrorHandlingIssue(
                    file=rel_path,
                    line=i + 1,
                    category="file_io",
                    pattern="DirAccess.open without null check",
                    suggestion="Check if dir != null before using",
                    severity="warning",
                    context=stripped[:60]
                ))

        # JSON parsing without error handling
        if re.search(r'JSON\.parse_string\s*\(', code_part):
            has_check = False
            for j in range(max(0, i-2), min(len(lines), i+3)):
                check_line = lines[j]
                if 'if' in check_line or 'error' in check_line.lower() or 'null' in check_line:
                    has_check = True
                    break

            if not has_check:
                issues.append(ErrorHandlingIssue(
                    file=rel_path,
                    line=i + 1,
                    category="json",
                    pattern="JSON.parse_string without error check",
                    suggestion="Check result for null or use try pattern",
                    severity="warning",
                    context=stripped[:60]
                ))

        # Dictionary access patterns
        # Direct bracket access that might fail
        dict_access = re.findall(r'\[(["\'][^"\']+["\'])\]', code_part)
        if dict_access and not '.get(' in code_part and not '.has(' in code_part:
            # Check if there's a has() check nearby
            has_guard = False
            for j in range(max(0, i-3), i):
                prev = lines[j]
                if '.has(' in prev or '.get(' in prev:
                    has_guard = True
                    break

            if not has_guard and strict:
                issues.append(ErrorHandlingIssue(
                    file=rel_path,
                    line=i + 1,
                    category="dictionary",
                    pattern="Direct dictionary access without .get() or .has()",
                    suggestion="Use .get(key, default) for safe access",
                    severity="info",
                    context=stripped[:60]
                ))

        # Array index access that might be out of bounds
        array_access = re.search(r'\[(\w+)\]', code_part)
        if array_access and not re.search(r'\[["\']', code_part):  # Not string key
            var_name = array_access.group(1)
            # Check if it's a numeric index variable
            if var_name.isdigit() or var_name in ['i', 'j', 'k', 'idx', 'index']:
                # Check for bounds checking
                has_bounds = False
                for j in range(max(0, i-5), i):
                    prev = lines[j]
                    if '.size()' in prev or 'len(' in prev or 'range(' in prev:
                        has_bounds = True
                        break
                    if 'for ' in prev and ' in ' in prev:
                        has_bounds = True
                        break

                if not has_bounds and strict:
                    issues.append(ErrorHandlingIssue(
                        file=rel_path,
                        line=i + 1,
                        category="array",
                        pattern="Array index access without visible bounds check",
                        suggestion="Ensure index is within bounds before access",
                        severity="info",
                        context=stripped[:60]
                    ))

        # get_node() without null check
        if re.search(r'get_node\s*\([^)]+\)\.', code_part):
            # Immediate method call on get_node result
            issues.append(ErrorHandlingIssue(
                file=rel_path,
                line=i + 1,
                category="node",
                pattern="get_node() with immediate method call",
                suggestion="Check node exists or use get_node_or_null()",
                severity="warning",
                context=stripped[:60]
            ))

        # $NodePath without null check - chained calls
        if re.search(r'\$[\w/]+\.', code_part) and not '@onready' in code_part:
            # Check if there's an if guard
            has_guard = False
            for j in range(max(0, i-2), i):
                prev = lines[j]
                if 'if' in prev and ('$' in prev or 'has_node' in prev):
                    has_guard = True
                    break

            if not has_guard and strict:
                issues.append(ErrorHandlingIssue(
                    file=rel_path,
                    line=i + 1,
                    category="node",
                    pattern="$NodePath with chained call",
                    suggestion="Use @onready or check has_node() first",
                    severity="info",
                    context=stripped[:60]
                ))

        # ResourceLoader.load without null check
        if re.search(r'ResourceLoader\.load\s*\(', code_part) or re.search(r'\bload\s*\(["\']res://', code_part):
            has_check = False
            for j in range(max(0, i-2), min(len(lines), i+3)):
                check_line = lines[j]
                if 'if' in check_line and ('null' in check_line or 'not' in check_line):
                    has_check = True
                    break

            if not has_check and strict:
                issues.append(ErrorHandlingIssue(
                    file=rel_path,
                    line=i + 1,
                    category="resource",
                    pattern="Resource load without null check",
                    suggestion="Check if resource loaded successfully",
                    severity="info",
                    context=stripped[:60]
                ))

        # parseInt/parseFloat equivalents without validation
        if re.search(r'\.to_int\s*\(\s*\)', code_part) or re.search(r'int\s*\([^)]*str', code_part):
            issues.append(ErrorHandlingIssue(
                file=rel_path,
                line=i + 1,
                category="parsing",
                pattern="String to int conversion",
                suggestion="Validate string is numeric with is_valid_int() first",
                severity="info",
                context=stripped[:60]
            ))

        if re.search(r'\.to_float\s*\(\s*\)', code_part) or re.search(r'float\s*\([^)]*str', code_part):
            issues.append(ErrorHandlingIssue(
                file=rel_path,
                line=i + 1,
                category="parsing",
                pattern="String to float conversion",
                suggestion="Validate string is numeric with is_valid_float() first",
                severity="info",
                context=stripped[:60]
            ))

        # Division without zero check
        div_match = re.search(r'/\s*(\w+)(?!\s*\.\s*0)', code_part)
        if div_match and not '//' in code_part:  # Not a comment
            divisor = div_match.group(1)
            if divisor not in ['2', '4', '8', '16', '32', '64', '100', '1000', '255', '256']:
                has_check = False
                for j in range(max(0, i-3), i):
                    prev = lines[j]
                    if divisor in prev and ('!= 0' in prev or '> 0' in prev or '== 0' in prev):
                        has_check = True
                        break

                if not has_check and strict:
                    issues.append(ErrorHandlingIssue(
                        file=rel_path,
                        line=i + 1,
                        category="math",
                        pattern=f"Division by variable '{divisor}'",
                        suggestion="Check divisor != 0 before division",
                        severity="info",
                        context=stripped[:60]
                    ))

        prev_lines.append(stripped)
        if len(prev_lines) > 10:
            prev_lines.pop(0)

    return issues


def check_error_handling(target_file: Optional[str] = None, strict: bool = False) -> ErrorHandlingReport:
    """Check for error handling issues across the project."""
    report = ErrorHandlingReport()

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
            report.by_category[issue.category] += 1

            if issue.severity == "warning":
                report.warnings += 1
            else:
                report.info += 1

    return report


def format_report(report: ErrorHandlingReport) -> str:
    """Format error handling report as text."""
    lines = []
    lines.append("=" * 60)
    lines.append("ERROR HANDLING CHECKER - KEYBOARD DEFENSE")
    lines.append("=" * 60)
    lines.append("")

    # Summary
    lines.append("## SUMMARY")
    lines.append(f"  Files checked:      {report.files_checked}")
    lines.append(f"  Total issues:       {report.total_issues}")
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
        lines.append("## ERROR HANDLING ISSUES")

        # Sort by severity then file
        sorted_issues = sorted(report.issues, key=lambda x: (0 if x.severity == "warning" else 1, x.file, x.line))

        for issue in sorted_issues[:50]:
            severity_marker = "[WARN]" if issue.severity == "warning" else "[INFO]"
            lines.append(f"  {severity_marker} {issue.file}:{issue.line}")
            lines.append(f"    {issue.pattern}")
            lines.append(f"    Suggestion: {issue.suggestion}")

        if len(report.issues) > 50:
            lines.append(f"  ... and {len(report.issues) - 50} more issues")
        lines.append("")

    # Files with most issues
    if report.by_file:
        lines.append("## FILES WITH MOST ISSUES")
        sorted_files = sorted(report.by_file.items(), key=lambda x: -len(x[1]))[:10]
        for file_path, issues in sorted_files:
            warning_count = sum(1 for i in issues if i.severity == "warning")
            lines.append(f"  {file_path}: {len(issues)} ({warning_count} warnings)")
        lines.append("")

    # Health indicators
    lines.append("## HEALTH INDICATORS")
    if report.warnings == 0:
        lines.append("  [OK] No error handling warnings")
    elif report.warnings < 10:
        lines.append(f"  [INFO] {report.warnings} error handling warnings")
    elif report.warnings < 30:
        lines.append(f"  [WARN] {report.warnings} error handling warnings - review recommended")
    else:
        lines.append(f"  [WARN] {report.warnings} error handling warnings - needs attention")

    file_io_count = report.by_category.get("file_io", 0)
    if file_io_count > 0:
        lines.append(f"  [WARN] {file_io_count} file I/O operations may need error handling")

    json_count = report.by_category.get("json", 0)
    if json_count > 0:
        lines.append(f"  [WARN] {json_count} JSON operations may need error handling")

    lines.append("")
    return "\n".join(lines)


def format_json(report: ErrorHandlingReport) -> str:
    """Format report as JSON."""
    data = {
        "summary": {
            "files_checked": report.files_checked,
            "total_issues": report.total_issues,
            "warnings": report.warnings,
            "info": report.info
        },
        "by_category": dict(report.by_category),
        "issues": [
            {
                "file": i.file,
                "line": i.line,
                "category": i.category,
                "pattern": i.pattern,
                "suggestion": i.suggestion,
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

    parser = argparse.ArgumentParser(description="Check error handling patterns")
    parser.add_argument("--json", "-j", action="store_true", help="JSON output")
    parser.add_argument("--file", "-f", type=str, help="Single file to check")
    parser.add_argument("--strict", "-s", action="store_true", help="Include info-level issues")
    args = parser.parse_args()

    report = check_error_handling(args.file, args.strict)

    if args.json:
        print(format_json(report))
    else:
        print(format_report(report))


if __name__ == "__main__":
    main()
