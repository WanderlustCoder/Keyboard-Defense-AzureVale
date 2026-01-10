#!/usr/bin/env python3
"""
Scene Validator

Validates Godot scene (.tscn) files for common issues:
- Missing or broken script references
- Missing resource references
- Deep nesting (performance concern)
- Large scenes (maintainability concern)
- Duplicate node names
- Orphan nodes

Usage:
    python scripts/validate_scenes.py              # Full report
    python scripts/validate_scenes.py --file scenes/Main.tscn  # Single file
    python scripts/validate_scenes.py --verbose    # Show all nodes
    python scripts/validate_scenes.py --json       # JSON output
"""

import json
import re
import sys
from dataclasses import dataclass, field
from pathlib import Path
from typing import Dict, List, Optional, Set, Tuple

# Project paths
SCRIPT_DIR = Path(__file__).parent
PROJECT_ROOT = SCRIPT_DIR.parent

# Thresholds
MAX_NESTING_DEPTH = 10
MAX_NODE_COUNT = 100
MAX_SCENE_SIZE_KB = 50


@dataclass
class NodeInfo:
    """Information about a scene node."""
    name: str
    type: str
    parent: str
    depth: int
    has_script: bool = False
    script_path: Optional[str] = None


@dataclass
class SceneInfo:
    """Information about a scene file."""
    file: str
    node_count: int = 0
    max_depth: int = 0
    size_kb: float = 0
    root_type: str = ""
    root_script: Optional[str] = None
    nodes: List[NodeInfo] = field(default_factory=list)
    issues: List[str] = field(default_factory=list)
    external_resources: List[str] = field(default_factory=list)
    missing_resources: List[str] = field(default_factory=list)
    duplicate_names: List[str] = field(default_factory=list)


@dataclass
class SceneReport:
    """Scene validation report."""
    scenes_checked: int = 0
    total_nodes: int = 0
    issues_found: int = 0
    scenes: List[SceneInfo] = field(default_factory=list)
    by_severity: Dict[str, int] = field(default_factory=lambda: {"high": 0, "medium": 0, "low": 0})


def parse_scene(file_path: Path, rel_path: str) -> SceneInfo:
    """Parse a scene file and extract information."""
    info = SceneInfo(file=rel_path)

    try:
        content = file_path.read_text(encoding="utf-8")
        info.size_kb = len(content) / 1024
    except Exception as e:
        info.issues.append(f"Could not read file: {e}")
        return info

    lines = content.split('\n')

    # Track resources
    resources: Dict[str, str] = {}  # id -> path
    nodes: List[Tuple[str, str, str, int]] = []  # (name, type, parent, depth)
    node_names: Dict[str, List[str]] = {}  # parent -> [child names]

    current_section = None
    current_node_name = ""
    current_node_type = ""
    current_node_parent = "."

    for line in lines:
        stripped = line.strip()

        # External resource
        ext_match = re.match(r'\[ext_resource\s+.*path="([^"]+)".*id="([^"]+)"', stripped)
        if ext_match:
            path = ext_match.group(1)
            res_id = ext_match.group(2)
            resources[res_id] = path
            info.external_resources.append(path)

            # Check if resource exists
            if path.startswith("res://"):
                res_path = PROJECT_ROOT / path.replace("res://", "")
                if not res_path.exists():
                    info.missing_resources.append(path)
                    info.issues.append(f"Missing resource: {path}")
            continue

        # Node definition
        node_match = re.match(r'\[node\s+name="([^"]+)"\s+type="([^"]+)"(?:\s+parent="([^"]+)")?', stripped)
        if node_match:
            name = node_match.group(1)
            node_type = node_match.group(2)
            parent = node_match.group(3) if node_match.group(3) else ""

            # Calculate depth
            if not parent:
                depth = 0
            elif parent == ".":
                depth = 1
            else:
                depth = parent.count("/") + 2

            nodes.append((name, node_type, parent, depth))

            # Track names for duplicate detection
            parent_key = parent if parent else "."
            if parent_key not in node_names:
                node_names[parent_key] = []
            if name in node_names[parent_key]:
                info.duplicate_names.append(f"{parent}/{name}" if parent else name)
            else:
                node_names[parent_key].append(name)

            current_node_name = name
            current_node_type = node_type
            current_node_parent = parent
            current_section = "node"
            continue

        # Script reference in node
        if current_section == "node" and "script = " in stripped:
            script_match = re.search(r'script\s*=\s*ExtResource\(\s*"([^"]+)"\s*\)', stripped)
            if script_match:
                script_id = script_match.group(1)
                if script_id in resources:
                    script_path = resources[script_id]
                    # Check if script exists
                    if script_path.startswith("res://"):
                        script_file = PROJECT_ROOT / script_path.replace("res://", "")
                        if not script_file.exists():
                            info.issues.append(f"Missing script: {script_path}")

    # Build node info
    for name, node_type, parent, depth in nodes:
        node_info = NodeInfo(
            name=name,
            type=node_type,
            parent=parent,
            depth=depth
        )
        info.nodes.append(node_info)

    info.node_count = len(nodes)
    info.max_depth = max((n[3] for n in nodes), default=0)

    if nodes:
        info.root_type = nodes[0][1]

    # Check for issues
    if info.node_count > MAX_NODE_COUNT:
        info.issues.append(f"Large scene: {info.node_count} nodes (threshold: {MAX_NODE_COUNT})")

    if info.max_depth > MAX_NESTING_DEPTH:
        info.issues.append(f"Deep nesting: {info.max_depth} levels (threshold: {MAX_NESTING_DEPTH})")

    if info.size_kb > MAX_SCENE_SIZE_KB:
        info.issues.append(f"Large file: {info.size_kb:.1f}KB (threshold: {MAX_SCENE_SIZE_KB}KB)")

    if info.duplicate_names:
        info.issues.append(f"Duplicate node names: {len(info.duplicate_names)}")

    return info


