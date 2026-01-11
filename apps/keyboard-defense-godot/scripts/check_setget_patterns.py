#!/usr/bin/env python3
"""
Setget Patterns Checker

Finds properties that should use set/get accessors:
- Variables modified from outside that need validation
- Variables that trigger side effects on change
- Export variables without setters
- Inconsistent setter/getter patterns

Usage:
    python scripts/check_setget_patterns.py              # Full report
    python scripts/check_setget_patterns.py --file game/main.gd  # Single file
    python scripts/check_setget_patterns.py --strict     # More patterns
    python scripts/check_setget_patterns.py --json       # JSON output
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
class PropertyInfo:
    """Information about a property."""
    file: str
    line: int
    name: str
    is_export: bool
    has_setter: bool
    has_getter: bool
    setter_name: Optional[str]
    getter_name: Optional[str]
    external_modifications: int = 0
    external_reads: int = 0


@dataclass
class SetgetIssue:
    """A setget pattern issue."""
    file: str
    line: int
    property: str
    issue_type: str
    message: str
    severity: str  # "warning", "info"


@dataclass
class SetgetReport:
    """Setget patterns report."""
    files_checked: int = 0
    total_properties: int = 0
    export_properties: int = 0
    properties_with_setters: int = 0
    properties_with_getters: int = 0
    issues: List[SetgetIssue] = field(default_factory=list)
    properties: Dict[str, List[PropertyInfo]] = field(default_factory=lambda: defaultdict(list))
    by_file: Dict[str, List[SetgetIssue]] = field(default_factory=lambda: defaultdict(list))


def extract_properties(file_path: Path, rel_path: str) -> List[PropertyInfo]:
    """Extract property declarations from a file."""
    properties = []

    try:
        content = file_path.read_text(encoding='utf-8')
        lines = content.split('\n')
    except Exception:
        return properties

    for i, line in enumerate(lines):
        stripped = line.strip()

        # Skip if inside a function
        if stripped.startswith('var ') and not line.startswith('\t') and not line.startswith('    '):
            # Class-level variable
            pass
        elif stripped.startswith('@export'):
            pass
        else:
            continue

        # Check for @export
        is_export = '@export' in line

        # Extract variable name and setter/getter
        # Patterns:
        # var name: Type
        # var name := value
        # var name = value
        # var name: Type: set = setter, get = getter
        # @export var name: Type

        var_match = re.search(r'var\s+(\w+)', stripped)
        if not var_match:
            continue

        var_name = var_match.group(1)

        # Check for set/get in Godot 4 style
        has_setter = False
        has_getter = False
        setter_name = None
        getter_name = None

        # Godot 4 inline setter/getter: var x: int: set = _set_x, get = _get_x
        setter_match = re.search(r'set\s*=\s*(\w+)', stripped)
        getter_match = re.search(r'get\s*=\s*(\w+)', stripped)

        if setter_match:
            has_setter = True
            setter_name = setter_match.group(1)

        if getter_match:
            has_getter = True
            getter_name = getter_match.group(1)

        # Also check for set(value): style on next lines
        if i + 1 < len(lines):
            next_line = lines[i + 1].strip()
            if next_line.startswith('set(') or next_line.startswith('set ('):
                has_setter = True
                setter_name = "inline"
            elif next_line.startswith('get:') or next_line.startswith('get():'):
                has_getter = True
                getter_name = "inline"

        properties.append(PropertyInfo(
            file=rel_path,
            line=i + 1,
            name=var_name,
            is_export=is_export,
            has_setter=has_setter,
            has_getter=has_getter,
            setter_name=setter_name,
            getter_name=getter_name
        ))

    return properties


def find_property_usage(all_files: List[Path], properties: Dict[str, Dict[str, PropertyInfo]]) -> None:
    """Find external property modifications and reads."""
    for gd_file in all_files:
        if ".godot" in str(gd_file) or "addons" in str(gd_file):
            continue

        if not gd_file.exists():
            continue

        try:
            rel_path = str(gd_file.relative_to(PROJECT_ROOT))
            content = gd_file.read_text(encoding='utf-8')
        except Exception:
            continue

        # Check each property from other files
        for prop_file, props in properties.items():
            if prop_file == rel_path:
                continue  # Skip same file

            for prop_name, prop_info in props.items():
                # Look for .property_name = (modification)
                mod_pattern = rf'\.{re.escape(prop_name)}\s*='
                if re.search(mod_pattern, content):
                    prop_info.external_modifications += 1

                # Look for .property_name (read)
                read_pattern = rf'\.{re.escape(prop_name)}\b(?!\s*=)'
                matches = re.findall(read_pattern, content)
                prop_info.external_reads += len(matches)


def check_setget_patterns(target_file: Optional[str] = None, strict: bool = False) -> SetgetReport:
    """Check setget patterns across the project."""
    report = SetgetReport()

    if target_file:
        gd_files = [PROJECT_ROOT / target_file]
    else:
        gd_files = list(PROJECT_ROOT.glob("**/*.gd"))

    # First pass: collect all properties
    all_properties: Dict[str, Dict[str, PropertyInfo]] = defaultdict(dict)

    for gd_file in gd_files:
        if ".godot" in str(gd_file) or "addons" in str(gd_file):
            continue

        if not gd_file.exists():
            continue

        rel_path = str(gd_file.relative_to(PROJECT_ROOT))
        report.files_checked += 1

        properties = extract_properties(gd_file, rel_path)

        for prop in properties:
            all_properties[rel_path][prop.name] = prop
            report.properties[rel_path].append(prop)
            report.total_properties += 1

            if prop.is_export:
                report.export_properties += 1
            if prop.has_setter:
                report.properties_with_setters += 1
            if prop.has_getter:
                report.properties_with_getters += 1

    # Second pass: find usage patterns
    find_property_usage(gd_files, all_properties)

    # Analyze issues
    for file_path, props in all_properties.items():
        for prop_name, prop in props.items():
            # Issue: Export without setter (can't validate input)
            if prop.is_export and not prop.has_setter:
                if strict:
                    report.issues.append(SetgetIssue(
                        file=file_path,
                        line=prop.line,
                        property=prop_name,
                        issue_type="export_no_setter",
                        message=f"@export '{prop_name}' has no setter for validation",
                        severity="info"
                    ))

            # Issue: Modified externally without setter
            if prop.external_modifications > 0 and not prop.has_setter:
                report.issues.append(SetgetIssue(
                    file=file_path,
                    line=prop.line,
                    property=prop_name,
                    issue_type="external_mod_no_setter",
                    message=f"'{prop_name}' modified externally {prop.external_modifications}x without setter",
                    severity="warning"
                ))

            # Issue: Has setter but no getter (or vice versa) - inconsistent
            if prop.has_setter and not prop.has_getter and prop.external_reads > 0:
                if strict:
                    report.issues.append(SetgetIssue(
                        file=file_path,
                        line=prop.line,
                        property=prop_name,
                        issue_type="setter_no_getter",
                        message=f"'{prop_name}' has setter but no getter (read {prop.external_reads}x)",
                        severity="info"
                    ))

            # Issue: Property name suggests it needs validation
            validation_patterns = ['_count', '_size', '_index', '_id', '_limit', '_max', '_min']
            for pattern in validation_patterns:
                if prop_name.endswith(pattern) and not prop.has_setter:
                    if strict and prop.external_modifications > 0:
                        report.issues.append(SetgetIssue(
                            file=file_path,
                            line=prop.line,
                            property=prop_name,
                            issue_type="needs_validation",
                            message=f"'{prop_name}' likely needs validation but has no setter",
                            severity="info"
                        ))
                    break

            report.by_file[file_path] = [i for i in report.issues if i.file == file_path]

    return report


def format_report(report: SetgetReport) -> str:
    """Format setget report as text."""
    lines = []
    lines.append("=" * 60)
    lines.append("SETGET PATTERNS CHECKER - KEYBOARD DEFENSE")
    lines.append("=" * 60)
    lines.append("")

    # Summary
    lines.append("## SUMMARY")
    lines.append(f"  Files checked:          {report.files_checked}")
    lines.append(f"  Total properties:       {report.total_properties}")
    lines.append(f"  Export properties:      {report.export_properties}")
    lines.append(f"  With setters:           {report.properties_with_setters}")
    lines.append(f"  With getters:           {report.properties_with_getters}")
    lines.append(f"  Issues found:           {len(report.issues)}")
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
        lines.append("## SETGET ISSUES")

        sorted_issues = sorted(report.issues, key=lambda x: (0 if x.severity == "warning" else 1, x.file, x.line))

        for issue in sorted_issues[:40]:
            severity_marker = "[WARN]" if issue.severity == "warning" else "[INFO]"
            lines.append(f"  {severity_marker} {issue.file}:{issue.line}")
            lines.append(f"    {issue.message}")

        if len(report.issues) > 40:
            lines.append(f"  ... and {len(report.issues) - 40} more issues")
        lines.append("")

    # Properties modified externally without setters
    external_mods = []
    for file_path, props in report.properties.items():
        for prop in props:
            if prop.external_modifications > 0 and not prop.has_setter:
                external_mods.append((file_path, prop))

    if external_mods:
        lines.append("## PROPERTIES MODIFIED EXTERNALLY WITHOUT SETTERS")
        sorted_mods = sorted(external_mods, key=lambda x: -x[1].external_modifications)[:15]
        for file_path, prop in sorted_mods:
            lines.append(f"  {file_path}: {prop.name} ({prop.external_modifications} external mods)")
        lines.append("")

    # Health indicators
    lines.append("## HEALTH INDICATORS")

    warning_count = sum(1 for i in report.issues if i.severity == "warning")
    if warning_count == 0:
        lines.append("  [OK] No setget pattern warnings")
    else:
        lines.append(f"  [WARN] {warning_count} properties modified externally without setters")

    if report.total_properties > 0:
        setter_ratio = report.properties_with_setters / report.total_properties * 100
        if setter_ratio >= 20:
            lines.append(f"  [OK] {setter_ratio:.0f}% properties have setters")
        else:
            lines.append(f"  [INFO] Only {setter_ratio:.0f}% properties have setters")

    lines.append("")
    return "\n".join(lines)


def format_json(report: SetgetReport) -> str:
    """Format report as JSON."""
    data = {
        "summary": {
            "files_checked": report.files_checked,
            "total_properties": report.total_properties,
            "export_properties": report.export_properties,
            "properties_with_setters": report.properties_with_setters,
            "properties_with_getters": report.properties_with_getters,
            "issues": len(report.issues)
        },
        "issues": [
            {
                "file": i.file,
                "line": i.line,
                "property": i.property,
                "type": i.issue_type,
                "message": i.message,
                "severity": i.severity
            }
            for i in report.issues[:100]
        ]
    }
    return json.dumps(data, indent=2)


def main():
    import argparse

    parser = argparse.ArgumentParser(description="Check setget patterns")
    parser.add_argument("--json", "-j", action="store_true", help="JSON output")
    parser.add_argument("--file", "-f", type=str, help="Single file to check")
    parser.add_argument("--strict", "-s", action="store_true", help="Include info-level issues")
    args = parser.parse_args()

    report = check_setget_patterns(args.file, args.strict)

    if args.json:
        print(format_json(report))
    else:
        print(format_report(report))


if __name__ == "__main__":
    main()
