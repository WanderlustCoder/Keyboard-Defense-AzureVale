#!/usr/bin/env python3
"""
State Mutations Checker

Finds direct state mutations that may violate architecture:
- Direct GameState modifications outside sim layer
- State changes without going through intents
- Mutable state access patterns

Usage:
    python scripts/check_state_mutations.py              # Full report
    python scripts/check_state_mutations.py --file game/main.gd  # Single file
    python scripts/check_state_mutations.py --strict     # More patterns
    python scripts/check_state_mutations.py --json       # JSON output
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

# Known state fields that should only be modified in sim/
STATE_FIELDS = [
    "hp", "ap", "gold", "day", "phase", "resources",
    "enemies", "structures", "terrain", "cursor_pos",
    "map_w", "map_h", "threat", "wave", "combo",
    "lesson_id", "selected_tower", "buildings",
    "pending_events", "active_effects", "inventory"
]

# Patterns that indicate state mutation
MUTATION_PATTERNS = [
    r'state\.(\w+)\s*=',           # state.field =
    r'state\.(\w+)\s*\+=',         # state.field +=
    r'state\.(\w+)\s*-=',          # state.field -=
    r'state\.(\w+)\.append\s*\(',  # state.field.append(
    r'state\.(\w+)\.push',         # state.field.push
    r'state\.(\w+)\.pop',          # state.field.pop
    r'state\.(\w+)\.erase',        # state.field.erase
    r'state\.(\w+)\.clear',        # state.field.clear
    r'state\.(\w+)\[.+\]\s*=',     # state.field[x] =
]


@dataclass
class MutationIssue:
    """A state mutation issue."""
    file: str
    line: int
    layer: str
    field: str
    pattern: str
    severity: str  # "error", "warning", "info"
    context: str


@dataclass
class MutationReport:
    """State mutations report."""
    files_checked: int = 0
    total_mutations: int = 0
    violations: int = 0
    sim_mutations: int = 0
    game_mutations: int = 0
    ui_mutations: int = 0
    issues: List[MutationIssue] = field(default_factory=list)
    by_file: Dict[str, List[MutationIssue]] = field(default_factory=lambda: defaultdict(list))
    by_field: Dict[str, int] = field(default_factory=lambda: defaultdict(int))


def get_layer(rel_path: str) -> str:
    """Determine which layer a file belongs to."""
    if rel_path.startswith("sim/"):
        return "sim"
    elif rel_path.startswith("game/"):
        return "game"
    elif rel_path.startswith("ui/"):
        return "ui"
    elif rel_path.startswith("scripts/"):
        return "scripts"
    elif rel_path.startswith("tests/"):
        return "tests"
    else:
        return "other"


def analyze_file(file_path: Path, rel_path: str, strict: bool) -> List[MutationIssue]:
    """Analyze a file for state mutations."""
    issues = []
    layer = get_layer(rel_path)

    try:
        content = file_path.read_text(encoding='utf-8')
        lines = content.split('\n')
    except Exception:
        return issues

    for i, line in enumerate(lines):
        stripped = line.strip()

        # Skip comments
        if stripped.startswith('#'):
            continue

        code_part = line.split('#')[0]  # Remove inline comments

        # Check for state mutation patterns
        for pattern in MUTATION_PATTERNS:
            match = re.search(pattern, code_part)
            if match:
                field_name = match.group(1) if match.lastindex else "unknown"

                # Determine severity based on layer
                if layer == "sim":
                    severity = "info"  # Expected in sim layer
                elif layer == "tests":
                    severity = "info"  # Tests may need to set up state
                elif layer in ["game", "ui", "scripts"]:
                    severity = "error"  # Violation!
                else:
                    severity = "warning"

                # Only report violations (not sim-layer mutations)
                if severity != "info" or strict:
                    issues.append(MutationIssue(
                        file=rel_path,
                        line=i + 1,
                        layer=layer,
                        field=field_name,
                        pattern=pattern.replace('\\', ''),
                        severity=severity,
                        context=stripped[:60]
                    ))

        # Check for direct field assignment to known state fields
        for field in STATE_FIELDS:
            # More specific patterns
            if re.search(rf'\.{field}\s*=(?!=)', code_part):
                # Check if it's on a state variable
                if 'state.' in code_part.lower() or '_state.' in code_part:
                    if layer not in ["sim", "tests"]:
                        issues.append(MutationIssue(
                            file=rel_path,
                            line=i + 1,
                            layer=layer,
                            field=field,
                            pattern=f"direct assignment to .{field}",
                            severity="error",
                            context=stripped[:60]
                        ))

    return issues


def check_state_mutations(target_file: Optional[str] = None, strict: bool = False) -> MutationReport:
    """Check for state mutations across the project."""
    report = MutationReport()

    if target_file:
        gd_files = [PROJECT_ROOT / target_file]
    else:
        gd_files = list(PROJECT_ROOT.glob("**/*.gd"))

    for gd_file in gd_files:
        if ".godot" in str(gd_file) or "addons" in str(gd_file):
            continue

        if not gd_file.exists():
            continue

        rel_path = str(gd_file.relative_to(PROJECT_ROOT))
        layer = get_layer(rel_path)
        report.files_checked += 1

        issues = analyze_file(gd_file, rel_path, strict)

        for issue in issues:
            report.issues.append(issue)
            report.by_file[issue.file].append(issue)
            report.by_field[issue.field] += 1
            report.total_mutations += 1

            if issue.severity == "error":
                report.violations += 1

            if issue.layer == "sim":
                report.sim_mutations += 1
            elif issue.layer == "game":
                report.game_mutations += 1
            elif issue.layer == "ui":
                report.ui_mutations += 1

    return report


def format_report(report: MutationReport) -> str:
    """Format mutations report as text."""
    lines = []
    lines.append("=" * 60)
    lines.append("STATE MUTATIONS CHECKER - KEYBOARD DEFENSE")
    lines.append("=" * 60)
    lines.append("")

    # Summary
    lines.append("## SUMMARY")
    lines.append(f"  Files checked:      {report.files_checked}")
    lines.append(f"  Total mutations:    {report.total_mutations}")
    lines.append(f"  Violations:         {report.violations}")
    lines.append(f"  By layer:")
    lines.append(f"    sim/:             {report.sim_mutations} (expected)")
    lines.append(f"    game/:            {report.game_mutations}")
    lines.append(f"    ui/:              {report.ui_mutations}")
    lines.append("")

    # Violations (errors)
    violations = [i for i in report.issues if i.severity == "error"]
    if violations:
        lines.append("## ARCHITECTURE VIOLATIONS")
        lines.append("  (State should only be mutated in sim/ layer)")
        lines.append("")

        for issue in violations[:30]:
            lines.append(f"  [ERROR] {issue.file}:{issue.line}")
            lines.append(f"    Mutates '{issue.field}' from {issue.layer}/ layer")
            lines.append(f"    Context: {issue.context}")

        if len(violations) > 30:
            lines.append(f"  ... and {len(violations) - 30} more violations")
        lines.append("")

    # Most mutated fields
    if report.by_field:
        lines.append("## MOST MUTATED FIELDS")
        sorted_fields = sorted(report.by_field.items(), key=lambda x: -x[1])[:15]
        for field, count in sorted_fields:
            lines.append(f"  {field}: {count} mutations")
        lines.append("")

    # Files with most mutations
    if report.by_file:
        lines.append("## FILES WITH MOST STATE MUTATIONS")
        sorted_files = sorted(report.by_file.items(), key=lambda x: -len(x[1]))[:10]
        for file_path, issues in sorted_files:
            violation_count = sum(1 for i in issues if i.severity == "error")
            layer = get_layer(file_path)
            status = "" if layer == "sim" else f" [{violation_count} violations]" if violation_count else ""
            lines.append(f"  {file_path}: {len(issues)} mutations{status}")
        lines.append("")

    # Health indicators
    lines.append("## HEALTH INDICATORS")
    if report.violations == 0:
        lines.append("  [OK] No state mutation violations")
        lines.append("  [OK] All mutations properly in sim/ layer")
    else:
        lines.append(f"  [ERROR] {report.violations} state mutation violations")
        lines.append("  [ERROR] State being mutated outside sim/ layer")

    if report.game_mutations + report.ui_mutations > 0:
        lines.append(f"  [WARN] {report.game_mutations + report.ui_mutations} mutations in game/ui layers")

    lines.append("")
    return "\n".join(lines)


def format_json(report: MutationReport) -> str:
    """Format report as JSON."""
    data = {
        "summary": {
            "files_checked": report.files_checked,
            "total_mutations": report.total_mutations,
            "violations": report.violations,
            "sim_mutations": report.sim_mutations,
            "game_mutations": report.game_mutations,
            "ui_mutations": report.ui_mutations
        },
        "by_field": dict(report.by_field),
        "violations": [
            {
                "file": i.file,
                "line": i.line,
                "layer": i.layer,
                "field": i.field,
                "context": i.context
            }
            for i in report.issues if i.severity == "error"
        ][:50],
        "files_with_most_mutations": [
            {"file": f, "count": len(issues), "violations": sum(1 for i in issues if i.severity == "error")}
            for f, issues in sorted(report.by_file.items(), key=lambda x: -len(x[1]))[:20]
        ]
    }
    return json.dumps(data, indent=2)


def main():
    import argparse

    parser = argparse.ArgumentParser(description="Check state mutations")
    parser.add_argument("--json", "-j", action="store_true", help="JSON output")
    parser.add_argument("--file", "-f", type=str, help="Single file to check")
    parser.add_argument("--strict", "-s", action="store_true", help="Include sim-layer mutations")
    args = parser.parse_args()

    report = check_state_mutations(args.file, args.strict)

    if args.json:
        print(format_json(report))
    else:
        print(format_report(report))


if __name__ == "__main__":
    main()
