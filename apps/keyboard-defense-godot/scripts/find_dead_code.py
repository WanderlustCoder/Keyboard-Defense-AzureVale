#!/usr/bin/env python3
"""
Dead Code Finder

Finds potentially unused code in the GDScript codebase:
- Unused functions (defined but never called)
- Unused classes (defined but never referenced)
- Unused constants (defined but never used)
- Orphan files (not loaded/preloaded anywhere)

Usage:
    python scripts/find_dead_code.py              # Full analysis
    python scripts/find_dead_code.py --json       # JSON output
    python scripts/find_dead_code.py --functions  # Functions only
    python scripts/find_dead_code.py --verbose    # Show all usages
"""

import json
import re
import sys
from collections import defaultdict
from dataclasses import dataclass, field
from pathlib import Path
from typing import Dict, List, Set, Tuple, Optional

# Project paths
SCRIPT_DIR = Path(__file__).parent
PROJECT_ROOT = SCRIPT_DIR.parent

# Patterns for code analysis
FUNC_DEF_PATTERN = re.compile(r"^(?:static\s+)?func\s+(\w+)\s*\(", re.MULTILINE)
CLASS_DEF_PATTERN = re.compile(r"^class\s+(\w+)", re.MULTILINE)
CLASS_NAME_PATTERN = re.compile(r"^class_name\s+(\w+)", re.MULTILINE)
CONST_DEF_PATTERN = re.compile(r"^const\s+(\w+)\s*[:=]", re.MULTILINE)
SIGNAL_DEF_PATTERN = re.compile(r"^signal\s+(\w+)", re.MULTILINE)
PRELOAD_PATTERN = re.compile(r'(?:preload|load)\s*\(\s*["\']res://([^"\']+)["\']')
EXTENDS_PATTERN = re.compile(r"^extends\s+(\w+)", re.MULTILINE)

# Built-in functions and methods to ignore
BUILTINS = {
    "_ready", "_process", "_physics_process", "_input", "_unhandled_input",
    "_draw", "_enter_tree", "_exit_tree", "_notification", "_init",
    "_get", "_set", "_get_property_list", "_to_string", "_validate_property",
    "main", "run", "parse", "apply", "setup", "cleanup", "reset",
    "update", "refresh", "show", "hide", "enable", "disable",
}

# Entry point functions (called by Godot/scenes)
ENTRY_POINTS = {
    "_on_", "test_", "scenario_", "emit_", "connect_",
}


@dataclass
class CodeItem:
    """Represents a defined code item."""
    name: str
    file: str
    line: int
    item_type: str  # "function", "class", "constant", "signal"
    usages: List[Tuple[str, int]] = field(default_factory=list)

    @property
    def is_potentially_unused(self) -> bool:
        """Check if item appears unused."""
        # Check for builtin/entry point
        if self.name in BUILTINS:
            return False
        for prefix in ENTRY_POINTS:
            if self.name.startswith(prefix):
                return False
        # Check for usages outside definition file
        external_usages = [u for u in self.usages if u[0] != self.file]
        # Also check for usages in same file but different line
        same_file_usages = [u for u in self.usages if u[0] == self.file and u[1] != self.line]
        return len(external_usages) == 0 and len(same_file_usages) == 0


@dataclass
class DeadCodeReport:
    """Report of potentially dead code."""
    unused_functions: List[CodeItem] = field(default_factory=list)
    unused_classes: List[CodeItem] = field(default_factory=list)
    unused_constants: List[CodeItem] = field(default_factory=list)
    unused_signals: List[CodeItem] = field(default_factory=list)
    orphan_files: List[str] = field(default_factory=list)

    # Statistics
    total_functions: int = 0
    total_classes: int = 0
    total_constants: int = 0
    total_signals: int = 0
    total_files: int = 0


