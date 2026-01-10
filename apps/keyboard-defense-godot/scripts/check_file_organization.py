#!/usr/bin/env python3
"""
File Organization Checker

Analyzes file organization and structure:
- File placement in correct directories
- Naming convention compliance
- File size distribution
- Directory structure consistency

Usage:
    python scripts/check_file_organization.py              # Full report
    python scripts/check_file_organization.py --layer sim  # Single layer
    python scripts/check_file_organization.py --json       # JSON output
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

# Expected directory structure
EXPECTED_STRUCTURE = {
    "sim/": {
        "description": "Deterministic game logic (RefCounted)",
        "expected_base": "RefCounted",
        "naming": "snake_case",
        "should_have_class_name": True
    },
    "game/": {
        "description": "Rendering, input, scene management",
        "expected_base": ["Node", "Node2D", "Control"],
        "naming": "snake_case",
        "should_have_class_name": False
    },
    "ui/": {
        "description": "UI components and panels",
        "expected_base": ["Control", "PanelContainer", "Container"],
        "naming": "snake_case",
        "should_have_class_name": False
    },
    "scripts/": {
        "description": "Scene-attached scripts",
        "expected_base": ["Node", "Control"],
        "naming": "PascalCase",
        "should_have_class_name": False
    },
    "tests/": {
        "description": "Test files",
        "naming": "snake_case",
        "should_have_class_name": False
    },
    "tools/": {
        "description": "Development tools",
        "naming": "snake_case",
        "should_have_class_name": False
    }
}

# Size thresholds
LARGE_FILE_THRESHOLD = 500  # lines
VERY_LARGE_FILE_THRESHOLD = 1000


@dataclass
class FileInfo:
    """Information about a file."""
    path: str
    layer: str
    size_lines: int
    size_bytes: int
    has_class_name: bool
    class_name: Optional[str]
    extends: Optional[str]
    naming_style: str  # "snake_case", "PascalCase", "other"
    issues: List[str] = field(default_factory=list)


@dataclass
class OrganizationReport:
    """File organization report."""
    files_checked: int = 0
    total_lines: int = 0
    total_bytes: int = 0
    misplaced_files: int = 0
    naming_issues: int = 0
    large_files: int = 0
    files: List[FileInfo] = field(default_factory=list)
    by_layer: Dict[str, List[FileInfo]] = field(default_factory=lambda: defaultdict(list))
    issues: List[Tuple[str, str, str]] = field(default_factory=list)  # (file, issue_type, message)


def detect_naming_style(name: str) -> str:
    """Detect the naming style of a file."""
    # Remove .gd extension
    base = name.replace(".gd", "")

    if "_" in base and base == base.lower():
        return "snake_case"
    elif base[0].isupper() and "_" not in base:
        return "PascalCase"
    elif base == base.lower():
        return "lowercase"
    else:
        return "other"


def analyze_file(file_path: Path, rel_path: str) -> FileInfo:
    """Analyze a single file."""
    # Determine layer
    layer = "other"
    for layer_name in EXPECTED_STRUCTURE:
        if rel_path.startswith(layer_name):
            layer = layer_name.rstrip("/")
            break

    try:
        content = file_path.read_text(encoding="utf-8")
        lines = content.split('\n')
        size_lines = len(lines)
        size_bytes = len(content)
    except Exception:
        return FileInfo(
            path=rel_path,
            layer=layer,
            size_lines=0,
            size_bytes=0,
            has_class_name=False,
            class_name=None,
            extends=None,
            naming_style="unknown",
            issues=["Could not read file"]
        )

    # Extract class_name
    class_name = None
    has_class_name = False
    class_name_match = re.search(r'^class_name\s+(\w+)', content, re.MULTILINE)
    if class_name_match:
        class_name = class_name_match.group(1)
        has_class_name = True

    # Extract extends
    extends = None
    extends_match = re.search(r'^extends\s+(\w+)', content, re.MULTILINE)
    if extends_match:
        extends = extends_match.group(1)

    # Detect naming style
    naming_style = detect_naming_style(file_path.name)

    info = FileInfo(
        path=rel_path,
        layer=layer,
        size_lines=size_lines,
        size_bytes=size_bytes,
        has_class_name=has_class_name,
        class_name=class_name,
        extends=extends,
        naming_style=naming_style
    )

    # Check for issues
    issues = []

    # Check layer rules
    if layer in EXPECTED_STRUCTURE:
        rules = EXPECTED_STRUCTURE[layer + "/"]

        # Check expected base class
        if "expected_base" in rules and extends:
            expected = rules["expected_base"]
            if isinstance(expected, list):
                if extends not in expected and extends not in ["RefCounted", "Resource", "Object"]:
                    # Allow common bases
                    pass
            elif expected != extends and extends not in ["RefCounted", "Resource", "Object"]:
                if layer == "sim" and extends not in ["RefCounted", "Resource"]:
                    issues.append(f"sim/ file extends {extends}, expected RefCounted")

        # Check naming convention
        expected_naming = rules.get("naming", "snake_case")
        if expected_naming == "snake_case" and naming_style == "PascalCase":
            issues.append(f"File uses PascalCase, expected snake_case for {layer}/")
        elif expected_naming == "PascalCase" and naming_style == "snake_case":
            issues.append(f"File uses snake_case, expected PascalCase for {layer}/")

    # Check file size
    if size_lines > VERY_LARGE_FILE_THRESHOLD:
        issues.append(f"Very large file: {size_lines} lines")
    elif size_lines > LARGE_FILE_THRESHOLD:
        issues.append(f"Large file: {size_lines} lines")

    info.issues = issues
    return info


def check_file_organization(target_layer: Optional[str] = None) -> OrganizationReport:
    """Check file organization across the project."""
    report = OrganizationReport()

    for gd_file in PROJECT_ROOT.glob("**/*.gd"):
        if ".godot" in str(gd_file) or "addons" in str(gd_file):
            continue

        if not gd_file.exists():
            continue

        rel_path = str(gd_file.relative_to(PROJECT_ROOT))

        # Filter by layer if specified
        if target_layer:
            if not rel_path.startswith(target_layer + "/"):
                continue

        report.files_checked += 1

        info = analyze_file(gd_file, rel_path)
        report.files.append(info)
        report.by_layer[info.layer].append(info)

        report.total_lines += info.size_lines
        report.total_bytes += info.size_bytes

        if info.issues:
            for issue in info.issues:
                if "misplaced" in issue.lower() or "expected" in issue.lower():
                    report.misplaced_files += 1
                if "naming" in issue.lower() or "case" in issue.lower():
                    report.naming_issues += 1
                if "large" in issue.lower():
                    report.large_files += 1

                report.issues.append((info.path, "issue", issue))

    return report


def format_report(report: OrganizationReport) -> str:
    """Format organization report as text."""
    lines = []
    lines.append("=" * 60)
    lines.append("FILE ORGANIZATION CHECKER - KEYBOARD DEFENSE")
    lines.append("=" * 60)
    lines.append("")

    # Summary
    lines.append("## SUMMARY")
    lines.append(f"  Files checked:      {report.files_checked}")
    lines.append(f"  Total lines:        {report.total_lines}")
    lines.append(f"  Total size:         {report.total_bytes / 1024:.1f} KB")
    lines.append(f"  Naming issues:      {report.naming_issues}")
    lines.append(f"  Large files:        {report.large_files}")
    lines.append("")

    # Files by layer
    lines.append("## FILES BY LAYER")
    for layer in ["sim", "game", "ui", "scripts", "tests", "tools", "other"]:
        if layer in report.by_layer:
            files = report.by_layer[layer]
            total_lines = sum(f.size_lines for f in files)
            lines.append(f"  {layer}/: {len(files)} files, {total_lines} lines")
    lines.append("")

    # Layer descriptions
    lines.append("## EXPECTED STRUCTURE")
    for layer, rules in EXPECTED_STRUCTURE.items():
        lines.append(f"  {layer}")
        lines.append(f"    {rules['description']}")
    lines.append("")

    # Large files
    large_files = sorted(
        [f for f in report.files if f.size_lines > LARGE_FILE_THRESHOLD],
        key=lambda f: -f.size_lines
    )
    if large_files:
        lines.append(f"## LARGE FILES (>{LARGE_FILE_THRESHOLD} lines)")
        for info in large_files[:15]:
            lines.append(f"  {info.path}: {info.size_lines} lines")
        if len(large_files) > 15:
            lines.append(f"  ... and {len(large_files) - 15} more")
        lines.append("")

    # Files with issues
    files_with_issues = [f for f in report.files if f.issues]
    if files_with_issues:
        lines.append("## FILES WITH ISSUES")
        for info in files_with_issues[:20]:
            lines.append(f"  {info.path}")
            for issue in info.issues:
                lines.append(f"    - {issue}")
        if len(files_with_issues) > 20:
            lines.append(f"  ... and {len(files_with_issues) - 20} more")
        lines.append("")

    # Naming style distribution
    naming_dist: Dict[str, int] = defaultdict(int)
    for info in report.files:
        naming_dist[info.naming_style] += 1

    lines.append("## NAMING STYLE DISTRIBUTION")
    for style, count in sorted(naming_dist.items(), key=lambda x: -x[1]):
        pct = count / report.files_checked * 100 if report.files_checked > 0 else 0
        lines.append(f"  {style}: {count} files ({pct:.0f}%)")
    lines.append("")

    # Health indicators
    lines.append("## HEALTH INDICATORS")
    if report.naming_issues == 0:
        lines.append("  [OK] Consistent naming conventions")
    else:
        lines.append(f"  [WARN] {report.naming_issues} naming convention issues")

    if report.large_files == 0:
        lines.append("  [OK] No oversized files")
    elif report.large_files < 10:
        lines.append(f"  [INFO] {report.large_files} large files")
    else:
        lines.append(f"  [WARN] {report.large_files} large files - consider splitting")

    avg_lines = report.total_lines / report.files_checked if report.files_checked > 0 else 0
    lines.append(f"  [INFO] Average file size: {avg_lines:.0f} lines")

    lines.append("")
    return "\n".join(lines)


def format_json(report: OrganizationReport) -> str:
    """Format report as JSON."""
    data = {
        "summary": {
            "files_checked": report.files_checked,
            "total_lines": report.total_lines,
            "total_bytes": report.total_bytes,
            "naming_issues": report.naming_issues,
            "large_files": report.large_files
        },
        "by_layer": {
            layer: {
                "file_count": len(files),
                "total_lines": sum(f.size_lines for f in files)
            }
            for layer, files in report.by_layer.items()
        },
        "large_files": [
            {"path": f.path, "lines": f.size_lines}
            for f in sorted(report.files, key=lambda x: -x.size_lines)[:20]
            if f.size_lines > LARGE_FILE_THRESHOLD
        ],
        "files_with_issues": [
            {"path": f.path, "issues": f.issues}
            for f in report.files if f.issues
        ][:30]
    }
    return json.dumps(data, indent=2)


def main():
    import argparse

    parser = argparse.ArgumentParser(description="Check file organization")
    parser.add_argument("--json", "-j", action="store_true", help="JSON output")
    parser.add_argument("--layer", "-l", type=str, help="Single layer to check")
    args = parser.parse_args()

    report = check_file_organization(args.layer)

    if args.json:
        print(format_json(report))
    else:
        print(format_report(report))


if __name__ == "__main__":
    main()
