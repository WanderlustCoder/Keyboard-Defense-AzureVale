#!/usr/bin/env python3
"""
Autoload Analyzer

Analyzes autoload (singleton) configuration and usage:
- Lists all autoloads from project.godot
- Finds autoload dependencies
- Detects circular dependencies
- Reports autoload usage across codebase

Usage:
    python scripts/analyze_autoloads.py              # Full report
    python scripts/analyze_autoloads.py --deps       # Show dependency graph
    python scripts/analyze_autoloads.py --usage      # Show usage stats
    python scripts/analyze_autoloads.py --json       # JSON output
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


@dataclass
class Autoload:
    """An autoload singleton."""
    name: str
    path: str
    enabled: bool = True
    script_exists: bool = False
    dependencies: List[str] = field(default_factory=list)
    used_by: List[str] = field(default_factory=list)
    usage_count: int = 0


@dataclass
class AutoloadReport:
    """Autoload analysis report."""
    autoloads: Dict[str, Autoload] = field(default_factory=dict)
    dependency_order: List[str] = field(default_factory=list)
    circular_deps: List[Tuple[str, str]] = field(default_factory=list)
    issues: List[str] = field(default_factory=list)
    usage_stats: Dict[str, int] = field(default_factory=dict)


def parse_project_godot() -> Dict[str, Autoload]:
    """Parse autoloads from project.godot."""
    autoloads = {}
    project_file = PROJECT_ROOT / "project.godot"

    if not project_file.exists():
        return autoloads

    try:
        content = project_file.read_text(encoding="utf-8")
    except Exception:
        return autoloads

    # Find [autoload] section
    in_autoload = False
    for line in content.split('\n'):
        line = line.strip()

        if line == "[autoload]":
            in_autoload = True
            continue
        elif line.startswith("[") and in_autoload:
            break

        if in_autoload and "=" in line:
            # Format: Name="*res://path/to/script.gd"
            match = re.match(r'(\w+)\s*=\s*"\*?(res://[^"]+)"', line)
            if match:
                name = match.group(1)
                path = match.group(2)

                # Check if script exists
                real_path = PROJECT_ROOT / path.replace("res://", "")
                script_exists = real_path.exists()

                autoloads[name] = Autoload(
                    name=name,
                    path=path,
                    script_exists=script_exists
                )

    return autoloads


def find_autoload_dependencies(autoload: Autoload, all_autoloads: Dict[str, Autoload]) -> List[str]:
    """Find which other autoloads this autoload depends on."""
    dependencies = []

    real_path = PROJECT_ROOT / autoload.path.replace("res://", "")
    if not real_path.exists():
        return dependencies

    try:
        content = real_path.read_text(encoding="utf-8")
    except Exception:
        return dependencies

    autoload_names = set(all_autoloads.keys())

    for line in content.split('\n'):
        # Skip comments
        if line.strip().startswith('#'):
            continue

        # Check for direct autoload references
        for name in autoload_names:
            if name == autoload.name:
                continue

            # Look for patterns like: AutoloadName.method() or AutoloadName.property
            if re.search(rf'\b{name}\b\.', line):
                if name not in dependencies:
                    dependencies.append(name)

    return dependencies


def find_autoload_usage(autoload_name: str) -> List[Tuple[str, int]]:
    """Find where an autoload is used in the codebase."""
    usage = []

    for gd_file in PROJECT_ROOT.glob("**/*.gd"):
        if ".godot" in str(gd_file) or "addons" in str(gd_file):
            continue

        rel_path = str(gd_file.relative_to(PROJECT_ROOT))

        try:
            content = gd_file.read_text(encoding="utf-8")
        except Exception:
            continue

        count = 0
        for line in content.split('\n'):
            if line.strip().startswith('#'):
                continue
            # Count references to autoload
            count += len(re.findall(rf'\b{autoload_name}\b\.', line))

        if count > 0:
            usage.append((rel_path, count))

    return usage


def detect_circular_dependencies(autoloads: Dict[str, Autoload]) -> List[Tuple[str, str]]:
    """Detect circular dependencies between autoloads."""
    circular = []

    for name, autoload in autoloads.items():
        for dep in autoload.dependencies:
            if dep in autoloads:
                dep_autoload = autoloads[dep]
                if name in dep_autoload.dependencies:
                    # Circular dependency found
                    pair = tuple(sorted([name, dep]))
                    if pair not in circular:
                        circular.append(pair)

    return circular


def topological_sort(autoloads: Dict[str, Autoload]) -> List[str]:
    """Sort autoloads by dependency order."""
    # Build adjacency list
    graph = {name: set(al.dependencies) for name, al in autoloads.items()}

    # Kahn's algorithm
    in_degree = {name: 0 for name in autoloads}
    for name, deps in graph.items():
        for dep in deps:
            if dep in in_degree:
                in_degree[dep] += 1

    # Start with nodes that have no dependencies
    queue = [name for name, degree in in_degree.items() if degree == 0]
    result = []

    while queue:
        node = queue.pop(0)
        result.append(node)

        for name, deps in graph.items():
            if node in deps:
                in_degree[name] -= 1
                if in_degree[name] == 0 and name not in result:
                    queue.append(name)

    # Add any remaining (circular deps)
    for name in autoloads:
        if name not in result:
            result.append(name)

    return result


def analyze_autoloads(show_deps: bool = False, show_usage: bool = False) -> AutoloadReport:
    """Analyze all autoloads."""
    report = AutoloadReport()

    # Parse autoloads
    report.autoloads = parse_project_godot()

    if not report.autoloads:
        report.issues.append("No autoloads found in project.godot")
        return report

    # Find dependencies
    for name, autoload in report.autoloads.items():
        autoload.dependencies = find_autoload_dependencies(autoload, report.autoloads)

    # Detect circular dependencies
    report.circular_deps = detect_circular_dependencies(report.autoloads)
    for a, b in report.circular_deps:
        report.issues.append(f"Circular dependency: {a} <-> {b}")

    # Sort by dependency order
    report.dependency_order = topological_sort(report.autoloads)

    # Find usage
    for name, autoload in report.autoloads.items():
        usage = find_autoload_usage(name)
        autoload.used_by = [u[0] for u in usage]
        autoload.usage_count = sum(u[1] for u in usage)
        report.usage_stats[name] = autoload.usage_count

    # Check for issues
    for name, autoload in report.autoloads.items():
        if not autoload.script_exists:
            report.issues.append(f"Autoload script not found: {name} -> {autoload.path}")

        if autoload.usage_count == 0:
            report.issues.append(f"Unused autoload: {name}")

    return report


def format_report(report: AutoloadReport, show_deps: bool = False, show_usage: bool = False) -> str:
    """Format autoload report as text."""
    lines = []
    lines.append("=" * 60)
    lines.append("AUTOLOAD ANALYZER - KEYBOARD DEFENSE")
    lines.append("=" * 60)
    lines.append("")

    # Summary
    lines.append("## SUMMARY")
    lines.append(f"  Total autoloads:     {len(report.autoloads)}")
    lines.append(f"  Circular deps:       {len(report.circular_deps)}")
    lines.append(f"  Issues:              {len(report.issues)}")
    lines.append("")

    if not report.autoloads:
        lines.append("No autoloads configured.")
        return "\n".join(lines)

    # Autoload list
    lines.append("## AUTOLOADS")
    for name in report.dependency_order:
        autoload = report.autoloads[name]
        status = "✓" if autoload.script_exists else "✗"
        deps = f" -> {', '.join(autoload.dependencies)}" if autoload.dependencies else ""
        lines.append(f"  [{status}] {name}")
        lines.append(f"      {autoload.path}")
        if deps:
            lines.append(f"      Depends on:{deps}")
        lines.append(f"      Used {autoload.usage_count} times in {len(autoload.used_by)} files")
    lines.append("")

    # Dependency order
    lines.append("## LOAD ORDER (by dependencies)")
    for i, name in enumerate(report.dependency_order, 1):
        lines.append(f"  {i}. {name}")
    lines.append("")

    # Usage statistics
    if show_usage:
        lines.append("## USAGE STATISTICS")
        sorted_usage = sorted(report.usage_stats.items(), key=lambda x: -x[1])
        for name, count in sorted_usage:
            bar_width = min(count // 5, 30)
            bar = "=" * bar_width
            lines.append(f"  {name:20} [{bar}] {count}")
        lines.append("")

    # Dependency graph
    if show_deps:
        lines.append("## DEPENDENCY GRAPH")
        for name, autoload in report.autoloads.items():
            if autoload.dependencies:
                lines.append(f"  {name}")
                for dep in autoload.dependencies:
                    lines.append(f"    └─> {dep}")
        lines.append("")

    # Issues
    if report.issues:
        lines.append("## ISSUES")
        for issue in report.issues:
            lines.append(f"  [!] {issue}")
        lines.append("")

    # Health indicators
    lines.append("## HEALTH INDICATORS")
    if report.circular_deps:
        lines.append(f"  [WARN] {len(report.circular_deps)} circular dependencies")
    else:
        lines.append("  [OK] No circular dependencies")

    unused = sum(1 for al in report.autoloads.values() if al.usage_count == 0)
    if unused > 0:
        lines.append(f"  [INFO] {unused} potentially unused autoloads")

    missing = sum(1 for al in report.autoloads.values() if not al.script_exists)
    if missing > 0:
        lines.append(f"  [ERROR] {missing} autoload scripts not found")
    else:
        lines.append("  [OK] All autoload scripts exist")

    lines.append("")
    return "\n".join(lines)


def format_json(report: AutoloadReport) -> str:
    """Format report as JSON."""
    data = {
        "summary": {
            "total": len(report.autoloads),
            "circular_deps": len(report.circular_deps),
            "issues": len(report.issues)
        },
        "autoloads": {
            name: {
                "path": al.path,
                "exists": al.script_exists,
                "dependencies": al.dependencies,
                "usage_count": al.usage_count,
                "used_by_files": len(al.used_by)
            }
            for name, al in report.autoloads.items()
        },
        "load_order": report.dependency_order,
        "circular_dependencies": [list(pair) for pair in report.circular_deps],
        "usage_stats": report.usage_stats,
        "issues": report.issues
    }
    return json.dumps(data, indent=2)


def main():
    import argparse

    parser = argparse.ArgumentParser(description="Analyze autoloads")
    parser.add_argument("--json", "-j", action="store_true", help="JSON output")
    parser.add_argument("--deps", "-d", action="store_true", help="Show dependency graph")
    parser.add_argument("--usage", "-u", action="store_true", help="Show usage stats")
    args = parser.parse_args()

    report = analyze_autoloads(args.deps, args.usage)

    if args.json:
        print(format_json(report))
    else:
        print(format_report(report, args.deps, args.usage))


if __name__ == "__main__":
    main()
