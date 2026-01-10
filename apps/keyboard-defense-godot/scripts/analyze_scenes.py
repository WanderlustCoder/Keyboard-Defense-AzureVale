#!/usr/bin/env python3
"""
Scene Analyzer

Analyzes Godot scene files (.tscn) for common issues:
- Missing script references
- Broken resource paths
- Orphan nodes (no script, no children)
- Deep nesting
- Large scenes (many nodes)
- Duplicate node names

Usage:
    python scripts/analyze_scenes.py              # Full report
    python scripts/analyze_scenes.py --file scenes/Main.tscn  # Single scene
    python scripts/analyze_scenes.py --json       # JSON output
    python scripts/analyze_scenes.py --verbose    # Show all nodes
"""

import json
import re
import sys
from dataclasses import dataclass, field
from pathlib import Path
from typing import Dict, List, Set, Optional, Tuple

# Project paths
SCRIPT_DIR = Path(__file__).parent
PROJECT_ROOT = SCRIPT_DIR.parent


@dataclass
class SceneIssue:
    """An issue found in a scene."""
    scene: str
    node: str
    issue_type: str
    severity: str  # "error", "warning", "info"
    message: str


@dataclass
class NodeInfo:
    """Information about a node in a scene."""
    name: str
    type: str
    parent: str
    script: Optional[str] = None
    has_children: bool = False
    depth: int = 0
    line: int = 0


@dataclass
class SceneReport:
    """Analysis report for a scene."""
    path: str
    node_count: int = 0
    max_depth: int = 0
    has_script: bool = False
    root_type: str = ""
    nodes: List[NodeInfo] = field(default_factory=list)
    issues: List[SceneIssue] = field(default_factory=list)
    external_resources: List[str] = field(default_factory=list)


