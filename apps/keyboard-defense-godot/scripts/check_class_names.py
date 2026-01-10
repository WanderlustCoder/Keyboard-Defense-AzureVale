#!/usr/bin/env python3
"""
Class Name Validator

Validates that class_name declarations match conventions:
- class_name should match filename (PascalCase)
- Files with classes should have class_name
- No duplicate class_name declarations

Usage:
    python scripts/check_class_names.py              # Full report
    python scripts/check_class_names.py --strict     # Stricter checks
    python scripts/check_class_names.py --json       # JSON output
"""

import json
import re
import sys
from dataclasses import dataclass, field
from pathlib import Path
from typing import Dict, List, Optional, Set

# Project paths
SCRIPT_DIR = Path(__file__).parent
PROJECT_ROOT = SCRIPT_DIR.parent


@dataclass
class ClassInfo:
    """Information about a class declaration."""
    file: str
    class_name: Optional[str]
    expected_name: str
    has_class_name: bool
    matches: bool
    line_number: int = 0
    issues: List[str] = field(default_factory=list)


@dataclass
class ClassNameReport:
    """Class name validation report."""
    files_checked: int = 0
    with_class_name: int = 0
    without_class_name: int = 0
    mismatches: int = 0
    duplicates: List[str] = field(default_factory=list)
    classes: List[ClassInfo] = field(default_factory=list)
    issues: List[str] = field(default_factory=list)


def filename_to_class_name(filename: str) -> str:
    """Convert snake_case filename to PascalCase class name."""
    # Remove .gd extension
    name = filename.replace(".gd", "")
    # Split by underscore and capitalize each part
    parts = name.split("_")
    return "".join(part.capitalize() for part in parts)


def analyze_file(file_path: Path, rel_path: str) -> ClassInfo:
    """Analyze a single file for class_name."""
    filename = file_path.name
    expected = filename_to_class_name(filename)

    info = ClassInfo(
        file=rel_path,
        class_name=None,
        expected_name=expected,
        has_class_name=False,
        matches=False
    )

    try:
        content = file_path.read_text(encoding="utf-8")
        lines = content.split('\n')
    except Exception:
        info.issues.append("Could not read file")
        return info

    # Find class_name declaration
    for i, line in enumerate(lines):
        match = re.match(r'^class_name\s+(\w+)', line.strip())
        if match:
            info.class_name = match.group(1)
            info.has_class_name = True
            info.line_number = i + 1
            break

    # Check if matches expected
    if info.has_class_name:
        info.matches = (info.class_name == expected)
        if not info.matches:
            info.issues.append(f"class_name '{info.class_name}' doesn't match expected '{expected}'")

    return info


def should_have_class_name(file_path: Path, rel_path: str) -> bool:
    """Determine if a file should have a class_name declaration."""
    # Skip test files
    if "tests/" in rel_path or "test_" in file_path.name:
        return False

    # Skip tool/utility scripts
    if "tools/" in rel_path:
        return False

    # Skip autoload scripts (they're singletons)
    autoloads = ["main.gd", "audio_manager.gd", "settings_manager.gd", "asset_loader.gd"]
    if file_path.name.lower() in autoloads:
        return False

    try:
        content = file_path.read_text(encoding="utf-8")
    except Exception:
        return False

    # Check if file extends RefCounted or has significant class structure
    has_extends = "extends " in content
    has_functions = "func " in content
    has_static = "static func" in content

    # sim/ layer files should have class_name for static access
    if "sim/" in rel_path and has_static:
        return True

    # Files with multiple functions that aren't scene scripts
    if has_extends and has_functions:
        # Scene scripts (extend Node types) may not need class_name
        extends_match = re.search(r'extends\s+(\w+)', content)
        if extends_match:
            base_class = extends_match.group(1)
            # Node-based scripts often don't need class_name
            node_bases = ["Node", "Node2D", "Node3D", "Control", "Container",
                         "Panel", "PanelContainer", "MarginContainer", "VBoxContainer",
                         "HBoxContainer", "GridContainer", "Button", "Label"]
            if base_class in node_bases:
                return False

    return False


