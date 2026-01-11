#!/usr/bin/env python3
"""
Dictionary Access Checker

Finds unsafe dictionary access patterns:
- Direct key access without .get() (may throw error)
- Missing default values in .get() calls
- Nested dictionary access without safety
- Dictionary iteration patterns

Usage:
    python scripts/check_dictionary_access.py              # Full report
    python scripts/check_dictionary_access.py --file game/main.gd  # Single file
    python scripts/check_dictionary_access.py --strict     # More patterns
    python scripts/check_dictionary_access.py --json       # JSON output
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
class DictAccessIssue:
    """A dictionary access issue."""
    file: str
    line: int
    code: str
    issue_type: str
    message: str
    severity: str  # "error", "warning", "info"


@dataclass
class DictAccessReport:
    """Dictionary access report."""
    files_checked: int = 0
    total_accesses: int = 0
    safe_accesses: int = 0
    unsafe_accesses: int = 0
    issues: List[DictAccessIssue] = field(default_factory=list)
    by_file: Dict[str, List[DictAccessIssue]] = field(default_factory=lambda: defaultdict(list))
    access_patterns: Dict[str, int] = field(default_factory=lambda: defaultdict(int))


def analyze_dict_access(file_path: Path, rel_path: str, strict: bool) -> Tuple[Dict[str, int], List[DictAccessIssue]]:
    """Analyze dictionary access patterns in a file."""
    issues = []
    patterns = defaultdict(int)

    try:
        content = file_path.read_text(encoding='utf-8')
        lines = content.split('\n')
    except Exception:
        return patterns, issues

    # Track known dictionaries
    known_dicts: Set[str] = set()

    for i, line in enumerate(lines):
        stripped = line.strip()

        # Skip comments
        if stripped.startswith('#'):
            continue

        # Track dictionary declarations
        # var dict_name = {} or var dict_name: Dictionary
        dict_decl = re.search(r'var\s+(\w+)\s*(?::\s*Dictionary)?\s*=\s*\{', stripped)
        if dict_decl:
            known_dicts.add(dict_decl.group(1))

        dict_type = re.search(r'var\s+(\w+)\s*:\s*Dictionary', stripped)
        if dict_type:
            known_dicts.add(dict_type.group(1))

        # Find .get() calls (safe access)
        get_calls = re.findall(r'\.get\s*\(', line)
        patterns["get_call"] += len(get_calls)

        # Find .get() without default value
        get_no_default = re.findall(r'\.get\s*\(\s*["\'][^"\']+["\']\s*\)', line)
        for match in get_no_default:
            if strict:
                issues.append(DictAccessIssue(
                    file=rel_path,
                    line=i + 1,
                    code=stripped[:60],
                    issue_type="get_no_default",
                    message=".get() without default value - returns null if key missing",
                    severity="info"
                ))
            patterns["get_no_default"] += 1

        # Find direct bracket access on variables that might be dicts
        # pattern: variable["key"] or variable[key]
        bracket_access = re.findall(r'(\w+)\s*\[\s*["\']([^"\']+)["\']\s*\]', line)
        for var_name, key in bracket_access:
            # Skip array-like access patterns
            if var_name in ['data', 'entries', 'items', 'list', 'array', 'lines', 'tokens', 'args', 'params']:
                continue
            # Skip known safe patterns
            if var_name in ['OS', 'Engine', 'Input', 'ProjectSettings']:
                continue

            patterns["bracket_access"] += 1

            # Check if it's in an if/match context (safer)
            in_check = 'if ' in line or 'has(' in line or 'in ' in line
            if not in_check:
                issues.append(DictAccessIssue(
                    file=rel_path,
                    line=i + 1,
                    code=stripped[:60],
                    issue_type="unsafe_bracket_access",
                    message=f"Direct access {var_name}[\"{key}\"] - use .get() for safety",
                    severity="warning"
                ))

        # Find nested dictionary access
        nested_access = re.findall(r'(\w+)\[[^\]]+\]\[[^\]]+\]', line)
        for match in nested_access:
            patterns["nested_access"] += 1
            if strict:
                issues.append(DictAccessIssue(
                    file=rel_path,
                    line=i + 1,
                    code=stripped[:60],
                    issue_type="nested_access",
                    message="Nested dictionary access - intermediate key might not exist",
                    severity="info"
                ))

        # Find .has() checks (good pattern)
        has_calls = re.findall(r'\.has\s*\(', line)
        patterns["has_check"] += len(has_calls)

        # Find "in" checks (good pattern)
        in_checks = re.findall(r'\bin\s+\w+', line)
        patterns["in_check"] += len(in_checks)

        # Find erase without has check
        erase_calls = re.findall(r'(\w+)\.erase\s*\(', line)
        for var_name in erase_calls:
            patterns["erase_call"] += 1
            # Check if there's a has() check nearby
            context_start = max(0, i - 2)
            context = '\n'.join(lines[context_start:i+1])
            if '.has(' not in context and ' in ' not in context:
                if strict:
                    issues.append(DictAccessIssue(
                        file=rel_path,
                        line=i + 1,
                        code=stripped[:60],
                        issue_type="erase_no_check",
                        message=f"{var_name}.erase() without existence check",
                        severity="info"
                    ))

    return patterns, issues


def check_dictionary_access(target_file: Optional[str] = None, strict: bool = False) -> DictAccessReport:
    """Check dictionary access patterns across the project."""
    report = DictAccessReport()

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

        patterns, issues = analyze_dict_access(gd_file, rel_path, strict)

        # Aggregate patterns
        for pattern, count in patterns.items():
            report.access_patterns[pattern] += count

        # Aggregate issues
        for issue in issues:
            report.issues.append(issue)
            report.by_file[issue.file].append(issue)

    # Calculate totals
    report.safe_accesses = report.access_patterns.get("get_call", 0) + report.access_patterns.get("has_check", 0)
    report.unsafe_accesses = report.access_patterns.get("bracket_access", 0)
    report.total_accesses = report.safe_accesses + report.unsafe_accesses

    return report


def format_report(report: DictAccessReport) -> str:
    """Format dictionary access report as text."""
    lines = []
    lines.append("=" * 60)
    lines.append("DICTIONARY ACCESS CHECKER - KEYBOARD DEFENSE")
    lines.append("=" * 60)
    lines.append("")

    # Summary
    lines.append("## SUMMARY")
    lines.append(f"  Files checked:      {report.files_checked}")
    lines.append(f"  Total accesses:     {report.total_accesses}")
    lines.append(f"  Safe accesses:      {report.safe_accesses}")
    lines.append(f"  Unsafe accesses:    {report.unsafe_accesses}")
    lines.append(f"  Issues found:       {len(report.issues)}")
    lines.append("")

    # Access patterns
    lines.append("## ACCESS PATTERNS")
    for pattern, count in sorted(report.access_patterns.items(), key=lambda x: -x[1]):
        lines.append(f"  {pattern}: {count}")
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
        lines.append("## DICTIONARY ACCESS ISSUES")

        sorted_issues = sorted(report.issues, key=lambda x: (0 if x.severity == "warning" else 1, x.file, x.line))

        for issue in sorted_issues[:40]:
            severity_marker = {"error": "[ERROR]", "warning": "[WARN]", "info": "[INFO]"}.get(issue.severity, "[???]")
            lines.append(f"  {severity_marker} {issue.file}:{issue.line}")
            lines.append(f"    {issue.message}")

        if len(report.issues) > 40:
            lines.append(f"  ... and {len(report.issues) - 40} more issues")
        lines.append("")

    # Files with most issues
    if report.by_file:
        lines.append("## FILES WITH MOST DICTIONARY ISSUES")
        sorted_files = sorted(report.by_file.items(), key=lambda x: -len(x[1]))[:10]
        for file_path, issues in sorted_files:
            warn_count = sum(1 for i in issues if i.severity == "warning")
            lines.append(f"  {file_path}: {len(issues)} ({warn_count} warnings)")
        lines.append("")

    # Health indicators
    lines.append("## HEALTH INDICATORS")

    if report.total_accesses > 0:
        safe_ratio = report.safe_accesses / report.total_accesses * 100
        if safe_ratio >= 70:
            lines.append(f"  [OK] {safe_ratio:.0f}% of dictionary accesses are safe (.get/.has)")
        else:
            lines.append(f"  [WARN] Only {safe_ratio:.0f}% of dictionary accesses are safe")

    unsafe_warnings = sum(1 for i in report.issues if i.issue_type == "unsafe_bracket_access")
    if unsafe_warnings == 0:
        lines.append("  [OK] No unsafe bracket access found")
    else:
        lines.append(f"  [WARN] {unsafe_warnings} unsafe bracket accesses (use .get())")

    lines.append("")
    lines.append("## SAFE ACCESS PATTERNS")
    lines.append("  # Instead of: dict[\"key\"]")
    lines.append("  # Use: dict.get(\"key\", default_value)")
    lines.append("  # Or: if dict.has(\"key\"): value = dict[\"key\"]")
    lines.append("")

    return "\n".join(lines)


def format_json(report: DictAccessReport) -> str:
    """Format report as JSON."""
    data = {
        "summary": {
            "files_checked": report.files_checked,
            "total_accesses": report.total_accesses,
            "safe_accesses": report.safe_accesses,
            "unsafe_accesses": report.unsafe_accesses,
            "issues": len(report.issues)
        },
        "access_patterns": dict(report.access_patterns),
        "issues": [
            {
                "file": i.file,
                "line": i.line,
                "code": i.code,
                "type": i.issue_type,
                "message": i.message,
                "severity": i.severity
            }
            for i in report.issues[:100]
        ],
        "by_type": {
            issue_type: len([i for i in report.issues if i.issue_type == issue_type])
            for issue_type in set(i.issue_type for i in report.issues)
        }
    }
    return json.dumps(data, indent=2)


def main():
    import argparse

    parser = argparse.ArgumentParser(description="Check dictionary access patterns")
    parser.add_argument("--json", "-j", action="store_true", help="JSON output")
    parser.add_argument("--file", "-f", type=str, help="Single file to check")
    parser.add_argument("--strict", "-s", action="store_true", help="Include info-level checks")
    args = parser.parse_args()

    report = check_dictionary_access(args.file, args.strict)

    if args.json:
        print(format_json(report))
    else:
        print(format_report(report))


if __name__ == "__main__":
    main()
