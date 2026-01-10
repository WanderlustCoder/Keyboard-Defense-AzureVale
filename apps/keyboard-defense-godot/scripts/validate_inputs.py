#!/usr/bin/env python3
"""
Input Action Validator

Validates input actions and their usage:
- Lists all input actions from project.godot
- Finds input action usage in code
- Detects undefined actions used in code
- Reports unused actions

Usage:
    python scripts/validate_inputs.py              # Full report
    python scripts/validate_inputs.py --undefined  # Show only undefined
    python scripts/validate_inputs.py --unused     # Show only unused
    python scripts/validate_inputs.py --json       # JSON output
"""

import json
import re
import sys
from dataclasses import dataclass, field
from pathlib import Path
from typing import Dict, List, Set, Optional, Tuple
from collections import defaultdict

# Project paths
SCRIPT_DIR = Path(__file__).parent
PROJECT_ROOT = SCRIPT_DIR.parent


@dataclass
class InputAction:
    """An input action."""
    name: str
    events: List[str] = field(default_factory=list)
    deadzone: float = 0.5
    used_in: List[Tuple[str, int]] = field(default_factory=list)
    usage_count: int = 0


@dataclass
class InputReference:
    """A reference to an input action in code."""
    action_name: str
    file: str
    line: int
    context: str


@dataclass
class InputReport:
    """Input action validation report."""
    defined_actions: Dict[str, InputAction] = field(default_factory=dict)
    used_actions: Dict[str, List[InputReference]] = field(default_factory=lambda: defaultdict(list))
    undefined_refs: List[InputReference] = field(default_factory=list)
    unused_actions: List[str] = field(default_factory=list)
    issues: List[str] = field(default_factory=list)


def parse_input_map() -> Dict[str, InputAction]:
    """Parse input actions from project.godot."""
    actions = {}
    project_file = PROJECT_ROOT / "project.godot"

    if not project_file.exists():
        return actions

    try:
        content = project_file.read_text(encoding="utf-8")
    except Exception:
        return actions

    # Find [input] section
    in_input = False
    current_action = None

    for line in content.split('\n'):
        stripped = line.strip()

        if stripped == "[input]":
            in_input = True
            continue
        elif stripped.startswith("[") and in_input:
            break

        if in_input:
            # Action definition: action_name={...}
            action_match = re.match(r'^(\w+)\s*=\s*\{', stripped)
            if action_match:
                action_name = action_match.group(1)
                actions[action_name] = InputAction(name=action_name)
                current_action = action_name

            # Deadzone
            if current_action and "deadzone" in stripped:
                dz_match = re.search(r'"deadzone":\s*([\d.]+)', stripped)
                if dz_match:
                    actions[current_action].deadzone = float(dz_match.group(1))

            # Events (keys, buttons, etc.)
            if current_action and "events" in stripped:
                # Extract key codes or button references
                key_matches = re.findall(r'InputEventKey[^}]+keycode=(\d+)', stripped)
                for keycode in key_matches:
                    actions[current_action].events.append(f"Key:{keycode}")

                # Mouse buttons
                mouse_matches = re.findall(r'InputEventMouseButton[^}]+button_index=(\d+)', stripped)
                for btn in mouse_matches:
                    actions[current_action].events.append(f"Mouse:{btn}")

                # Joypad buttons
                joy_matches = re.findall(r'InputEventJoypadButton[^}]+button_index=(\d+)', stripped)
                for btn in joy_matches:
                    actions[current_action].events.append(f"Joy:{btn}")

    return actions


def find_input_usage() -> Dict[str, List[InputReference]]:
    """Find all input action references in code."""
    usage = defaultdict(list)

    # Patterns for input action usage
    patterns = [
        r'Input\.is_action_pressed\s*\(\s*["\']([^"\']+)["\']',
        r'Input\.is_action_just_pressed\s*\(\s*["\']([^"\']+)["\']',
        r'Input\.is_action_just_released\s*\(\s*["\']([^"\']+)["\']',
        r'Input\.get_action_strength\s*\(\s*["\']([^"\']+)["\']',
        r'Input\.get_action_raw_strength\s*\(\s*["\']([^"\']+)["\']',
        r'Input\.is_action\s*\(\s*["\']([^"\']+)["\']',
        r'event\.is_action\s*\(\s*["\']([^"\']+)["\']',
        r'event\.is_action_pressed\s*\(\s*["\']([^"\']+)["\']',
        r'event\.is_action_released\s*\(\s*["\']([^"\']+)["\']',
        r'InputMap\.has_action\s*\(\s*["\']([^"\']+)["\']',
        r'InputMap\.action_get_events\s*\(\s*["\']([^"\']+)["\']',
    ]

    for gd_file in PROJECT_ROOT.glob("**/*.gd"):
        if ".godot" in str(gd_file) or "addons" in str(gd_file):
            continue

        rel_path = str(gd_file.relative_to(PROJECT_ROOT))

        try:
            content = gd_file.read_text(encoding="utf-8")
            lines = content.split('\n')
        except Exception:
            continue

        for i, line in enumerate(lines):
            for pattern in patterns:
                matches = re.findall(pattern, line)
                for action_name in matches:
                    usage[action_name].append(InputReference(
                        action_name=action_name,
                        file=rel_path,
                        line=i + 1,
                        context=line.strip()[:60]
                    ))

    return usage


