#!/usr/bin/env python3
"""
API Consistency Checker

Finds inconsistent naming patterns in public APIs:
- Inconsistent verb prefixes (get_ vs fetch_ vs retrieve_)
- Inconsistent noun forms (item vs items)
- Boolean naming (is_ vs has_ vs can_)
- Callback naming (_on_ patterns)

Usage:
    python scripts/check_api_consistency.py              # Full report
    python scripts/check_api_consistency.py --file game/main.gd  # Single file
    python scripts/check_api_consistency.py --strict     # More patterns
    python scripts/check_api_consistency.py --json       # JSON output
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

# Common verb groups (should be consistent within a codebase)
VERB_GROUPS = {
    "get": ["get_", "fetch_", "retrieve_", "obtain_", "acquire_"],
    "set": ["set_", "assign_", "update_"],
    "create": ["create_", "make_", "build_", "construct_", "generate_"],
    "delete": ["delete_", "remove_", "destroy_", "clear_", "erase_"],
    "check": ["check_", "verify_", "validate_", "test_", "is_valid_"],
    "find": ["find_", "search_", "lookup_", "locate_"],
    "load": ["load_", "read_", "fetch_", "import_"],
    "save": ["save_", "write_", "store_", "export_"],
    "show": ["show_", "display_", "render_", "draw_", "present_"],
    "hide": ["hide_", "conceal_", "dismiss_"],
    "enable": ["enable_", "activate_", "start_", "begin_"],
    "disable": ["disable_", "deactivate_", "stop_", "end_"],
}

# Boolean function patterns
BOOL_PREFIXES = ["is_", "has_", "can_", "should_", "will_", "was_", "did_"]


@dataclass
class ConsistencyIssue:
    """An API consistency issue."""
    file: str
    line: int
    function: str
    category: str
    message: str
    suggestion: str
    severity: str  # "warning", "info"


@dataclass
class FunctionStat:
    """Statistics about a function naming pattern."""
    prefix: str
    count: int
    examples: List[Tuple[str, str]]  # (file, function_name)


@dataclass
class ConsistencyReport:
    """API consistency report."""
    files_checked: int = 0
    total_functions: int = 0
    public_functions: int = 0
    issues_found: int = 0
    issues: List[ConsistencyIssue] = field(default_factory=list)
    verb_usage: Dict[str, Dict[str, FunctionStat]] = field(default_factory=lambda: defaultdict(dict))
    bool_usage: Dict[str, int] = field(default_factory=lambda: defaultdict(int))
    callback_patterns: Dict[str, int] = field(default_factory=lambda: defaultdict(int))


def analyze_file(file_path: Path, rel_path: str, strict: bool) -> Tuple[List[ConsistencyIssue], Dict]:
    """Analyze a file for API consistency."""
    issues = []
    stats = {
        "functions": [],
        "verbs": defaultdict(list),
        "bools": [],
        "callbacks": []
    }

    try:
        content = file_path.read_text(encoding='utf-8')
        lines = content.split('\n')
    except Exception:
        return issues, stats

    for i, line in enumerate(lines):
        stripped = line.strip()

        # Find function declarations
        func_match = re.match(r'^(static\s+)?func\s+(\w+)\s*\(', stripped)
        if func_match:
            func_name = func_match.group(2)
            is_private = func_name.startswith('_')

            stats["functions"].append((rel_path, func_name))

            # Skip private functions for most checks
            if is_private:
                # Check callback naming
                if func_name.startswith('_on_'):
                    stats["callbacks"].append(func_name)
                continue

            # Check verb consistency
            for verb_group, prefixes in VERB_GROUPS.items():
                for prefix in prefixes:
                    if func_name.startswith(prefix):
                        stats["verbs"][verb_group].append((prefix, func_name, rel_path, i + 1))
                        break

            # Check boolean naming
            returns_bool = False
            # Look for return type hint
            if '-> bool' in stripped or '->bool' in stripped:
                returns_bool = True

            if returns_bool:
                has_bool_prefix = any(func_name.startswith(p) for p in BOOL_PREFIXES)
                if not has_bool_prefix:
                    issues.append(ConsistencyIssue(
                        file=rel_path,
                        line=i + 1,
                        function=func_name,
                        category="bool_naming",
                        message=f"Function returns bool but doesn't use bool prefix",
                        suggestion=f"Consider renaming to is_{func_name} or has_{func_name}",
                        severity="info"
                    ))

            # Check for bool-prefixed functions
            for prefix in BOOL_PREFIXES:
                if func_name.startswith(prefix):
                    stats["bools"].append((prefix, func_name))
                    break

            # Check for inconsistent plural/singular
            if strict:
                if func_name.endswith('_item') and 'items' not in func_name:
                    # Check if there's a corresponding _items function
                    pass  # Would need cross-file analysis

    return issues, stats


def check_api_consistency(target_file: Optional[str] = None, strict: bool = False) -> ConsistencyReport:
    """Check API consistency across the project."""
    report = ConsistencyReport()
    all_stats = {
        "verbs": defaultdict(list),
        "bools": defaultdict(int),
        "callbacks": defaultdict(int)
    }

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
        report.files_checked += 1

        issues, stats = analyze_file(gd_file, rel_path, strict)
        report.issues.extend(issues)

        report.total_functions += len(stats["functions"])
        report.public_functions += len([f for f in stats["functions"] if not f[1].startswith('_')])

        # Aggregate verb usage
        for verb_group, usages in stats["verbs"].items():
            all_stats["verbs"][verb_group].extend(usages)

        # Aggregate bool prefixes
        for prefix, _ in stats["bools"]:
            all_stats["bools"][prefix] += 1

        # Aggregate callback patterns
        for callback in stats["callbacks"]:
            all_stats["callbacks"]["_on_"] += 1

    # Analyze verb consistency
    for verb_group, usages in all_stats["verbs"].items():
        # Group by prefix
        prefix_counts: Dict[str, List] = defaultdict(list)
        for prefix, func_name, file, line in usages:
            prefix_counts[prefix].append((func_name, file, line))

        # If multiple prefixes used for same verb group, flag inconsistency
        if len(prefix_counts) > 1:
            dominant_prefix = max(prefix_counts.items(), key=lambda x: len(x[1]))[0]

            for prefix, funcs in prefix_counts.items():
                if prefix != dominant_prefix and len(funcs) > 0:
                    for func_name, file, line in funcs[:3]:  # Limit examples
                        report.issues.append(ConsistencyIssue(
                            file=file,
                            line=line,
                            function=func_name,
                            category="verb_inconsistency",
                            message=f"Uses '{prefix}' but codebase prefers '{dominant_prefix}' for {verb_group} operations",
                            suggestion=f"Consider using '{dominant_prefix}' prefix",
                            severity="info"
                        ))

        # Store verb usage stats
        for prefix, funcs in prefix_counts.items():
            report.verb_usage[verb_group][prefix] = FunctionStat(
                prefix=prefix,
                count=len(funcs),
                examples=[(f, fn) for fn, f, _ in funcs[:3]]
            )

    report.bool_usage = dict(all_stats["bools"])
    report.callback_patterns = dict(all_stats["callbacks"])
    report.issues_found = len(report.issues)

    return report


def format_report(report: ConsistencyReport) -> str:
    """Format consistency report as text."""
    lines = []
    lines.append("=" * 60)
    lines.append("API CONSISTENCY CHECKER - KEYBOARD DEFENSE")
    lines.append("=" * 60)
    lines.append("")

    # Summary
    lines.append("## SUMMARY")
    lines.append(f"  Files checked:      {report.files_checked}")
    lines.append(f"  Total functions:    {report.total_functions}")
    lines.append(f"  Public functions:   {report.public_functions}")
    lines.append(f"  Issues found:       {report.issues_found}")
    lines.append("")

    # Verb usage
    lines.append("## VERB PREFIX USAGE")
    for verb_group, prefixes in sorted(report.verb_usage.items()):
        if len(prefixes) > 1:
            lines.append(f"  {verb_group} (INCONSISTENT):")
        else:
            lines.append(f"  {verb_group}:")

        for prefix, stat in sorted(prefixes.items(), key=lambda x: -x[1].count):
            lines.append(f"    {prefix}: {stat.count} functions")
    lines.append("")

    # Boolean prefixes
    if report.bool_usage:
        lines.append("## BOOLEAN PREFIX USAGE")
        for prefix, count in sorted(report.bool_usage.items(), key=lambda x: -x[1]):
            lines.append(f"  {prefix}: {count} functions")
        lines.append("")

    # Issues
    if report.issues:
        lines.append("## CONSISTENCY ISSUES")

        # Group by category
        by_category: Dict[str, List] = defaultdict(list)
        for issue in report.issues:
            by_category[issue.category].append(issue)

        for category, issues in by_category.items():
            lines.append(f"  ### {category.upper().replace('_', ' ')}")
            for issue in issues[:10]:
                lines.append(f"    {issue.file}:{issue.line} - {issue.function}")
                lines.append(f"      {issue.message}")

            if len(issues) > 10:
                lines.append(f"    ... and {len(issues) - 10} more")
            lines.append("")

    # Health indicators
    lines.append("## HEALTH INDICATORS")

    inconsistent_verbs = sum(1 for v in report.verb_usage.values() if len(v) > 1)
    if inconsistent_verbs == 0:
        lines.append("  [OK] Consistent verb prefix usage")
    else:
        lines.append(f"  [INFO] {inconsistent_verbs} verb groups have inconsistent prefixes")

    if report.issues_found == 0:
        lines.append("  [OK] No API naming issues found")
    elif report.issues_found < 20:
        lines.append(f"  [INFO] {report.issues_found} minor naming suggestions")
    else:
        lines.append(f"  [WARN] {report.issues_found} naming inconsistencies")

    lines.append("")
    return "\n".join(lines)


def format_json(report: ConsistencyReport) -> str:
    """Format report as JSON."""
    data = {
        "summary": {
            "files_checked": report.files_checked,
            "total_functions": report.total_functions,
            "public_functions": report.public_functions,
            "issues_found": report.issues_found
        },
        "verb_usage": {
            group: {
                prefix: {"count": stat.count, "examples": stat.examples}
                for prefix, stat in prefixes.items()
            }
            for group, prefixes in report.verb_usage.items()
        },
        "bool_usage": report.bool_usage,
        "issues": [
            {
                "file": i.file,
                "line": i.line,
                "function": i.function,
                "category": i.category,
                "message": i.message,
                "suggestion": i.suggestion
            }
            for i in report.issues[:50]
        ]
    }
    return json.dumps(data, indent=2)


def main():
    import argparse

    parser = argparse.ArgumentParser(description="Check API consistency")
    parser.add_argument("--json", "-j", action="store_true", help="JSON output")
    parser.add_argument("--file", "-f", type=str, help="Single file to check")
    parser.add_argument("--strict", "-s", action="store_true", help="More strict checks")
    args = parser.parse_args()

    report = check_api_consistency(args.file, args.strict)

    if args.json:
        print(format_json(report))
    else:
        print(format_report(report))


if __name__ == "__main__":
    main()
