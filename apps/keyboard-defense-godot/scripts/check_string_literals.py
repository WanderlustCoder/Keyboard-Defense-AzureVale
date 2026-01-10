#!/usr/bin/env python3
"""
String Literal Checker

Finds repeated string literals that could be constants:
- Strings used multiple times across files
- Potential typos in similar strings
- Hardcoded paths and identifiers

Usage:
    python scripts/check_string_literals.py              # Full report
    python scripts/check_string_literals.py --min 3      # Min occurrences
    python scripts/check_string_literals.py --file game/main.gd  # Single file
    python scripts/check_string_literals.py --json       # JSON output
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

# Default thresholds
DEFAULT_MIN_OCCURRENCES = 3
MIN_STRING_LENGTH = 4


@dataclass
class StringUsage:
    """A string literal usage."""
    value: str
    file: str
    line: int
    context: str


@dataclass
class StringLiteralReport:
    """String literal check report."""
    files_checked: int = 0
    total_strings: int = 0
    unique_strings: int = 0
    repeated_strings: int = 0
    string_usages: Dict[str, List[StringUsage]] = field(default_factory=lambda: defaultdict(list))
    suggestions: List[Tuple[str, int, str]] = field(default_factory=list)  # (string, count, suggested_name)


def extract_strings(file_path: Path, rel_path: str) -> List[StringUsage]:
    """Extract string literals from a file."""
    usages = []

    try:
        content = file_path.read_text(encoding="utf-8")
        lines = content.split('\n')
    except Exception:
        return usages

    for i, line in enumerate(lines):
        line_num = i + 1
        stripped = line.strip()

        # Skip comments
        if stripped.startswith("#"):
            continue

        # Skip lines that are likely constant definitions
        if re.match(r'^(const|var)\s+[A-Z_]+\s*[:=]', stripped):
            continue

        # Find double-quoted strings
        double_matches = re.findall(r'"([^"\\]*(?:\\.[^"\\]*)*)"', line)
        for match in double_matches:
            if len(match) >= MIN_STRING_LENGTH:
                usages.append(StringUsage(
                    value=match,
                    file=rel_path,
                    line=line_num,
                    context=stripped[:60]
                ))

        # Find single-quoted strings
        single_matches = re.findall(r"'([^'\\]*(?:\\.[^'\\]*)*)'", line)
        for match in single_matches:
            if len(match) >= MIN_STRING_LENGTH:
                usages.append(StringUsage(
                    value=match,
                    file=rel_path,
                    line=line_num,
                    context=stripped[:60]
                ))

    return usages


def suggest_constant_name(value: str) -> str:
    """Suggest a constant name for a string value."""
    # Clean the string
    cleaned = re.sub(r'[^a-zA-Z0-9_\s]', '', value)
    cleaned = cleaned.strip()

    if not cleaned:
        return "STRING_CONSTANT"

    # Convert to SCREAMING_SNAKE_CASE
    words = cleaned.split()
    if len(words) > 4:
        words = words[:4]

    name = "_".join(word.upper() for word in words)

    # Add prefix based on content type
    if value.startswith("res://"):
        return "PATH_" + name
    elif value.startswith("/"):
        return "ROUTE_" + name
    elif "_" in value and value == value.lower():
        return "KEY_" + name

    return name


def categorize_string(value: str) -> str:
    """Categorize a string by its likely purpose."""
    if value.startswith("res://"):
        return "resource_path"
    elif value.startswith("/"):
        return "path"
    elif "_" in value and value == value.lower():
        return "identifier"
    elif value[0].isupper():
        return "display_text"
    elif "." in value:
        return "dotted_name"
    else:
        return "other"


def check_string_literals(min_occurrences: int = DEFAULT_MIN_OCCURRENCES, target_file: Optional[str] = None) -> StringLiteralReport:
    """Check string literals across the project."""
    report = StringLiteralReport()

    if target_file:
        gd_files = [PROJECT_ROOT / target_file]
    else:
        gd_files = list(PROJECT_ROOT.glob("**/*.gd"))

    # Collect all string usages
    for gd_file in gd_files:
        if ".godot" in str(gd_file) or "addons" in str(gd_file):
            continue

        if not gd_file.exists():
            continue

        rel_path = str(gd_file.relative_to(PROJECT_ROOT))
        report.files_checked += 1

        usages = extract_strings(gd_file, rel_path)
        for usage in usages:
            report.total_strings += 1
            report.string_usages[usage.value].append(usage)

    report.unique_strings = len(report.string_usages)

    # Find repeated strings
    for value, usages in report.string_usages.items():
        if len(usages) >= min_occurrences:
            report.repeated_strings += 1

            # Skip common patterns that are expected to repeat
            if value in ("", " ", "\n", "\t", "true", "false", "null"):
                continue

            # Skip very short strings
            if len(value) < MIN_STRING_LENGTH:
                continue

            suggested_name = suggest_constant_name(value)
            report.suggestions.append((value, len(usages), suggested_name))

    # Sort suggestions by occurrence count
    report.suggestions.sort(key=lambda x: -x[1])

    return report


def format_report(report: StringLiteralReport, min_occurrences: int) -> str:
    """Format string literal report as text."""
    lines = []
    lines.append("=" * 60)
    lines.append("STRING LITERAL CHECKER - KEYBOARD DEFENSE")
    lines.append("=" * 60)
    lines.append("")

    # Summary
    lines.append("## SUMMARY")
    lines.append(f"  Files checked:      {report.files_checked}")
    lines.append(f"  Total strings:      {report.total_strings}")
    lines.append(f"  Unique strings:     {report.unique_strings}")
    lines.append(f"  Repeated (>={min_occurrences}x):  {report.repeated_strings}")
    lines.append("")

    # Suggestions for constants
    if report.suggestions:
        lines.append(f"## REPEATED STRINGS (>={min_occurrences} occurrences)")
        lines.append("  Consider extracting to constants:")
        lines.append("")

        for value, count, suggested in report.suggestions[:25]:
            display_value = value[:40] + "..." if len(value) > 40 else value
            lines.append(f"  \"{display_value}\"")
            lines.append(f"    Used {count} times")
            lines.append(f"    Suggested: const {suggested} = \"{value[:30]}...\"" if len(value) > 30 else f"    Suggested: const {suggested} = \"{value}\"")
            lines.append("")

        if len(report.suggestions) > 25:
            lines.append(f"  ... and {len(report.suggestions) - 25} more")
        lines.append("")

    # Categorize repeated strings
    categories: Dict[str, int] = defaultdict(int)
    for value, count, _ in report.suggestions:
        cat = categorize_string(value)
        categories[cat] += 1

    if categories:
        lines.append("## BY CATEGORY")
        for cat, count in sorted(categories.items(), key=lambda x: -x[1]):
            lines.append(f"  {cat}: {count} repeated strings")
        lines.append("")

    # Most used strings
    lines.append("## MOST REPEATED STRINGS")
    for value, count, _ in report.suggestions[:10]:
        display = value[:50] + "..." if len(value) > 50 else value
        files = len(set(u.file for u in report.string_usages[value]))
        lines.append(f"  \"{display}\": {count} uses in {files} files")
    lines.append("")

    # Health indicators
    lines.append("## HEALTH INDICATORS")
    if report.repeated_strings < 20:
        lines.append(f"  [OK] Few repeated strings ({report.repeated_strings})")
    elif report.repeated_strings < 50:
        lines.append(f"  [INFO] {report.repeated_strings} repeated strings - consider extracting common ones")
    else:
        lines.append(f"  [WARN] {report.repeated_strings} repeated strings - significant duplication")

    reuse_ratio = (report.total_strings - report.unique_strings) / report.total_strings * 100 if report.total_strings > 0 else 0
    lines.append(f"  [INFO] {reuse_ratio:.1f}% string reuse rate")

    lines.append("")
    return "\n".join(lines)


def format_json(report: StringLiteralReport) -> str:
    """Format report as JSON."""
    data = {
        "summary": {
            "files_checked": report.files_checked,
            "total_strings": report.total_strings,
            "unique_strings": report.unique_strings,
            "repeated_strings": report.repeated_strings
        },
        "suggestions": [
            {
                "value": value,
                "occurrences": count,
                "suggested_name": suggested,
                "category": categorize_string(value),
                "files": list(set(u.file for u in report.string_usages[value]))
            }
            for value, count, suggested in report.suggestions[:50]
        ]
    }
    return json.dumps(data, indent=2)


def main():
    import argparse

    parser = argparse.ArgumentParser(description="Check string literals")
    parser.add_argument("--json", "-j", action="store_true", help="JSON output")
    parser.add_argument("--min", "-m", type=int, default=DEFAULT_MIN_OCCURRENCES, help="Min occurrences")
    parser.add_argument("--file", "-f", type=str, help="Single file to check")
    args = parser.parse_args()

    report = check_string_literals(args.min, args.file)

    if args.json:
        print(format_json(report))
    else:
        print(format_report(report, args.min))


if __name__ == "__main__":
    main()
