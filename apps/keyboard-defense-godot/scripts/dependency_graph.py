#!/usr/bin/env python3
"""
Dependency Graph Generator

Analyzes GDScript files to build a dependency graph showing:
- What each file imports (preload/load)
- What extends each file uses
- Which files depend on which
- Circular dependency detection

Usage:
    python scripts/dependency_graph.py              # Text overview
    python scripts/dependency_graph.py --dot        # Graphviz DOT format
    python scripts/dependency_graph.py --json       # JSON output
    python scripts/dependency_graph.py --file sim/types.gd  # Single file deps
    python scripts/dependency_graph.py --reverse sim/types.gd  # What depends on file
"""

import json
import re
import sys
from collections import defaultdict
from dataclasses import dataclass, field
from pathlib import Path
from typing import Dict, List, Set, Optional, Tuple

# Project paths
SCRIPT_DIR = Path(__file__).parent
PROJECT_ROOT = SCRIPT_DIR.parent

# Patterns
PRELOAD_PATTERN = re.compile(r'(?:preload|load)\s*\(\s*["\']res://([^"\']+)["\']')
EXTENDS_PATTERN = re.compile(r'^extends\s+(\w+)', re.MULTILINE)
CLASS_NAME_PATTERN = re.compile(r'^class_name\s+(\w+)', re.MULTILINE)


@dataclass
class FileNode:
    """Represents a file in the dependency graph."""
    path: str
    class_name: Optional[str] = None
    extends: Optional[str] = None
    imports: List[str] = field(default_factory=list)
    imported_by: List[str] = field(default_factory=list)
    layer: str = ""  # sim, game, ui, etc.


def get_layer(filepath: str) -> str:
    """Determine which architectural layer a file belongs to."""
    if filepath.startswith("sim/"):
        return "sim"
    elif filepath.startswith("game/"):
        return "game"
    elif filepath.startswith("ui/"):
        return "ui"
    elif filepath.startswith("scripts/"):
        return "scripts"
    elif filepath.startswith("tests/"):
        return "tests"
    elif filepath.startswith("tools/"):
        return "tools"
    return "other"


def analyze_file(filepath: Path) -> FileNode:
    """Analyze a single GDScript file for dependencies."""
    rel_path = str(filepath.relative_to(PROJECT_ROOT))
    node = FileNode(path=rel_path, layer=get_layer(rel_path))

    try:
        content = filepath.read_text(encoding="utf-8")
    except Exception:
        return node

    # Find class_name
    class_match = CLASS_NAME_PATTERN.search(content)
    if class_match:
        node.class_name = class_match.group(1)

    # Find extends
    extends_match = EXTENDS_PATTERN.search(content)
    if extends_match:
        node.extends = extends_match.group(1)

    # Find imports (preload/load)
    for match in PRELOAD_PATTERN.finditer(content):
        imported_path = match.group(1)
        if imported_path.endswith(".gd"):
            node.imports.append(imported_path)

    return node


def build_graph() -> Dict[str, FileNode]:
    """Build the complete dependency graph."""
    graph: Dict[str, FileNode] = {}
    class_to_file: Dict[str, str] = {}

    # First pass: analyze all files
    for gd_file in PROJECT_ROOT.glob("**/*.gd"):
        if ".godot" in str(gd_file) or "addons" in str(gd_file):
            continue

        node = analyze_file(gd_file)
        graph[node.path] = node

        if node.class_name:
            class_to_file[node.class_name] = node.path

    # Second pass: resolve extends to file paths and build imported_by
    for path, node in graph.items():
        # Add imported_by references
        for imported in node.imports:
            if imported in graph:
                graph[imported].imported_by.append(path)

        # Resolve extends to file if it's a class_name reference
        if node.extends and node.extends in class_to_file:
            extends_file = class_to_file[node.extends]
            if extends_file not in node.imports:
                node.imports.append(extends_file)
            if path not in graph[extends_file].imported_by:
                graph[extends_file].imported_by.append(path)

    return graph


def find_circular_deps(graph: Dict[str, FileNode]) -> List[List[str]]:
    """Find circular dependencies in the graph."""
    cycles = []
    visited = set()
    rec_stack = set()

    def dfs(path: str, current_path: List[str]) -> None:
        visited.add(path)
        rec_stack.add(path)
        current_path.append(path)

        node = graph.get(path)
        if node:
            for imported in node.imports:
                if imported not in visited:
                    dfs(imported, current_path.copy())
                elif imported in rec_stack:
                    # Found cycle
                    cycle_start = current_path.index(imported)
                    cycle = current_path[cycle_start:] + [imported]
                    if cycle not in cycles:
                        cycles.append(cycle)

        rec_stack.remove(path)

    for path in graph:
        if path not in visited:
            dfs(path, [])

    return cycles


