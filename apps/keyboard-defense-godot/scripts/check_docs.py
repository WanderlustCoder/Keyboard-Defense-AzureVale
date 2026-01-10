#!/usr/bin/env python3
"""
Documentation Coverage Checker

Analyzes GDScript files for documentation coverage:
- Finds functions missing docstrings
- Checks class-level documentation
- Reports documentation coverage percentage
- Identifies priority files needing docs

Usage:
    python scripts/check_docs.py              # Full report
    python scripts/check_docs.py --layer sim  # Only sim layer
    python scripts/check_docs.py --public     # Only public functions
    python scripts/check_docs.py --file game/main.gd  # Single file
    python scripts/check_docs.py --json       # JSON output
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
class FunctionDoc:
    """Documentation info for a function."""
    name: str
    file: str
    line: int
    has_docstring: bool = False
    docstring: str = ""
    is_private: bool = False
    is_static: bool = False
    param_count: int = 0


@dataclass
class ClassDoc:
    """Documentation info for a class."""
    name: str
    file: str
    line: int
    has_docstring: bool = False
    docstring: str = ""
    function_count: int = 0
    documented_functions: int = 0


@dataclass
class DocReport:
    """Documentation coverage report."""
    functions: List[FunctionDoc] = field(default_factory=list)
    classes: List[ClassDoc] = field(default_factory=list)
    by_file: Dict[str, Dict] = field(default_factory=dict)
    by_layer: Dict[str, Dict] = field(default_factory=dict)
    total_functions: int = 0
    documented_functions: int = 0
    total_classes: int = 0
    documented_classes: int = 0
    coverage_percent: float = 0.0


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
    return "other"


def extract_docstring(lines: List[str], start_idx: int) -> Tuple[bool, str]:
    """Extract docstring from lines following a declaration."""
    # Look for ## comment on same line or following lines
    docstring_lines = []

    # Check next lines for ## comments
    for i in range(start_idx + 1, min(start_idx + 10, len(lines))):
        line = lines[i].strip()
        if line.startswith('##'):
            docstring_lines.append(line[2:].strip())
        elif line.startswith('#') and not line.startswith('##'):
            # Regular comment, might be part of docstring
            continue
        elif line and not line.startswith('#'):
            # Non-comment, non-empty line - stop looking
            break

    # Also check the line before for ## comment (common pattern)
    if start_idx > 0:
        prev_line = lines[start_idx - 1].strip()
        if prev_line.startswith('##'):
            docstring_lines.insert(0, prev_line[2:].strip())

    if docstring_lines:
        return True, ' '.join(docstring_lines)

    return False, ""


def analyze_file(filepath: Path) -> Tuple[List[FunctionDoc], List[ClassDoc]]:
    """Analyze a file for documentation coverage."""
    functions = []
    classes = []
    rel_path = str(filepath.relative_to(PROJECT_ROOT))

    try:
        content = filepath.read_text(encoding="utf-8")
        lines = content.split('\n')
    except Exception:
        return functions, classes

    current_class = None

    for i, line in enumerate(lines):
        stripped = line.strip()

        # Check for class_name
        class_match = re.match(r'^class_name\s+(\w+)', stripped)
        if class_match:
            has_doc, docstring = extract_docstring(lines, i)
            class_info = ClassDoc(
                name=class_match.group(1),
                file=rel_path,
                line=i + 1,
                has_docstring=has_doc,
                docstring=docstring
            )
            classes.append(class_info)
            current_class = class_info

        # Check for inner class
        inner_match = re.match(r'^class\s+(\w+)', stripped)
        if inner_match:
            has_doc, docstring = extract_docstring(lines, i)
            class_info = ClassDoc(
                name=inner_match.group(1),
                file=rel_path,
                line=i + 1,
                has_docstring=has_doc,
                docstring=docstring
            )
            classes.append(class_info)

        # Check for function definition
        func_match = re.match(r'^(static\s+)?func\s+(\w+)\s*\(([^)]*)\)', stripped)
        if func_match:
            is_static = func_match.group(1) is not None
            func_name = func_match.group(2)
            params = func_match.group(3)

            # Count parameters
            param_count = 0
            if params.strip():
                param_count = len([p for p in params.split(',') if p.strip()])

            has_doc, docstring = extract_docstring(lines, i)

            func_info = FunctionDoc(
                name=func_name,
                file=rel_path,
                line=i + 1,
                has_docstring=has_doc,
                docstring=docstring,
                is_private=func_name.startswith('_'),
                is_static=is_static,
                param_count=param_count
            )
            functions.append(func_info)

            # Update class stats
            if current_class:
                current_class.function_count += 1
                if has_doc:
                    current_class.documented_functions += 1

    return functions, classes


def analyze_docs(layer_filter: Optional[str] = None,
                 file_filter: Optional[str] = None,
                 public_only: bool = False) -> DocReport:
    """Analyze documentation coverage across the codebase."""
    report = DocReport()

    for gd_file in PROJECT_ROOT.glob("**/*.gd"):
        if ".godot" in str(gd_file) or "addons" in str(gd_file):
            continue

        rel_path = str(gd_file.relative_to(PROJECT_ROOT))
        layer = get_layer(rel_path)

        # Apply filters
        if layer_filter and layer != layer_filter:
            continue
        if file_filter and file_filter not in rel_path:
            continue

        functions, classes = analyze_file(gd_file)

        # Filter private functions if requested
        if public_only:
            functions = [f for f in functions if not f.is_private]

        report.functions.extend(functions)
        report.classes.extend(classes)

        # File stats
        if functions:
            documented = sum(1 for f in functions if f.has_docstring)
            report.by_file[rel_path] = {
                "total": len(functions),
                "documented": documented,
                "percent": (documented / len(functions)) * 100 if functions else 0
            }

            # Layer stats
            if layer not in report.by_layer:
                report.by_layer[layer] = {"total": 0, "documented": 0}
            report.by_layer[layer]["total"] += len(functions)
            report.by_layer[layer]["documented"] += documented

    # Calculate totals
    report.total_functions = len(report.functions)
    report.documented_functions = sum(1 for f in report.functions if f.has_docstring)
    report.total_classes = len(report.classes)
    report.documented_classes = sum(1 for c in report.classes if c.has_docstring)

    if report.total_functions > 0:
        report.coverage_percent = (report.documented_functions / report.total_functions) * 100

    return report


def format_report(report: DocReport) -> str:
    """Format documentation report as text."""
    lines = []
    lines.append("=" * 60)
    lines.append("DOCUMENTATION COVERAGE - KEYBOARD DEFENSE")
    lines.append("=" * 60)
    lines.append("")

    # Summary
    lines.append("## SUMMARY")
    lines.append(f"  Total functions:       {report.total_functions}")
    lines.append(f"  Documented functions:  {report.documented_functions}")
    lines.append(f"  Function coverage:     {report.coverage_percent:.1f}%")
    lines.append("")
    lines.append(f"  Total classes:         {report.total_classes}")
    lines.append(f"  Documented classes:    {report.documented_classes}")
    class_pct = (report.documented_classes / max(report.total_classes, 1)) * 100
    lines.append(f"  Class coverage:        {class_pct:.1f}%")
    lines.append("")

    # Coverage bar
    bar_width = 40
    filled = int(bar_width * report.coverage_percent / 100)
    bar = "[" + "=" * filled + " " * (bar_width - filled) + "]"
    lines.append(f"  {bar} {report.coverage_percent:.1f}%")
    lines.append("")

    # By layer
    lines.append("## COVERAGE BY LAYER")
    for layer in ["sim", "game", "ui", "scripts", "tests", "other"]:
        stats = report.by_layer.get(layer, {"total": 0, "documented": 0})
        if stats["total"] > 0:
            pct = (stats["documented"] / stats["total"]) * 100
            bar_filled = int(20 * pct / 100)
            mini_bar = "[" + "=" * bar_filled + " " * (20 - bar_filled) + "]"
            lines.append(f"  {layer:10} {mini_bar} {pct:5.1f}% ({stats['documented']}/{stats['total']})")
    lines.append("")

    # Undocumented public functions (priority)
    undocumented_public = [f for f in report.functions if not f.has_docstring and not f.is_private]
    if undocumented_public:
        lines.append("## UNDOCUMENTED PUBLIC FUNCTIONS (Priority)")
        # Group by file
        by_file: Dict[str, List[FunctionDoc]] = {}
        for f in undocumented_public:
            if f.file not in by_file:
                by_file[f.file] = []
            by_file[f.file].append(f)

        shown = 0
        for filepath in sorted(by_file.keys()):
            if shown >= 20:
                break
            funcs = by_file[filepath]
            lines.append(f"  {filepath}:")
            for func in funcs[:3]:
                static = "[S] " if func.is_static else "    "
                lines.append(f"    {static}{func.name}() line {func.line}")
                shown += 1
            if len(funcs) > 3:
                lines.append(f"    ... and {len(funcs) - 3} more")

        remaining = len(undocumented_public) - shown
        if remaining > 0:
            lines.append(f"  ... and {remaining} more undocumented public functions")
        lines.append("")

    # Files with lowest coverage
    lines.append("## FILES NEEDING DOCUMENTATION")
    file_coverage = [
        (f, d["percent"], d["total"] - d["documented"])
        for f, d in report.by_file.items()
        if d["total"] >= 3
    ]
    file_coverage.sort(key=lambda x: (x[1], -x[2]))

    for filepath, pct, missing in file_coverage[:15]:
        lines.append(f"  {pct:5.1f}%  ({missing} missing)  {filepath}")
    lines.append("")

    # Well-documented files
    well_documented = [
        (f, d["percent"], d["total"])
        for f, d in report.by_file.items()
        if d["percent"] >= 80 and d["total"] >= 5
    ]
    if well_documented:
        lines.append("## WELL-DOCUMENTED FILES")
        well_documented.sort(key=lambda x: -x[1])
        for filepath, pct, total in well_documented[:10]:
            lines.append(f"  {pct:5.1f}%  ({total} funcs)  {filepath}")
        lines.append("")

    # Health indicators
    lines.append("## HEALTH INDICATORS")
    if report.coverage_percent >= 50:
        lines.append("  [OK] Good documentation coverage")
    elif report.coverage_percent >= 20:
        lines.append("  [INFO] Moderate documentation coverage")
    else:
        lines.append("  [WARN] Low documentation coverage")

    sim_stats = report.by_layer.get("sim", {"total": 0, "documented": 0})
    if sim_stats["total"] > 0:
        sim_pct = (sim_stats["documented"] / sim_stats["total"]) * 100
        if sim_pct < 30:
            lines.append(f"  [WARN] Sim layer at {sim_pct:.0f}% - core logic needs docs")
        else:
            lines.append(f"  [OK] Sim layer at {sim_pct:.0f}%")

    lines.append("")
    return "\n".join(lines)


def format_json(report: DocReport) -> str:
    """Format report as JSON."""
    data = {
        "summary": {
            "total_functions": report.total_functions,
            "documented_functions": report.documented_functions,
            "coverage_percent": round(report.coverage_percent, 1),
            "total_classes": report.total_classes,
            "documented_classes": report.documented_classes
        },
        "by_layer": {
            layer: {
                "total": stats["total"],
                "documented": stats["documented"],
                "percent": round((stats["documented"] / max(stats["total"], 1)) * 100, 1)
            }
            for layer, stats in report.by_layer.items()
        },
        "by_file": {
            filepath: {
                "total": stats["total"],
                "documented": stats["documented"],
                "percent": round(stats["percent"], 1)
            }
            for filepath, stats in report.by_file.items()
        },
        "undocumented_public": [
            {
                "name": f.name,
                "file": f.file,
                "line": f.line,
                "is_static": f.is_static
            }
            for f in report.functions
            if not f.has_docstring and not f.is_private
        ][:50]
    }
    return json.dumps(data, indent=2)


def main():
    import argparse

    parser = argparse.ArgumentParser(description="Check documentation coverage")
    parser.add_argument("--json", "-j", action="store_true", help="JSON output")
    parser.add_argument("--layer", "-l", type=str, help="Filter by layer")
    parser.add_argument("--file", "-f", type=str, help="Filter by file path")
    parser.add_argument("--public", "-p", action="store_true", help="Only public functions")
    args = parser.parse_args()

    report = analyze_docs(args.layer, args.file, args.public)

    if args.json:
        print(format_json(report))
    else:
        print(format_report(report))


if __name__ == "__main__":
    main()
