#!/usr/bin/env python3
"""
Magic Number Detector

Finds hardcoded magic numbers that should be constants:
- Numbers in logic that aren't 0, 1, or 2
- Repeated numeric values
- Numbers in comparisons
- Suggests constant names

Usage:
    python scripts/find_magic_numbers.py              # Full report
    python scripts/find_magic_numbers.py --threshold 5  # Min occurrences
    python scripts/find_magic_numbers.py --file game/main.gd  # Single file
    python scripts/find_magic_numbers.py --json       # JSON output
"""

import json
import re
import sys
from dataclasses import dataclass, field
from pathlib import Path
from typing import Dict, List, Set, Optional, Tuple
from collections import defaultdict

# Project paths
SCRIPT_DIR = Path(__file__).parent
PROJECT_ROOT = SCRIPT_DIR.parent

# Numbers that are commonly acceptable
ACCEPTABLE_NUMBERS = {0, 1, 2, -1, 0.0, 1.0, 0.5, 2.0, 10, 100, 1000}

# Context patterns where numbers are often acceptable
ACCEPTABLE_CONTEXTS = [
    r'range\s*\(',  # range(0, n), range(n)
    r'Vector2\s*\(',  # Vector2(0, 0)
    r'Vector3\s*\(',
    r'Color\s*\(',  # Color values
    r'Rect2\s*\(',
    r':\s*=\s*\d',  # Default values in declarations
    r'const\s+\w+\s*[=:]',  # Constant definitions
    r'enum\s+',  # Enum definitions
    r'@export',  # Export defaults
    r'version',  # Version numbers
]


@dataclass
class MagicNumber:
    """A magic number occurrence."""
    value: str
    file: str
    line: int
    context: str
    numeric_value: float = 0.0


@dataclass
class MagicReport:
    """Magic number analysis report."""
    occurrences: List[MagicNumber] = field(default_factory=list)
    by_value: Dict[str, List[MagicNumber]] = field(default_factory=lambda: defaultdict(list))
    by_file: Dict[str, int] = field(default_factory=dict)
    repeated_values: List[Tuple[str, int]] = field(default_factory=list)
    suggestions: List[str] = field(default_factory=list)


def is_acceptable_context(line: str) -> bool:
    """Check if the line contains acceptable context for numbers."""
    for pattern in ACCEPTABLE_CONTEXTS:
        if re.search(pattern, line, re.IGNORECASE):
            return True
    return False


def extract_numbers(line: str) -> List[Tuple[str, float]]:
    """Extract numeric literals from a line."""
    numbers = []

    # Match integers and floats, but not in variable names
    # Negative numbers, decimals, scientific notation
    pattern = r'(?<![a-zA-Z_])(-?\d+\.?\d*(?:e[+-]?\d+)?)\b'

    for match in re.finditer(pattern, line):
        num_str = match.group(1)
        try:
            if '.' in num_str or 'e' in num_str.lower():
                num_val = float(num_str)
            else:
                num_val = float(int(num_str))
            numbers.append((num_str, num_val))
        except ValueError:
            continue

    return numbers


def get_context(line: str, num_str: str) -> str:
    """Extract context around a number."""
    # Find the number in the line and get surrounding context
    idx = line.find(num_str)
    if idx == -1:
        return line.strip()[:50]

    start = max(0, idx - 20)
    end = min(len(line), idx + len(num_str) + 20)
    context = line[start:end].strip()

    if start > 0:
        context = "..." + context
    if end < len(line):
        context = context + "..."

    return context


def analyze_file(filepath: Path, min_threshold: int = 1) -> List[MagicNumber]:
    """Analyze a file for magic numbers."""
    magic_numbers = []
    rel_path = str(filepath.relative_to(PROJECT_ROOT))

    try:
        content = filepath.read_text(encoding="utf-8")
        lines = content.split('\n')
    except Exception:
        return magic_numbers

    for i, line in enumerate(lines):
        stripped = line.strip()

        # Skip comments
        if stripped.startswith('#'):
            continue

        # Skip acceptable contexts
        if is_acceptable_context(stripped):
            continue

        # Skip constant definitions (they're defining the constant)
        if re.match(r'^const\s+', stripped):
            continue

        # Skip enum definitions
        if 'enum ' in stripped or stripped.startswith('}'):
            continue

        numbers = extract_numbers(stripped)

        for num_str, num_val in numbers:
            # Skip acceptable numbers
            if num_val in ACCEPTABLE_NUMBERS:
                continue

            # Skip if it's a small integer often used in loops/indices
            if num_val == int(num_val) and -10 <= num_val <= 10:
                # But flag if it's in a comparison or calculation
                if not any(op in stripped for op in ['<', '>', '==', '!=', '<=', '>=']):
                    continue

            context = get_context(stripped, num_str)

            magic_numbers.append(MagicNumber(
                value=num_str,
                file=rel_path,
                line=i + 1,
                context=context,
                numeric_value=num_val
            ))

    return magic_numbers


def suggest_constant_name(value: str, contexts: List[str]) -> str:
    """Suggest a constant name based on value and context."""
    # Common patterns
    num = float(value)

    if num == int(num):
        num = int(num)

    # Time-related
    if num in [60, 3600, 86400]:
        return "SECONDS_PER_MINUTE/HOUR/DAY"
    if 'time' in ' '.join(contexts).lower() or 'duration' in ' '.join(contexts).lower():
        return f"DURATION_{num}"

    # Size/count related
    if 'size' in ' '.join(contexts).lower() or 'count' in ' '.join(contexts).lower():
        return f"MAX_COUNT_{num}" if num > 0 else f"MIN_COUNT_{abs(num)}"

    # Damage/health related
    if any(word in ' '.join(contexts).lower() for word in ['damage', 'hp', 'health']):
        return f"BASE_DAMAGE_{num}" if num > 0 else f"DAMAGE_MODIFIER"

    # Speed related
    if 'speed' in ' '.join(contexts).lower():
        return f"BASE_SPEED_{num}"

    # Generic
    if num > 0:
        return f"CONSTANT_{num}"
    else:
        return f"CONSTANT_NEG_{abs(num)}"


