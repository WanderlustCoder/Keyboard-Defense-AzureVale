#!/usr/bin/env python3
"""
TODO/FIXME Tracker

Finds and reports all TODO, FIXME, HACK, and XXX comments in the codebase:
- Categorizes by type and priority
- Groups by file and layer
- Tracks technical debt over time
- Exports for issue tracking

Usage:
    python scripts/track_todos.py              # Full report
    python scripts/track_todos.py --type TODO  # Only TODOs
    python scripts/track_todos.py --layer sim  # Only sim layer
    python scripts/track_todos.py --json       # JSON output
    python scripts/track_todos.py --markdown   # Markdown for issue tracking
"""

import json
import re
import sys
from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Set, Optional, Tuple

# Project paths
SCRIPT_DIR = Path(__file__).parent
PROJECT_ROOT = SCRIPT_DIR.parent

# Patterns for different comment types
TODO_PATTERNS = {
    "TODO": re.compile(r'#\s*TODO[:\s]*(.*)$', re.IGNORECASE),
    "FIXME": re.compile(r'#\s*FIXME[:\s]*(.*)$', re.IGNORECASE),
    "HACK": re.compile(r'#\s*HACK[:\s]*(.*)$', re.IGNORECASE),
    "XXX": re.compile(r'#\s*XXX[:\s]*(.*)$', re.IGNORECASE),
    "BUG": re.compile(r'#\s*BUG[:\s]*(.*)$', re.IGNORECASE),
    "NOTE": re.compile(r'#\s*NOTE[:\s]*(.*)$', re.IGNORECASE),
    "OPTIMIZE": re.compile(r'#\s*OPTIMIZE[:\s]*(.*)$', re.IGNORECASE),
    "REFACTOR": re.compile(r'#\s*REFACTOR[:\s]*(.*)$', re.IGNORECASE),
}

# Priority indicators
PRIORITY_PATTERNS = {
    "high": re.compile(r'\b(urgent|critical|important|asap|!+)\b', re.IGNORECASE),
    "low": re.compile(r'\b(later|eventually|someday|minor|maybe)\b', re.IGNORECASE),
}


@dataclass
class TodoItem:
    """A single TODO/FIXME item."""
    file: str
    line: int
    todo_type: str
    content: str
    priority: str = "normal"
    layer: str = ""
    context: str = ""  # Function/class containing the TODO


@dataclass
class TodoReport:
    """Report of all TODO items."""
    items: List[TodoItem] = field(default_factory=list)
    by_type: Dict[str, int] = field(default_factory=dict)
    by_layer: Dict[str, int] = field(default_factory=dict)
    by_priority: Dict[str, int] = field(default_factory=dict)
    by_file: Dict[str, int] = field(default_factory=dict)


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


def get_priority(content: str) -> str:
    """Determine priority from content."""
    if PRIORITY_PATTERNS["high"].search(content):
        return "high"
    if PRIORITY_PATTERNS["low"].search(content):
        return "low"
    return "normal"


def get_context(lines: List[str], line_idx: int) -> str:
    """Find the function/class containing this line."""
    # Look backwards for function or class definition
    for i in range(line_idx - 1, -1, -1):
        line = lines[i].strip()
        # Function
        match = re.match(r'^(?:static\s+)?func\s+(\w+)', line)
        if match:
            return f"func {match.group(1)}"
        # Class
        match = re.match(r'^class\s+(\w+)', line)
        if match:
            return f"class {match.group(1)}"
        # class_name
        match = re.match(r'^class_name\s+(\w+)', line)
        if match:
            return match.group(1)
    return ""


def scan_file(filepath: Path) -> List[TodoItem]:
    """Scan a file for TODO items."""
    items = []
    rel_path = str(filepath.relative_to(PROJECT_ROOT))
    layer = get_layer(rel_path)

    try:
        content = filepath.read_text(encoding="utf-8")
        lines = content.split('\n')
    except Exception:
        return items

    for i, line in enumerate(lines):
        for todo_type, pattern in TODO_PATTERNS.items():
            match = pattern.search(line)
            if match:
                todo_content = match.group(1).strip()
                if not todo_content:
                    # Try to get content from next line if this line is just the marker
                    if i + 1 < len(lines):
                        next_line = lines[i + 1].strip()
                        if next_line.startswith('#'):
                            todo_content = next_line[1:].strip()

                item = TodoItem(
                    file=rel_path,
                    line=i + 1,
                    todo_type=todo_type,
                    content=todo_content,
                    priority=get_priority(todo_content),
                    layer=layer,
                    context=get_context(lines, i)
                )
                items.append(item)
                break  # Only match one pattern per line

    return items


