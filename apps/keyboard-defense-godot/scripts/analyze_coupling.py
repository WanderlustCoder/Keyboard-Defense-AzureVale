#!/usr/bin/env python3
"""
Coupling Analyzer

Measures coupling between files and classes:
- Afferent coupling (incoming dependencies)
- Efferent coupling (outgoing dependencies)
- Instability metric
- Cross-layer coupling violations

Usage:
    python scripts/analyze_coupling.py              # Full report
    python scripts/analyze_coupling.py --file game/main.gd  # Single file
    python scripts/analyze_coupling.py --layer sim  # Single layer
    python scripts/analyze_coupling.py --json       # JSON output
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

# Layer definitions (inner layers should not depend on outer)
LAYERS = {
    "sim": 0,      # Core logic (innermost)
    "game": 1,     # Game rendering
    "ui": 2,       # UI components
    "scripts": 2,  # Scene scripts (same level as UI)
    "tools": 3,    # Development tools
    "tests": 3,    # Tests
}


@dataclass
class FileCoupling:
    """Coupling metrics for a file."""
    file: str
    layer: str
    afferent: int = 0  # Files that depend on this
    efferent: int = 0  # Files this depends on
    instability: float = 0.0  # efferent / (afferent + efferent)
    depends_on: Set[str] = field(default_factory=set)
    depended_by: Set[str] = field(default_factory=set)
    violations: List[str] = field(default_factory=list)


@dataclass
class CouplingReport:
    """Coupling analysis report."""
    files_checked: int = 0
    total_dependencies: int = 0
    layer_violations: int = 0
    avg_afferent: float = 0.0
    avg_efferent: float = 0.0
    avg_instability: float = 0.0
    files: Dict[str, FileCoupling] = field(default_factory=dict)
    violations: List[Tuple[str, str, str]] = field(default_factory=list)  # (from, to, reason)
    most_coupled: List[FileCoupling] = field(default_factory=list)


def get_layer(file_path: str) -> str:
    """Get the layer for a file path."""
    for layer in LAYERS:
        if file_path.startswith(layer + "/"):
            return layer
    return "other"


def extract_dependencies(file_path: Path, rel_path: str) -> Set[str]:
    """Extract file dependencies from a GDScript file."""
    deps = set()

    try:
        content = file_path.read_text(encoding="utf-8")
    except Exception:
        return deps

    # preload() and load() calls
    preload_matches = re.findall(r'(?:preload|load)\s*\(\s*["\']res://([^"\']+)["\']', content)
    for match in preload_matches:
        if match.endswith(".gd"):
            deps.add(match)

    # class_name references (direct usage)
    # This is approximate - we track explicit class references
    class_refs = re.findall(r'\b([A-Z][a-zA-Z0-9]+)\s*\.', content)
    # We'll resolve these later if we have a class_name mapping

    # extends with path
    extends_match = re.search(r'extends\s+["\']res://([^"\']+\.gd)["\']', content)
    if extends_match:
        deps.add(extends_match.group(1))

    return deps


def build_class_map() -> Dict[str, str]:
    """Build a map of class_name to file path."""
    class_map = {}

    for gd_file in PROJECT_ROOT.glob("**/*.gd"):
        if ".godot" in str(gd_file) or "addons" in str(gd_file):
            continue

        try:
            content = gd_file.read_text(encoding="utf-8")
            match = re.search(r'^class_name\s+(\w+)', content, re.MULTILINE)
            if match:
                rel_path = str(gd_file.relative_to(PROJECT_ROOT))
                class_map[match.group(1)] = rel_path
        except Exception:
            continue

    return class_map


def analyze_coupling(target_file: Optional[str] = None, target_layer: Optional[str] = None) -> CouplingReport:
    """Analyze coupling across the project."""
    report = CouplingReport()

    # Build class_name map
    class_map = build_class_map()

    # First pass: collect all dependencies
    file_deps: Dict[str, Set[str]] = {}

    for gd_file in PROJECT_ROOT.glob("**/*.gd"):
        if ".godot" in str(gd_file) or "addons" in str(gd_file):
            continue

        if not gd_file.exists():
            continue

        rel_path = str(gd_file.relative_to(PROJECT_ROOT))
        layer = get_layer(rel_path)

        if target_layer and layer != target_layer:
            continue

        if target_file and rel_path != target_file:
            continue

        report.files_checked += 1

        deps = extract_dependencies(gd_file, rel_path)
        file_deps[rel_path] = deps

        # Initialize file coupling
        report.files[rel_path] = FileCoupling(
            file=rel_path,
            layer=layer,
            depends_on=deps
        )

    # Second pass: calculate afferent coupling (who depends on each file)
    for file_path, deps in file_deps.items():
        for dep in deps:
            if dep in report.files:
                report.files[dep].depended_by.add(file_path)

    # Calculate metrics
    total_afferent = 0
    total_efferent = 0
    total_instability = 0

    for file_path, coupling in report.files.items():
        coupling.afferent = len(coupling.depended_by)
        coupling.efferent = len(coupling.depends_on)

        total = coupling.afferent + coupling.efferent
        if total > 0:
            coupling.instability = coupling.efferent / total
        else:
            coupling.instability = 0.0

        total_afferent += coupling.afferent
        total_efferent += coupling.efferent
        total_instability += coupling.instability

        report.total_dependencies += coupling.efferent

        # Check for layer violations
        file_layer = get_layer(file_path)
        file_layer_num = LAYERS.get(file_layer, 99)

        for dep in coupling.depends_on:
            dep_layer = get_layer(dep)
            dep_layer_num = LAYERS.get(dep_layer, 99)

            # Inner layers should not depend on outer layers
            if file_layer_num < dep_layer_num:
                violation = f"{file_layer} -> {dep_layer}"
                coupling.violations.append(f"Depends on {dep} ({dep_layer})")
                report.violations.append((file_path, dep, violation))
                report.layer_violations += 1

    # Calculate averages
    if report.files:
        report.avg_afferent = total_afferent / len(report.files)
        report.avg_efferent = total_efferent / len(report.files)
        report.avg_instability = total_instability / len(report.files)

    # Find most coupled files
    report.most_coupled = sorted(
        report.files.values(),
        key=lambda f: f.afferent + f.efferent,
        reverse=True
    )[:20]

    return report


def format_report(report: CouplingReport) -> str:
    """Format coupling report as text."""
    lines = []
    lines.append("=" * 60)
    lines.append("COUPLING ANALYZER - KEYBOARD DEFENSE")
    lines.append("=" * 60)
    lines.append("")

    # Summary
    lines.append("## SUMMARY")
    lines.append(f"  Files checked:       {report.files_checked}")
    lines.append(f"  Total dependencies:  {report.total_dependencies}")
    lines.append(f"  Layer violations:    {report.layer_violations}")
    lines.append(f"  Avg afferent:        {report.avg_afferent:.1f}")
    lines.append(f"  Avg efferent:        {report.avg_efferent:.1f}")
    lines.append(f"  Avg instability:     {report.avg_instability:.2f}")
    lines.append("")

    # Most coupled files
    lines.append("## MOST COUPLED FILES")
    for coupling in report.most_coupled[:15]:
        total = coupling.afferent + coupling.efferent
        lines.append(f"  {coupling.file}")
        lines.append(f"    In: {coupling.afferent}, Out: {coupling.efferent}, Total: {total}, I: {coupling.instability:.2f}")
    lines.append("")

    # Layer violations
    if report.violations:
        lines.append("## LAYER VIOLATIONS")
        lines.append("  (Inner layers should not depend on outer layers)")
        for from_file, to_file, reason in report.violations[:20]:
            lines.append(f"  {from_file}")
            lines.append(f"    -> {to_file} ({reason})")
        if len(report.violations) > 20:
            lines.append(f"  ... and {len(report.violations) - 20} more")
        lines.append("")

    # Coupling by layer
    layer_stats: Dict[str, Dict[str, int]] = defaultdict(lambda: {"files": 0, "afferent": 0, "efferent": 0})
    for coupling in report.files.values():
        layer_stats[coupling.layer]["files"] += 1
        layer_stats[coupling.layer]["afferent"] += coupling.afferent
        layer_stats[coupling.layer]["efferent"] += coupling.efferent

    lines.append("## COUPLING BY LAYER")
    for layer in ["sim", "game", "ui", "scripts", "tools", "tests", "other"]:
        if layer in layer_stats:
            stats = layer_stats[layer]
            lines.append(f"  {layer}/")
            lines.append(f"    Files: {stats['files']}, In: {stats['afferent']}, Out: {stats['efferent']}")
    lines.append("")

    # Most stable files (low instability, high afferent)
    stable_files = sorted(
        [f for f in report.files.values() if f.afferent > 2],
        key=lambda f: f.instability
    )[:10]

    if stable_files:
        lines.append("## MOST STABLE FILES (Core dependencies)")
        for coupling in stable_files:
            lines.append(f"  {coupling.file}")
            lines.append(f"    Instability: {coupling.instability:.2f}, Depended by: {coupling.afferent} files")
        lines.append("")

    # Health indicators
    lines.append("## HEALTH INDICATORS")
    if report.layer_violations == 0:
        lines.append("  [OK] No layer violations")
    else:
        lines.append(f"  [ERROR] {report.layer_violations} layer violations (architecture issue)")

    if report.avg_instability < 0.5:
        lines.append(f"  [OK] Good average instability ({report.avg_instability:.2f})")
    else:
        lines.append(f"  [WARN] High average instability ({report.avg_instability:.2f})")

    if report.avg_efferent < 5:
        lines.append(f"  [OK] Low average efferent coupling ({report.avg_efferent:.1f})")
    else:
        lines.append(f"  [INFO] Average efferent coupling: {report.avg_efferent:.1f}")

    lines.append("")
    return "\n".join(lines)


def format_json(report: CouplingReport) -> str:
    """Format report as JSON."""
    data = {
        "summary": {
            "files_checked": report.files_checked,
            "total_dependencies": report.total_dependencies,
            "layer_violations": report.layer_violations,
            "avg_afferent": round(report.avg_afferent, 1),
            "avg_efferent": round(report.avg_efferent, 1),
            "avg_instability": round(report.avg_instability, 2)
        },
        "most_coupled": [
            {
                "file": f.file,
                "layer": f.layer,
                "afferent": f.afferent,
                "efferent": f.efferent,
                "instability": round(f.instability, 2)
            }
            for f in report.most_coupled
        ],
        "violations": [
            {"from": f, "to": t, "reason": r}
            for f, t, r in report.violations
        ]
    }
    return json.dumps(data, indent=2)


def main():
    import argparse

    parser = argparse.ArgumentParser(description="Analyze coupling")
    parser.add_argument("--json", "-j", action="store_true", help="JSON output")
    parser.add_argument("--file", "-f", type=str, help="Single file to analyze")
    parser.add_argument("--layer", "-l", type=str, help="Single layer to analyze")
    args = parser.parse_args()

    report = analyze_coupling(args.file, args.layer)

    if args.json:
        print(format_json(report))
    else:
        print(format_report(report))


if __name__ == "__main__":
    main()