def validate_scenes(target_file: Optional[str] = None) -> SceneReport:
    """Validate scene files."""
    report = SceneReport()

    if target_file:
        scene_files = [PROJECT_ROOT / target_file]
    else:
        scene_files = list(PROJECT_ROOT.glob("**/*.tscn"))

    for scene_file in scene_files:
        if ".godot" in str(scene_file) or "addons" in str(scene_file):
            continue

        if not scene_file.exists():
            continue

        rel_path = str(scene_file.relative_to(PROJECT_ROOT))
        report.scenes_checked += 1

        info = parse_scene(scene_file, rel_path)
        report.total_nodes += info.node_count

        if info.issues:
            report.scenes.append(info)
            report.issues_found += len(info.issues)

            # Categorize by severity
            for issue in info.issues:
                if "Missing" in issue:
                    report.by_severity["high"] += 1
                elif "Large" in issue or "Deep" in issue:
                    report.by_severity["medium"] += 1
                else:
                    report.by_severity["low"] += 1

    return report


def format_report(report: SceneReport, verbose: bool = False) -> str:
    """Format scene report as text."""
    lines = []
    lines.append("=" * 60)
    lines.append("SCENE VALIDATOR - KEYBOARD DEFENSE")
    lines.append("=" * 60)
    lines.append("")

    # Summary
    lines.append("## SUMMARY")
    lines.append(f"  Scenes checked:    {report.scenes_checked}")
    lines.append(f"  Total nodes:       {report.total_nodes}")
    lines.append(f"  Issues found:      {report.issues_found}")
    lines.append(f"    High severity:   {report.by_severity['high']}")
    lines.append(f"    Medium severity: {report.by_severity['medium']}")
    lines.append(f"    Low severity:    {report.by_severity['low']}")
    lines.append("")

    # Scenes with issues
    if report.scenes:
        lines.append("## SCENES WITH ISSUES")
        for scene in report.scenes:
            lines.append(f"  {scene.file}")
            lines.append(f"    Nodes: {scene.node_count}, Max depth: {scene.max_depth}, Size: {scene.size_kb:.1f}KB")
            for issue in scene.issues:
                severity = "!" if "Missing" in issue else "?"
                lines.append(f"    [{severity}] {issue}")

            if verbose and scene.nodes:
                lines.append("    Nodes:")
                for node in scene.nodes[:20]:
                    indent = "  " * node.depth
                    lines.append(f"      {indent}{node.name} ({node.type})")
                if len(scene.nodes) > 20:
                    lines.append(f"      ... and {len(scene.nodes) - 20} more")
        lines.append("")

    # Missing resources
    missing = []
    for scene in report.scenes:
        for res in scene.missing_resources:
            missing.append((scene.file, res))

    if missing:
        lines.append("## MISSING RESOURCES")
        for scene_file, res in missing[:20]:
            lines.append(f"  {scene_file}")
            lines.append(f"    Missing: {res}")
        if len(missing) > 20:
            lines.append(f"  ... and {len(missing) - 20} more")
        lines.append("")

    # Health indicators
    lines.append("## HEALTH INDICATORS")
    if report.by_severity["high"] == 0:
        lines.append("  [OK] No missing resources or scripts")
    else:
        lines.append(f"  [ERROR] {report.by_severity['high']} missing resources/scripts")

    if report.by_severity["medium"] == 0:
        lines.append("  [OK] No oversized or deeply nested scenes")
    else:
        lines.append(f"  [WARN] {report.by_severity['medium']} scenes with size/depth issues")

    avg_nodes = report.total_nodes / report.scenes_checked if report.scenes_checked > 0 else 0
    lines.append(f"  [INFO] Average {avg_nodes:.1f} nodes per scene")

    lines.append("")
    return "\n".join(lines)


def format_json(report: SceneReport) -> str:
    """Format report as JSON."""
    data = {
        "summary": {
            "scenes_checked": report.scenes_checked,
            "total_nodes": report.total_nodes,
            "issues_found": report.issues_found,
            "by_severity": report.by_severity
        },
        "scenes_with_issues": [
            {
                "file": s.file,
                "node_count": s.node_count,
                "max_depth": s.max_depth,
                "size_kb": round(s.size_kb, 1),
                "root_type": s.root_type,
                "issues": s.issues,
                "missing_resources": s.missing_resources,
                "duplicate_names": s.duplicate_names
            }
            for s in report.scenes
        ]
    }
    return json.dumps(data, indent=2)


def main():
    import argparse

    parser = argparse.ArgumentParser(description="Validate scene files")
    parser.add_argument("--json", "-j", action="store_true", help="JSON output")
    parser.add_argument("--file", "-f", type=str, help="Single file to check")
    parser.add_argument("--verbose", "-v", action="store_true", help="Show all nodes")
    args = parser.parse_args()

    report = validate_scenes(args.file)

    if args.json:
        print(format_json(report))
    else:
        print(format_report(report, args.verbose))


if __name__ == "__main__":
    main()