def find_definitions(filepath: Path) -> Tuple[List[CodeItem], str]:
    """Find all definitions in a GDScript file."""
    items = []
    rel_path = str(filepath.relative_to(PROJECT_ROOT))

    try:
        content = filepath.read_text(encoding="utf-8")
        lines = content.split("\n")
    except Exception:
        return items, ""

    # Find functions
    for match in FUNC_DEF_PATTERN.finditer(content):
        name = match.group(1)
        line_num = content[:match.start()].count("\n") + 1
        items.append(CodeItem(name=name, file=rel_path, line=line_num, item_type="function"))

    # Find inner classes
    for match in CLASS_DEF_PATTERN.finditer(content):
        name = match.group(1)
        line_num = content[:match.start()].count("\n") + 1
        items.append(CodeItem(name=name, file=rel_path, line=line_num, item_type="class"))

    # Find class_name declarations
    for match in CLASS_NAME_PATTERN.finditer(content):
        name = match.group(1)
        line_num = content[:match.start()].count("\n") + 1
        items.append(CodeItem(name=name, file=rel_path, line=line_num, item_type="class"))

    # Find constants
    for match in CONST_DEF_PATTERN.finditer(content):
        name = match.group(1)
        line_num = content[:match.start()].count("\n") + 1
        items.append(CodeItem(name=name, file=rel_path, line=line_num, item_type="constant"))

    # Find signals
    for match in SIGNAL_DEF_PATTERN.finditer(content):
        name = match.group(1)
        line_num = content[:match.start()].count("\n") + 1
        items.append(CodeItem(name=name, file=rel_path, line=line_num, item_type="signal"))

    return items, content


def find_usages(name: str, all_files: Dict[str, str], definition_file: str) -> List[Tuple[str, int]]:
    """Find all usages of a name across the codebase."""
    usages = []

    # Pattern to find word usage (not just definition)
    # Look for: .name( or name( or name. or name) or name, etc
    usage_pattern = re.compile(r'\b' + re.escape(name) + r'\b')

    for filepath, content in all_files.items():
        lines = content.split("\n")
        for line_num, line in enumerate(lines, 1):
            if usage_pattern.search(line):
                usages.append((filepath, line_num))

    return usages


def find_file_references(all_files: Dict[str, str]) -> Set[str]:
    """Find all files that are referenced via preload/load."""
    referenced = set()

    for content in all_files.values():
        for match in PRELOAD_PATTERN.finditer(content):
            path = match.group(1)
            if path.endswith(".gd"):
                referenced.add(path)

    # Also check scene files for script references
    for tscn_file in PROJECT_ROOT.glob("**/*.tscn"):
        if ".godot" in str(tscn_file):
            continue
        try:
            content = tscn_file.read_text(encoding="utf-8")
            # Look for script = ExtResource or script = "res://"
            for match in re.finditer(r'script\s*=.*?"res://([^"]+\.gd)"', content):
                referenced.add(match.group(1))
            for match in re.finditer(r'path="res://([^"]+\.gd)"', content):
                referenced.add(match.group(1))
        except Exception:
            pass

    # Check project.godot for autoloads
    project_file = PROJECT_ROOT / "project.godot"
    if project_file.exists():
        try:
            content = project_file.read_text(encoding="utf-8")
            for match in re.finditer(r'"?\*?res://([^"]+\.gd)"?', content):
                referenced.add(match.group(1))
        except Exception:
            pass

    return referenced