def scan_codebase(todo_type: Optional[str] = None, layer: Optional[str] = None) -> TodoReport:
    """Scan entire codebase for TODO items."""
    report = TodoReport()

    for gd_file in PROJECT_ROOT.glob("**/*.gd"):
        if ".godot" in str(gd_file) or "addons" in str(gd_file):
            continue

        items = scan_file(gd_file)

        for item in items:
            # Filter by type if specified
            if todo_type and item.todo_type.upper() != todo_type.upper():
                continue
            # Filter by layer if specified
            if layer and item.layer != layer:
                continue

            report.items.append(item)

            # Update counts
            report.by_type[item.todo_type] = report.by_type.get(item.todo_type, 0) + 1
            report.by_layer[item.layer] = report.by_layer.get(item.layer, 0) + 1
            report.by_priority[item.priority] = report.by_priority.get(item.priority, 0) + 1
            report.by_file[item.file] = report.by_file.get(item.file, 0) + 1

    # Sort items by priority then type
    priority_order = {"high": 0, "normal": 1, "low": 2}
    type_order = {"BUG": 0, "FIXME": 1, "TODO": 2, "HACK": 3, "OPTIMIZE": 4, "REFACTOR": 5, "XXX": 6, "NOTE": 7}
    report.items.sort(key=lambda x: (priority_order.get(x.priority, 1), type_order.get(x.todo_type, 5)))

    return report


def format_report(report: TodoReport) -> str:
    """Format TODO report as text."""
    lines = []
    lines.append("=" * 60)
    lines.append("TODO/FIXME TRACKER - KEYBOARD DEFENSE")
    lines.append("=" * 60)
    lines.append("")

    # Summary
    lines.append("## SUMMARY")
    lines.append(f"  Total items: {len(report.items)}")
    lines.append("")

    # By type
    lines.append("  By type:")
    for todo_type in ["BUG", "FIXME", "TODO", "HACK", "OPTIMIZE", "REFACTOR", "XXX", "NOTE"]:
        count = report.by_type.get(todo_type, 0)
        if count > 0:
            lines.append(f"    {todo_type:10} {count:4}")
    lines.append("")

    # By priority
    lines.append("  By priority:")
    for priority in ["high", "normal", "low"]:
        count = report.by_priority.get(priority, 0)
        if count > 0:
            lines.append(f"    {priority:10} {count:4}")
    lines.append("")

    # By layer
    lines.append("  By layer:")
    for layer in ["sim", "game", "ui", "scripts", "tests", "tools", "other"]:
        count = report.by_layer.get(layer, 0)
        if count > 0:
            lines.append(f"    {layer:10} {count:4}")
    lines.append("")

    if not report.items:
        lines.append("No TODO/FIXME items found!")
        return "\n".join(lines)

    # High priority items
    high_priority = [i for i in report.items if i.priority == "high"]
    if high_priority:
        lines.append("## HIGH PRIORITY")
        for item in high_priority:
            lines.append(f"  [{item.todo_type}] {item.file}:{item.line}")
            lines.append(f"    {item.content[:70]}")
            if item.context:
                lines.append(f"    in {item.context}")
        lines.append("")

    # Bugs and FIXMEs
    bugs_fixes = [i for i in report.items if i.todo_type in ["BUG", "FIXME"] and i.priority != "high"]
    if bugs_fixes:
        lines.append("## BUGS & FIXMES")
        for item in bugs_fixes[:20]:
            lines.append(f"  [{item.todo_type}] {item.file}:{item.line}")
            lines.append(f"    {item.content[:70]}")
        if len(bugs_fixes) > 20:
            lines.append(f"  ... and {len(bugs_fixes) - 20} more")
        lines.append("")

    # Regular TODOs
    todos = [i for i in report.items if i.todo_type == "TODO" and i.priority == "normal"]
    if todos:
        lines.append("## TODOs")
        for item in todos[:20]:
            lines.append(f"  {item.file}:{item.line}")
            lines.append(f"    {item.content[:70]}")
        if len(todos) > 20:
            lines.append(f"  ... and {len(todos) - 20} more")
        lines.append("")

    # Files with most items
    lines.append("## FILES WITH MOST ITEMS")
    sorted_files = sorted(report.by_file.items(), key=lambda x: -x[1])
    for filepath, count in sorted_files[:10]:
        lines.append(f"  {count:4} items  {filepath}")
    lines.append("")

    # Health indicators
    lines.append("## HEALTH INDICATORS")
    bug_count = report.by_type.get("BUG", 0) + report.by_type.get("FIXME", 0)
    if bug_count > 10:
        lines.append(f"  [WARN] Many bugs/fixmes: {bug_count}")
    else:
        lines.append(f"  [OK] Bugs/fixmes: {bug_count}")

    high_count = report.by_priority.get("high", 0)
    if high_count > 0:
        lines.append(f"  [WARN] High priority items: {high_count}")
    else:
        lines.append("  [OK] No high priority items")

    hack_count = report.by_type.get("HACK", 0)
    if hack_count > 5:
        lines.append(f"  [INFO] Technical debt (HACKs): {hack_count}")

    lines.append("")
    return "\n".join(lines)


