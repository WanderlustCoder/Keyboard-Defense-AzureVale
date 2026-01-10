#!/usr/bin/env python3
"""
Hardcoded Values Checker

Finds hardcoded values that should be constants:
- Hardcoded resource paths (res://)
- Hardcoded colors (Color())
- Hardcoded positions (Vector2/Vector3)
- Hardcoded timing values
- Hardcoded UI sizes

Usage:
    python scripts/check_hardcoded_values.py              # Full report
    python scripts/check_hardcoded_values.py --file game/main.gd  # Single file
    python scripts/check_hardcoded_values.py --strict     # More patterns
    python scripts/check_hardcoded_values.py --json       # JSON output
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
class HardcodedValue:
    """A hardcoded value instance."""
    file: str
    line: int
    category: str
    value: str
    severity: str  # "warning", "info"
    context: str
    suggestion: str


@dataclass
class HardcodedReport:
    """Hardcoded values report."""
    files_checked: int = 0
    total_issues: int = 0
    warnings: int = 0
    info: int = 0
    issues: List[HardcodedValue] = field(default_factory=list)
    by_file: Dict[str, List[HardcodedValue]] = field(default_factory=lambda: defaultdict(list))
    by_category: Dict[str, int] = field(default_factory=lambda: defaultdict(int))
    repeated_values: Dict[str, int] = field(default_factory=lambda: defaultdict(int))


def analyze_file(file_path: Path, rel_path: str, strict: bool) -> List[HardcodedValue]:
    """Analyze a file for hardcoded values."""
    issues = []

    try:
        content = file_path.read_text(encoding='utf-8')
        lines = content.split('\n')
    except Exception:
        return issues

    # Track if we're in a const declaration (which is fine)
    in_const = False

    for i, line in enumerate(lines):
        stripped = line.strip()

        # Skip comments
        if stripped.startswith('#'):
            continue

        # Track const declarations
        if stripped.startswith('const '):
            in_const = True
            continue
        else:
            in_const = False

        code_part = line.split('#')[0]  # Remove inline comments

        # Skip if this is a const or enum definition
        if 'const ' in code_part or 'enum ' in code_part:
            continue

        # Hardcoded resource paths in function bodies
        res_paths = re.findall(r'["\']res://([^"\']+)["\']', code_part)
        for path in res_paths:
            # Skip if it's in a preload/load at class level
            if 'preload(' in code_part or re.match(r'^(const|var)\s+\w+\s*=', stripped):
                continue
            if strict:
                issues.append(HardcodedValue(
                    file=rel_path,
                    line=i + 1,
                    category="resource_path",
                    value=f"res://{path}",
                    severity="info",
                    context=stripped[:60],
                    suggestion="Consider using a preloaded constant"
                ))

        # Hardcoded colors
        color_matches = re.findall(r'Color\s*\(\s*([^)]+)\s*\)', code_part)
        for color_args in color_matches:
            # Skip if it's referencing a constant
            if re.match(r'^[A-Z_]+$', color_args.strip()):
                continue
            # Skip simple colors like Color.WHITE
            if '.' in color_args and not ',' in color_args:
                continue
            issues.append(HardcodedValue(
                file=rel_path,
                line=i + 1,
                category="color",
                value=f"Color({color_args})",
                severity="info",
                context=stripped[:60],
                suggestion="Consider using a color constant from theme_colors.gd"
            ))

        # Hardcoded hex colors
        hex_colors = re.findall(r'Color\s*\(\s*["\']#([0-9a-fA-F]{6,8})["\']\s*\)', code_part)
        for hex_color in hex_colors:
            issues.append(HardcodedValue(
                file=rel_path,
                line=i + 1,
                category="color",
                value=f"#{hex_color}",
                severity="warning",
                context=stripped[:60],
                suggestion="Use a named color constant"
            ))

        # Hardcoded Vector2 positions (not Vector2.ZERO, etc.)
        vec2_matches = re.findall(r'Vector2\s*\(\s*(-?\d+\.?\d*)\s*,\s*(-?\d+\.?\d*)\s*\)', code_part)
        for x, y in vec2_matches:
            # Skip common values
            if (x, y) in [('0', '0'), ('1', '1'), ('0.5', '0.5'), ('-1', '-1')]:
                continue
            if strict:
                issues.append(HardcodedValue(
                    file=rel_path,
                    line=i + 1,
                    category="position",
                    value=f"Vector2({x}, {y})",
                    severity="info",
                    context=stripped[:60],
                    suggestion="Consider using a named constant for this position"
                ))

        # Hardcoded timing values (likely magic numbers for animations/delays)
        timing_patterns = [
            (r'await\s+get_tree\(\)\.create_timer\s*\(\s*(\d+\.?\d*)\s*\)', "timer"),
            (r'\.wait_time\s*=\s*(\d+\.?\d*)', "wait_time"),
            (r'\.duration\s*=\s*(\d+\.?\d*)', "duration"),
            (r'tween.*\.set_trans.*\.\s*(\d+\.?\d*)', "tween_time"),
        ]
        for pattern, timing_type in timing_patterns:
            matches = re.findall(pattern, code_part)
            for value in matches:
                try:
                    num = float(value)
                    # Skip very common values
                    if num in [0, 0.0, 1, 1.0, 0.5, 0.1, 0.25]:
                        continue
                    if strict:
                        issues.append(HardcodedValue(
                            file=rel_path,
                            line=i + 1,
                            category="timing",
                            value=f"{value}s ({timing_type})",
                            severity="info",
                            context=stripped[:60],
                            suggestion="Consider using a timing constant"
                        ))
                except ValueError:
                    pass

        # Hardcoded sizes (width, height patterns)
        size_patterns = [
            (r'\.size\s*=\s*Vector2\s*\(\s*(\d+)\s*,\s*(\d+)\s*\)', "size"),
            (r'\.custom_minimum_size\s*=\s*Vector2\s*\(\s*(\d+)\s*,\s*(\d+)\s*\)', "min_size"),
        ]
        for pattern, size_type in size_patterns:
            matches = re.findall(pattern, code_part)
            for w, h in matches:
                if strict:
                    issues.append(HardcodedValue(
                        file=rel_path,
                        line=i + 1,
                        category="size",
                        value=f"{w}x{h} ({size_type})",
                        severity="info",
                        context=stripped[:60],
                        suggestion="Consider using a size constant"
                    ))

        # Hardcoded font sizes
        font_size_matches = re.findall(r'font_size\s*=\s*(\d+)', code_part)
        for size in font_size_matches:
            if int(size) not in [8, 10, 12, 14, 16, 18, 20, 24]:  # Common sizes
                issues.append(HardcodedValue(
                    file=rel_path,
                    line=i + 1,
                    category="font_size",
                    value=f"{size}px",
                    severity="info",
                    context=stripped[:60],
                    suggestion="Consider using a theme font size"
                ))

        # Hardcoded layer/z-index
        z_index_matches = re.findall(r'z_index\s*=\s*(-?\d+)', code_part)
        for z in z_index_matches:
            if int(z) not in [0, 1, -1, 10, 100]:  # Common values
                if strict:
                    issues.append(HardcodedValue(
                        file=rel_path,
                        line=i + 1,
                        category="z_index",
                        value=f"z_index={z}",
                        severity="info",
                        context=stripped[:60],
                        suggestion="Consider using a z-index constant"
                    ))

    return issues


def check_hardcoded_values(target_file: Optional[str] = None, strict: bool = False) -> HardcodedReport:
    """Check for hardcoded values across the project."""
    report = HardcodedReport()

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
            report.by_category[issue.category] += 1
            report.repeated_values[issue.value] += 1
            report.total_issues += 1

            if issue.severity == "warning":
                report.warnings += 1
            else:
                report.info += 1

    return report


def format_report(report: HardcodedReport) -> str:
    """Format hardcoded values report as text."""
    lines = []
    lines.append("=" * 60)
    lines.append("HARDCODED VALUES CHECKER - KEYBOARD DEFENSE")
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

    # Repeated values (good candidates for constants)
    repeated = [(v, c) for v, c in report.repeated_values.items() if c >= 3]
    if repeated:
        lines.append("## REPEATED VALUES (3+ occurrences)")
        lines.append("  (Strong candidates for constants)")
        for value, count in sorted(repeated, key=lambda x: -x[1])[:15]:
            lines.append(f"  {count}x: {value[:50]}")
        lines.append("")

    # Issues
    if report.issues:
        lines.append("## HARDCODED VALUE ISSUES")

        sorted_issues = sorted(report.issues, key=lambda x: (0 if x.severity == "warning" else 1, x.file, x.line))

        for issue in sorted_issues[:40]:
            severity_marker = "[WARN]" if issue.severity == "warning" else "[INFO]"
            lines.append(f"  {severity_marker} {issue.file}:{issue.line}")
            lines.append(f"    {issue.category}: {issue.value}")
            lines.append(f"    Suggestion: {issue.suggestion}")

        if len(report.issues) > 40:
            lines.append(f"  ... and {len(report.issues) - 40} more issues")
        lines.append("")

    # Files with most issues
    if report.by_file:
        lines.append("## FILES WITH MOST HARDCODED VALUES")
        sorted_files = sorted(report.by_file.items(), key=lambda x: -len(x[1]))[:10]
        for file_path, issues in sorted_files:
            lines.append(f"  {file_path}: {len(issues)}")
        lines.append("")

    # Health indicators
    lines.append("## HEALTH INDICATORS")
    if report.warnings == 0:
        lines.append("  [OK] No critical hardcoded value warnings")
    else:
        lines.append(f"  [WARN] {report.warnings} hardcoded values should be constants")

    color_count = report.by_category.get("color", 0)
    if color_count > 20:
        lines.append(f"  [WARN] {color_count} hardcoded colors - use theme_colors.gd")

    lines.append("")
    return "\n".join(lines)


def format_json(report: HardcodedReport) -> str:
    """Format report as JSON."""
    data = {
        "summary": {
            "files_checked": report.files_checked,
            "total_issues": report.total_issues,
            "warnings": report.warnings,
            "info": report.info
        },
        "by_category": dict(report.by_category),
        "repeated_values": [
            {"value": v, "count": c}
            for v, c in sorted(report.repeated_values.items(), key=lambda x: -x[1])[:30]
            if c >= 2
        ],
        "issues": [
            {
                "file": i.file,
                "line": i.line,
                "category": i.category,
                "value": i.value,
                "severity": i.severity,
                "suggestion": i.suggestion
            }
            for i in report.issues[:100]
        ]
    }
    return json.dumps(data, indent=2)


def main():
    import argparse

    parser = argparse.ArgumentParser(description="Check for hardcoded values")
    parser.add_argument("--json", "-j", action="store_true", help="JSON output")
    parser.add_argument("--file", "-f", type=str, help="Single file to check")
    parser.add_argument("--strict", "-s", action="store_true", help="Include more patterns")
    args = parser.parse_args()

    report = check_hardcoded_values(args.file, args.strict)

    if args.json:
        print(format_json(report))
    else:
        print(format_report(report))


if __name__ == "__main__":
    main()
