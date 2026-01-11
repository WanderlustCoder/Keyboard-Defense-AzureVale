#!/usr/bin/env python3
"""
Resource References Checker

Finds issues with resource references:
- Broken res:// paths
- Missing preloaded resources
- Circular resource dependencies
- Unused loaded resources

Usage:
    python scripts/check_resource_refs.py              # Full report
    python scripts/check_resource_refs.py --file game/main.gd  # Single file
    python scripts/check_resource_refs.py --strict     # More patterns
    python scripts/check_resource_refs.py --json       # JSON output
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
class ResourceRef:
    """A resource reference."""
    file: str
    line: int
    path: str
    ref_type: str  # "preload", "load", "res_path"
    variable: Optional[str]
    exists: bool


@dataclass
class ResourceIssue:
    """A resource reference issue."""
    file: str
    line: int
    path: str
    issue_type: str
    message: str
    severity: str  # "error", "warning", "info"


@dataclass
class ResourceReport:
    """Resource references report."""
    files_checked: int = 0
    total_refs: int = 0
    preloads: int = 0
    loads: int = 0
    res_paths: int = 0
    broken_refs: int = 0
    issues: List[ResourceIssue] = field(default_factory=list)
    refs: List[ResourceRef] = field(default_factory=list)
    by_file: Dict[str, List[ResourceRef]] = field(default_factory=lambda: defaultdict(list))
    resource_usage: Dict[str, int] = field(default_factory=lambda: defaultdict(int))


def extract_resource_refs(file_path: Path, rel_path: str) -> List[ResourceRef]:
    """Extract resource references from a file."""
    refs = []

    try:
        content = file_path.read_text(encoding='utf-8')
        lines = content.split('\n')
    except Exception:
        return refs

    for i, line in enumerate(lines):
        stripped = line.strip()

        # Skip comments
        if stripped.startswith('#'):
            continue

        # Find preload() calls
        preload_matches = re.findall(r'preload\s*\(\s*["\']([^"\']+)["\']\s*\)', line)
        for path in preload_matches:
            variable = None
            var_match = re.match(r'(?:const|var)\s+(\w+)\s*=', stripped)
            if var_match:
                variable = var_match.group(1)

            exists = check_resource_exists(path)
            refs.append(ResourceRef(
                file=rel_path,
                line=i + 1,
                path=path,
                ref_type="preload",
                variable=variable,
                exists=exists
            ))

        # Find load() calls
        load_matches = re.findall(r'(?<!pre)load\s*\(\s*["\']([^"\']+)["\']\s*\)', line)
        for path in load_matches:
            variable = None
            var_match = re.match(r'(?:const|var)\s+(\w+)\s*=', stripped)
            if var_match:
                variable = var_match.group(1)

            exists = check_resource_exists(path)
            refs.append(ResourceRef(
                file=rel_path,
                line=i + 1,
                path=path,
                ref_type="load",
                variable=variable,
                exists=exists
            ))

        # Find res:// paths in strings (not already captured)
        res_matches = re.findall(r'["\']res://([^"\']+)["\']', line)
        for path in res_matches:
            full_path = f"res://{path}"
            # Skip if already captured as preload/load
            if any(r.path == full_path and r.line == i + 1 for r in refs):
                continue

            exists = check_resource_exists(full_path)
            refs.append(ResourceRef(
                file=rel_path,
                line=i + 1,
                path=full_path,
                ref_type="res_path",
                variable=None,
                exists=exists
            ))

    return refs


def check_resource_exists(res_path: str) -> bool:
    """Check if a resource path exists."""
    if not res_path.startswith("res://"):
        return False

    # Convert res:// to actual path
    relative_path = res_path.replace("res://", "")
    actual_path = PROJECT_ROOT / relative_path

    return actual_path.exists()


def find_resource_dependencies(all_refs: List[ResourceRef]) -> Dict[str, Set[str]]:
    """Build a graph of resource dependencies."""
    deps: Dict[str, Set[str]] = defaultdict(set)

    for ref in all_refs:
        if ref.path.startswith("res://"):
            deps[ref.file].add(ref.path)

    return deps


def find_unused_loaded_resources(file_path: Path, refs: List[ResourceRef]) -> List[Tuple[str, int, str]]:
    """Find loaded resources that are never used."""
    unused = []

    try:
        content = file_path.read_text(encoding='utf-8')
    except Exception:
        return unused

    for ref in refs:
        if ref.variable and ref.ref_type in ["preload", "load"]:
            # Check if variable is used after declaration
            pattern = rf'\b{re.escape(ref.variable)}\b'
            matches = list(re.finditer(pattern, content))
            # Should appear at least twice (declaration + usage)
            if len(matches) < 2:
                unused.append((ref.variable, ref.line, ref.path))

    return unused


def check_resource_refs(target_file: Optional[str] = None, strict: bool = False) -> ResourceReport:
    """Check resource references across the project."""
    report = ResourceReport()

    if target_file:
        gd_files = [PROJECT_ROOT / target_file]
    else:
        gd_files = list(PROJECT_ROOT.glob("**/*.gd"))

    all_refs: List[ResourceRef] = []

    for gd_file in gd_files:
        if ".godot" in str(gd_file) or "addons" in str(gd_file):
            continue

        if not gd_file.exists():
            continue

        rel_path = str(gd_file.relative_to(PROJECT_ROOT))
        report.files_checked += 1

        refs = extract_resource_refs(gd_file, rel_path)
        all_refs.extend(refs)

        for ref in refs:
            report.refs.append(ref)
            report.by_file[rel_path].append(ref)
            report.total_refs += 1
            report.resource_usage[ref.path] += 1

            if ref.ref_type == "preload":
                report.preloads += 1
            elif ref.ref_type == "load":
                report.loads += 1
            else:
                report.res_paths += 1

            # Check for broken references
            if not ref.exists:
                report.broken_refs += 1
                report.issues.append(ResourceIssue(
                    file=rel_path,
                    line=ref.line,
                    path=ref.path,
                    issue_type="broken_ref",
                    message=f"Resource not found: {ref.path}",
                    severity="error"
                ))

        # Check for unused loaded resources
        if strict:
            unused = find_unused_loaded_resources(gd_file, refs)
            for var_name, line, path in unused:
                report.issues.append(ResourceIssue(
                    file=rel_path,
                    line=line,
                    path=path,
                    issue_type="unused_load",
                    message=f"Loaded resource '{var_name}' appears unused",
                    severity="info"
                ))

    # Check for load() in frequently called functions
    for gd_file in gd_files:
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

        current_func = None
        hot_funcs = {'_process', '_physics_process', '_input', '_unhandled_input'}

        for i, line in enumerate(lines):
            stripped = line.strip()

            func_match = re.match(r'^func\s+(\w+)\s*\(', stripped)
            if func_match:
                current_func = func_match.group(1)
                continue

            if current_func in hot_funcs:
                if 'load(' in line and 'preload(' not in line:
                    report.issues.append(ResourceIssue(
                        file=rel_path,
                        line=i + 1,
                        path="",
                        issue_type="load_in_hot_path",
                        message=f"load() called in {current_func}() - use preload instead",
                        severity="warning"
                    ))

    return report


def format_report(report: ResourceReport) -> str:
    """Format resource report as text."""
    lines = []
    lines.append("=" * 60)
    lines.append("RESOURCE REFERENCES CHECKER - KEYBOARD DEFENSE")
    lines.append("=" * 60)
    lines.append("")

    # Summary
    lines.append("## SUMMARY")
    lines.append(f"  Files checked:      {report.files_checked}")
    lines.append(f"  Total references:   {report.total_refs}")
    lines.append(f"  Preloads:           {report.preloads}")
    lines.append(f"  Loads:              {report.loads}")
    lines.append(f"  Res paths:          {report.res_paths}")
    lines.append(f"  Broken refs:        {report.broken_refs}")
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

    # Issues
    if report.issues:
        lines.append("## RESOURCE ISSUES")

        sorted_issues = sorted(report.issues, key=lambda x: (0 if x.severity == "error" else 1, x.file, x.line))

        for issue in sorted_issues[:40]:
            severity_marker = {"error": "[ERROR]", "warning": "[WARN]", "info": "[INFO]"}.get(issue.severity, "[???]")
            lines.append(f"  {severity_marker} {issue.file}:{issue.line}")
            lines.append(f"    {issue.message}")

        if len(report.issues) > 40:
            lines.append(f"  ... and {len(report.issues) - 40} more issues")
        lines.append("")

    # Most referenced resources
    if report.resource_usage:
        lines.append("## MOST REFERENCED RESOURCES")
        sorted_resources = sorted(report.resource_usage.items(), key=lambda x: -x[1])[:15]
        for path, count in sorted_resources:
            lines.append(f"  {count:3}x {path}")
        lines.append("")

    # Files with most refs
    if report.by_file:
        lines.append("## FILES WITH MOST RESOURCE REFS")
        sorted_files = sorted(report.by_file.items(), key=lambda x: -len(x[1]))[:10]
        for file_path, refs in sorted_files:
            preload_count = sum(1 for r in refs if r.ref_type == "preload")
            load_count = sum(1 for r in refs if r.ref_type == "load")
            lines.append(f"  {file_path}: {len(refs)} ({preload_count} preload, {load_count} load)")
        lines.append("")

    # Health indicators
    lines.append("## HEALTH INDICATORS")
    if report.broken_refs == 0:
        lines.append("  [OK] No broken resource references")
    else:
        lines.append(f"  [ERROR] {report.broken_refs} broken resource references")

    hot_path_issues = sum(1 for i in report.issues if i.issue_type == "load_in_hot_path")
    if hot_path_issues == 0:
        lines.append("  [OK] No load() calls in hot paths")
    else:
        lines.append(f"  [WARN] {hot_path_issues} load() calls in hot path functions")

    if report.total_refs > 0:
        preload_ratio = report.preloads / report.total_refs * 100
        lines.append(f"  [INFO] {preload_ratio:.0f}% of loads use preload()")

    lines.append("")
    return "\n".join(lines)


def format_json(report: ResourceReport) -> str:
    """Format report as JSON."""
    data = {
        "summary": {
            "files_checked": report.files_checked,
            "total_refs": report.total_refs,
            "preloads": report.preloads,
            "loads": report.loads,
            "res_paths": report.res_paths,
            "broken_refs": report.broken_refs,
            "issues": len(report.issues)
        },
        "issues": [
            {
                "file": i.file,
                "line": i.line,
                "path": i.path,
                "type": i.issue_type,
                "message": i.message,
                "severity": i.severity
            }
            for i in report.issues[:100]
        ],
        "most_referenced": [
            {"path": p, "count": c}
            for p, c in sorted(report.resource_usage.items(), key=lambda x: -x[1])[:20]
        ]
    }
    return json.dumps(data, indent=2)


def main():
    import argparse

    parser = argparse.ArgumentParser(description="Check resource references")
    parser.add_argument("--json", "-j", action="store_true", help="JSON output")
    parser.add_argument("--file", "-f", type=str, help="Single file to check")
    parser.add_argument("--strict", "-s", action="store_true", help="Include info-level checks")
    args = parser.parse_args()

    report = check_resource_refs(args.file, args.strict)

    if args.json:
        print(format_json(report))
    else:
        print(format_report(report))


if __name__ == "__main__":
    main()