def format_markdown(report: TodoReport) -> str:
    """Format as Markdown for issue tracking."""
    lines = []
    lines.append("# Technical Debt Report")
    lines.append("")
    lines.append(f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M')}")
    lines.append("")

    # Summary table
    lines.append("## Summary")
    lines.append("")
    lines.append("| Type | Count |")
    lines.append("|------|-------|")
    for todo_type, count in sorted(report.by_type.items(), key=lambda x: -x[1]):
        lines.append(f"| {todo_type} | {count} |")
    lines.append("")

    # High priority section
    high_priority = [i for i in report.items if i.priority == "high"]
    if high_priority:
        lines.append("## 🔴 High Priority")
        lines.append("")
        for item in high_priority:
            lines.append(f"- [ ] **[{item.todo_type}]** `{item.file}:{item.line}`")
            lines.append(f"  - {item.content}")
            if item.context:
                lines.append(f"  - Context: `{item.context}`")
        lines.append("")

    # Bugs
    bugs = [i for i in report.items if i.todo_type in ["BUG", "FIXME"]]
    if bugs:
        lines.append("## 🐛 Bugs & Fixes")
        lines.append("")
        for item in bugs[:30]:
            priority_mark = "🔴 " if item.priority == "high" else ""
            lines.append(f"- [ ] {priority_mark}**[{item.todo_type}]** `{item.file}:{item.line}`")
            lines.append(f"  - {item.content}")
        if len(bugs) > 30:
            lines.append(f"\n*... and {len(bugs) - 30} more*")
        lines.append("")

    # TODOs by layer
    for layer in ["sim", "game", "ui"]:
        layer_items = [i for i in report.items if i.layer == layer and i.todo_type == "TODO"]
        if layer_items:
            lines.append(f"## 📋 {layer.upper()} Layer TODOs")
            lines.append("")
            for item in layer_items[:20]:
                lines.append(f"- [ ] `{item.file}:{item.line}` - {item.content[:60]}")
            if len(layer_items) > 20:
                lines.append(f"\n*... and {len(layer_items) - 20} more*")
            lines.append("")

    return "\n".join(lines)


def format_json(report: TodoReport) -> str:
    """Format as JSON."""
    data = {
        "generated": datetime.now().isoformat(),
        "summary": {
            "total": len(report.items),
            "by_type": report.by_type,
            "by_layer": report.by_layer,
            "by_priority": report.by_priority,
        },
        "items": [
            {
                "file": item.file,
                "line": item.line,
                "type": item.todo_type,
                "content": item.content,
                "priority": item.priority,
                "layer": item.layer,
                "context": item.context,
            }
            for item in report.items
        ],
    }
    return json.dumps(data, indent=2)


def main():
    import argparse

    parser = argparse.ArgumentParser(description="Track TODO/FIXME comments")
    parser.add_argument("--json", "-j", action="store_true", help="JSON output")
    parser.add_argument("--markdown", "-m", action="store_true", help="Markdown output")
    parser.add_argument("--type", "-t", type=str, help="Filter by type (TODO, FIXME, etc)")
    parser.add_argument("--layer", "-l", type=str, help="Filter by layer")
    args = parser.parse_args()

    report = scan_codebase(args.type, args.layer)

    if args.json:
        print(format_json(report))
    elif args.markdown:
        print(format_markdown(report))
    else:
        print(format_report(report))


if __name__ == "__main__":
    main()
