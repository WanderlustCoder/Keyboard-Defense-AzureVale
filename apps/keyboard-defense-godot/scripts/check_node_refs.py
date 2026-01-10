#!/usr/bin/env python3
"""
Node Reference Checker

Checks for node reference patterns in GDScript:
- $NodePath syntax usage
- get_node() calls
- @onready var patterns
- Potential runtime errors from missing nodes

Usage:
    python scripts/check_node_refs.py              # Full report
    python scripts/check_node_refs.py --file game/main.gd  # Single file
    python scripts/check_node_refs.py --strict     # Stricter checks
    python scripts/check_node_refs.py --json       # JSON output
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
class NodeRef:
    """A node reference in code."""
    file: str
    line: int
    ref_type: str  # "$", "get_node", "@onready", "find_child"
    path: str
    context: str
    is_safe: bool = True  # has null check or is @onready


@dataclass
class NodeRefIssue:
    """An issue with a node reference."""
    file: str
    line: int
    issue_type: str
    path: str
    message: str
    severity: str


@dataclass
class NodeRefReport:
    """Node reference check report."""
    files_checked: int = 0
    total_refs: int = 0
    dollar_refs: int = 0
    get_node_refs: int = 0
    onready_refs: int = 0
    find_child_refs: int = 0
    unsafe_refs: int = 0
    refs: List[NodeRef] = field(default_factory=list)
    issues: List[NodeRefIssue] = field(default_factory=list)
    by_severity: Dict[str, int] = field(default_factory=lambda: {"high": 0, "medium": 0, "low": 0})


def analyze_file(file_path: Path, rel_path: str, strict: bool = False) -> tuple:
    """Analyze a file for node references."""
    refs = []
    issues = []

    try:
        content = file_path.read_text(encoding="utf-8")
        lines = content.split('\n')
    except Exception:
        return refs, issues

    # Track @onready variables
    onready_vars: Set[str] = set()

    for i, line in enumerate(lines):
        line_num = i + 1
        stripped = line.strip()

        # Skip comments
        if stripped.startswith("#"):
            continue

        # @onready var pattern
        onready_match = re.search(r'@onready\s+var\s+(\w+)\s*[=:].*\$([^\s:]+)', line)
        if onready_match:
            var_name = onready_match.group(1)
            node_path = onready_match.group(2)
            onready_vars.add(var_name)

            refs.append(NodeRef(
                file=rel_path,
                line=line_num,
                ref_type="@onready",
                path=node_path,
                context=stripped[:80],
                is_safe=True
            ))
            continue

        # @onready with get_node
        onready_getnode = re.search(r'@onready\s+var\s+(\w+)\s*[=:].*get_node\(["\']([^"\']+)["\']\)', line)
        if onready_getnode:
            var_name = onready_getnode.group(1)
            node_path = onready_getnode.group(2)
            onready_vars.add(var_name)

            refs.append(NodeRef(
                file=rel_path,
                line=line_num,
                ref_type="@onready",
                path=node_path,
                context=stripped[:80],
                is_safe=True
            ))
            continue

        # $ syntax (not in @onready)
        dollar_matches = re.findall(r'\$([A-Za-z_][A-Za-z0-9_/]*)', line)
        for match in dollar_matches:
            # Check if this line has a null check
            has_null_check = "if " in line and ("!=" in line or "==" in line or " is " in line)
            is_safe = has_null_check or "@onready" in line

            refs.append(NodeRef(
                file=rel_path,
                line=line_num,
                ref_type="$",
                path=match,
                context=stripped[:80],
                is_safe=is_safe
            ))

            # Check for potential issues
            if not is_safe and strict:
                # Check if used in _ready or later
                issues.append(NodeRefIssue(
                    file=rel_path,
                    line=line_num,
                    issue_type="unchecked_dollar",
                    path=match,
                    message=f"$ reference without null check: ${match}",
                    severity="low"
                ))

        # get_node() calls
        getnode_matches = re.findall(r'get_node\(["\']([^"\']+)["\']\)', line)
        for match in getnode_matches:
            has_null_check = "if " in line or "get_node_or_null" in line

            refs.append(NodeRef(
                file=rel_path,
                line=line_num,
                ref_type="get_node",
                path=match,
                context=stripped[:80],
                is_safe=has_null_check
            ))

            if not has_null_check and strict:
                issues.append(NodeRefIssue(
                    file=rel_path,
                    line=line_num,
                    issue_type="unchecked_get_node",
                    path=match,
                    message=f"get_node() without null check",
                    severity="medium"
                ))

        # get_node_or_null() - always safe
        safe_getnode = re.findall(r'get_node_or_null\(["\']([^"\']+)["\']\)', line)
        for match in safe_getnode:
            refs.append(NodeRef(
                file=rel_path,
                line=line_num,
                ref_type="get_node_or_null",
                path=match,
                context=stripped[:80],
                is_safe=True
            ))

        # find_child() calls
        findchild_matches = re.findall(r'find_child\(["\']([^"\']+)["\']\)', line)
        for match in findchild_matches:
            has_null_check = "if " in line

            refs.append(NodeRef(
                file=rel_path,
                line=line_num,
                ref_type="find_child",
                path=match,
                context=stripped[:80],
                is_safe=has_null_check
            ))

        # Deep path patterns (potential fragility)
        deep_paths = [r for r in refs if r.line == line_num and r.path.count("/") > 3]
        for ref in deep_paths:
            issues.append(NodeRefIssue(
                file=rel_path,
                line=line_num,
                issue_type="deep_path",
                path=ref.path,
                message=f"Deep node path ({ref.path.count('/') + 1} levels) is fragile",
                severity="low"
            ))

    return refs, issues


def check_node_refs(target_file: Optional[str] = None, strict: bool = False) -> NodeRefReport:
    """Check node references across the project."""
    report = NodeRefReport()

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

        refs, issues = analyze_file(gd_file, rel_path, strict)

        for ref in refs:
            report.total_refs += 1
            report.refs.append(ref)

            if ref.ref_type == "$":
                report.dollar_refs += 1
            elif ref.ref_type == "get_node":
                report.get_node_refs += 1
            elif ref.ref_type == "@onready":
                report.onready_refs += 1
            elif ref.ref_type == "find_child":
                report.find_child_refs += 1

            if not ref.is_safe:
                report.unsafe_refs += 1

        for issue in issues:
            report.issues.append(issue)
            report.by_severity[issue.severity] += 1

    return report


def format_report(report: NodeRefReport, strict: bool = False) -> str:
    """Format node reference report as text."""
    lines = []
    lines.append("=" * 60)
    lines.append("NODE REFERENCE CHECKER - KEYBOARD DEFENSE")
    lines.append("=" * 60)
    lines.append("")

    # Summary
    lines.append("## SUMMARY")
    lines.append(f"  Files checked:       {report.files_checked}")
    lines.append(f"  Total references:    {report.total_refs}")
    lines.append(f"    $ syntax:          {report.dollar_refs}")
    lines.append(f"    get_node():        {report.get_node_refs}")
    lines.append(f"    @onready:          {report.onready_refs}")
    lines.append(f"    find_child():      {report.find_child_refs}")
    lines.append(f"  Potentially unsafe:  {report.unsafe_refs}")
    lines.append("")

    # Reference breakdown by file
    files_with_refs: Dict[str, int] = {}
    for ref in report.refs:
        files_with_refs[ref.file] = files_with_refs.get(ref.file, 0) + 1

    lines.append("## REFERENCES BY FILE")
    sorted_files = sorted(files_with_refs.items(), key=lambda x: -x[1])
    for file_path, count in sorted_files[:10]:
        lines.append(f"  {file_path}: {count} refs")
    if len(sorted_files) > 10:
        lines.append(f"  ... and {len(sorted_files) - 10} more files")
    lines.append("")

    # Issues
    if report.issues:
        lines.append("## ISSUES")
        for issue in report.issues[:20]:
            severity_marker = "!" if issue.severity == "high" else "?" if issue.severity == "medium" else "i"
            lines.append(f"  [{severity_marker}] {issue.file}:{issue.line}")
            lines.append(f"      {issue.message}")
        if len(report.issues) > 20:
            lines.append(f"  ... and {len(report.issues) - 20} more")
        lines.append("")

    # Pattern recommendations
    lines.append("## RECOMMENDATIONS")
    if report.get_node_refs > 0:
        lines.append("  - Consider using @onready for node references used multiple times")
    if report.dollar_refs > report.onready_refs:
        lines.append("  - Move frequent $ references to @onready vars for better performance")

    deep_paths = [r for r in report.refs if r.path.count("/") > 2]
    if deep_paths:
        lines.append(f"  - {len(deep_paths)} deep paths found - consider flattening scene structure")
    lines.append("")

    # Health indicators
    lines.append("## HEALTH INDICATORS")
    if report.onready_refs > report.dollar_refs:
        lines.append("  [OK] Good use of @onready pattern")
    else:
        lines.append("  [INFO] Consider using more @onready for frequently accessed nodes")

    if report.unsafe_refs == 0:
        lines.append("  [OK] All node references appear safe")
    elif report.unsafe_refs < 10:
        lines.append(f"  [INFO] {report.unsafe_refs} potentially unsafe references")
    else:
        lines.append(f"  [WARN] {report.unsafe_refs} potentially unsafe references")

    lines.append("")
    return "\n".join(lines)


def format_json(report: NodeRefReport) -> str:
    """Format report as JSON."""
    data = {
        "summary": {
            "files_checked": report.files_checked,
            "total_refs": report.total_refs,
            "dollar_refs": report.dollar_refs,
            "get_node_refs": report.get_node_refs,
            "onready_refs": report.onready_refs,
            "find_child_refs": report.find_child_refs,
            "unsafe_refs": report.unsafe_refs
        },
        "by_severity": report.by_severity,
        "issues": [
            {
                "file": i.file,
                "line": i.line,
                "type": i.issue_type,
                "path": i.path,
                "message": i.message,
                "severity": i.severity
            }
            for i in report.issues
        ],
        "references": [
            {
                "file": r.file,
                "line": r.line,
                "type": r.ref_type,
                "path": r.path,
                "is_safe": r.is_safe
            }
            for r in report.refs[:100]  # Limit for JSON size
        ]
    }
    return json.dumps(data, indent=2)


def main():
    import argparse

    parser = argparse.ArgumentParser(description="Check node references")
    parser.add_argument("--json", "-j", action="store_true", help="JSON output")
    parser.add_argument("--file", "-f", type=str, help="Single file to check")
    parser.add_argument("--strict", "-s", action="store_true", help="Stricter checks")
    args = parser.parse_args()

    report = check_node_refs(args.file, args.strict)

    if args.json:
        print(format_json(report))
    else:
        print(format_report(report, args.strict))


if __name__ == "__main__":
    main()
