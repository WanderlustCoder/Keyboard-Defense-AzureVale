#!/usr/bin/env python3
"""
Naming Convention Checker

Checks GDScript code against naming conventions:
- snake_case for functions, variables, signals
- PascalCase for classes, class_name
- SCREAMING_SNAKE_CASE for constants
- _prefixed for private members
- Consistent naming patterns

Usage:
    python scripts/check_naming.py              # Full report
    python scripts/check_naming.py --file game/main.gd  # Single file
    python scripts/check_naming.py --strict     # Stricter checks
    python scripts/check_naming.py --json       # JSON output
"""

import json
import re
import sys
from dataclasses import dataclass, field
from pathlib import Path
from typing import Dict, List, Set, Tuple, Optional

# Project paths
SCRIPT_DIR = Path(__file__).parent
PROJECT_ROOT = SCRIPT_DIR.parent


@dataclass
class NamingViolation:
    """A naming convention violation."""
    file: str
    line: int
    name: str
    kind: str  # "function", "variable", "constant", "class", "signal"
    expected: str  # What convention it should follow
    message: str


@dataclass
class FileReport:
    """Naming analysis for a file."""
    path: str
    violations: List[NamingViolation] = field(default_factory=list)
    stats: Dict[str, int] = field(default_factory=dict)


# Naming patterns
def is_snake_case(name: str) -> bool:
    """Check if name is snake_case."""
    if name.startswith('_'):
        name = name[1:]
    return bool(re.match(r'^[a-z][a-z0-9]*(_[a-z0-9]+)*$', name))


def is_screaming_snake(name: str) -> bool:
    """Check if name is SCREAMING_SNAKE_CASE."""
    return bool(re.match(r'^[A-Z][A-Z0-9]*(_[A-Z0-9]+)*$', name))


def is_pascal_case(name: str) -> bool:
    """Check if name is PascalCase."""
    return bool(re.match(r'^[A-Z][a-zA-Z0-9]*$', name))


def suggest_snake_case(name: str) -> str:
    """Convert name to snake_case suggestion."""
    # Handle PascalCase
    s1 = re.sub('(.)([A-Z][a-z]+)', r'\1_\2', name)
    s2 = re.sub('([a-z0-9])([A-Z])', r'\1_\2', s1)
    return s2.lower()


def suggest_pascal_case(name: str) -> str:
    """Convert name to PascalCase suggestion."""
    parts = name.split('_')
    return ''.join(p.capitalize() for p in parts)


def suggest_screaming_snake(name: str) -> str:
    """Convert name to SCREAMING_SNAKE_CASE suggestion."""
    s1 = re.sub('(.)([A-Z][a-z]+)', r'\1_\2', name)
    s2 = re.sub('([a-z0-9])([A-Z])', r'\1_\2', s1)
    return s2.upper()


# Known exceptions (built-in names, common patterns)
EXCEPTIONS = {
    # Godot lifecycle methods
    '_ready', '_process', '_physics_process', '_input', '_unhandled_input',
    '_draw', '_enter_tree', '_exit_tree', '_notification', '_init',
    '_get', '_set', '_get_property_list', '_to_string',
    # Common abbreviations that look like violations
    'x', 'y', 'z', 'w', 'i', 'j', 'k', 'n', 'id', 'hp', 'mp', 'ap',
    'ui', 'io', 'db', 'ok', 'PI', 'TAU',
}


