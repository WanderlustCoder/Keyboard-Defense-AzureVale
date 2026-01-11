#!/usr/bin/env python3
"""
Print Statement Checker

Finds debug print statements left in code:
- print() calls
- prints() calls
- printt() calls
- print_debug() calls
- push_error/push_warning (optionally)

Usage:
    python scripts/check_print_statements.py              # Full report
    python scripts/check_print_statements.py --file game/main.gd  # Single file
    python scripts/check_print_statements.py --strict     # Include push_error/warning
    python scripts/check_print_statements.py --json       # JSON output
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
class PrintIssue:
    """A print statement issue."""
    file: str
    line: int
    code: str
    print_type: str
    message: str
    severity: str  # "error", "warning", "info"


@dataclass
class PrintReport:
    """Print statement report."""
    files_checked: int = 0
    total_prints: int = 0
    debug_prints: int = 0
    error_prints: int = 0
    issues: List[PrintIssue] = field(default_factory=list)
    by_file: Dict[str, List[PrintIssue]] = field(default_factory=lambda: defaultdict(list))
    by_type: Dict[str, int] = field(default_factory=lambda: defaultdict(int))


def analyze_prints(file_path: Path, rel_path: str, strict: bool) -> List[PrintIssue]:
    """Analyze print statements in a file."""
    issues = []

    try:
        content = file_path.read_text(encoding='utf-8')
        lines = content.split('\n')
    except Exception:
        return issues

    # Skip test files - prints are expected there
    if 'test' in rel_path.lower() or rel_path.startswith('tests/'):
        return issues

    in_function = None
    function_line = 0

    for i, line in enumerate(lines):
        stripped = line.strip()

        # Skip comments
        if stripped.startswith('#'):
            continue

        # Track current function
        func_match = re.match(r'^func\s+(\w+)', stripped)
        if func_match:
            in_function = func_match.group(1)
            function_line = i + 1

        # Find print() calls
        print_match = re.search(r'\bprint\s*\(', line)
        if print_match:
            # Check if it's commented out
            comment_pos = line.find('#')
            if comment_pos >= 0 and comment_pos < print_match.start():
                continue

            issues.append(PrintIssue(
                file=rel_path,
                line=i + 1,
                code=stripped[:60],
                print_type="print",
                message=f"Debug print() in {in_function or 'global scope'}",
                severity="warning"
            ))

        # Find prints() calls (multiple args with space separator)
        prints_match = re.search(r'\bprints\s*\(', line)
        if prints_match:
            comment_pos = line.find('#')
            if comment_pos >= 0 and comment_pos < prints_match.start():
                continue

            issues.append(PrintIssue(
                file=rel_path,
                line=i + 1,
                code=stripped[:60],
                print_type="prints",
                message=f"Debug prints() in {in_function or 'global scope'}",
                severity="warning"
            ))

        # Find printt() calls (tab separator)
        printt_match = re.search(r'\bprintt\s*\(', line)
        if printt_match:
            comment_pos = line.find('#')
            if comment_pos >= 0 and comment_pos < printt_match.start():
                continue

            issues.append(PrintIssue(
                file=rel_path,
                line=i + 1,
                code=stripped[:60],
                print_type="printt",
                message=f"Debug printt() in {in_function or 'global scope'}",
                severity="warning"
            ))

        # Find print_debug() calls
        print_debug_match = re.search(r'\bprint_debug\s*\(', line)
        if print_debug_match:
            comment_pos = line.find('#')
            if comment_pos >= 0 and comment_pos < print_debug_match.start():
                continue

            issues.append(PrintIssue(
                file=rel_path,
                line=i + 1,
                code=stripped[:60],
                print_type="print_debug",
                message=f"Debug print_debug() in {in_function or 'global scope'}",
                severity="warning"
            ))

        # Find print_rich() calls
        print_rich_match = re.search(r'\bprint_rich\s*\(', line)
        if print_rich_match:
            comment_pos = line.find('#')
            if comment_pos >= 0 and comment_pos < print_rich_match.start():
                continue

            issues.append(PrintIssue(
                file=rel_path,
                line=i + 1,
                code=stripped[:60],
                print_type="print_rich",
                message=f"Debug print_rich() in {in_function or 'global scope'}",
                severity="warning"
            ))

        # Strict mode: find push_error/push_warning
        if strict:
            push_error_match = re.search(r'\bpush_error\s*\(', line)
            if push_error_match:
                comment_pos = line.find('#')
                if comment_pos < 0 or comment_pos > push_error_match.start():
                    issues.append(PrintIssue(
                        file=rel_path,
                        line=i + 1,
                        code=stripped[:60],
                        print_type="push_error",
                        message=f"push_error() in {in_function or 'global scope'}",
                        severity="info"
                    ))

            push_warning_match = re.search(r'\bpush_warning\s*\(', line)
            if push_warning_match:
                comment_pos = line.find('#')
                if comment_pos < 0 or comment_pos > push_warning_match.start():
                    issues.append(PrintIssue(
                        file=rel_path,
                        line=i + 1,
                        code=stripped[:60],
                        print_type="push_warning",
                        message=f"push_warning() in {in_function or 'global scope'}",
                        severity="info"
                    ))

    return issues


def check_print_statements(target_file: Optional[str] = None, strict: bool = False) -> PrintReport:
    """Check print statements across the project."""
    report = PrintReport()

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

        issues = analyze_prints(gd_file, rel_path, strict)

        for issue in issues:
            report.issues.append(issue)
            report.by_file[issue.file].append(issue)
            report.by_type[issue.print_type] += 1
            report.total_prints += 1

            if issue.print_type in ['print', 'prints', 'printt', 'print_debug', 'print_rich']:
                report.debug_prints += 1
            else:
                report.error_prints += 1

    return report


def format_report(report: PrintReport) -> str:
    """Format print statement report as text."""
    lines = []
    lines.append("=" * 60)
    lines.append("PRINT STATEMENT CHECKER - KEYBOARD DEFENSE")
    lines.append("=" * 60)
    lines.append("")

    # Summary
    lines.append("## SUMMARY")
    lines.append(f"  Files checked:      {report.files_checked}")
    lines.append(f"  Total prints:       {report.total_prints}")
    lines.append(f"  Debug prints:       {report.debug_prints}")
    lines.append(f"  Error/warning:      {report.error_prints}")
    lines.append("")

    # By type
    if report.by_type:
        lines.append("## PRINTS BY TYPE")
        for print_type, count in sorted(report.by_type.items(), key=lambda x: -x[1]):
            lines.append(f"  {print_type}: {count}")
        lines.append("")

    # Issues
    if report.issues:
        lines.append("## PRINT STATEMENTS FOUND")

        sorted_issues = sorted(report.issues, key=lambda x: (0 if x.severity == "warning" else 1, x.file, x.line))

        for issue in sorted_issues[:50]:
            severity_marker = {"error": "[ERROR]", "warning": "[WARN]", "info": "[INFO]"}.get(issue.severity, "[???]")
            lines.append(f"  {severity_marker} {issue.file}:{issue.line}")
            lines.append(f"    {issue.message}")
            lines.append(f"    {issue.code}")

        if len(report.issues) > 50:
            lines.append(f"  ... and {len(report.issues) - 50} more")
        lines.append("")

    # Files with most prints
    if report.by_file:
        lines.append("## FILES WITH MOST PRINT STATEMENTS")
        sorted_files = sorted(report.by_file.items(), key=lambda x: -len(x[1]))[:10]
        for file_path, issues in sorted_files:
            lines.append(f"  {file_path}: {len(issues)}")
        lines.append("")

    # Health indicators
    lines.append("## HEALTH INDICATORS")

    if report.debug_prints == 0:
        lines.append("  [OK] No debug print statements found")
    else:
        lines.append(f"  [WARN] {report.debug_prints} debug print statements should be removed")

    lines.append("")
    lines.append("## ALTERNATIVES TO PRINT")
    lines.append("  # For debugging: Use breakpoints or OS.is_debug_build()")
    lines.append("  # For errors: Use push_error() for logged errors")
    lines.append("  # For warnings: Use push_warning() for logged warnings")
    lines.append("  # For conditionals: if OS.is_debug_build(): print(...)")
    lines.append("")

    return "\n".join(lines)


def format_json(report: PrintReport) -> str:
    """Format report as JSON."""
    data = {
        "summary": {
            "files_checked": report.files_checked,
            "total_prints": report.total_prints,
            "debug_prints": report.debug_prints,
            "error_prints": report.error_prints
        },
        "by_type": dict(report.by_type),
        "issues": [
            {
                "file": i.file,
                "line": i.line,
                "code": i.code,
                "type": i.print_type,
                "message": i.message,
                "severity": i.severity
            }
            for i in report.issues[:100]
        ],
        "files_with_prints": [
            {"file": f, "count": len(issues)}
            for f, issues in sorted(report.by_file.items(), key=lambda x: -len(x[1]))[:20]
        ]
    }
    return json.dumps(data, indent=2)


def main():
    import argparse

    parser = argparse.ArgumentParser(description="Check print statements")
    parser.add_argument("--json", "-j", action="store_true", help="JSON output")
    parser.add_argument("--file", "-f", type=str, help="Single file to check")
    parser.add_argument("--strict", "-s", action="store_true", help="Include push_error/warning")
    args = parser.parse_args()

    report = check_print_statements(args.file, args.strict)

    if args.json:
        print(format_json(report))
    else:
        print(format_report(report))


if __name__ == "__main__":
    main()
