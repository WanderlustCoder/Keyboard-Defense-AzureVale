#!/usr/bin/env python3
"""
Export Variable Checker

Analyzes @export variables in GDScript:
- Finds exports without type hints
- Checks for missing default values
- Validates export_range/export_enum usage
- Reports export patterns

Usage:
    python scripts/check_exports.py              # Full report
    python scripts/check_exports.py --untyped    # Only untyped exports
    python scripts/check_exports.py --file game/main.gd  # Single file
    python scripts/check_exports.py --json       # JSON output
"""

import json
import re
import sys
from dataclasses import dataclass, field
from pathlib import Path
from typing import Dict, List, Set, Optional, Tuple

# Project paths
SCRIPT_DIR = Path(__file__).parent
PROJECT_ROOT = SCRIPT_DIR.parent


@dataclass
class ExportVar:
    """An @export variable."""
    name: str
    file: str
    line: int
    export_type: str  # "export", "export_range", "export_enum", etc.
    var_type: str = ""
    has_type: bool = False
    has_default: bool = False
    default_value: str = ""
    hint: str = ""


@dataclass
class ExportIssue:
    """An issue with an export variable."""
    file: str
    line: int
    var_name: str
    issue_type: str
    message: str


@dataclass
class ExportReport:
    """Export variable analysis report."""
    exports: List[ExportVar] = field(default_factory=list)
    issues: List[ExportIssue] = field(default_factory=list)
    by_file: Dict[str, int] = field(default_factory=dict)
    by_type: Dict[str, int] = field(default_factory=dict)
    typed_count: int = 0
    untyped_count: int = 0
    with_default: int = 0
    without_default: int = 0


def parse_export_line(line: str) -> Optional[Dict]:
    """Parse an @export line and extract information."""
    stripped = line.strip()

    # Match various export patterns
    # @export var name: Type = value
    # @export var name := value
    # @export var name = value
    # @export_range(min, max) var name: Type = value
    # @export_enum("A", "B") var name: Type = value

    export_match = re.match(
        r'^@(export(?:_\w+)?)\s*(?:\(([^)]*)\))?\s*var\s+(\w+)\s*(?::\s*(\w+(?:\[[^\]]+\])?))?(?:\s*:?=\s*(.+))?$',
        stripped
    )

    if not export_match:
        return None

    export_type = export_match.group(1)
    hint = export_match.group(2) or ""
    var_name = export_match.group(3)
    var_type = export_match.group(4) or ""
    default_value = export_match.group(5) or ""

    # Check for := inference
    has_type = bool(var_type) or (':=' in stripped)
    has_default = bool(default_value) or ('=' in stripped and 'var' in stripped)

    return {
        "export_type": export_type,
        "hint": hint,
        "name": var_name,
        "var_type": var_type,
        "has_type": has_type,
        "has_default": has_default,
        "default_value": default_value.strip() if default_value else ""
    }