def analyze_file(filepath: Path, strict: bool = False) -> FileReport:
    """Analyze naming conventions in a file."""
    rel_path = str(filepath.relative_to(PROJECT_ROOT))
    report = FileReport(path=rel_path)
    report.stats = {
        "functions": 0, "variables": 0, "constants": 0,
        "classes": 0, "signals": 0, "violations": 0
    }

    try:
        content = filepath.read_text(encoding="utf-8")
        lines = content.split('\n')
    except Exception:
        return report

    for i, line in enumerate(lines):
        line_num = i + 1
        stripped = line.strip()

        # Skip comments and empty lines
        if not stripped or stripped.startswith('#'):
            continue

        # Check class_name
        match = re.match(r'^class_name\s+(\w+)', stripped)
        if match:
            name = match.group(1)
            report.stats["classes"] += 1
            if not is_pascal_case(name):
                report.violations.append(NamingViolation(
                    file=rel_path, line=line_num, name=name, kind="class_name",
                    expected="PascalCase",
                    message=f"class_name '{name}' should be PascalCase: '{suggest_pascal_case(name)}'"
                ))
            continue

        # Check inner class
        match = re.match(r'^class\s+(\w+)', stripped)
        if match:
            name = match.group(1)
            report.stats["classes"] += 1
            if not is_pascal_case(name):
                report.violations.append(NamingViolation(
                    file=rel_path, line=line_num, name=name, kind="class",
                    expected="PascalCase",
                    message=f"class '{name}' should be PascalCase: '{suggest_pascal_case(name)}'"
                ))
            continue

        # Check constants
        match = re.match(r'^const\s+(\w+)\s*[:=]', stripped)
        if match:
            name = match.group(1)
            report.stats["constants"] += 1
            if name not in EXCEPTIONS and not is_screaming_snake(name):
                # Allow PascalCase for preloaded scenes/classes
                if 'preload' not in stripped and not is_pascal_case(name):
                    report.violations.append(NamingViolation(
                        file=rel_path, line=line_num, name=name, kind="constant",
                        expected="SCREAMING_SNAKE_CASE",
                        message=f"const '{name}' should be SCREAMING_SNAKE_CASE: '{suggest_screaming_snake(name)}'"
                    ))
            continue

        # Check signals
        match = re.match(r'^signal\s+(\w+)', stripped)
        if match:
            name = match.group(1)
            report.stats["signals"] += 1
            if name not in EXCEPTIONS and not is_snake_case(name):
                report.violations.append(NamingViolation(
                    file=rel_path, line=line_num, name=name, kind="signal",
                    expected="snake_case",
                    message=f"signal '{name}' should be snake_case: '{suggest_snake_case(name)}'"
                ))
            continue

        # Check functions
        match = re.match(r'^(?:static\s+)?func\s+(\w+)\s*\(', stripped)
        if match:
            name = match.group(1)
            report.stats["functions"] += 1
            if name not in EXCEPTIONS and not is_snake_case(name):
                report.violations.append(NamingViolation(
                    file=rel_path, line=line_num, name=name, kind="function",
                    expected="snake_case",
                    message=f"function '{name}' should be snake_case: '{suggest_snake_case(name)}'"
                ))
            continue

        # Check variables (var, @export, @onready)
        match = re.match(r'^(?:@\w+\s+)*var\s+(\w+)\s*[:=]?', stripped)
        if match:
            name = match.group(1)
            report.stats["variables"] += 1
            if name not in EXCEPTIONS and not is_snake_case(name):
                # Allow _prefixed private vars
                if not name.startswith('_') or not is_snake_case(name[1:]):
                    report.violations.append(NamingViolation(
                        file=rel_path, line=line_num, name=name, kind="variable",
                        expected="snake_case",
                        message=f"variable '{name}' should be snake_case: '{suggest_snake_case(name)}'"
                    ))
            continue

        # Check enum values (strict mode only)
        if strict:
            match = re.match(r'^enum\s+(\w+)', stripped)
            if match:
                name = match.group(1)
                if not is_pascal_case(name):
                    report.violations.append(NamingViolation(
                        file=rel_path, line=line_num, name=name, kind="enum",
                        expected="PascalCase",
                        message=f"enum '{name}' should be PascalCase: '{suggest_pascal_case(name)}'"
                    ))

    report.stats["violations"] = len(report.violations)
    return report


def analyze_codebase(target_file: Optional[str] = None, strict: bool = False) -> List[FileReport]:
    """Analyze all GDScript files."""
    results = []

    if target_file:
        filepath = PROJECT_ROOT / target_file
        if filepath.exists():
            results.append(analyze_file(filepath, strict))
        return results

    for gd_file in PROJECT_ROOT.glob("**/*.gd"):
        if ".godot" in str(gd_file) or "addons" in str(gd_file):
            continue
        report = analyze_file(gd_file, strict)
        results.append(report)

    return results


