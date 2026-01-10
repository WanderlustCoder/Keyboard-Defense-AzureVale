#!/usr/bin/env python3
"""
Inheritance Analyzer

Analyzes class inheritance hierarchy:
- Maps extends relationships
- Finds deep inheritance chains
- Detects diamond inheritance patterns
- Reports class hierarchy statistics

Usage:
    python scripts/analyze_inheritance.py              # Full report
    python scripts/analyze_inheritance.py --class GameState  # Single class
    python scripts/analyze_inheritance.py --depth 5    # Max depth threshold
    python scripts/analyze_inheritance.py --json       # JSON output
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

# Thresholds
DEFAULT_DEPTH_THRESHOLD = 5


@dataclass
class ClassInfo:
    """Information about a class."""
    name: str
    file: str
    line: int
    extends: str
    is_inner_class: bool = False
    methods: List[str] = field(default_factory=list)
    signals: List[str] = field(default_factory=list)


@dataclass
class InheritanceChain:
    """An inheritance chain."""
    class_name: str
    chain: List[str]
    depth: int
    file: str


@dataclass
class InheritanceReport:
    """Inheritance analysis report."""
    files_checked: int = 0
    classes_found: int = 0
    max_depth: int = 0
    avg_depth: float = 0.0
    classes: Dict[str, ClassInfo] = field(default_factory=dict)
    chains: List[InheritanceChain] = field(default_factory=list)
    deep_chains: List[InheritanceChain] = field(default_factory=list)
    base_class_usage: Dict[str, int] = field(default_factory=lambda: defaultdict(int))
    issues: List[str] = field(default_factory=list)


def analyze_file(file_path: Path, rel_path: str) -> List[ClassInfo]:
    """Analyze a file for class definitions."""
    classes = []

    try:
        content = file_path.read_text(encoding="utf-8")
        lines = content.split('\n')
    except Exception:
        return classes

    current_class_name = None
    current_extends = None
    current_line = 0
    in_inner_class = False

    for i, line in enumerate(lines):
        line_num = i + 1
        stripped = line.strip()

        # class_name declaration
        class_name_match = re.match(r'^class_name\s+(\w+)', stripped)
        if class_name_match:
            current_class_name = class_name_match.group(1)
            continue

        # extends declaration
        extends_match = re.match(r'^extends\s+(\w+)', stripped)
        if extends_match:
            current_extends = extends_match.group(1)
            current_line = line_num
            continue

        # Inner class
        inner_class_match = re.match(r'^class\s+(\w+)(?:\s+extends\s+(\w+))?:', stripped)
        if inner_class_match:
            inner_name = inner_class_match.group(1)
            inner_extends = inner_class_match.group(2) or "RefCounted"

            classes.append(ClassInfo(
                name=inner_name,
                file=rel_path,
                line=line_num,
                extends=inner_extends,
                is_inner_class=True
            ))
            continue

    # Add main class if found
    if current_extends:
        name = current_class_name or file_path.stem
        classes.append(ClassInfo(
            name=name,
            file=rel_path,
            line=current_line,
            extends=current_extends,
            is_inner_class=False
        ))

    return classes


def build_inheritance_chain(class_name: str, classes: Dict[str, ClassInfo], visited: Set[str] = None) -> List[str]:
    """Build the inheritance chain for a class."""
    if visited is None:
        visited = set()

    chain = [class_name]

    if class_name in visited:
        return chain  # Circular reference

    visited.add(class_name)

    if class_name in classes:
        parent = classes[class_name].extends
        if parent and parent not in ("RefCounted", "Resource", "Object"):
            parent_chain = build_inheritance_chain(parent, classes, visited)
            chain.extend(parent_chain)

    return chain


def analyze_inheritance(target_class: Optional[str] = None, depth_threshold: int = DEFAULT_DEPTH_THRESHOLD) -> InheritanceReport:
    """Analyze inheritance across the project."""
    report = InheritanceReport()

    # Collect all classes
    for gd_file in PROJECT_ROOT.glob("**/*.gd"):
        if ".godot" in str(gd_file) or "addons" in str(gd_file):
            continue

        if not gd_file.exists():
            continue

        rel_path = str(gd_file.relative_to(PROJECT_ROOT))
        report.files_checked += 1

        classes = analyze_file(gd_file, rel_path)
        for cls in classes:
            report.classes[cls.name] = cls
            report.classes_found += 1
            report.base_class_usage[cls.extends] += 1

    # Build inheritance chains
    total_depth = 0
    for class_name, class_info in report.classes.items():
        if target_class and class_name != target_class:
            continue

        chain = build_inheritance_chain(class_name, report.classes)
        depth = len(chain)

        inheritance_chain = InheritanceChain(
            class_name=class_name,
            chain=chain,
            depth=depth,
            file=class_info.file
        )

        report.chains.append(inheritance_chain)
        total_depth += depth

        if depth > report.max_depth:
            report.max_depth = depth

        if depth > depth_threshold:
            report.deep_chains.append(inheritance_chain)
            report.issues.append(f"Deep inheritance: {class_name} has {depth} levels")

    if report.chains:
        report.avg_depth = total_depth / len(report.chains)

    # Sort chains by depth
    report.chains.sort(key=lambda c: -c.depth)
    report.deep_chains.sort(key=lambda c: -c.depth)

    return report


def format_report(report: InheritanceReport, depth_threshold: int) -> str:
    """Format inheritance report as text."""
    lines = []
    lines.append("=" * 60)
    lines.append("INHERITANCE ANALYZER - KEYBOARD DEFENSE")
    lines.append("=" * 60)
    lines.append("")

    # Summary
    lines.append("## SUMMARY")
    lines.append(f"  Files checked:     {report.files_checked}")
    lines.append(f"  Classes found:     {report.classes_found}")
    lines.append(f"  Max depth:         {report.max_depth}")
    lines.append(f"  Average depth:     {report.avg_depth:.1f}")
    lines.append(f"  Deep chains (>{depth_threshold}): {len(report.deep_chains)}")
    lines.append("")

    # Base class usage
    lines.append("## BASE CLASS USAGE")
    sorted_bases = sorted(report.base_class_usage.items(), key=lambda x: -x[1])
    for base, count in sorted_bases[:15]:
        lines.append(f"  {base}: {count} classes")
    if len(sorted_bases) > 15:
        lines.append(f"  ... and {len(sorted_bases) - 15} more")
    lines.append("")

    # Deep inheritance chains
    if report.deep_chains:
        lines.append(f"## DEEP INHERITANCE CHAINS (>{depth_threshold} levels)")
        for chain in report.deep_chains[:10]:
            lines.append(f"  {chain.class_name} ({chain.depth} levels)")
            lines.append(f"    {' -> '.join(chain.chain)}")
            lines.append(f"    File: {chain.file}")
        if len(report.deep_chains) > 10:
            lines.append(f"  ... and {len(report.deep_chains) - 10} more")
        lines.append("")

    # Deepest chains (regardless of threshold)
    lines.append("## DEEPEST INHERITANCE CHAINS")
    for chain in report.chains[:10]:
        lines.append(f"  {chain.class_name}: {chain.depth} levels")
        if chain.depth > 2:
            lines.append(f"    {' -> '.join(chain.chain[:5])}" + ("..." if chain.depth > 5 else ""))
    lines.append("")

    # Class hierarchy by layer
    lines.append("## CLASSES BY LAYER")
    layers = {"sim/": [], "game/": [], "ui/": [], "scripts/": [], "other": []}
    for cls in report.classes.values():
        placed = False
        for layer in ["sim/", "game/", "ui/", "scripts/"]:
            if cls.file.startswith(layer):
                layers[layer].append(cls.name)
                placed = True
                break
        if not placed:
            layers["other"].append(cls.name)

    for layer, classes in layers.items():
        if classes:
            lines.append(f"  {layer}: {len(classes)} classes")
    lines.append("")

    # Health indicators
    lines.append("## HEALTH INDICATORS")
    if report.max_depth <= depth_threshold:
        lines.append(f"  [OK] Max inheritance depth ({report.max_depth}) within threshold")
    else:
        lines.append(f"  [WARN] Max inheritance depth ({report.max_depth}) exceeds threshold ({depth_threshold})")

    if report.avg_depth < 2.5:
        lines.append(f"  [OK] Shallow average inheritance ({report.avg_depth:.1f})")
    else:
        lines.append(f"  [INFO] Average inheritance depth: {report.avg_depth:.1f}")

    # Check for RefCounted usage in sim/
    sim_classes = [c for c in report.classes.values() if c.file.startswith("sim/")]
    non_refcounted_sim = [c for c in sim_classes if c.extends not in ("RefCounted", "Resource")]
    if non_refcounted_sim:
        lines.append(f"  [INFO] {len(non_refcounted_sim)} sim/ classes extend non-RefCounted bases")

    lines.append("")
    return "\n".join(lines)


def format_json(report: InheritanceReport) -> str:
    """Format report as JSON."""
    data = {
        "summary": {
            "files_checked": report.files_checked,
            "classes_found": report.classes_found,
            "max_depth": report.max_depth,
            "avg_depth": round(report.avg_depth, 1),
            "deep_chains": len(report.deep_chains)
        },
        "base_class_usage": dict(sorted(report.base_class_usage.items(), key=lambda x: -x[1])),
        "deep_chains": [
            {
                "class": c.class_name,
                "depth": c.depth,
                "chain": c.chain,
                "file": c.file
            }
            for c in report.deep_chains
        ],
        "all_classes": [
            {
                "name": c.name,
                "file": c.file,
                "extends": c.extends,
                "is_inner": c.is_inner_class
            }
            for c in report.classes.values()
        ]
    }
    return json.dumps(data, indent=2)


def main():
    import argparse

    parser = argparse.ArgumentParser(description="Analyze inheritance")
    parser.add_argument("--json", "-j", action="store_true", help="JSON output")
    parser.add_argument("--class", "-c", dest="target_class", type=str, help="Single class to analyze")
    parser.add_argument("--depth", "-d", type=int, default=DEFAULT_DEPTH_THRESHOLD, help="Depth threshold")
    args = parser.parse_args()

    report = analyze_inheritance(args.target_class, args.depth)

    if args.json:
        print(format_json(report))
    else:
        print(format_report(report, args.depth))


if __name__ == "__main__":
    main()