def analyze_codebase() -> DeadCodeReport:
    """Analyze the entire codebase for dead code."""
    report = DeadCodeReport()
    all_items: List[CodeItem] = []
    all_files: Dict[str, str] = {}  # filepath -> content
    gd_files: List[str] = []

    # Collect all GDScript files
    for gd_file in PROJECT_ROOT.glob("**/*.gd"):
        if ".godot" in str(gd_file) or "addons" in str(gd_file):
            continue

        rel_path = str(gd_file.relative_to(PROJECT_ROOT))
        gd_files.append(rel_path)

        items, content = find_definitions(gd_file)
        all_items.extend(items)
        all_files[rel_path] = content
        report.total_files += 1

    # Count by type
    for item in all_items:
        if item.item_type == "function":
            report.total_functions += 1
        elif item.item_type == "class":
            report.total_classes += 1
        elif item.item_type == "constant":
            report.total_constants += 1
        elif item.item_type == "signal":
            report.total_signals += 1

    # Find usages for each item
    for item in all_items:
        item.usages = find_usages(item.name, all_files, item.file)

    # Categorize unused items
    for item in all_items:
        if item.is_potentially_unused:
            if item.item_type == "function":
                report.unused_functions.append(item)
            elif item.item_type == "class":
                report.unused_classes.append(item)
            elif item.item_type == "constant":
                report.unused_constants.append(item)
            elif item.item_type == "signal":
                report.unused_signals.append(item)

    # Find orphan files
    referenced = find_file_references(all_files)
    for gd_path in gd_files:
        # Skip entry points and tests
        if any(x in gd_path for x in ["tests/", "tools/", "scripts/"]):
            continue
        # Skip autoloads and main files
        if any(x in gd_path for x in ["main.gd", "autoload"]):
            continue

        if gd_path not in referenced:
            # Check if class_name is used
            content = all_files.get(gd_path, "")
            class_name_match = CLASS_NAME_PATTERN.search(content)
            if class_name_match:
                class_name = class_name_match.group(1)
                # Check if class is referenced anywhere
                is_used = False
                for other_file, other_content in all_files.items():
                    if other_file != gd_path and class_name in other_content:
                        is_used = True
                        break
                if not is_used:
                    report.orphan_files.append(gd_path)
            else:
                report.orphan_files.append(gd_path)

    return report


def format_report(report: DeadCodeReport, verbose: bool = False) -> str:
    """Format the dead code report."""
    lines = []
    lines.append("=" * 60)
    lines.append("DEAD CODE ANALYSIS - KEYBOARD DEFENSE")
    lines.append("=" * 60)
    lines.append("")

    # Summary
    lines.append("## SUMMARY")
    lines.append(f"  Total files analyzed:      {report.total_files}")
    lines.append(f"  Total functions:           {report.total_functions}")
    lines.append(f"  Total classes:             {report.total_classes}")
    lines.append(f"  Total constants:           {report.total_constants}")
    lines.append(f"  Total signals:             {report.total_signals}")
    lines.append("")
    lines.append(f"  Potentially unused funcs:  {len(report.unused_functions)}")
    lines.append(f"  Potentially unused classes:{len(report.unused_classes)}")
    lines.append(f"  Potentially unused consts: {len(report.unused_constants)}")
    lines.append(f"  Potentially unused signals:{len(report.unused_signals)}")
    lines.append(f"  Potentially orphan files:  {len(report.orphan_files)}")
    lines.append("")

    # Unused functions
    if report.unused_functions:
        lines.append("## POTENTIALLY UNUSED FUNCTIONS")
        for item in sorted(report.unused_functions, key=lambda x: (x.file, x.line)):
            lines.append(f"  {item.file}:{item.line}  {item.name}()")
            if verbose and item.usages:
                for usage_file, usage_line in item.usages[:3]:
                    lines.append(f"    └ used at {usage_file}:{usage_line}")
        lines.append("")

    # Unused classes
    if report.unused_classes:
        lines.append("## POTENTIALLY UNUSED CLASSES")
        for item in sorted(report.unused_classes, key=lambda x: (x.file, x.line)):
            lines.append(f"  {item.file}:{item.line}  class {item.name}")
        lines.append("")

    # Unused constants
    if report.unused_constants:
        lines.append("## POTENTIALLY UNUSED CONSTANTS")
        for item in sorted(report.unused_constants, key=lambda x: (x.file, x.line)):
            lines.append(f"  {item.file}:{item.line}  const {item.name}")
        lines.append("")

    # Unused signals
    if report.unused_signals:
        lines.append("## POTENTIALLY UNUSED SIGNALS")
        for item in sorted(report.unused_signals, key=lambda x: (x.file, x.line)):
            lines.append(f"  {item.file}:{item.line}  signal {item.name}")
        lines.append("")

    # Orphan files
    if report.orphan_files:
        lines.append("## POTENTIALLY ORPHAN FILES")
        lines.append("  (Not preloaded/loaded anywhere, no class_name used)")
        for filepath in sorted(report.orphan_files):
            lines.append(f"  {filepath}")
        lines.append("")

    # Health indicators
    lines.append("## HEALTH INDICATORS")
    unused_func_pct = len(report.unused_functions) * 100 // max(report.total_functions, 1)
    if unused_func_pct > 20:
        lines.append(f"  [WARN] High unused function ratio: {unused_func_pct}%")
    else:
        lines.append(f"  [OK] Unused function ratio: {unused_func_pct}%")

    if len(report.orphan_files) > 5:
        lines.append(f"  [WARN] Many potentially orphan files: {len(report.orphan_files)}")
    else:
        lines.append(f"  [OK] Orphan files: {len(report.orphan_files)}")

    lines.append("")
    lines.append("Note: Some items may be false positives (called via signals, strings, etc.)")
    lines.append("")

    return "\n".join(lines)