def format_report(results: List[FileReport]) -> str:
    """Format naming convention report."""
    lines = []
    lines.append("=" * 60)
    lines.append("NAMING CONVENTION CHECKER - KEYBOARD DEFENSE")
    lines.append("=" * 60)
    lines.append("")

    # Summary
    total_violations = sum(len(r.violations) for r in results)
    files_with_violations = sum(1 for r in results if r.violations)

    total_items = sum(
        r.stats.get("functions", 0) + r.stats.get("variables", 0) +
        r.stats.get("constants", 0) + r.stats.get("classes", 0) +
        r.stats.get("signals", 0)
        for r in results
    )

    lines.append("## SUMMARY")
    lines.append(f"  Files analyzed: {len(results)}")
    lines.append(f"  Total identifiers: {total_items}")
    lines.append(f"  Violations found: {total_violations}")
    lines.append(f"  Files with violations: {files_with_violations}")
    lines.append("")

    # Conventions reference
    lines.append("## CONVENTIONS")
    lines.append("  Functions:  snake_case     (e.g., get_player_health)")
    lines.append("  Variables:  snake_case     (e.g., player_health)")
    lines.append("  Constants:  SCREAMING_SNAKE (e.g., MAX_HEALTH)")
    lines.append("  Classes:    PascalCase     (e.g., PlayerController)")
    lines.append("  Signals:    snake_case     (e.g., health_changed)")
    lines.append("  Private:    _prefixed      (e.g., _internal_state)")
    lines.append("")

    if total_violations == 0:
        lines.append("No naming convention violations found!")
        return "\n".join(lines)

    # Group violations by type
    by_kind: Dict[str, List[NamingViolation]] = {}
    for report in results:
        for v in report.violations:
            if v.kind not in by_kind:
                by_kind[v.kind] = []
            by_kind[v.kind].append(v)

    # Show violations by type
    for kind in ["class", "class_name", "constant", "function", "variable", "signal"]:
        if kind in by_kind:
            violations = by_kind[kind]
            lines.append(f"## {kind.upper()} VIOLATIONS ({len(violations)})")
            for v in violations[:20]:
                lines.append(f"  {v.file}:{v.line}")
                lines.append(f"    {v.message}")
            if len(violations) > 20:
                lines.append(f"  ... and {len(violations) - 20} more")
            lines.append("")

    # Files with most violations
    lines.append("## FILES WITH MOST VIOLATIONS")
    by_file = sorted(results, key=lambda r: len(r.violations), reverse=True)
    for report in by_file[:10]:
        if report.violations:
            lines.append(f"  {len(report.violations):4} violations  {report.path}")
    lines.append("")

    # Health indicators
    lines.append("## HEALTH INDICATORS")
    violation_rate = total_violations * 100 // max(total_items, 1)
    if violation_rate > 10:
        lines.append(f"  [WARN] High violation rate: {violation_rate}%")
    elif violation_rate > 5:
        lines.append(f"  [INFO] Moderate violation rate: {violation_rate}%")
    else:
        lines.append(f"  [OK] Low violation rate: {violation_rate}%")

    lines.append("")
    return "\n".join(lines)


def format_json(results: List[FileReport]) -> str:
    """Format as JSON."""
    data = {
        "summary": {
            "files_analyzed": len(results),
            "total_violations": sum(len(r.violations) for r in results),
            "files_with_violations": sum(1 for r in results if r.violations),
        },
        "by_kind": {},
        "files": [],
    }

    # Group by kind
    by_kind: Dict[str, int] = {}
    for report in results:
        for v in report.violations:
            by_kind[v.kind] = by_kind.get(v.kind, 0) + 1
    data["by_kind"] = by_kind

    # File details
    for report in results:
        if report.violations:
            file_data = {
                "path": report.path,
                "violations": [
                    {
                        "line": v.line,
                        "name": v.name,
                        "kind": v.kind,
                        "expected": v.expected,
                        "message": v.message,
                    }
                    for v in report.violations
                ],
                "stats": report.stats,
            }
            data["files"].append(file_data)

    return json.dumps(data, indent=2)


def main():
    import argparse

    parser = argparse.ArgumentParser(description="Check naming conventions")
    parser.add_argument("--json", "-j", action="store_true", help="JSON output")
    parser.add_argument("--file", "-f", type=str, help="Check single file")
    parser.add_argument("--strict", action="store_true", help="Stricter checks")
    args = parser.parse_args()

    results = analyze_codebase(args.file, args.strict)

    if args.json:
        print(format_json(results))
    else:
        print(format_report(results))


if __name__ == "__main__":
    main()
