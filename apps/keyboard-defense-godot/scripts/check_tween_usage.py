#!/usr/bin/env python3
"""
Tween Usage Checker

Finds issues with tween usage patterns:
- Tweens without kill() cleanup
- Tweens created in _process (expensive)
- Tween chains that might be interrupted
- Missing tween references (can't be stopped)

Usage:
    python scripts/check_tween_usage.py              # Full report
    python scripts/check_tween_usage.py --file game/main.gd  # Single file
    python scripts/check_tween_usage.py --strict     # More patterns
    python scripts/check_tween_usage.py --json       # JSON output
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


@dataclass
class TweenIssue:
    """A tween usage issue."""
    file: str
    line: int
    code: str
    issue_type: str
    message: str
    severity: str  # "error", "warning", "info"


@dataclass
class TweenReport:
    """Tween usage report."""
    files_checked: int = 0
    total_tweens: int = 0
    stored_tweens: int = 0
    unstored_tweens: int = 0
    tween_kills: int = 0
    issues: List[TweenIssue] = field(default_factory=list)
    by_file: Dict[str, List[TweenIssue]] = field(default_factory=lambda: defaultdict(list))
    patterns: Dict[str, int] = field(default_factory=lambda: defaultdict(int))


def analyze_tweens(file_path: Path, rel_path: str, strict: bool) -> Tuple[Dict[str, int], List[TweenIssue]]:
    """Analyze tween usage patterns in a file."""
    issues = []
    patterns = defaultdict(int)

    try:
        content = file_path.read_text(encoding='utf-8')
        lines = content.split('\n')
    except Exception:
        return patterns, issues

    # Track tween variables
    tween_vars: Set[str] = set()
    has_exit_tree = '_exit_tree' in content
    has_queue_free = 'queue_free' in content

    current_func = None
    hot_funcs = {'_process', '_physics_process', '_input', '_unhandled_input'}

    for i, line in enumerate(lines):
        stripped = line.strip()

        # Skip comments
        if stripped.startswith('#'):
            continue

        # Track current function
        func_match = re.match(r'^func\s+(\w+)', stripped)
        if func_match:
            current_func = func_match.group(1)

        # Find create_tween() calls
        create_tween = re.search(r'create_tween\s*\(', line)
        if create_tween:
            patterns["create_tween"] += 1

            # Check if stored in variable
            var_match = re.match(r'(?:var\s+)?(\w+)\s*=.*create_tween', stripped)
            if var_match:
                tween_vars.add(var_match.group(1))
                patterns["stored_tween"] += 1
            else:
                # Tween not stored - might be intentional for fire-and-forget
                patterns["unstored_tween"] += 1
                if strict:
                    issues.append(TweenIssue(
                        file=rel_path,
                        line=i + 1,
                        code=stripped[:60],
                        issue_type="unstored_tween",
                        message="Tween not stored in variable - cannot be stopped/killed",
                        severity="info"
                    ))

            # Check if in hot path
            if current_func in hot_funcs:
                issues.append(TweenIssue(
                    file=rel_path,
                    line=i + 1,
                    code=stripped[:60],
                    issue_type="tween_in_hot_path",
                    message=f"create_tween() in {current_func}() - creates new object every frame",
                    severity="warning"
                ))

        # Find get_tree().create_tween() calls (older pattern)
        tree_tween = re.search(r'get_tree\(\)\.create_tween\s*\(', line)
        if tree_tween:
            patterns["tree_tween"] += 1
            issues.append(TweenIssue(
                file=rel_path,
                line=i + 1,
                code=stripped[:60],
                issue_type="tree_tween",
                message="get_tree().create_tween() - prefer create_tween() (node-bound)",
                severity="info"
            ))

        # Find tween.kill() calls
        kill_match = re.search(r'(\w+)\.kill\s*\(', line)
        if kill_match:
            var_name = kill_match.group(1)
            if var_name in tween_vars or 'tween' in var_name.lower():
                patterns["tween_kill"] += 1

        # Find tween.stop() calls
        stop_match = re.search(r'(\w+)\.stop\s*\(', line)
        if stop_match:
            var_name = stop_match.group(1)
            if var_name in tween_vars or 'tween' in var_name.lower():
                patterns["tween_stop"] += 1

        # Find tween_property chains
        if '.tween_property(' in line:
            patterns["tween_property"] += 1

        # Find tween_callback chains
        if '.tween_callback(' in line:
            patterns["tween_callback"] += 1

        # Find tween_interval chains
        if '.tween_interval(' in line:
            patterns["tween_interval"] += 1

        # Find tween_method chains
        if '.tween_method(' in line:
            patterns["tween_method"] += 1

        # Find parallel/set_parallel
        if '.set_parallel(' in line or '.parallel()' in line:
            patterns["parallel_tween"] += 1

        # Find set_trans/set_ease
        if '.set_trans(' in line:
            patterns["set_trans"] += 1
        if '.set_ease(' in line:
            patterns["set_ease"] += 1

    # Check for cleanup issues
    if patterns["create_tween"] > 0 and (has_exit_tree or has_queue_free):
        if patterns.get("tween_kill", 0) == 0 and patterns.get("tween_stop", 0) == 0:
            # Has cleanup methods but no tween cleanup
            if strict and patterns.get("stored_tween", 0) > 0:
                issues.append(TweenIssue(
                    file=rel_path,
                    line=1,
                    code="",
                    issue_type="no_tween_cleanup",
                    message=f"File has tweens and cleanup methods but no tween.kill()/stop()",
                    severity="info"
                ))

    return patterns, issues


def check_tween_usage(target_file: Optional[str] = None, strict: bool = False) -> TweenReport:
    """Check tween usage patterns across the project."""
    report = TweenReport()

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

        patterns, issues = analyze_tweens(gd_file, rel_path, strict)

        # Aggregate patterns
        for pattern, count in patterns.items():
            report.patterns[pattern] += count

        # Aggregate issues
        for issue in issues:
            report.issues.append(issue)
            report.by_file[issue.file].append(issue)

    # Calculate totals
    report.total_tweens = report.patterns.get("create_tween", 0) + report.patterns.get("tree_tween", 0)
    report.stored_tweens = report.patterns.get("stored_tween", 0)
    report.unstored_tweens = report.patterns.get("unstored_tween", 0)
    report.tween_kills = report.patterns.get("tween_kill", 0) + report.patterns.get("tween_stop", 0)

    return report


def format_report(report: TweenReport) -> str:
    """Format tween usage report as text."""
    lines = []
    lines.append("=" * 60)
    lines.append("TWEEN USAGE CHECKER - KEYBOARD DEFENSE")
    lines.append("=" * 60)
    lines.append("")

    # Summary
    lines.append("## SUMMARY")
    lines.append(f"  Files checked:      {report.files_checked}")
    lines.append(f"  Total tweens:       {report.total_tweens}")
    lines.append(f"  Stored tweens:      {report.stored_tweens}")
    lines.append(f"  Unstored tweens:    {report.unstored_tweens}")
    lines.append(f"  Tween kills/stops:  {report.tween_kills}")
    lines.append(f"  Issues found:       {len(report.issues)}")
    lines.append("")

    # Patterns
    lines.append("## TWEEN PATTERNS")
    for pattern, count in sorted(report.patterns.items(), key=lambda x: -x[1]):
        if count > 0:
            lines.append(f"  {pattern}: {count}")
    lines.append("")

    # Issues by type
    by_type: Dict[str, List] = defaultdict(list)
    for issue in report.issues:
        by_type[issue.issue_type].append(issue)

    if by_type:
        lines.append("## ISSUES BY TYPE")
        for issue_type, issues in sorted(by_type.items(), key=lambda x: -len(x[1])):
            lines.append(f"  {issue_type}: {len(issues)}")
        lines.append("")

    # Issues
    if report.issues:
        lines.append("## TWEEN ISSUES")

        sorted_issues = sorted(report.issues, key=lambda x: (0 if x.severity == "warning" else 1, x.file, x.line))

        for issue in sorted_issues[:40]:
            severity_marker = {"error": "[ERROR]", "warning": "[WARN]", "info": "[INFO]"}.get(issue.severity, "[???]")
            lines.append(f"  {severity_marker} {issue.file}:{issue.line}")
            lines.append(f"    {issue.message}")

        if len(report.issues) > 40:
            lines.append(f"  ... and {len(report.issues) - 40} more issues")
        lines.append("")

    # Files with most issues
    if report.by_file:
        lines.append("## FILES WITH TWEEN ISSUES")
        sorted_files = sorted(report.by_file.items(), key=lambda x: -len(x[1]))[:10]
        for file_path, issues in sorted_files:
            warn_count = sum(1 for i in issues if i.severity == "warning")
            lines.append(f"  {file_path}: {len(issues)} ({warn_count} warnings)")
        lines.append("")

    # Health indicators
    lines.append("## HEALTH INDICATORS")

    hot_path_issues = sum(1 for i in report.issues if i.issue_type == "tween_in_hot_path")
    if hot_path_issues == 0:
        lines.append("  [OK] No tweens created in hot paths")
    else:
        lines.append(f"  [WARN] {hot_path_issues} tweens created in _process/_physics_process")

    if report.total_tweens > 0:
        if report.stored_tweens >= report.total_tweens * 0.5:
            lines.append(f"  [OK] {report.stored_tweens}/{report.total_tweens} tweens are stored in variables")
        else:
            lines.append(f"  [INFO] Only {report.stored_tweens}/{report.total_tweens} tweens are stored")

    lines.append("")
    lines.append("## TWEEN BEST PRACTICES")
    lines.append("  # Store tweens: var tween = create_tween()")
    lines.append("  # Kill before creating: if tween: tween.kill()")
    lines.append("  # Cleanup in _exit_tree: if tween: tween.kill()")
    lines.append("  # Avoid in _process: use once, store reference")
    lines.append("")

    return "\n".join(lines)


def format_json(report: TweenReport) -> str:
    """Format report as JSON."""
    data = {
        "summary": {
            "files_checked": report.files_checked,
            "total_tweens": report.total_tweens,
            "stored_tweens": report.stored_tweens,
            "unstored_tweens": report.unstored_tweens,
            "tween_kills": report.tween_kills,
            "issues": len(report.issues)
        },
        "patterns": dict(report.patterns),
        "issues": [
            {
                "file": i.file,
                "line": i.line,
                "code": i.code,
                "type": i.issue_type,
                "message": i.message,
                "severity": i.severity
            }
            for i in report.issues[:100]
        ],
        "by_type": {
            issue_type: len([i for i in report.issues if i.issue_type == issue_type])
            for issue_type in set(i.issue_type for i in report.issues)
        }
    }
    return json.dumps(data, indent=2)


def main():
    import argparse

    parser = argparse.ArgumentParser(description="Check tween usage patterns")
    parser.add_argument("--json", "-j", action="store_true", help="JSON output")
    parser.add_argument("--file", "-f", type=str, help="Single file to check")
    parser.add_argument("--strict", "-s", action="store_true", help="Include info-level checks")
    args = parser.parse_args()

    report = check_tween_usage(args.file, args.strict)

    if args.json:
        print(format_json(report))
    else:
        print(format_report(report))


if __name__ == "__main__":
    main()