def analyze_magic_numbers(file_filter: Optional[str] = None,
                          threshold: int = 2) -> MagicReport:
    """Analyze magic numbers across the codebase."""
    report = MagicReport()

    for gd_file in PROJECT_ROOT.glob("**/*.gd"):
        if ".godot" in str(gd_file) or "addons" in str(gd_file):
            continue

        rel_path = str(gd_file.relative_to(PROJECT_ROOT))
        if file_filter and file_filter not in rel_path:
            continue

        magic_nums = analyze_file(gd_file)

        for mn in magic_nums:
            report.occurrences.append(mn)
            report.by_value[mn.value].append(mn)
            report.by_file[mn.file] = report.by_file.get(mn.file, 0) + 1

    # Find repeated values
    for value, occurrences in report.by_value.items():
        if len(occurrences) >= threshold:
            report.repeated_values.append((value, len(occurrences)))

    report.repeated_values.sort(key=lambda x: -x[1])

    # Generate suggestions for most repeated
    for value, count in report.repeated_values[:10]:
        contexts = [occ.context for occ in report.by_value[value][:5]]
        suggestion = suggest_constant_name(value, contexts)
        report.suggestions.append(f"{value} (used {count}x) -> {suggestion}")

    return report


def format_report(report: MagicReport, threshold: int = 2) -> str:
    """Format magic number report as text."""
    lines = []
    lines.append("=" * 60)
    lines.append("MAGIC NUMBER DETECTOR - KEYBOARD DEFENSE")
    lines.append("=" * 60)
    lines.append("")

    # Summary
    lines.append("## SUMMARY")
    lines.append(f"  Total magic numbers:  {len(report.occurrences)}")
    lines.append(f"  Unique values:        {len(report.by_value)}")
    lines.append(f"  Repeated (>={threshold}x):     {len(report.repeated_values)}")
    lines.append("")

    if not report.occurrences:
        lines.append("No magic numbers found!")
        return "\n".join(lines)

    # Most repeated values (candidates for constants)
    if report.repeated_values:
        lines.append(f"## REPEATED VALUES (appear >= {threshold} times)")
        lines.append("  These should probably be constants:")
        lines.append("")
        for value, count in report.repeated_values[:15]:
            lines.append(f"  {count:4}x  {value}")
            # Show sample contexts
            samples = report.by_value[value][:2]
            for sample in samples:
                lines.append(f"         {sample.file}:{sample.line}")
                lines.append(f"         > {sample.context}")
        if len(report.repeated_values) > 15:
            lines.append(f"  ... and {len(report.repeated_values) - 15} more")
        lines.append("")

    # Suggested constant names
    if report.suggestions:
        lines.append("## SUGGESTED CONSTANTS")
        for suggestion in report.suggestions:
            lines.append(f"  {suggestion}")
        lines.append("")

    # Files with most magic numbers
    lines.append("## FILES WITH MOST MAGIC NUMBERS")
    sorted_files = sorted(report.by_file.items(), key=lambda x: -x[1])
    for filepath, count in sorted_files[:10]:
        lines.append(f"  {count:4} numbers  {filepath}")
    lines.append("")

    # Health indicators
    lines.append("## HEALTH INDICATORS")
    if len(report.repeated_values) > 20:
        lines.append(f"  [WARN] {len(report.repeated_values)} repeated magic numbers")
        lines.append("         Consider extracting to constants in sim/balance.gd")
    elif len(report.repeated_values) > 5:
        lines.append(f"  [INFO] {len(report.repeated_values)} repeated magic numbers")
    else:
        lines.append("  [OK] Few repeated magic numbers")

    total = len(report.occurrences)
    if total > 200:
        lines.append(f"  [INFO] {total} total magic numbers - review for constants")

    lines.append("")
    return "\n".join(lines)


def format_json(report: MagicReport) -> str:
    """Format report as JSON."""
    data = {
        "summary": {
            "total": len(report.occurrences),
            "unique_values": len(report.by_value),
            "repeated": len(report.repeated_values)
        },
        "repeated_values": [
            {"value": v, "count": c}
            for v, c in report.repeated_values
        ],
        "suggestions": report.suggestions,
        "by_file": report.by_file,
        "occurrences": [
            {
                "value": o.value,
                "file": o.file,
                "line": o.line,
                "context": o.context
            }
            for o in report.occurrences[:100]  # Limit for JSON size
        ]
    }
    return json.dumps(data, indent=2)


def main():
    import argparse

    parser = argparse.ArgumentParser(description="Find magic numbers")
    parser.add_argument("--json", "-j", action="store_true", help="JSON output")
    parser.add_argument("--file", "-f", type=str, help="Filter by file path")
    parser.add_argument("--threshold", "-t", type=int, default=2,
                        help="Minimum occurrences to report as repeated")
    args = parser.parse_args()

    report = analyze_magic_numbers(args.file, args.threshold)

    if args.json:
        print(format_json(report))
    else:
        print(format_report(report, args.threshold))


if __name__ == "__main__":
    main()