def get_dependencies(graph: Dict[str, FileNode], filepath: str, depth: int = -1) -> Set[str]:
    """Get all dependencies of a file (transitive)."""
    deps = set()
    to_process = [filepath]
    current_depth = 0

    while to_process and (depth == -1 or current_depth < depth):
        next_process = []
        for path in to_process:
            node = graph.get(path)
            if node:
                for imported in node.imports:
                    if imported not in deps:
                        deps.add(imported)
                        next_process.append(imported)
        to_process = next_process
        current_depth += 1

    return deps


def get_dependents(graph: Dict[str, FileNode], filepath: str, depth: int = -1) -> Set[str]:
    """Get all files that depend on this file (transitive)."""
    deps = set()
    to_process = [filepath]
    current_depth = 0

    while to_process and (depth == -1 or current_depth < depth):
        next_process = []
        for path in to_process:
            node = graph.get(path)
            if node:
                for dependent in node.imported_by:
                    if dependent not in deps:
                        deps.add(dependent)
                        next_process.append(dependent)
        to_process = next_process
        current_depth += 1

    return deps


def format_text(graph: Dict[str, FileNode], target_file: Optional[str] = None, reverse: bool = False) -> str:
    """Format graph as text report."""
    lines = []
    lines.append("=" * 60)
    lines.append("DEPENDENCY GRAPH - KEYBOARD DEFENSE")
    lines.append("=" * 60)
    lines.append("")

    if target_file:
        # Single file analysis
        node = graph.get(target_file)
        if not node:
            return f"File not found: {target_file}"

        lines.append(f"## FILE: {target_file}")
        if node.class_name:
            lines.append(f"   class_name: {node.class_name}")
        if node.extends:
            lines.append(f"   extends: {node.extends}")
        lines.append(f"   layer: {node.layer}")
        lines.append("")

        if reverse:
            lines.append("## DEPENDENTS (what imports this file):")
            dependents = get_dependents(graph, target_file)
            if dependents:
                for dep in sorted(dependents):
                    lines.append(f"   {dep}")
            else:
                lines.append("   (none)")
        else:
            lines.append("## DEPENDENCIES (what this file imports):")
            deps = get_dependencies(graph, target_file)
            if deps:
                for dep in sorted(deps):
                    lines.append(f"   {dep}")
            else:
                lines.append("   (none)")

            lines.append("")
            lines.append("## DIRECT IMPORTS:")
            if node.imports:
                for imp in sorted(node.imports):
                    lines.append(f"   {imp}")
            else:
                lines.append("   (none)")

        return "\n".join(lines)

    # Full graph analysis
    # Summary by layer
    by_layer = defaultdict(list)
    for path, node in graph.items():
        by_layer[node.layer].append(node)

    lines.append("## SUMMARY BY LAYER")
    for layer in ["sim", "game", "ui", "scripts", "tests", "tools", "other"]:
        if layer in by_layer:
            nodes = by_layer[layer]
            total_imports = sum(len(n.imports) for n in nodes)
            total_imported_by = sum(len(n.imported_by) for n in nodes)
            lines.append(f"  {layer:10} {len(nodes):4} files  {total_imports:4} imports  {total_imported_by:4} dependents")
    lines.append("")

    # Cross-layer dependencies (potential violations)
    lines.append("## CROSS-LAYER DEPENDENCIES")
    violations = []
    for path, node in graph.items():
        for imported in node.imports:
            imp_node = graph.get(imported)
            if imp_node:
                # sim should not import game/ui
                if node.layer == "sim" and imp_node.layer in ["game", "ui"]:
                    violations.append((path, imported, "sim → game/ui"))
                # game should not import ui (debatable)
                # elif node.layer == "game" and imp_node.layer == "ui":
                #     violations.append((path, imported, "game → ui"))

    if violations:
        for src, dst, violation_type in violations[:20]:
            lines.append(f"  [VIOLATION] {violation_type}")
            lines.append(f"    {src} → {dst}")
    else:
        lines.append("  No architecture violations detected.")
    lines.append("")

    # Circular dependencies
    cycles = find_circular_deps(graph)
    lines.append("## CIRCULAR DEPENDENCIES")
    if cycles:
        for cycle in cycles[:10]:
            lines.append(f"  Cycle: {' → '.join(cycle)}")
    else:
        lines.append("  No circular dependencies detected.")
    lines.append("")

    # Most imported files (core dependencies)
    lines.append("## MOST IMPORTED FILES (core dependencies)")
    by_imports = sorted(graph.values(), key=lambda n: len(n.imported_by), reverse=True)
    for node in by_imports[:15]:
        if node.imported_by:
            lines.append(f"  {len(node.imported_by):4} dependents  {node.path}")
    lines.append("")

    # Files with most imports (highest coupling)
    lines.append("## FILES WITH MOST IMPORTS (highest coupling)")
    by_coupling = sorted(graph.values(), key=lambda n: len(n.imports), reverse=True)
    for node in by_coupling[:15]:
        if node.imports:
            lines.append(f"  {len(node.imports):4} imports     {node.path}")
    lines.append("")

    # Isolated files (no imports, no dependents)
    isolated = [n for n in graph.values() if not n.imports and not n.imported_by]
    if isolated:
        lines.append("## ISOLATED FILES (no imports, no dependents)")
        for node in isolated[:20]:
            lines.append(f"  {node.path}")
        if len(isolated) > 20:
            lines.append(f"  ... and {len(isolated) - 20} more")
        lines.append("")

    return "\n".join(lines)


