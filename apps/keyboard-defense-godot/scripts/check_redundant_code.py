#!/usr/bin/env python3
"""
Redundant Code Checker

Finds potentially redundant code patterns:
- Redundant conditions (if true, if false)
- Self-assignments (x = x)
- Redundant returns (return at end of void function)
- Dead code after return/break/continue
- Redundant type conversions
- Double negations

Usage:
    python scripts/check_redundant_code.py              # Full report
    python scripts/check_redundant_code.py --file game/main.gd  # Single file
    python scripts/check_redundant_code.py --strict     # More patterns
    python scripts/check_redundant_code.py --json       # JSON output
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


@dataclass
class RedundantIssue:
    """A redundant code issue."""
    file: str
    line: int
    category: str
    pattern: str
    suggestion: str
    severity: str  # "warning", "info"
    context: str


@dataclass
class RedundantReport:
    """Redundant code report."""
    files_checked: int = 0
    total_issues: int = 0
    warnings: int = 0
    info: int = 0
    issues: List[RedundantIssue] = field(default_factory=list)
    by_file: Dict[str, List[RedundantIssue]] = field(default_factory=lambda: defaultdict(list))
    by_category: Dict[str, int] = field(default_factory=lambda: defaultdict(int))


def analyze_file(file_path: Path, rel_path: str, strict: bool) -> List[RedundantIssue]:
    """Analyze a file for redundant code."""
    issues = []

    try:
        content = file_path.read_text(encoding='utf-8')
        lines = content.split('\n')
    except Exception:
        return issues

    in_function = False
    return_indent = -1  # Track indent level of return statement
    function_indent = 0

    for i, line in enumerate(lines):
        stripped = line.strip()

        # Skip comments and empty lines
        if not stripped or stripped.startswith('#'):
            continue

        code_part = line.split('#')[0]  # Remove inline comments
        current_indent = len(line) - len(line.lstrip())

        # Track function scope
        if re.match(r'^(?:static\s+)?func\s+', stripped):
            in_function = True
            return_indent = -1
            function_indent = current_indent
            continue

        # Exit function scope
        if in_function and current_indent <= function_indent and stripped:
            if re.match(r'^(func|static func|var|const|signal|class|enum)\s', stripped):
                in_function = False
                return_indent = -1

        # Check for dead code at same indent level after return/break/continue
        if return_indent >= 0 and current_indent == return_indent:
            # This is code at the same level as the return - likely dead
            # But only if it's not a block-ending statement
            if not stripped in ['else:', 'elif', 'except:', 'finally:'] and not stripped.startswith('elif '):
                issues.append(RedundantIssue(
                    file=rel_path,
                    line=i + 1,
                    category="dead_code",
                    pattern="Code after return/break/continue at same indent",
                    suggestion="Remove unreachable code",
                    severity="warning",
                    context=stripped[:60]
                ))
            return_indent = -1

        # Reset on indent change (entering/exiting block)
        if return_indent >= 0 and current_indent < return_indent:
            return_indent = -1

        # Track return/break/continue (only unconditional ones at statement start)
        if re.match(r'^(return|break|continue)\b', stripped):
            return_indent = current_indent

        # Redundant true/false conditions
        if re.search(r'if\s+true\s*:', code_part, re.IGNORECASE):
            issues.append(RedundantIssue(
                file=rel_path,
                line=i + 1,
                category="redundant_condition",
                pattern="if true:",
                suggestion="Remove condition, code always executes",
                severity="warning",
                context=stripped[:60]
            ))

        if re.search(r'if\s+false\s*:', code_part, re.IGNORECASE):
            issues.append(RedundantIssue(
                file=rel_path,
                line=i + 1,
                category="redundant_condition",
                pattern="if false:",
                suggestion="Remove block, code never executes",
                severity="warning",
                context=stripped[:60]
            ))

        # Self-assignment: x = x
        self_assign = re.search(r'\b(\w+)\s*=\s*\1\s*(?:[#\n]|$)', code_part)
        if self_assign:
            var_name = self_assign.group(1)
            # Avoid false positives with x = x + 1 patterns
            if not re.search(rf'\b{var_name}\s*=\s*{var_name}\s*[+\-*/]', code_part):
                issues.append(RedundantIssue(
                    file=rel_path,
                    line=i + 1,
                    category="self_assignment",
                    pattern=f"Self-assignment: {var_name} = {var_name}",
                    suggestion="Remove redundant assignment",
                    severity="warning",
                    context=stripped[:60]
                ))

        # Double negation: not not x, !!x
        if re.search(r'not\s+not\s+', code_part):
            issues.append(RedundantIssue(
                file=rel_path,
                line=i + 1,
                category="double_negation",
                pattern="Double negation: not not",
                suggestion="Remove double negation",
                severity="info",
                context=stripped[:60]
            ))

        # Redundant bool(): bool(true), bool(false)
        if re.search(r'bool\s*\(\s*(true|false)\s*\)', code_part, re.IGNORECASE):
            issues.append(RedundantIssue(
                file=rel_path,
                line=i + 1,
                category="redundant_conversion",
                pattern="Redundant bool() on literal",
                suggestion="Use true/false directly",
                severity="info",
                context=stripped[:60]
            ))

        # Redundant str(): str("literal")
        if re.search(r'str\s*\(\s*["\'][^"\']*["\']\s*\)', code_part):
            issues.append(RedundantIssue(
                file=rel_path,
                line=i + 1,
                category="redundant_conversion",
                pattern="Redundant str() on string literal",
                suggestion="Use string directly",
                severity="info",
                context=stripped[:60]
            ))

        # Redundant int(): int(123)
        if re.search(r'int\s*\(\s*\d+\s*\)', code_part):
            issues.append(RedundantIssue(
                file=rel_path,
                line=i + 1,
                category="redundant_conversion",
                pattern="Redundant int() on integer literal",
                suggestion="Use integer directly",
                severity="info",
                context=stripped[:60]
            ))

        # Comparison to bool literal: x == true, x == false
        if re.search(r'==\s*(true|false)\b', code_part, re.IGNORECASE):
            issues.append(RedundantIssue(
                file=rel_path,
                line=i + 1,
                category="redundant_comparison",
                pattern="Comparison to bool literal",
                suggestion="Use 'if x:' or 'if not x:' instead",
                severity="info",
                context=stripped[:60]
            ))

        if re.search(r'!=\s*(true|false)\b', code_part, re.IGNORECASE):
            issues.append(RedundantIssue(
                file=rel_path,
                line=i + 1,
                category="redundant_comparison",
                pattern="Comparison to bool literal",
                suggestion="Use 'if x:' or 'if not x:' instead",
                severity="info",
                context=stripped[:60]
            ))

        # Empty else block (strict mode)
        if strict and re.match(r'^else\s*:\s*$', stripped):
            # Check next line for pass
            if i + 1 < len(lines):
                next_stripped = lines[i + 1].strip()
                if next_stripped == 'pass':
                    issues.append(RedundantIssue(
                        file=rel_path,
                        line=i + 1,
                        category="empty_else",
                        pattern="Empty else block with pass",
                        suggestion="Remove empty else block",
                        severity="info",
                        context=stripped[:60]
                    ))

        # Redundant pass after other statements (strict)
        if strict and stripped == 'pass':
            # Check if there's content before pass at same indent
            if i > 0:
                prev_line = lines[i - 1]
                prev_stripped = prev_line.strip()
                prev_indent = len(prev_line) - len(prev_line.lstrip())
                if prev_stripped and not prev_stripped.endswith(':') and prev_indent == current_indent:
                    issues.append(RedundantIssue(
                        file=rel_path,
                        line=i + 1,
                        category="redundant_pass",
                        pattern="Redundant pass statement",
                        suggestion="Remove unnecessary pass",
                        severity="info",
                        context=stripped[:60]
                    ))

        # Return null at end of function (common redundancy)
        if stripped == 'return' or stripped == 'return null':
            # This is often redundant but might be intentional
            if strict:
                issues.append(RedundantIssue(
                    file=rel_path,
                    line=i + 1,
                    category="redundant_return",
                    pattern="Explicit return at function end",
                    suggestion="May be redundant if function returns void",
                    severity="info",
                    context=stripped[:60]
                ))

        # x if true else y / x if false else y
        if re.search(r'\bif\s+true\s+else\b', code_part, re.IGNORECASE):
            issues.append(RedundantIssue(
                file=rel_path,
                line=i + 1,
                category="redundant_ternary",
                pattern="Ternary with 'if true'",
                suggestion="Use the first value directly",
                severity="warning",
                context=stripped[:60]
            ))

        if re.search(r'\bif\s+false\s+else\b', code_part, re.IGNORECASE):
            issues.append(RedundantIssue(
                file=rel_path,
                line=i + 1,
                category="redundant_ternary",
                pattern="Ternary with 'if false'",
                suggestion="Use the else value directly",
                severity="warning",
                context=stripped[:60]
            ))

        # len(x) > 0 instead of not x.is_empty()
        if re.search(r'len\s*\([^)]+\)\s*[>!=]=?\s*0', code_part):
            issues.append(RedundantIssue(
                file=rel_path,
                line=i + 1,
                category="redundant_len",
                pattern="len() comparison to 0",
                suggestion="Use .is_empty() instead",
                severity="info",
                context=stripped[:60]
            ))

    return issues


def check_redundant_code(target_file: Optional[str] = None, strict: bool = False) -> RedundantReport:
    """Check for redundant code across the project."""
    report = RedundantReport()

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


def format_report(report: RedundantReport) -> str:
    """Format redundant code report as text."""
    lines = []
    lines.append("=" * 60)
    lines.append("REDUNDANT CODE CHECKER - KEYBOARD DEFENSE")
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
        lines.append("## REDUNDANT CODE ISSUES")

        # Sort by severity then file
        sorted_issues = sorted(report.issues, key=lambda x: (0 if x.severity == "warning" else 1, x.file, x.line))

        for issue in sorted_issues[:40]:
            severity_marker = "[WARN]" if issue.severity == "warning" else "[INFO]"
            lines.append(f"  {severity_marker} {issue.file}:{issue.line}")
            lines.append(f"    {issue.pattern}")
            lines.append(f"    Suggestion: {issue.suggestion}")

        if len(report.issues) > 40:
            lines.append(f"  ... and {len(report.issues) - 40} more issues")
        lines.append("")

    # Files with most issues
    if report.by_file:
        lines.append("## FILES WITH MOST REDUNDANT CODE")
        sorted_files = sorted(report.by_file.items(), key=lambda x: -len(x[1]))[:10]
        for file_path, issues in sorted_files:
            warning_count = sum(1 for i in issues if i.severity == "warning")
            lines.append(f"  {file_path}: {len(issues)} ({warning_count} warnings)")
        lines.append("")

    # Health indicators
    lines.append("## HEALTH INDICATORS")
    if report.warnings == 0:
        lines.append("  [OK] No redundant code warnings")
    elif report.warnings < 10:
        lines.append(f"  [INFO] {report.warnings} redundant code warnings")
    else:
        lines.append(f"  [WARN] {report.warnings} redundant code warnings - consider cleanup")

    dead_code_count = report.by_category.get("dead_code", 0)
    if dead_code_count > 0:
        lines.append(f"  [WARN] {dead_code_count} instances of dead/unreachable code")

    lines.append("")
    return "\n".join(lines)


def format_json(report: RedundantReport) -> str:
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

    parser = argparse.ArgumentParser(description="Check for redundant code")
    parser.add_argument("--json", "-j", action="store_true", help="JSON output")
    parser.add_argument("--file", "-f", type=str, help="Single file to check")
    parser.add_argument("--strict", "-s", action="store_true", help="Include info-level patterns")
    args = parser.parse_args()

    report = check_redundant_code(args.file, args.strict)

    if args.json:
        print(format_json(report))
    else:
        print(format_report(report))


if __name__ == "__main__":
    main()
