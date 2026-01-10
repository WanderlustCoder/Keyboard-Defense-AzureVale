#!/usr/bin/env python3
"""
Signal Analyzer

Analyzes GDScript signal declarations and connections:
- Finds declared signals and their parameters
- Tracks signal connections (.connect() calls)
- Identifies unused signals (declared but never connected)
- Finds potential connection issues

Usage:
    python scripts/analyze_signals.py              # Full report
    python scripts/analyze_signals.py --unused     # Show only unused signals
    python scripts/analyze_signals.py --file game/main.gd  # Single file
    python scripts/analyze_signals.py --json       # JSON output
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
class SignalDeclaration:
    """A declared signal."""
    name: str
    file: str
    line: int
    parameters: List[str] = field(default_factory=list)
    class_name: str = ""
    is_used: bool = False


@dataclass
class SignalConnection:
    """A signal connection."""
    signal_name: str
    file: str
    line: int
    target_method: str = ""
    source_object: str = ""


@dataclass
class SignalEmission:
    """A signal emission."""
    signal_name: str
    file: str
    line: int


@dataclass
class SignalReport:
    """Signal analysis report."""
    declarations: List[SignalDeclaration] = field(default_factory=list)
    connections: List[SignalConnection] = field(default_factory=list)
    emissions: List[SignalEmission] = field(default_factory=list)
    unused_signals: List[SignalDeclaration] = field(default_factory=list)
    by_file: Dict[str, Dict] = field(default_factory=dict)
    issues: List[str] = field(default_factory=list)


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
    return "other"


def extract_signals(filepath: Path) -> Tuple[List[SignalDeclaration], List[SignalConnection], List[SignalEmission]]:
    """Extract signal declarations, connections, and emissions from a file."""
    declarations = []
    connections = []
    emissions = []
    rel_path = str(filepath.relative_to(PROJECT_ROOT))

    try:
        content = filepath.read_text(encoding="utf-8")
        lines = content.split('\n')
    except Exception:
        return declarations, connections, emissions

    current_class = ""

    for i, line in enumerate(lines):
        stripped = line.strip()

        # Check for class_name
        class_match = re.match(r'^class_name\s+(\w+)', stripped)
        if class_match:
            current_class = class_match.group(1)

        # Check for signal declaration
        # signal name
        # signal name(param1, param2)
        # signal name(param1: Type, param2: Type)
        signal_match = re.match(r'^signal\s+(\w+)(?:\s*\(([^)]*)\))?', stripped)
        if signal_match:
            signal_name = signal_match.group(1)
            params_str = signal_match.group(2) or ""
            params = []
            if params_str.strip():
                # Parse parameters
                for param in params_str.split(','):
                    param = param.strip()
                    if ':' in param:
                        param = param.split(':')[0].strip()
                    if param:
                        params.append(param)

            declarations.append(SignalDeclaration(
                name=signal_name,
                file=rel_path,
                line=i + 1,
                parameters=params,
                class_name=current_class
            ))

        # Check for signal connection
        # object.signal_name.connect(method)
        # object.signal_name.connect(self.method)
        # object.signal_name.connect(_on_something)
        connect_match = re.search(r'(\w+)\.(\w+)\.connect\s*\(\s*([^)]+)\)', stripped)
        if connect_match:
            source = connect_match.group(1)
            signal_name = connect_match.group(2)
            target = connect_match.group(3).strip()

            connections.append(SignalConnection(
                signal_name=signal_name,
                file=rel_path,
                line=i + 1,
                target_method=target,
                source_object=source
            ))

        # Also check for older connect syntax
        # connect("signal_name", self, "_method")
        old_connect = re.search(r'\.connect\s*\(\s*["\'](\w+)["\']', stripped)
        if old_connect and not connect_match:
            connections.append(SignalConnection(
                signal_name=old_connect.group(1),
                file=rel_path,
                line=i + 1
            ))

        # Check for signal emission
        # signal_name.emit()
        # signal_name.emit(arg1, arg2)
        emit_match = re.search(r'(\w+)\.emit\s*\(', stripped)
        if emit_match:
            emissions.append(SignalEmission(
                signal_name=emit_match.group(1),
                file=rel_path,
                line=i + 1
            ))

    return declarations, connections, emissions


def analyze_signals(file_filter: Optional[str] = None) -> SignalReport:
    """Analyze signals across the codebase."""
    report = SignalReport()

    all_declarations = []
    all_connections = []
    all_emissions = []

    # Scan all GDScript files
    for gd_file in PROJECT_ROOT.glob("**/*.gd"):
        if ".godot" in str(gd_file) or "addons" in str(gd_file):
            continue

        rel_path = str(gd_file.relative_to(PROJECT_ROOT))

        # Apply file filter
        if file_filter and file_filter not in rel_path:
            continue

        declarations, connections, emissions = extract_signals(gd_file)

        all_declarations.extend(declarations)
        all_connections.extend(connections)
        all_emissions.extend(emissions)

        # Update file stats
        if declarations or connections or emissions:
            report.by_file[rel_path] = {
                "declarations": len(declarations),
                "connections": len(connections),
                "emissions": len(emissions)
            }

    report.declarations = all_declarations
    report.connections = all_connections
    report.emissions = all_emissions

    # Build set of used signal names
    connected_signals = {c.signal_name for c in all_connections}
    emitted_signals = {e.signal_name for e in all_emissions}
    used_signals = connected_signals | emitted_signals

    # Find unused signals
    for decl in all_declarations:
        if decl.name in used_signals:
            decl.is_used = True
        else:
            # Check if it might be used via string reference
            decl.is_used = False
            report.unused_signals.append(decl)

    # Check for issues
    # 1. Signals in sim layer (shouldn't have signals)
    for decl in all_declarations:
        if decl.file.startswith("sim/"):
            report.issues.append(f"Signal in sim layer: {decl.name} in {decl.file}:{decl.line}")

    # 2. Connected to non-existent signals (heuristic)
    declared_names = {d.name for d in all_declarations}
    builtin_signals = {
        "ready", "tree_entered", "tree_exited", "process", "physics_process",
        "input", "gui_input", "draw", "visibility_changed", "item_rect_changed",
        "resized", "minimum_size_changed", "focus_entered", "focus_exited",
        "mouse_entered", "mouse_exited", "pressed", "button_down", "button_up",
        "toggled", "value_changed", "text_changed", "text_submitted",
        "timeout", "finished", "body_entered", "body_exited", "area_entered",
        "area_exited", "screen_entered", "screen_exited", "animation_finished",
        "tween_completed", "child_entered_tree", "child_exiting_tree",
        "sort_children", "child_order_changed", "renamed", "editor_description_changed"
    }

    for conn in all_connections:
        if conn.signal_name not in declared_names and conn.signal_name not in builtin_signals:
            # Could be from an external class or dynamic
            pass  # Don't report as error, too many false positives

    return report


def format_report(report: SignalReport, show_unused_only: bool = False) -> str:
    """Format signal report as text."""
    lines = []
    lines.append("=" * 60)
    lines.append("SIGNAL ANALYZER - KEYBOARD DEFENSE")
    lines.append("=" * 60)
    lines.append("")

    # Summary
    lines.append("## SUMMARY")
    lines.append(f"  Signal declarations:  {len(report.declarations)}")
    lines.append(f"  Signal connections:   {len(report.connections)}")
    lines.append(f"  Signal emissions:     {len(report.emissions)}")
    lines.append(f"  Unused signals:       {len(report.unused_signals)}")
    lines.append("")

    if show_unused_only:
        # Show all unused signals
        if report.unused_signals:
            lines.append("## UNUSED SIGNALS")
            for sig in sorted(report.unused_signals, key=lambda s: (s.file, s.line)):
                params = f"({', '.join(sig.parameters)})" if sig.parameters else ""
                lines.append(f"  {sig.file}:{sig.line}")
                lines.append(f"    signal {sig.name}{params}")
            lines.append("")
        else:
            lines.append("No unused signals found!")
            lines.append("")
    else:
        # Issues
        if report.issues:
            lines.append("## ISSUES")
            for issue in report.issues:
                lines.append(f"  [WARN] {issue}")
            lines.append("")

        # Unused signals
        if report.unused_signals:
            lines.append("## UNUSED SIGNALS")
            lines.append("  Signals declared but never connected to:")
            lines.append("")
            for sig in report.unused_signals[:15]:
                params = f"({', '.join(sig.parameters)})" if sig.parameters else ""
                lines.append(f"    {sig.file}:{sig.line}")
                lines.append(f"      signal {sig.name}{params}")
            if len(report.unused_signals) > 15:
                lines.append(f"    ... and {len(report.unused_signals) - 15} more")
            lines.append("")

        # Signals by layer
        lines.append("## SIGNALS BY LAYER")
        layer_counts = {"sim": 0, "game": 0, "ui": 0, "other": 0}
        for decl in report.declarations:
            layer = get_layer(decl.file)
            layer_counts[layer] = layer_counts.get(layer, 0) + 1

        for layer in ["sim", "game", "ui", "other"]:
            count = layer_counts.get(layer, 0)
            if count > 0:
                lines.append(f"  {layer:10} {count}")
        lines.append("")

        # Files with most signals
        lines.append("## FILES WITH MOST SIGNALS")
        sorted_files = sorted(
            [(f, d["declarations"]) for f, d in report.by_file.items()],
            key=lambda x: -x[1]
        )
        for filepath, count in sorted_files[:10]:
            if count > 0:
                lines.append(f"  {count:4} signals  {filepath}")
        lines.append("")

        # Most connected signals
        lines.append("## MOST CONNECTED SIGNALS")
        connection_counts: Dict[str, int] = {}
        for conn in report.connections:
            connection_counts[conn.signal_name] = connection_counts.get(conn.signal_name, 0) + 1

        sorted_conns = sorted(connection_counts.items(), key=lambda x: -x[1])
        for signal_name, count in sorted_conns[:10]:
            lines.append(f"  {count:4} connections  {signal_name}")
        lines.append("")

    # Health indicators
    lines.append("## HEALTH INDICATORS")
    if report.issues:
        lines.append(f"  [WARN] {len(report.issues)} issues found")
    else:
        lines.append("  [OK] No issues found")

    unused_pct = (len(report.unused_signals) / max(len(report.declarations), 1)) * 100
    if unused_pct > 30:
        lines.append(f"  [WARN] {unused_pct:.0f}% of signals appear unused")
    elif report.unused_signals:
        lines.append(f"  [INFO] {len(report.unused_signals)} potentially unused signals")
    else:
        lines.append("  [OK] All signals appear to be used")

    lines.append("")
    return "\n".join(lines)


def format_json(report: SignalReport) -> str:
    """Format report as JSON."""
    data = {
        "summary": {
            "declarations": len(report.declarations),
            "connections": len(report.connections),
            "emissions": len(report.emissions),
            "unused": len(report.unused_signals)
        },
        "declarations": [
            {
                "name": d.name,
                "file": d.file,
                "line": d.line,
                "parameters": d.parameters,
                "class_name": d.class_name,
                "is_used": d.is_used
            }
            for d in report.declarations
        ],
        "connections": [
            {
                "signal_name": c.signal_name,
                "file": c.file,
                "line": c.line,
                "target_method": c.target_method,
                "source_object": c.source_object
            }
            for c in report.connections
        ],
        "unused_signals": [
            {
                "name": s.name,
                "file": s.file,
                "line": s.line
            }
            for s in report.unused_signals
        ],
        "issues": report.issues
    }
    return json.dumps(data, indent=2)


def main():
    import argparse

    parser = argparse.ArgumentParser(description="Analyze GDScript signals")
    parser.add_argument("--json", "-j", action="store_true", help="JSON output")
    parser.add_argument("--file", "-f", type=str, help="Filter by file path")
    parser.add_argument("--unused", "-u", action="store_true", help="Show only unused signals")
    args = parser.parse_args()

    report = analyze_signals(args.file)

    if args.json:
        print(format_json(report))
    else:
        print(format_report(report, args.unused))


if __name__ == "__main__":
    main()
