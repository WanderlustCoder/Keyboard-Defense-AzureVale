#!/usr/bin/env python3
"""
Constant Usage Checker

Finds issues with constant declarations and usage:
- Constants defined but never used
- Repeated literal values that should be constants
- Constants with wrong naming convention
- Constants that could be enums

Usage:
    python scripts/check_constant_usage.py              # Full report
    python scripts/check_constant_usage.py --file game/main.gd  # Single file
    python scripts/check_constant_usage.py --strict     # More patterns
    python scripts/check_constant_usage.py --json       # JSON output
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
class ConstantDecl:
    """A constant declaration."""
    file: str
    line: int
    name: str
    value: str
    usage_count: int = 0


@dataclass
class ConstantIssue:
    """A constant usage issue."""
    file: str
    line: int
    name: str
    issue_type: str
    message: str
    severity: str  # "error", "warning", "info"


@dataclass
class ConstantReport:
    """Constant usage report."""
    files_checked: int = 0
    total_constants: int = 0
    unused_constants: int = 0
    naming_violations: int = 0
    issues: List[ConstantIssue] = field(default_factory=list)
    constants: Dict[str, List[ConstantDecl]] = field(default_factory=lambda: defaultdict(list))
    by_file: Dict[str, List[ConstantDecl]] = field(default_factory=lambda: defaultdict(list))
    repeated_values: Dict[str, List[Tuple[str, int]]] = field(default_factory=lambda: defaultdict(list))


def extract_constants(file_path: Path, rel_path: str) -> List[ConstantDecl]:
    """Extract constant declarations from a file."""
    constants = []

    try:
        content = file_path.read_text(encoding='utf-8')
        lines = content.split('\n')
    except Exception:
        return constants

    for i, line in enumerate(lines):
        stripped = line.strip()

        # Skip comments
        if stripped.startswith('#'):
            continue

        # Find const declarations
        # const NAME = value
        # const NAME: Type = value
        const_match = re.match(r'^const\s+(\w+)\s*(?::\s*\w+)?\s*=\s*(.+)$', stripped)
        if const_match:
            name = const_match.group(1)
            value = const_match.group(2).strip()
            constants.append(ConstantDecl(
                file=rel_path,
                line=i + 1,
                name=name,
                value=value
            ))

    return constants


def count_constant_usage(file_path: Path, constants: List[ConstantDecl]) -> None:
    """Count how many times each constant is used."""
    try:
        content = file_path.read_text(encoding='utf-8')
    except Exception:
        return

    for const in constants:
        # Count usages (excluding the declaration line)
        pattern = rf'\b{re.escape(const.name)}\b'
        matches = list(re.finditer(pattern, content))
        # Subtract 1 for the declaration itself
        const.usage_count = max(0, len(matches) - 1)


def find_repeated_values(all_files: List[Path]) -> Dict[str, List[Tuple[str, int]]]:
    """Find literal values that appear multiple times across files."""
    value_locations: Dict[str, List[Tuple[str, int]]] = defaultdict(list)

    # Patterns for values that might need constants
    patterns = [
        (r'"([^"]{4,})"', "string"),  # String literals (4+ chars)
        (r"'([^']{4,})'", "string"),  # Single-quoted strings
    ]

    for gd_file in all_files:
        if ".godot" in str(gd_file) or "addons" in str(gd_file):
            continue

        if not gd_file.exists():
            continue

        try:
            rel_path = str(gd_file.relative_to(PROJECT_ROOT))
            content = gd_file.read_text(encoding='utf-8')
            lines = content.split('\n')
        except Exception:
            continue

        for i, line in enumerate(lines):
            stripped = line.strip()

            # Skip comments and const declarations
            if stripped.startswith('#') or stripped.startswith('const '):
                continue

            for pattern, _ in patterns:
                matches = re.findall(pattern, line)
                for match in matches:
                    # Skip common patterns that don't need constants
                    if match in ['true', 'false', 'null', '']:
                        continue
                    # Skip paths (already handled by other tools)
                    if match.startswith('res://') or match.startswith('user://'):
                        continue
                    # Skip format strings
                    if '%' in match:
                        continue

                    value_locations[match].append((rel_path, i + 1))

    # Filter to only repeated values
    return {v: locs for v, locs in value_locations.items() if len(locs) >= 3}


def check_naming_convention(name: str) -> bool:
    """Check if constant name follows SCREAMING_SNAKE_CASE."""
    return bool(re.match(r'^[A-Z][A-Z0-9_]*$', name))


def check_constant_usage(target_file: Optional[str] = None, strict: bool = False) -> ConstantReport:
    """Check constant usage across the project."""
    report = ConstantReport()

    if target_file:
        gd_files = [PROJECT_ROOT / target_file]
    else:
        gd_files = list(PROJECT_ROOT.glob("**/*.gd"))

    # First pass: collect all constants
    all_constants: Dict[str, List[ConstantDecl]] = defaultdict(list)

    for gd_file in gd_files:
        if ".godot" in str(gd_file) or "addons" in str(gd_file):
            continue

        if not gd_file.exists():
            continue

        rel_path = str(gd_file.relative_to(PROJECT_ROOT))
        report.files_checked += 1

        constants = extract_constants(gd_file, rel_path)
        count_constant_usage(gd_file, constants)

        for const in constants:
            all_constants[const.name].append(const)
            report.constants[const.name].append(const)
            report.by_file[rel_path].append(const)
            report.total_constants += 1

            # Check for unused constants
            if const.usage_count == 0:
                report.unused_constants += 1
                report.issues.append(ConstantIssue(
                    file=rel_path,
                    line=const.line,
                    name=const.name,
                    issue_type="unused_constant",
                    message=f"Constant '{const.name}' is never used",
                    severity="warning"
                ))

            # Check naming convention
            if not check_naming_convention(const.name):
                # Allow some exceptions
                if not const.name.startswith('_'):
                    report.naming_violations += 1
                    if strict:
                        report.issues.append(ConstantIssue(
                            file=rel_path,
                            line=const.line,
                            name=const.name,
                            issue_type="naming_violation",
                            message=f"Constant '{const.name}' should be SCREAMING_SNAKE_CASE",
                            severity="info"
                        ))

    # Find repeated values that should be constants
    if not target_file:
        repeated = find_repeated_values(gd_files)
        report.repeated_values = repeated

        if strict:
            for value, locations in list(repeated.items())[:20]:
                if len(locations) >= 3:
                    first_loc = locations[0]
                    report.issues.append(ConstantIssue(
                        file=first_loc[0],
                        line=first_loc[1],
                        name=value[:30],
                        issue_type="repeated_value",
                        message=f"Value '{value[:40]}' appears {len(locations)} times - consider a constant",
                        severity="info"
                    ))

    # Check for constants that could be grouped into enums
    const_groups: Dict[str, List[str]] = defaultdict(list)
    for name, decls in all_constants.items():
        # Group by prefix
        parts = name.split('_')
        if len(parts) >= 2:
            prefix = parts[0]
            const_groups[prefix].append(name)

    for prefix, names in const_groups.items():
        if len(names) >= 4 and strict:
            # Could be an enum
            first_const = all_constants[names[0]][0]
            report.issues.append(ConstantIssue(
                file=first_const.file,
                line=first_const.line,
                name=prefix,
                issue_type="potential_enum",
                message=f"Constants with prefix '{prefix}_' ({len(names)} total) could be an enum",
                severity="info"
            ))

    return report


def format_report(report: ConstantReport) -> str:
    """Format constant report as text."""
    lines = []
    lines.append("=" * 60)
    lines.append("CONSTANT USAGE CHECKER - KEYBOARD DEFENSE")
    lines.append("=" * 60)
    lines.append("")

    # Summary
    lines.append("## SUMMARY")
    lines.append(f"  Files checked:      {report.files_checked}")
    lines.append(f"  Total constants:    {report.total_constants}")
    lines.append(f"  Unused constants:   {report.unused_constants}")
    lines.append(f"  Naming violations:  {report.naming_violations}")
    lines.append(f"  Repeated values:    {len(report.repeated_values)}")
    lines.append(f"  Issues found:       {len(report.issues)}")
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

    # Unused constants
    unused = [i for i in report.issues if i.issue_type == "unused_constant"]
    if unused:
        lines.append("## UNUSED CONSTANTS")
        for issue in unused[:30]:
            lines.append(f"  {issue.file}:{issue.line} - {issue.name}")
        if len(unused) > 30:
            lines.append(f"  ... and {len(unused) - 30} more")
        lines.append("")

    # Repeated values
    if report.repeated_values:
        lines.append("## REPEATED VALUES (Consider Constants)")
        sorted_values = sorted(report.repeated_values.items(), key=lambda x: -len(x[1]))[:15]
        for value, locations in sorted_values:
            display_value = value[:40] + "..." if len(value) > 40 else value
            lines.append(f"  '{display_value}' - {len(locations)} occurrences")
        lines.append("")

    # Files with most constants
    if report.by_file:
        lines.append("## FILES WITH MOST CONSTANTS")
        sorted_files = sorted(report.by_file.items(), key=lambda x: -len(x[1]))[:10]
        for file_path, consts in sorted_files:
            unused_count = sum(1 for c in consts if c.usage_count == 0)
            lines.append(f"  {file_path}: {len(consts)} ({unused_count} unused)")
        lines.append("")

    # Health indicators
    lines.append("## HEALTH INDICATORS")
    if report.unused_constants == 0:
        lines.append("  [OK] No unused constants")
    else:
        lines.append(f"  [WARN] {report.unused_constants} unused constants (dead code)")

    if report.total_constants > 0:
        usage_ratio = (report.total_constants - report.unused_constants) / report.total_constants * 100
        lines.append(f"  [INFO] {usage_ratio:.0f}% constant utilization")

    if len(report.repeated_values) == 0:
        lines.append("  [OK] No repeated string values")
    else:
        lines.append(f"  [INFO] {len(report.repeated_values)} repeated values could be constants")

    lines.append("")
    return "\n".join(lines)


def format_json(report: ConstantReport) -> str:
    """Format report as JSON."""
    data = {
        "summary": {
            "files_checked": report.files_checked,
            "total_constants": report.total_constants,
            "unused_constants": report.unused_constants,
            "naming_violations": report.naming_violations,
            "repeated_values": len(report.repeated_values),
            "issues": len(report.issues)
        },
        "issues": [
            {
                "file": i.file,
                "line": i.line,
                "name": i.name,
                "type": i.issue_type,
                "message": i.message,
                "severity": i.severity
            }
            for i in report.issues[:100]
        ],
        "unused_constants": [
            {"file": i.file, "line": i.line, "name": i.name}
            for i in report.issues if i.issue_type == "unused_constant"
        ][:50],
        "repeated_values": [
            {"value": v[:50], "count": len(locs)}
            for v, locs in sorted(report.repeated_values.items(), key=lambda x: -len(x[1]))[:20]
        ]
    }
    return json.dumps(data, indent=2)


def main():
    import argparse

    parser = argparse.ArgumentParser(description="Check constant usage")
    parser.add_argument("--json", "-j", action="store_true", help="JSON output")
    parser.add_argument("--file", "-f", type=str, help="Single file to check")
    parser.add_argument("--strict", "-s", action="store_true", help="Include info-level checks")
    args = parser.parse_args()

    report = check_constant_usage(args.file, args.strict)

    if args.json:
        print(format_json(report))
    else:
        print(format_report(report))


if __name__ == "__main__":
    main()
