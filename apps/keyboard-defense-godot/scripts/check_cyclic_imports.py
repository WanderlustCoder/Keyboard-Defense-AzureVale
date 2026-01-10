#!/usr/bin/env python3
"""
Cyclic Imports Checker

Detects circular import dependencies:
- Direct cycles (A imports B, B imports A)
- Indirect cycles (A -> B -> C -> A)
- Reports cycle paths and affected files

Usage:
    python scripts/check_cyclic_imports.py              # Full report
    python scripts/check_cyclic_imports.py --file game/main.gd  # Check specific file
    python scripts/check_cyclic_imports.py --max-depth 5  # Limit cycle depth
    python scripts/check_cyclic_imports.py --json       # JSON output
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
class ImportInfo:
    """Information about an import."""
    file: str
    line: int
    imported_path: str
    import_type: str  # "preload", "load", "class_name"


@dataclass
class Cycle:
    """A detected import cycle."""
    path: List[str]  # List of files in the cycle
    length: int
    severity: str  # "error" for direct, "warning" for indirect


@dataclass
class CyclicReport:
    """Cyclic imports report."""
    files_checked: int = 0
    total_imports: int = 0
    cycles_found: int = 0
    direct_cycles: int = 0
    indirect_cycles: int = 0
    imports: Dict[str, List[ImportInfo]] = field(default_factory=lambda: defaultdict(list))
    cycles: List[Cycle] = field(default_factory=list)
    files_in_cycles: Set[str] = field(default_factory=set)


def normalize_path(path: str) -> str:
    """Normalize a resource path to relative path."""
    if path.startswith("res://"):
        path = path[6:]
    return path


def extract_imports(file_path: Path, rel_path: str) -> List[ImportInfo]:
    """Extract all imports from a file."""
    imports = []

    try:
        content = file_path.read_text(encoding='utf-8')
        lines = content.split('\n')
    except Exception:
        return imports

    for i, line in enumerate(lines):
        stripped = line.strip()

        # Skip comments
        if stripped.startswith('#'):
            continue

        # preload("res://path/file.gd")
        preload_match = re.search(r'preload\s*\(\s*["\']([^"\']+)["\']\s*\)', line)
        if preload_match:
            imported = normalize_path(preload_match.group(1))
            if imported.endswith('.gd'):
                imports.append(ImportInfo(
                    file=rel_path,
                    line=i + 1,
                    imported_path=imported,
                    import_type="preload"
                ))

        # load("res://path/file.gd")
        load_match = re.search(r'(?<!pre)load\s*\(\s*["\']([^"\']+)["\']\s*\)', line)
        if load_match:
            imported = normalize_path(load_match.group(1))
            if imported.endswith('.gd'):
                imports.append(ImportInfo(
                    file=rel_path,
                    line=i + 1,
                    imported_path=imported,
                    import_type="load"
                ))

    return imports


def find_cycles(imports: Dict[str, List[ImportInfo]], max_depth: int = 10) -> List[Cycle]:
    """Find all import cycles using DFS."""
    cycles = []
    visited_global: Set[Tuple[str, ...]] = set()  # Track unique cycles

    # Build adjacency list
    graph: Dict[str, Set[str]] = defaultdict(set)
    for file, import_list in imports.items():
        for imp in import_list:
            graph[file].add(imp.imported_path)

    def dfs(start: str, current: str, path: List[str], visited: Set[str]):
        if len(path) > max_depth:
            return

        if current in visited:
            # Found a cycle
            if current == start and len(path) > 1:
                # Normalize cycle to avoid duplicates
                cycle_tuple = tuple(sorted(path))
                if cycle_tuple not in visited_global:
                    visited_global.add(cycle_tuple)
                    cycles.append(Cycle(
                        path=path.copy(),
                        length=len(path),
                        severity="error" if len(path) == 2 else "warning"
                    ))
            return

        visited.add(current)
        path.append(current)

        for neighbor in graph.get(current, []):
            dfs(start, neighbor, path, visited)

        path.pop()
        visited.remove(current)

    # Start DFS from each node
    for start_file in graph:
        dfs(start_file, start_file, [], set())

    return cycles


def check_cyclic_imports(target_file: Optional[str] = None, max_depth: int = 10) -> CyclicReport:
    """Check for cyclic imports across the project."""
    report = CyclicReport()

    gd_files = list(PROJECT_ROOT.glob("**/*.gd"))

    # First pass: collect all imports
    for gd_file in gd_files:
        if ".godot" in str(gd_file) or "addons" in str(gd_file):
            continue

        if not gd_file.exists():
            continue

        rel_path = str(gd_file.relative_to(PROJECT_ROOT))
        report.files_checked += 1

        imports = extract_imports(gd_file, rel_path)
        report.imports[rel_path] = imports
        report.total_imports += len(imports)

    # Find cycles
    cycles = find_cycles(report.imports, max_depth)

    # Filter by target file if specified
    if target_file:
        cycles = [c for c in cycles if target_file in c.path]

    for cycle in cycles:
        report.cycles.append(cycle)
        report.cycles_found += 1

        if cycle.severity == "error":
            report.direct_cycles += 1
        else:
            report.indirect_cycles += 1

        for file in cycle.path:
            report.files_in_cycles.add(file)

    return report


def format_report(report: CyclicReport) -> str:
    """Format cyclic imports report as text."""
    lines = []
    lines.append("=" * 60)
    lines.append("CYCLIC IMPORTS CHECKER - KEYBOARD DEFENSE")
    lines.append("=" * 60)
    lines.append("")

    # Summary
    lines.append("## SUMMARY")
    lines.append(f"  Files checked:      {report.files_checked}")
    lines.append(f"  Total imports:      {report.total_imports}")
    lines.append(f"  Cycles found:       {report.cycles_found}")
    lines.append(f"    Direct (A<->B):   {report.direct_cycles}")
    lines.append(f"    Indirect:         {report.indirect_cycles}")
    lines.append(f"  Files in cycles:    {len(report.files_in_cycles)}")
    lines.append("")

    # Cycles
    if report.cycles:
        lines.append("## IMPORT CYCLES")

        # Sort by length (direct cycles first)
        sorted_cycles = sorted(report.cycles, key=lambda c: (c.length, c.path[0]))

        for cycle in sorted_cycles[:20]:
            severity_marker = "[ERROR]" if cycle.severity == "error" else "[WARN]"
            lines.append(f"  {severity_marker} Cycle of length {cycle.length}:")
            lines.append(f"    {' -> '.join(cycle.path)} -> {cycle.path[0]}")

        if len(report.cycles) > 20:
            lines.append(f"  ... and {len(report.cycles) - 20} more cycles")
        lines.append("")

    # Files in cycles
    if report.files_in_cycles:
        lines.append("## FILES INVOLVED IN CYCLES")
        for file in sorted(report.files_in_cycles)[:30]:
            cycle_count = sum(1 for c in report.cycles if file in c.path)
            lines.append(f"  {file}: in {cycle_count} cycle(s)")

        if len(report.files_in_cycles) > 30:
            lines.append(f"  ... and {len(report.files_in_cycles) - 30} more files")
        lines.append("")

    # Most imported files
    import_counts: Dict[str, int] = defaultdict(int)
    for import_list in report.imports.values():
        for imp in import_list:
            import_counts[imp.imported_path] += 1

    if import_counts:
        lines.append("## MOST IMPORTED FILES")
        sorted_imports = sorted(import_counts.items(), key=lambda x: -x[1])[:10]
        for path, count in sorted_imports:
            in_cycle = " [IN CYCLE]" if path in report.files_in_cycles else ""
            lines.append(f"  {path}: {count} imports{in_cycle}")
        lines.append("")

    # Health indicators
    lines.append("## HEALTH INDICATORS")
    if report.direct_cycles == 0:
        lines.append("  [OK] No direct circular imports")
    else:
        lines.append(f"  [ERROR] {report.direct_cycles} direct circular imports - must fix")

    if report.indirect_cycles == 0:
        lines.append("  [OK] No indirect circular imports")
    elif report.indirect_cycles < 5:
        lines.append(f"  [WARN] {report.indirect_cycles} indirect circular imports")
    else:
        lines.append(f"  [WARN] {report.indirect_cycles} indirect circular imports - consider refactoring")

    lines.append("")
    return "\n".join(lines)


def format_json(report: CyclicReport) -> str:
    """Format report as JSON."""
    data = {
        "summary": {
            "files_checked": report.files_checked,
            "total_imports": report.total_imports,
            "cycles_found": report.cycles_found,
            "direct_cycles": report.direct_cycles,
            "indirect_cycles": report.indirect_cycles,
            "files_in_cycles": len(report.files_in_cycles)
        },
        "cycles": [
            {
                "path": c.path,
                "length": c.length,
                "severity": c.severity
            }
            for c in report.cycles[:50]
        ],
        "files_in_cycles": sorted(report.files_in_cycles),
        "most_imported": [
            {"path": path, "count": count}
            for path, count in sorted(
                ((p, sum(1 for il in report.imports.values() for i in il if i.imported_path == p))
                 for p in set(i.imported_path for il in report.imports.values() for i in il)),
                key=lambda x: -x[1]
            )[:20]
        ]
    }
    return json.dumps(data, indent=2)


def main():
    import argparse

    parser = argparse.ArgumentParser(description="Check for cyclic imports")
    parser.add_argument("--json", "-j", action="store_true", help="JSON output")
    parser.add_argument("--file", "-f", type=str, help="Check cycles involving specific file")
    parser.add_argument("--max-depth", "-d", type=int, default=10, help="Max cycle depth to check")
    args = parser.parse_args()

    report = check_cyclic_imports(args.file, args.max_depth)

    if args.json:
        print(format_json(report))
    else:
        print(format_report(report))


if __name__ == "__main__":
    main()