def analyze_file(filepath: Path) -> Tuple[List[ExportVar], List[ExportIssue]]:
    """Analyze a file for export variables."""
    exports = []
    issues = []
    rel_path = str(filepath.relative_to(PROJECT_ROOT))

    try:
        content = filepath.read_text(encoding="utf-8")
        lines = content.split('\n')
    except Exception:
        return exports, issues

    for i, line in enumerate(lines):
        stripped = line.strip()

        if not stripped.startswith('@export'):
            continue

        parsed = parse_export_line(stripped)
        if not parsed:
            # Multi-line or complex export - try simpler parse
            simple_match = re.match(r'^@(export\w*)', stripped)
            if simple_match:
                # Just record we found an export
                var_match = re.search(r'var\s+(\w+)', stripped)
                var_name = var_match.group(1) if var_match else "unknown"
                exports.append(ExportVar(
                    name=var_name,
                    file=rel_path,
                    line=i + 1,
                    export_type=simple_match.group(1),
                    has_type=':' in stripped,
                    has_default='=' in stripped
                ))
            continue

        export_var = ExportVar(
            name=parsed["name"],
            file=rel_path,
            line=i + 1,
            export_type=parsed["export_type"],
            var_type=parsed["var_type"],
            has_type=parsed["has_type"],
            has_default=parsed["has_default"],
            default_value=parsed["default_value"],
            hint=parsed["hint"]
        )
        exports.append(export_var)

        # Check for issues

        # 1. No type annotation
        if not parsed["has_type"]:
            issues.append(ExportIssue(
                file=rel_path,
                line=i + 1,
                var_name=parsed["name"],
                issue_type="untyped",
                message="Export variable missing type annotation"
            ))

        # 2. export_range without numeric type
        if parsed["export_type"] == "export_range":
            if parsed["var_type"] and parsed["var_type"] not in ["int", "float"]:
                issues.append(ExportIssue(
                    file=rel_path,
                    line=i + 1,
                    var_name=parsed["name"],
                    issue_type="range_type",
                    message=f"export_range with non-numeric type: {parsed['var_type']}"
                ))

        # 3. export_enum should use int or String
        if parsed["export_type"] == "export_enum":
            if parsed["var_type"] and parsed["var_type"] not in ["int", "String"]:
                issues.append(ExportIssue(
                    file=rel_path,
                    line=i + 1,
                    var_name=parsed["name"],
                    issue_type="enum_type",
                    message=f"export_enum should use int or String, not {parsed['var_type']}"
                ))

        # 4. Node types without default often cause issues
        node_types = ["Node", "Node2D", "Node3D", "Control", "Sprite2D", "Label", "Button"]
        if parsed["var_type"] in node_types and not parsed["has_default"]:
            issues.append(ExportIssue(
                file=rel_path,
                line=i + 1,
                var_name=parsed["name"],
                issue_type="node_no_default",
                message=f"Node export '{parsed['var_type']}' without default - may be null"
            ))

    return exports, issues


def analyze_exports(file_filter: Optional[str] = None,
                    show_untyped_only: bool = False) -> ExportReport:
    """Analyze exports across the codebase."""
    report = ExportReport()

    for gd_file in PROJECT_ROOT.glob("**/*.gd"):
        if ".godot" in str(gd_file) or "addons" in str(gd_file):
            continue

        rel_path = str(gd_file.relative_to(PROJECT_ROOT))
        if file_filter and file_filter not in rel_path:
            continue

        exports, issues = analyze_file(gd_file)

        for exp in exports:
            report.exports.append(exp)
            report.by_file[exp.file] = report.by_file.get(exp.file, 0) + 1
            report.by_type[exp.export_type] = report.by_type.get(exp.export_type, 0) + 1

            if exp.has_type:
                report.typed_count += 1
            else:
                report.untyped_count += 1

            if exp.has_default:
                report.with_default += 1
            else:
                report.without_default += 1

        # Filter issues if showing untyped only
        if show_untyped_only:
            issues = [i for i in issues if i.issue_type == "untyped"]

        report.issues.extend(issues)

    return report