def parse_tscn(filepath: Path) -> SceneReport:
    """Parse a .tscn file and extract node information."""
    rel_path = str(filepath.relative_to(PROJECT_ROOT))
    report = SceneReport(path=rel_path)

    try:
        content = filepath.read_text(encoding="utf-8")
        lines = content.split('\n')
    except Exception:
        return report

    # Track external resources
    ext_resources: Dict[str, str] = {}  # id -> path

    # Parse external resources
    for line in lines:
        # [ext_resource type="Script" path="res://..." id="1"]
        match = re.match(r'\[ext_resource.*path="([^"]+)".*id="([^"]+)"', line)
        if match:
            path = match.group(1)
            res_id = match.group(2)
            ext_resources[res_id] = path
            report.external_resources.append(path)

    # Parse nodes
    current_node = None
    node_parents: Dict[str, str] = {}  # node path -> parent path
    node_names: Dict[str, int] = {}  # name -> count (for duplicate detection)
    node_depths: Dict[str, int] = {}  # node path -> depth

    for i, line in enumerate(lines):
        # [node name="NodeName" type="NodeType" parent="ParentPath"]
        match = re.match(r'\[node name="([^"]+)"(?:\s+type="([^"]+)")?(?:\s+parent="([^"]*)")?', line)
        if match:
            name = match.group(1)
            node_type = match.group(2) or "Node"
            parent = match.group(3) or ""

            # Calculate full path
            if parent == "":
                full_path = name
                depth = 0
            elif parent == ".":
                full_path = name
                depth = 1
            else:
                full_path = f"{parent}/{name}"
                depth = parent.count('/') + 2

            # Track for duplicate detection
            node_names[name] = node_names.get(name, 0) + 1

            node_info = NodeInfo(
                name=name,
                type=node_type,
                parent=parent,
                depth=depth,
                line=i + 1
            )

            # Check for script
            # Look ahead for script property
            for j in range(i + 1, min(i + 20, len(lines))):
                if lines[j].startswith('['):
                    break
                script_match = re.match(r'script\s*=\s*ExtResource\(\s*"?(\d+)"?\s*\)', lines[j])
                if script_match:
                    res_id = script_match.group(1)
                    if res_id in ext_resources:
                        node_info.script = ext_resources[res_id]
                    break

            report.nodes.append(node_info)
            report.node_count += 1
            report.max_depth = max(report.max_depth, depth)

            if depth == 0:
                report.root_type = node_type
                if node_info.script:
                    report.has_script = True

    # Mark nodes that have children
    for node in report.nodes:
        node_path = node.name if node.parent in ["", "."] else f"{node.parent}/{node.name}"
        for other in report.nodes:
            if other.parent == node_path or (node.parent in ["", "."] and other.parent == node.name):
                node.has_children = True
                break

    # Check for issues
    # 1. Duplicate node names
    for name, count in node_names.items():
        if count > 1:
            report.issues.append(SceneIssue(
                scene=rel_path, node=name, issue_type="duplicate_name",
                severity="warning",
                message=f"Node name '{name}' appears {count} times"
            ))

    # 2. Missing scripts (for nodes that typically need them)
    scriptable_types = ["Control", "Node2D", "Node3D", "Area2D", "CharacterBody2D"]
    for node in report.nodes:
        if node.depth == 0 and not node.script:
            report.issues.append(SceneIssue(
                scene=rel_path, node=node.name, issue_type="no_root_script",
                severity="info",
                message=f"Root node '{node.name}' has no script attached"
            ))

    # 3. Deep nesting
    if report.max_depth > 10:
        report.issues.append(SceneIssue(
            scene=rel_path, node="(scene)", issue_type="deep_nesting",
            severity="warning",
            message=f"Scene has deep nesting (depth={report.max_depth})"
        ))

    # 4. Large scene
    if report.node_count > 100:
        report.issues.append(SceneIssue(
            scene=rel_path, node="(scene)", issue_type="large_scene",
            severity="info",
            message=f"Scene has many nodes ({report.node_count})"
        ))

    # 5. Broken resource references
    for res_path in report.external_resources:
        if res_path.startswith("res://"):
            local_path = res_path.replace("res://", "")
            full_path = PROJECT_ROOT / local_path
            if not full_path.exists():
                report.issues.append(SceneIssue(
                    scene=rel_path, node="(resource)", issue_type="broken_reference",
                    severity="error",
                    message=f"Missing resource: {res_path}"
                ))

    # 6. Orphan nodes (no script, no children, not a simple type)
    simple_types = ["Label", "Button", "TextureRect", "Sprite2D", "ColorRect",
                    "MarginContainer", "VBoxContainer", "HBoxContainer", "Panel",
                    "Control", "Node2D", "CanvasLayer"]
    for node in report.nodes:
        if (not node.script and not node.has_children and
            node.type not in simple_types and node.depth > 0):
            report.issues.append(SceneIssue(
                scene=rel_path, node=node.name, issue_type="orphan_node",
                severity="info",
                message=f"Node '{node.name}' ({node.type}) has no script and no children"
            ))

    return report


def analyze_scenes(target_file: Optional[str] = None) -> List[SceneReport]:
    """Analyze all scene files."""
    results = []

    if target_file:
        filepath = PROJECT_ROOT / target_file
        if filepath.exists():
            results.append(parse_tscn(filepath))
        return results

    for tscn_file in PROJECT_ROOT.glob("**/*.tscn"):
        if ".godot" in str(tscn_file) or "addons" in str(tscn_file):
            continue
        results.append(parse_tscn(tscn_file))

    return results