def validate_inputs() -> InputReport:
    """Validate input actions."""
    report = InputReport()

    # Parse defined actions
    report.defined_actions = parse_input_map()

    # Find usage
    report.used_actions = find_input_usage()

    # Cross-reference
    defined_names = set(report.defined_actions.keys())

    # Find undefined references
    for action_name, refs in report.used_actions.items():
        if action_name not in defined_names:
            # Check if it's a built-in action
            builtin = action_name.startswith("ui_") or action_name in [
                "ui_accept", "ui_cancel", "ui_select", "ui_focus_next",
                "ui_focus_prev", "ui_left", "ui_right", "ui_up", "ui_down",
                "ui_page_up", "ui_page_down", "ui_home", "ui_end", "ui_cut",
                "ui_copy", "ui_paste", "ui_undo", "ui_redo", "ui_text_completion_query"
            ]

            if not builtin:
                report.undefined_refs.extend(refs)
                report.issues.append(f"Undefined action '{action_name}' used {len(refs)} times")

    # Find unused actions
    for action_name in report.defined_actions:
        if action_name not in report.used_actions:
            report.unused_actions.append(action_name)

    # Update usage counts
    for action_name, action in report.defined_actions.items():
        if action_name in report.used_actions:
            refs = report.used_actions[action_name]
            action.usage_count = len(refs)
            action.used_in = [(r.file, r.line) for r in refs]

    return report


def format_report(report: InputReport, show_undefined: bool = False, show_unused: bool = False) -> str:
    """Format input report as text."""
    lines = []
    lines.append("=" * 60)
    lines.append("INPUT ACTION VALIDATOR - KEYBOARD DEFENSE")
    lines.append("=" * 60)
    lines.append("")

    # Summary
    lines.append("## SUMMARY")
    lines.append(f"  Defined actions:     {len(report.defined_actions)}")
    lines.append(f"  Used actions:        {len(report.used_actions)}")
    lines.append(f"  Undefined refs:      {len(report.undefined_refs)}")
    lines.append(f"  Unused actions:      {len(report.unused_actions)}")
    lines.append("")

    if show_undefined and report.undefined_refs:
        lines.append("## UNDEFINED ACTION REFERENCES")
        for ref in report.undefined_refs:
            lines.append(f"  {ref.file}:{ref.line}")
            lines.append(f"    '{ref.action_name}' in: {ref.context}")
        lines.append("")
        return "\n".join(lines)

    if show_unused and report.unused_actions:
        lines.append("## UNUSED ACTIONS")
        for action_name in report.unused_actions:
            action = report.defined_actions[action_name]
            events = ", ".join(action.events[:3]) if action.events else "no events"
            lines.append(f"  {action_name}")
            lines.append(f"    Events: {events}")
        lines.append("")
        return "\n".join(lines)

    # Defined actions
    lines.append("## DEFINED ACTIONS")
    for name, action in sorted(report.defined_actions.items()):
        status = "✓" if action.usage_count > 0 else "!"
        events = ", ".join(action.events[:2]) if action.events else "none"
        lines.append(f"  [{status}] {name}")
        lines.append(f"      Events: {events}")
        lines.append(f"      Used: {action.usage_count} times")
    lines.append("")

    # Undefined references
    if report.undefined_refs:
        lines.append("## UNDEFINED ACTION REFERENCES")
        shown = {}
        for ref in report.undefined_refs:
            if ref.action_name not in shown:
                shown[ref.action_name] = 0
            if shown[ref.action_name] < 2:
                lines.append(f"  '{ref.action_name}' at {ref.file}:{ref.line}")
                shown[ref.action_name] += 1
        total_undefined = len(set(r.action_name for r in report.undefined_refs))
        lines.append(f"  ... {total_undefined} unique undefined actions")
        lines.append("")

    # Unused actions
    if report.unused_actions:
        lines.append("## UNUSED ACTIONS")
        for name in report.unused_actions[:10]:
            lines.append(f"  - {name}")
        if len(report.unused_actions) > 10:
            lines.append(f"  ... and {len(report.unused_actions) - 10} more")
        lines.append("")

    # Issues
    if report.issues:
        lines.append("## ISSUES")
        for issue in report.issues[:10]:
            lines.append(f"  [!] {issue}")
        if len(report.issues) > 10:
            lines.append(f"  ... and {len(report.issues) - 10} more")
        lines.append("")

    # Health indicators
    lines.append("## HEALTH INDICATORS")
    if not report.undefined_refs:
        lines.append("  [OK] All input actions are defined")
    else:
        lines.append(f"  [ERROR] {len(report.undefined_refs)} references to undefined actions")

    if not report.unused_actions:
        lines.append("  [OK] All defined actions are used")
    else:
        lines.append(f"  [INFO] {len(report.unused_actions)} unused actions")

    lines.append("")
    return "\n".join(lines)


def format_json(report: InputReport) -> str:
    """Format report as JSON."""
    data = {
        "summary": {
            "defined": len(report.defined_actions),
            "used": len(report.used_actions),
            "undefined_refs": len(report.undefined_refs),
            "unused": len(report.unused_actions)
        },
        "defined_actions": {
            name: {
                "events": action.events,
                "usage_count": action.usage_count,
                "used_in_files": len(action.used_in)
            }
            for name, action in report.defined_actions.items()
        },
        "undefined_references": [
            {
                "action": ref.action_name,
                "file": ref.file,
                "line": ref.line
            }
            for ref in report.undefined_refs
        ],
        "unused_actions": report.unused_actions,
        "issues": report.issues
    }
    return json.dumps(data, indent=2)


def main():
    import argparse

    parser = argparse.ArgumentParser(description="Validate input actions")
    parser.add_argument("--json", "-j", action="store_true", help="JSON output")
    parser.add_argument("--undefined", "-u", action="store_true", help="Show only undefined")
    parser.add_argument("--unused", action="store_true", help="Show only unused")
    args = parser.parse_args()

    report = validate_inputs()

    if args.json:
        print(format_json(report))
    else:
        print(format_report(report, args.undefined, args.unused))


if __name__ == "__main__":
    main()