def validate_class_names(strict: bool = False) -> ClassNameReport:
    """Validate class names across the project."""
    report = ClassNameReport()
    class_names_seen: Dict[str, str] = {}  # class_name -> file

    for gd_file in PROJECT_ROOT.glob("**/*.gd"):
        if ".godot" in str(gd_file) or "addons" in str(gd_file):
            continue

        rel_path = str(gd_file.relative_to(PROJECT_ROOT))
        report.files_checked += 1

        info = analyze_file(gd_file, rel_path)

        if info.has_class_name:
            report.with_class_name += 1

            # Check for duplicates
            if info.class_name in class_names_seen:
                other_file = class_names_seen[info.class_name]
                report.duplicates.append(f"'{info.class_name}' in {rel_path} and {other_file}")
                info.issues.append(f"Duplicate class_name (also in {other_file})")
            else:
                class_names_seen[info.class_name] = rel_path

            # Check for mismatch
            if not info.matches:
                report.mismatches += 1
        else:
            report.without_class_name += 1

            # In strict mode, check if file should have class_name
            if strict and should_have_class_name(gd_file, rel_path):
                info.issues.append(f"Missing class_name (expected '{info.expected_name}')")

        if info.issues:
            report.classes.append(info)

    # Collect issues
    if report.duplicates:
        report.issues.append(f"{len(report.duplicates)} duplicate class_name declarations")
    if report.mismatches:
        report.issues.append(f"{report.mismatches} class_name/filename mismatches")

    return report


def format_report(report: ClassNameReport, strict: bool = False) -> str:
    """Format class name report as text."""
    lines = []
    lines.append("=" * 60)
    lines.append("CLASS NAME VALIDATOR - KEYBOARD DEFENSE")
    lines.append("=" * 60)
    lines.append("")

    # Summary
    lines.append("## SUMMARY")
    lines.append(f"  Files checked:       {report.files_checked}")
    lines.append(f"  With class_name:     {report.with_class_name}")
    lines.append(f"  Without class_name:  {report.without_class_name}")
    lines.append(f"  Mismatches:          {report.mismatches}")
    lines.append(f"  Duplicates:          {len(report.duplicates)}")
    lines.append("")

    # Duplicates
    if report.duplicates:
        lines.append("## DUPLICATE CLASS NAMES")
        for dup in report.duplicates:
            lines.append(f"  [!] {dup}")
        lines.append("")

    # Mismatches
    mismatches = [c for c in report.classes if c.has_class_name and not c.matches]
    if mismatches:
        lines.append("## CLASS NAME MISMATCHES")
        for info in mismatches:
            lines.append(f"  {info.file}:{info.line_number}")
            lines.append(f"    Found:    {info.class_name}")
            lines.append(f"    Expected: {info.expected_name}")
        lines.append("")

    # Missing class_name (strict mode)
    if strict:
        missing = [c for c in report.classes if not c.has_class_name and c.issues]
        if missing:
            lines.append("## MISSING CLASS_NAME (strict)")
            for info in missing[:20]:
                lines.append(f"  {info.file}")
                lines.append(f"    Suggested: class_name {info.expected_name}")
            if len(missing) > 20:
                lines.append(f"  ... and {len(missing) - 20} more")
            lines.append("")

    # Health indicators
    lines.append("## HEALTH INDICATORS")
    if not report.duplicates:
        lines.append("  [OK] No duplicate class_name declarations")
    else:
        lines.append(f"  [ERROR] {len(report.duplicates)} duplicate class_name declarations")

    if report.mismatches == 0:
        lines.append("  [OK] All class_name declarations match filenames")
    else:
        lines.append(f"  [WARN] {report.mismatches} class_name/filename mismatches")

    coverage = (report.with_class_name / report.files_checked * 100) if report.files_checked > 0 else 0
    lines.append(f"  [INFO] {coverage:.1f}% of files have class_name declarations")

    lines.append("")
    return "\n".join(lines)


def format_json(report: ClassNameReport) -> str:
    """Format report as JSON."""
    data = {
        "summary": {
            "files_checked": report.files_checked,
            "with_class_name": report.with_class_name,
            "without_class_name": report.without_class_name,
            "mismatches": report.mismatches,
            "duplicates": len(report.duplicates)
        },
        "duplicate_class_names": report.duplicates,
        "issues": [
            {
                "file": c.file,
                "class_name": c.class_name,
                "expected": c.expected_name,
                "line": c.line_number,
                "problems": c.issues
            }
            for c in report.classes if c.issues
        ]
    }
    return json.dumps(data, indent=2)


def main():
    import argparse

    parser = argparse.ArgumentParser(description="Validate class names")
    parser.add_argument("--json", "-j", action="store_true", help="JSON output")
    parser.add_argument("--strict", "-s", action="store_true", help="Stricter checks")
    args = parser.parse_args()

    report = validate_class_names(args.strict)

    if args.json:
        print(format_json(report))
    else:
        print(format_report(report, args.strict))


if __name__ == "__main__":
    main()