def format_report(results: List[SceneReport], verbose: bool = False) -> str:
    """Format the scene analysis report."""
    lines = []
    lines.append("=" * 60)
    lines.append("SCENE ANALYZER - KEYBOARD DEFENSE")
    lines.append("=" * 60)
    lines.append("")

    # Summary
    total_scenes = len(results)
    total_nodes = sum(r.node_count for r in results)
    total_issues = sum(len(r.issues) for r in results)
    errors = sum(1 for r in results for i in r.issues if i.severity == "error")
    warnings = sum(1 for r in results for i in r.issues if i.severity == "warning")

    lines.append("## SUMMARY")
    lines.append(f"  Scenes analyzed: {total_scenes}")
    lines.append(f"  Total nodes: {total_nodes}")
    lines.append(f"  Issues found: {total_issues} ({errors} errors, {warnings} warnings)")
    lines.append("")

    # Errors first
    error_issues = [i for r in results for i in r.issues if i.severity == "error"]
    if error_issues:
        lines.append("## ERRORS")
        for issue in error_issues:
            lines.append(f"  {issue.scene}")
            lines.append(f"    {issue.message}")
        lines.append("")

    # Warnings
    warning_issues = [i for r in results for i in r.issues if i.severity == "warning"]
    if warning_issues:
        lines.append("## WARNINGS")
        for issue in warning_issues[:20]:
            lines.append(f"  {issue.scene}: {issue.message}")
        if len(warning_issues) > 20:
            lines.append(f"  ... and {len(warning_issues) - 20} more")
        lines.append("")

    # Scene statistics
    lines.append("## LARGEST SCENES (by node count)")
    by_nodes = sorted(results, key=lambda r: r.node_count, reverse=True)
    for report in by_nodes[:10]:
        lines.append(f"  {report.node_count:4} nodes  depth={report.max_depth:2}  {report.path}")
    lines.append("")

    # Deepest nesting
    lines.append("## DEEPEST SCENES (by nesting)")
    by_depth = sorted(results, key=lambda r: r.max_depth, reverse=True)
    for report in by_depth[:10]:
        if report.max_depth > 3:
            lines.append(f"  depth={report.max_depth:2}  {report.node_count:4} nodes  {report.path}")
    lines.append("")

    # Scenes without root script
    no_script = [r for r in results if not r.has_script]
    if no_script:
        lines.append("## SCENES WITHOUT ROOT SCRIPT")
        for report in no_script[:15]:
            lines.append(f"  {report.path} ({report.root_type})")
        if len(no_script) > 15:
            lines.append(f"  ... and {len(no_script) - 15} more")
        lines.append("")

    if verbose:
        lines.append("## ALL SCENES")
        for report in sorted(results, key=lambda r: r.path):
            lines.append(f"\n### {report.path}")
            lines.append(f"  Root: {report.root_type}")
            lines.append(f"  Nodes: {report.node_count}, Max depth: {report.max_depth}")
            if report.has_script:
                lines.append(f"  Has script: Yes")
            for node in report.nodes[:20]:
                indent = "  " * (node.depth + 1)
                script_mark = " [S]" if node.script else ""
                lines.append(f"{indent}{node.name}: {node.type}{script_mark}")
            if len(report.nodes) > 20:
                lines.append(f"  ... and {len(report.nodes) - 20} more nodes")

    # Health indicators
    lines.append("## HEALTH INDICATORS")
    if errors > 0:
        lines.append(f"  [ERROR] {errors} broken resource references")
    else:
        lines.append("  [OK] No broken references")

    avg_nodes = total_nodes // max(total_scenes, 1)
    if avg_nodes > 50:
        lines.append(f"  [WARN] High average node count: {avg_nodes}")
    else:
        lines.append(f"  [OK] Average node count: {avg_nodes}")

    lines.append("")
    return "\n".join(lines)


def format_json(results: List[SceneReport]) -> str:
    """Format as JSON."""
    data = {
        "summary": {
            "total_scenes": len(results),
            "total_nodes": sum(r.node_count for r in results),
            "total_issues": sum(len(r.issues) for r in results),
            "errors": sum(1 for r in results for i in r.issues if i.severity == "error"),
            "warnings": sum(1 for r in results for i in r.issues if i.severity == "warning"),
        },
        "scenes": [],
    }

    for report in results:
        scene_data = {
            "path": report.path,
            "node_count": report.node_count,
            "max_depth": report.max_depth,
            "root_type": report.root_type,
            "has_script": report.has_script,
            "issues": [
                {
                    "node": i.node,
                    "type": i.issue_type,
                    "severity": i.severity,
                    "message": i.message,
                }
                for i in report.issues
            ],
        }
        data["scenes"].append(scene_data)

    return json.dumps(data, indent=2)


def main():
    import argparse

    parser = argparse.ArgumentParser(description="Analyze Godot scenes")
    parser.add_argument("--json", "-j", action="store_true", help="JSON output")
    parser.add_argument("--file", "-f", type=str, help="Analyze single scene")
    parser.add_argument("--verbose", "-v", action="store_true", help="Show all nodes")
    args = parser.parse_args()

    results = analyze_scenes(args.file)

    if args.json:
        print(format_json(results))
    else:
        print(format_report(results, args.verbose))


if __name__ == "__main__":
    main()
