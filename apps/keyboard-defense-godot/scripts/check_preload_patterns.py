#!/usr/bin/env python3
"""
Preload Patterns Checker

Analyzes preload vs load usage patterns:
- Preload at class level (good for always-needed resources)
- Load at runtime (good for conditional resources)
- Potential issues (preload in functions, load of always-needed)

Usage:
    python scripts/check_preload_patterns.py              # Full report
    python scripts/check_preload_patterns.py --file game/main.gd  # Single file
    python scripts/check_preload_patterns.py --strict     # More patterns
    python scripts/check_preload_patterns.py --json       # JSON output
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
class ResourceLoad:
    """A resource load instance."""
    file: str
    line: int
    resource_path: str
    load_type: str  # "preload", "load"
    scope: str  # "class", "function", "onready"
    is_const: bool
    context: str


@dataclass
class LoadIssue:
    """A potential loading issue."""
    file: str
    line: int
    issue_type: str
    message: str
    severity: str  # "warning", "info"
    context: str


@dataclass
class PreloadReport:
    """Preload patterns report."""
    files_checked: int = 0
    total_preloads: int = 0
    total_loads: int = 0
    class_level_preloads: int = 0
    function_preloads: int = 0
    runtime_loads: int = 0
    issues: List[LoadIssue] = field(default_factory=list)
    loads: List[ResourceLoad] = field(default_factory=list)
    by_file: Dict[str, List[ResourceLoad]] = field(default_factory=lambda: defaultdict(list))
    by_resource: Dict[str, List[ResourceLoad]] = field(default_factory=lambda: defaultdict(list))


def analyze_file(file_path: Path, rel_path: str, strict: bool) -> Tuple[List[ResourceLoad], List[LoadIssue]]:
    """Analyze a file for preload/load patterns."""
    loads = []
    issues = []

    try:
        content = file_path.read_text(encoding='utf-8')
        lines = content.split('\n')
    except Exception:
        return loads, issues

    in_function = False
    function_name = ""
    base_indent = 0

    for i, line in enumerate(lines):
        stripped = line.strip()

        # Skip comments
        if stripped.startswith('#'):
            continue

        # Track function scope
        func_match = re.match(r'^(?:static\s+)?func\s+(\w+)', stripped)
        if func_match:
            in_function = True
            function_name = func_match.group(1)
            base_indent = len(line) - len(line.lstrip())
            continue

        # Exit function on dedent
        if in_function and stripped and not line.startswith('\t') and not line.startswith('    '):
            current_indent = len(line) - len(line.lstrip())
            if current_indent <= base_indent and not stripped.startswith('#'):
                in_function = False
                function_name = ""

        # Check for preload
        preload_match = re.search(r'preload\s*\(\s*["\']([^"\']+)["\']\s*\)', line)
        if preload_match:
            resource_path = preload_match.group(1)
            is_const = 'const ' in line
            is_onready = '@onready' in line

            if is_onready:
                scope = "onready"
            elif in_function:
                scope = "function"
            else:
                scope = "class"

            loads.append(ResourceLoad(
                file=rel_path,
                line=i + 1,
                resource_path=resource_path,
                load_type="preload",
                scope=scope,
                is_const=is_const,
                context=stripped[:60]
            ))

            # Issue: preload inside function (loads at parse time anyway)
            if scope == "function":
                issues.append(LoadIssue(
                    file=rel_path,
                    line=i + 1,
                    issue_type="preload_in_function",
                    message=f"preload() in function '{function_name}' still loads at parse time",
                    severity="warning",
                    context=stripped[:60]
                ))

        # Check for load
        load_match = re.search(r'(?<!pre)load\s*\(\s*["\']([^"\']+)["\']\s*\)', line)
        if load_match:
            resource_path = load_match.group(1)
            is_const = 'const ' in line
            is_onready = '@onready' in line

            if is_onready:
                scope = "onready"
            elif in_function:
                scope = "function"
            else:
                scope = "class"

            loads.append(ResourceLoad(
                file=rel_path,
                line=i + 1,
                resource_path=resource_path,
                load_type="load",
                scope=scope,
                is_const=is_const,
                context=stripped[:60]
            ))

            # Issue: load at class level (could be preload for better performance)
            if scope == "class" and not is_onready and strict:
                issues.append(LoadIssue(
                    file=rel_path,
                    line=i + 1,
                    issue_type="class_level_load",
                    message="load() at class level could be preload() for faster startup",
                    severity="info",
                    context=stripped[:60]
                ))

        # Check for ResourceLoader.load
        res_loader_match = re.search(r'ResourceLoader\.load\s*\(\s*["\']([^"\']+)["\']\s*\)', line)
        if res_loader_match:
            resource_path = res_loader_match.group(1)

            scope = "function" if in_function else "class"

            loads.append(ResourceLoad(
                file=rel_path,
                line=i + 1,
                resource_path=resource_path,
                load_type="load",
                scope=scope,
                is_const=False,
                context=stripped[:60]
            ))

    return loads, issues


def check_preload_patterns(target_file: Optional[str] = None, strict: bool = False) -> PreloadReport:
    """Check preload patterns across the project."""
    report = PreloadReport()

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

        loads, issues = analyze_file(gd_file, rel_path, strict)

        for load in loads:
            report.loads.append(load)
            report.by_file[load.file].append(load)
            report.by_resource[load.resource_path].append(load)

            if load.load_type == "preload":
                report.total_preloads += 1
                if load.scope == "class":
                    report.class_level_preloads += 1
                elif load.scope == "function":
                    report.function_preloads += 1
            else:
                report.total_loads += 1
                if load.scope == "function":
                    report.runtime_loads += 1

        report.issues.extend(issues)

    # Check for resources loaded multiple times
    for resource_path, load_list in report.by_resource.items():
        if len(load_list) > 2:
            # Multiple loads of same resource - suggest caching
            files = set(l.file for l in load_list)
            if len(files) > 1 and strict:
                report.issues.append(LoadIssue(
                    file=load_list[0].file,
                    line=load_list[0].line,
                    issue_type="duplicate_load",
                    message=f"'{resource_path}' loaded in {len(files)} files - consider shared constant",
                    severity="info",
                    context=resource_path
                ))

    return report


def format_report(report: PreloadReport) -> str:
    """Format preload report as text."""
    lines = []
    lines.append("=" * 60)
    lines.append("PRELOAD PATTERNS CHECKER - KEYBOARD DEFENSE")
    lines.append("=" * 60)
    lines.append("")

    # Summary
    lines.append("## SUMMARY")
    lines.append(f"  Files checked:        {report.files_checked}")
    lines.append(f"  Total preloads:       {report.total_preloads}")
    lines.append(f"    Class level:        {report.class_level_preloads}")
    lines.append(f"    In functions:       {report.function_preloads}")
    lines.append(f"  Total loads:          {report.total_loads}")
    lines.append(f"    Runtime loads:      {report.runtime_loads}")
    lines.append(f"  Issues found:         {len(report.issues)}")
    lines.append("")

    # Issues
    if report.issues:
        lines.append("## LOADING ISSUES")

        # Sort by severity
        sorted_issues = sorted(report.issues, key=lambda x: (0 if x.severity == "warning" else 1, x.file))

        for issue in sorted_issues[:30]:
            severity_marker = "[WARN]" if issue.severity == "warning" else "[INFO]"
            lines.append(f"  {severity_marker} {issue.file}:{issue.line}")
            lines.append(f"    {issue.message}")

        if len(report.issues) > 30:
            lines.append(f"  ... and {len(report.issues) - 30} more issues")
        lines.append("")

    # Most loaded resources
    if report.by_resource:
        lines.append("## MOST LOADED RESOURCES")
        sorted_resources = sorted(report.by_resource.items(), key=lambda x: -len(x[1]))[:15]
        for resource_path, load_list in sorted_resources:
            files = set(l.file for l in load_list)
            preload_count = sum(1 for l in load_list if l.load_type == "preload")
            load_count = len(load_list) - preload_count
            lines.append(f"  {resource_path}")
            lines.append(f"    {len(load_list)}x in {len(files)} files (preload: {preload_count}, load: {load_count})")
        lines.append("")

    # Files with most loads
    if report.by_file:
        lines.append("## FILES WITH MOST RESOURCE LOADS")
        sorted_files = sorted(report.by_file.items(), key=lambda x: -len(x[1]))[:10]
        for file_path, load_list in sorted_files:
            preload_count = sum(1 for l in load_list if l.load_type == "preload")
            load_count = len(load_list) - preload_count
            lines.append(f"  {file_path}: {len(load_list)} (preload: {preload_count}, load: {load_count})")
        lines.append("")

    # Health indicators
    lines.append("## HEALTH INDICATORS")

    warning_count = sum(1 for i in report.issues if i.severity == "warning")
    if warning_count == 0:
        lines.append("  [OK] No preload pattern warnings")
    else:
        lines.append(f"  [WARN] {warning_count} preload pattern warnings")

    if report.function_preloads > 0:
        lines.append(f"  [WARN] {report.function_preloads} preloads inside functions (still load at parse time)")

    preload_ratio = report.total_preloads / (report.total_preloads + report.total_loads) * 100 if (report.total_preloads + report.total_loads) > 0 else 0
    lines.append(f"  [INFO] Preload ratio: {preload_ratio:.0f}%")

    lines.append("")
    return "\n".join(lines)


def format_json(report: PreloadReport) -> str:
    """Format report as JSON."""
    data = {
        "summary": {
            "files_checked": report.files_checked,
            "total_preloads": report.total_preloads,
            "class_level_preloads": report.class_level_preloads,
            "function_preloads": report.function_preloads,
            "total_loads": report.total_loads,
            "runtime_loads": report.runtime_loads,
            "issues": len(report.issues)
        },
        "issues": [
            {
                "file": i.file,
                "line": i.line,
                "type": i.issue_type,
                "message": i.message,
                "severity": i.severity
            }
            for i in report.issues[:50]
        ],
        "most_loaded_resources": [
            {
                "path": path,
                "count": len(loads),
                "files": len(set(l.file for l in loads))
            }
            for path, loads in sorted(report.by_resource.items(), key=lambda x: -len(x[1]))[:20]
        ],
        "files_with_most_loads": [
            {"file": f, "count": len(loads)}
            for f, loads in sorted(report.by_file.items(), key=lambda x: -len(x[1]))[:20]
        ]
    }
    return json.dumps(data, indent=2)


def main():
    import argparse

    parser = argparse.ArgumentParser(description="Check preload patterns")
    parser.add_argument("--json", "-j", action="store_true", help="JSON output")
    parser.add_argument("--file", "-f", type=str, help="Single file to check")
    parser.add_argument("--strict", "-s", action="store_true", help="Include info-level issues")
    args = parser.parse_args()

    report = check_preload_patterns(args.file, args.strict)

    if args.json:
        print(format_json(report))
    else:
        print(format_report(report))


if __name__ == "__main__":
    main()
