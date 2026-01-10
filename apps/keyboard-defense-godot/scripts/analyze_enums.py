#!/usr/bin/env python3
"""
Enum Analyzer

Analyzes enum definitions and usage:
- Lists all enum declarations
- Tracks enum value usage
- Finds potentially unused enum values
- Detects enum-like constant patterns

Usage:
    python scripts/analyze_enums.py              # Full report
    python scripts/analyze_enums.py --file game/main.gd  # Single file
    python scripts/analyze_enums.py --unused     # Show only unused
    python scripts/analyze_enums.py --json       # JSON output
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
class EnumValue:
    """An enum value."""
    name: str
    value: Optional[int]
    used: bool = False
    usage_count: int = 0


@dataclass
class EnumInfo:
    """Information about an enum."""
    name: str
    file: str
    line: int
    values: List[EnumValue]
    is_global: bool = False
    usage_count: int = 0


@dataclass
class EnumUsage:
    """A usage of an enum or enum value."""
    enum_name: str
    value_name: Optional[str]
    file: str
    line: int
    context: str


@dataclass
class EnumReport:
    """Enum analysis report."""
    files_checked: int = 0
    total_enums: int = 0
    total_values: int = 0
    unused_values: int = 0
    enums: List[EnumInfo] = field(default_factory=list)
    usages: List[EnumUsage] = field(default_factory=list)
    enum_like_constants: List[Tuple[str, str, int]] = field(default_factory=list)  # (file, pattern, count)


def parse_enum(lines: List[str], start_idx: int) -> Tuple[List[EnumValue], int]:
    """Parse enum values starting from an enum declaration."""
    values = []
    i = start_idx

    # Check if single-line enum: enum Name { A, B, C }
    line = lines[start_idx].strip()
    if "{" in line and "}" in line:
        # Single-line enum
        match = re.search(r'\{([^}]+)\}', line)
        if match:
            value_str = match.group(1)
            for val in value_str.split(","):
                val = val.strip()
                if val:
                    if "=" in val:
                        name, num = val.split("=")
                        values.append(EnumValue(name=name.strip(), value=int(num.strip())))
                    else:
                        values.append(EnumValue(name=val, value=None))
        return values, start_idx + 1

    # Multi-line enum
    i += 1
    base_indent = len(lines[start_idx]) - len(lines[start_idx].lstrip())

    while i < len(lines):
        line = lines[i]
        stripped = line.strip()

        if not stripped or stripped.startswith("#"):
            i += 1
            continue

        # Check if we've exited the enum
        current_indent = len(line) - len(line.lstrip())
        if current_indent <= base_indent and stripped and not stripped.startswith("#"):
            if not stripped.startswith("}"):
                break

        # Parse value
        if stripped == "}":
            i += 1
            break

        # Remove trailing comma and comments
        value_part = stripped.split("#")[0].rstrip(",").strip()
        if value_part:
            if "=" in value_part:
                name, num = value_part.split("=")
                try:
                    values.append(EnumValue(name=name.strip(), value=int(num.strip())))
                except ValueError:
                    values.append(EnumValue(name=name.strip(), value=None))
            else:
                values.append(EnumValue(name=value_part, value=None))

        i += 1

    return values, i


def analyze_file(file_path: Path, rel_path: str) -> Tuple[List[EnumInfo], List[EnumUsage]]:
    """Analyze a file for enum definitions and usages."""
    enums = []
    usages = []

    try:
        content = file_path.read_text(encoding="utf-8")
        lines = content.split('\n')
    except Exception:
        return enums, usages

    i = 0
    while i < len(lines):
        line = lines[i]
        stripped = line.strip()

        # Find enum declaration
        enum_match = re.match(r'^enum\s+(\w+)\s*\{?', stripped)
        if enum_match:
            enum_name = enum_match.group(1)
            values, next_i = parse_enum(lines, i)

            enums.append(EnumInfo(
                name=enum_name,
                file=rel_path,
                line=i + 1,
                values=values,
                is_global=True  # class-level enum
            ))

            i = next_i
            continue

        # Find enum usages: EnumName.VALUE or EnumName
        for enum_pattern in re.finditer(r'\b([A-Z][a-zA-Z0-9]*)\s*\.\s*([A-Z][A-Z0-9_]*)\b', stripped):
            enum_name = enum_pattern.group(1)
            value_name = enum_pattern.group(2)

            usages.append(EnumUsage(
                enum_name=enum_name,
                value_name=value_name,
                file=rel_path,
                line=i + 1,
                context=stripped[:60]
            ))

        i += 1

    return enums, usages


def find_enum_like_constants(file_path: Path, rel_path: str) -> List[Tuple[str, int]]:
    """Find patterns that look like they should be enums."""
    patterns = []

    try:
        content = file_path.read_text(encoding="utf-8")
        lines = content.split('\n')
    except Exception:
        return patterns

    # Look for groups of related constants
    const_groups: Dict[str, List[str]] = defaultdict(list)

    for line in lines:
        stripped = line.strip()

        # Match const SOMETHING_TYPE = "value" or const SOMETHING_TYPE = 0
        const_match = re.match(r'^const\s+([A-Z][A-Z0-9]*_[A-Z][A-Z0-9_]*)\s*[:=]', stripped)
        if const_match:
            const_name = const_match.group(1)
            # Extract prefix (e.g., "STATE" from "STATE_IDLE")
            parts = const_name.split("_")
            if len(parts) >= 2:
                prefix = parts[0]
                const_groups[prefix].append(const_name)

    # Report groups with 3+ constants
    for prefix, constants in const_groups.items():
        if len(constants) >= 3:
            patterns.append((prefix, len(constants)))

    return patterns


def analyze_enums(target_file: Optional[str] = None, show_unused: bool = False) -> EnumReport:
    """Analyze enums across the project."""
    report = EnumReport()

    if target_file:
        gd_files = [PROJECT_ROOT / target_file]
    else:
        gd_files = list(PROJECT_ROOT.glob("**/*.gd"))

    all_enums: Dict[str, EnumInfo] = {}
    all_usages: List[EnumUsage] = []

    # First pass: collect all enums
    for gd_file in gd_files:
        if ".godot" in str(gd_file) or "addons" in str(gd_file):
            continue

        if not gd_file.exists():
            continue

        rel_path = str(gd_file.relative_to(PROJECT_ROOT))
        report.files_checked += 1

        enums, usages = analyze_file(gd_file, rel_path)

        for enum in enums:
            all_enums[enum.name] = enum
            report.enums.append(enum)
            report.total_enums += 1
            report.total_values += len(enum.values)

        all_usages.extend(usages)

        # Check for enum-like constants
        patterns = find_enum_like_constants(gd_file, rel_path)
        for prefix, count in patterns:
            report.enum_like_constants.append((rel_path, prefix, count))

    # Second pass: track usage
    for usage in all_usages:
        report.usages.append(usage)

        if usage.enum_name in all_enums:
            enum = all_enums[usage.enum_name]
            enum.usage_count += 1

            if usage.value_name:
                for value in enum.values:
                    if value.name == usage.value_name:
                        value.used = True
                        value.usage_count += 1
                        break

    # Count unused values
    for enum in report.enums:
        for value in enum.values:
            if not value.used:
                report.unused_values += 1

    return report


def format_report(report: EnumReport, show_unused: bool = False) -> str:
    """Format enum report as text."""
    lines = []
    lines.append("=" * 60)
    lines.append("ENUM ANALYZER - KEYBOARD DEFENSE")
    lines.append("=" * 60)
    lines.append("")

    # Summary
    lines.append("## SUMMARY")
    lines.append(f"  Files checked:      {report.files_checked}")
    lines.append(f"  Total enums:        {report.total_enums}")
    lines.append(f"  Total values:       {report.total_values}")
    lines.append(f"  Unused values:      {report.unused_values}")
    lines.append(f"  Total usages:       {len(report.usages)}")
    lines.append("")

    # Enum definitions
    lines.append("## ENUM DEFINITIONS")
    for enum in sorted(report.enums, key=lambda e: -e.usage_count):
        unused_count = sum(1 for v in enum.values if not v.used)
        lines.append(f"  {enum.name} ({enum.file}:{enum.line})")
        lines.append(f"    Values: {len(enum.values)}, Used: {enum.usage_count}x, Unused values: {unused_count}")

        if show_unused and unused_count > 0:
            unused_names = [v.name for v in enum.values if not v.used]
            lines.append(f"    Unused: {', '.join(unused_names[:5])}" + ("..." if len(unused_names) > 5 else ""))
    lines.append("")

    # Most used enums
    most_used = sorted(report.enums, key=lambda e: -e.usage_count)[:10]
    if most_used:
        lines.append("## MOST USED ENUMS")
        for enum in most_used:
            lines.append(f"  {enum.name}: {enum.usage_count} usages")
        lines.append("")

    # Enum-like constant patterns
    if report.enum_like_constants:
        lines.append("## ENUM-LIKE CONSTANT PATTERNS")
        lines.append("  (Consider converting to enums)")
        for file_path, prefix, count in sorted(report.enum_like_constants, key=lambda x: -x[2])[:10]:
            lines.append(f"  {file_path}: {prefix}_* ({count} constants)")
        lines.append("")

    # Health indicators
    lines.append("## HEALTH INDICATORS")
    if report.total_enums > 0:
        unused_pct = report.unused_values / report.total_values * 100 if report.total_values > 0 else 0
        if unused_pct < 20:
            lines.append(f"  [OK] {unused_pct:.0f}% unused enum values")
        elif unused_pct < 50:
            lines.append(f"  [INFO] {unused_pct:.0f}% unused enum values")
        else:
            lines.append(f"  [WARN] {unused_pct:.0f}% unused enum values")
    else:
        lines.append("  [INFO] No enums found in codebase")

    if report.enum_like_constants:
        lines.append(f"  [INFO] {len(report.enum_like_constants)} constant patterns could be enums")

    lines.append("")
    return "\n".join(lines)


def format_json(report: EnumReport) -> str:
    """Format report as JSON."""
    data = {
        "summary": {
            "files_checked": report.files_checked,
            "total_enums": report.total_enums,
            "total_values": report.total_values,
            "unused_values": report.unused_values,
            "total_usages": len(report.usages)
        },
        "enums": [
            {
                "name": e.name,
                "file": e.file,
                "line": e.line,
                "values": [{"name": v.name, "used": v.used, "usage_count": v.usage_count} for v in e.values],
                "usage_count": e.usage_count
            }
            for e in report.enums
        ],
        "enum_like_patterns": [
            {"file": f, "prefix": p, "count": c}
            for f, p, c in report.enum_like_constants
        ]
    }
    return json.dumps(data, indent=2)


def main():
    import argparse

    parser = argparse.ArgumentParser(description="Analyze enums")
    parser.add_argument("--json", "-j", action="store_true", help="JSON output")
    parser.add_argument("--file", "-f", type=str, help="Single file to check")
    parser.add_argument("--unused", "-u", action="store_true", help="Show unused values")
    args = parser.parse_args()

    report = analyze_enums(args.file, args.unused)

    if args.json:
        print(format_json(report))
    else:
        print(format_report(report, args.unused))


if __name__ == "__main__":
    main()