def format_json(report: DeadCodeReport) -> str:
    """Format as JSON."""
    data = {
        "summary": {
            "total_files": report.total_files,
            "total_functions": report.total_functions,
            "total_classes": report.total_classes,
            "total_constants": report.total_constants,
            "total_signals": report.total_signals,
            "unused_functions": len(report.unused_functions),
            "unused_classes": len(report.unused_classes),
            "unused_constants": len(report.unused_constants),
            "unused_signals": len(report.unused_signals),
            "orphan_files": len(report.orphan_files),
        },
        "unused_functions": [
            {"name": item.name, "file": item.file, "line": item.line}
            for item in report.unused_functions
        ],
        "unused_classes": [
            {"name": item.name, "file": item.file, "line": item.line}
            for item in report.unused_classes
        ],
        "unused_constants": [
            {"name": item.name, "file": item.file, "line": item.line}
            for item in report.unused_constants
        ],
        "unused_signals": [
            {"name": item.name, "file": item.file, "line": item.line}
            for item in report.unused_signals
        ],
        "orphan_files": report.orphan_files,
    }
    return json.dumps(data, indent=2)


def main():
    import argparse

    parser = argparse.ArgumentParser(description="Find potentially dead code")
    parser.add_argument("--json", "-j", action="store_true", help="JSON output")
    parser.add_argument("--verbose", "-v", action="store_true", help="Show usage details")
    parser.add_argument("--functions", action="store_true", help="Functions only")
    parser.add_argument("--classes", action="store_true", help="Classes only")
    parser.add_argument("--constants", action="store_true", help="Constants only")
    parser.add_argument("--signals", action="store_true", help="Signals only")
    parser.add_argument("--files", action="store_true", help="Orphan files only")
    args = parser.parse_args()

    report = analyze_codebase()

    # Filter if requested
    if args.functions:
        report.unused_classes = []
        report.unused_constants = []
        report.unused_signals = []
        report.orphan_files = []
    elif args.classes:
        report.unused_functions = []
        report.unused_constants = []
        report.unused_signals = []
        report.orphan_files = []
    elif args.constants:
        report.unused_functions = []
        report.unused_classes = []
        report.unused_signals = []
        report.orphan_files = []
    elif args.signals:
        report.unused_functions = []
        report.unused_classes = []
        report.unused_constants = []
        report.orphan_files = []
    elif args.files:
        report.unused_functions = []
        report.unused_classes = []
        report.unused_constants = []
        report.unused_signals = []

    if args.json:
        print(format_json(report))
    else:
        print(format_report(report, args.verbose))


if __name__ == "__main__":
    main()