def format_dot(graph: Dict[str, FileNode]) -> str:
    """Format graph as Graphviz DOT."""
    lines = []
    lines.append("digraph Dependencies {")
    lines.append("  rankdir=LR;")
    lines.append("  node [shape=box];")
    lines.append("")

    # Color by layer
    layer_colors = {
        "sim": "#90EE90",      # light green
        "game": "#87CEEB",     # sky blue
        "ui": "#DDA0DD",       # plum
        "scripts": "#F0E68C",  # khaki
        "tests": "#D3D3D3",    # light gray
        "tools": "#FFB6C1",    # light pink
        "other": "#FFFFFF",    # white
    }

    # Define nodes with colors
    for path, node in graph.items():
        safe_name = path.replace("/", "_").replace(".", "_")
        color = layer_colors.get(node.layer, "#FFFFFF")
        label = path.split("/")[-1]  # Just filename
        lines.append(f'  {safe_name} [label="{label}" fillcolor="{color}" style=filled];')

    lines.append("")

    # Define edges
    for path, node in graph.items():
        safe_src = path.replace("/", "_").replace(".", "_")
        for imported in node.imports:
            safe_dst = imported.replace("/", "_").replace(".", "_")
            lines.append(f"  {safe_src} -> {safe_dst};")

    lines.append("}")
    return "\n".join(lines)


def format_json(graph: Dict[str, FileNode], target_file: Optional[str] = None, reverse: bool = False) -> str:
    """Format graph as JSON."""
    if target_file:
        node = graph.get(target_file)
        if not node:
            return json.dumps({"error": f"File not found: {target_file}"})

        if reverse:
            deps = list(get_dependents(graph, target_file))
        else:
            deps = list(get_dependencies(graph, target_file))

        data = {
            "file": target_file,
            "class_name": node.class_name,
            "extends": node.extends,
            "layer": node.layer,
            "direct_imports": node.imports,
            "direct_imported_by": node.imported_by,
            "transitive_dependencies" if not reverse else "transitive_dependents": deps,
        }
        return json.dumps(data, indent=2)

    # Full graph
    cycles = find_circular_deps(graph)
    data = {
        "summary": {
            "total_files": len(graph),
            "total_edges": sum(len(n.imports) for n in graph.values()),
            "circular_dependencies": len(cycles),
        },
        "by_layer": {},
        "nodes": {},
        "cycles": cycles,
    }

    # By layer stats
    by_layer = defaultdict(list)
    for path, node in graph.items():
        by_layer[node.layer].append(node)

    for layer, nodes in by_layer.items():
        data["by_layer"][layer] = {
            "files": len(nodes),
            "imports": sum(len(n.imports) for n in nodes),
            "dependents": sum(len(n.imported_by) for n in nodes),
        }

    # Node data
    for path, node in graph.items():
        data["nodes"][path] = {
            "class_name": node.class_name,
            "extends": node.extends,
            "layer": node.layer,
            "imports": node.imports,
            "imported_by": node.imported_by,
        }

    return json.dumps(data, indent=2)


def main():
    import argparse

    parser = argparse.ArgumentParser(description="Generate dependency graph")
    parser.add_argument("--dot", action="store_true", help="Graphviz DOT output")
    parser.add_argument("--json", "-j", action="store_true", help="JSON output")
    parser.add_argument("--file", "-f", type=str, help="Analyze single file")
    parser.add_argument("--reverse", "-r", action="store_true", help="Show dependents instead of dependencies")
    args = parser.parse_args()

    graph = build_graph()

    if args.dot:
        print(format_dot(graph))
    elif args.json:
        print(format_json(graph, args.file, args.reverse))
    else:
        print(format_text(graph, args.file, args.reverse))


if __name__ == "__main__":
    main()