def format_report(report: ExportReport, show_untyped_only: bool = False) -> str:
    """Format export report as text."""
    lines = []
    lines.append("=" * 60)
    lines.append("EXPORT VARIABLE CHECKER - KEYBOARD DEFENSE")
    lines.append("=" * 60)
    lines.append("")

    # Summary
    lines.append("## SUMMARY")
    lines.append(f"  Total exports:      {len(report.exports)}")
    lines.append(f"  With type hints:    {report.typed_count}")
    lines.append(f"  Without type hints: {report.untyped_count}")
    lines.append(f"  With defaults:      {report.with_default}")
    lines.append(f"  Without defaults:   {report.without_default}")
    lines.append(f"  Issues found:       {len(report.issues)}")
    lines.append("")

    # Type coverage
    if report.exports:
        type_pct = (report.typed_count / len(report.exports)) * 100
        bar_width = 40
        filled = int(bar_width * type_pct / 100)
        bar = "[" + "=" * filled + " " * (bar_width - filled) + "]"
        lines.append(f"  Type coverage: {bar} {type_pct:.1f}%")
        lines.append("")

    # By export type
    if report.by_type:
        lines.append("## BY EXPORT TYPE")
        for exp_type, count in sorted(report.by_type.items(), key=lambda x: -x[1]):
            lines.append(f"  {exp_type:20} {count}")
        lines.append("")

    # Issues
    if report.issues:
        lines.append("## ISSUES")
        for issue in report.issues[:25]:
            lines.append(f"  {issue.file}:{issue.line}")
            lines.append(f"    [{issue.issue_type}] {issue.var_name}: {issue.message}")
        if len(report.issues) > 25:
            lines.append(f"  ... and {len(report.issues) - 25} more issues")
        lines.append("")

    # Files with most exports
    if report.by_file:
        lines.append("## FILES WITH MOST EXPORTS")
        sorted_files = sorted(report.by_file.items(), key=lambda x: -x[1])
        for filepath, count in sorted_files[:10]:
            lines.append(f"  {count:4} exports  {filepath}")
        lines.append("")

    # Sample exports
    if not show_untyped_only and report.exports:
        lines.append("## SAMPLE EXPORTS")
        for exp in report.exports[:10]:
            type_str = f": {exp.var_type}" if exp.var_type else ""
            default_str = f" = {exp.default_value[:20]}" if exp.default_value else ""
            lines.append(f"  @{exp.export_type} var {exp.name}{type_str}{default_str}")
            lines.append(f"    {exp.file}:{exp.line}")
        lines.append("")

    # Health indicators
    lines.append("## HEALTH INDICATORS")
    if report.exports:
        type_pct = (report.typed_count / len(report.exports)) * 100
        if type_pct >= 90:
            lines.append(f"  [OK] {type_pct:.0f}% of exports have type hints")
        elif type_pct >= 70:
            lines.append(f"  [INFO] {type_pct:.0f}% of exports have type hints")
        else:
            lines.append(f"  [WARN] Only {type_pct:.0f}% of exports have type hints")

    issue_types = {}
    for issue in report.issues:
        issue_types[issue.issue_type] = issue_types.get(issue.issue_type, 0) + 1

    if issue_types.get("untyped", 0) > 10:
        lines.append(f"  [WARN] {issue_types['untyped']} untyped exports")
    if issue_types.get("node_no_default", 0) > 0:
        lines.append(f"  [INFO] {issue_types['node_no_default']} Node exports without defaults")

    lines.append("")
    return "\n".join(lines)


def format_json(report: ExportReport) -> str:
    """Format report as JSON."""
    data = {
        "summary": {
            "total": len(report.exports),
            "typed": report.typed_count,
            "untyped": report.untyped_count,
            "with_default": report.with_default,
            "without_default": report.without_default,
            "issues": len(report.issues)
        },
        "by_type": report.by_type,
        "by_file": report.by_file,
        "exports": [
            {
                "name": e.name,
                "file": e.file,
                "line": e.line,
                "export_type": e.export_type,
                "var_type": e.var_type,
                "has_type": e.has_type,
                "has_default": e.has_default
            }
            for e in report.exports
        ],
        "issues": [
            {
                "file": i.file,
                "line": i.line,
                "var_name": i.var_name,
                "type": i.issue_type,
                "message": i.message
            }
            for i in report.issues
        ]
    }
    return json.dumps(data, indent=2)


def main():
    import argparse

    parser = argparse.ArgumentParser(description="Check export variables")
    parser.add_argument("--json", "-j", action="store_true", help="JSON output")
    parser.add_argument("--file", "-f", type=str, help="Filter by file path")
    parser.add_argument("--untyped", "-u", action="store_true", help="Show only untyped exports")
    args = parser.parse_args()

    report = analyze_exports(args.file, args.untyped)

    if args.json:
        print(format_json(report))
    else:
        print(format_report(report, args.untyped))


if __name__ == "__main__":
    main()
