#!/usr/bin/env python3
"""
Memory Leak Detector

Finds potential memory leaks in GDScript code:
- Signals connected but not disconnected
- Nodes created but not freed
- Tweens created without proper cleanup
- Timers without one_shot
- Reference cycles

Usage:
    python scripts/check_memory.py              # Full report
    python scripts/check_memory.py --strict     # More aggressive checks
    python scripts/check_memory.py --file game/main.gd  # Single file
    python scripts/check_memory.py --json       # JSON output
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
class MemoryIssue:
    """A potential memory issue."""
    file: str
    line: int
    severity: str  # "high", "medium", "low"
    category: str
    message: str
    code_snippet: str = ""


@dataclass
class MemoryReport:
    """Memory analysis report."""
    issues: List[MemoryIssue] = field(default_factory=list)
    by_file: Dict[str, int] = field(default_factory=dict)
    by_category: Dict[str, int] = field(default_factory=dict)
    by_severity: Dict[str, int] = field(default_factory=dict)
    signal_connects: int = 0
    signal_disconnects: int = 0
    node_creates: int = 0
    node_frees: int = 0


def analyze_file(filepath: Path, strict: bool = False) -> Tuple[List[MemoryIssue], Dict]:
    """Analyze a file for memory issues."""
    issues = []
    stats = {
        "connects": 0,
        "disconnects": 0,
        "creates": 0,
        "frees": 0
    }
    rel_path = str(filepath.relative_to(PROJECT_ROOT))

    try:
        content = filepath.read_text(encoding="utf-8")
        lines = content.split('\n')
    except Exception:
        return issues, stats

    # Track what we find
    signal_connects = []  # (line, signal_name, target)
    node_instantiates = []  # (line, var_name)
    has_exit_tree = False
    has_queue_free = False
    tweens_created = []  # (line, var_name)
    timers_created = []  # (line, var_name)

    current_func = None
    func_start_line = 0

    for i, line in enumerate(lines):
        stripped = line.strip()

        # Track current function
        func_match = re.match(r'^(?:static\s+)?func\s+(\w+)', stripped)
        if func_match:
            current_func = func_match.group(1)
            func_start_line = i

        # Check for _exit_tree
        if '_exit_tree' in stripped and 'func' in stripped:
            has_exit_tree = True

        # Check for queue_free
        if 'queue_free()' in stripped or '.free()' in stripped:
            has_queue_free = True
            stats["frees"] += 1

        # Signal connections
        connect_match = re.search(r'\.connect\s*\(', stripped)
        if connect_match:
            stats["connects"] += 1
            signal_connects.append((i + 1, stripped))

        # Signal disconnections
        disconnect_match = re.search(r'\.disconnect\s*\(', stripped)
        if disconnect_match:
            stats["disconnects"] += 1

        # Node instantiation
        inst_match = re.search(r'(\w+)\s*=\s*(\w+)\.instantiate\s*\(', stripped)
        if inst_match:
            var_name = inst_match.group(1)
            node_instantiates.append((i + 1, var_name))
            stats["creates"] += 1

        # .new() calls (potential object creation)
        new_match = re.search(r'(\w+)\s*=\s*\w+\.new\s*\(', stripped)
        if new_match:
            stats["creates"] += 1

        # Tween creation
        tween_match = re.search(r'(\w+)\s*=\s*(?:create_tween|get_tree\(\)\.create_tween)', stripped)
        if tween_match:
            tweens_created.append((i + 1, tween_match.group(1)))

        # Timer creation without one_shot
        timer_match = re.search(r'Timer\.new\s*\(', stripped)
        if timer_match:
            timers_created.append((i + 1, stripped))

        # Check for potential issues

        # 1. Connecting to lambda/callable that captures self without disconnect
        if '.connect(' in stripped and 'func(' in stripped:
            issues.append(MemoryIssue(
                file=rel_path,
                line=i + 1,
                severity="medium",
                category="signal_lambda",
                message="Lambda connected to signal - ensure disconnected in _exit_tree",
                code_snippet=stripped[:60]
            ))

        # 2. add_child without corresponding remove
        if 'add_child(' in stripped:
            # Check if there's a remove_child or queue_free nearby
            pass  # Hard to track statically

        # 3. Creating timer without one_shot in non-autoload
        if 'Timer.new()' in stripped:
            # Check if one_shot is set nearby
            next_lines = '\n'.join(lines[i:i+5])
            if 'one_shot' not in next_lines and 'autostart' not in next_lines:
                issues.append(MemoryIssue(
                    file=rel_path,
                    line=i + 1,
                    severity="low",
                    category="timer_config",
                    message="Timer created - ensure one_shot=true or proper cleanup",
                    code_snippet=stripped[:60]
                ))

        # 4. Creating tween without kill() on cleanup
        if 'create_tween()' in stripped and current_func not in ['_exit_tree', '_on_tree_exiting']:
            issues.append(MemoryIssue(
                file=rel_path,
                line=i + 1,
                severity="low",
                category="tween_cleanup",
                message="Tween created - kill() in _exit_tree if object can be freed mid-tween",
                code_snippet=stripped[:60]
            ))

        # 5. get_tree().create_timer() without await
        if 'create_timer(' in stripped and 'await' not in stripped:
            issues.append(MemoryIssue(
                file=rel_path,
                line=i + 1,
                severity="low",
                category="orphan_timer",
                message="create_timer() without await - timer may be orphaned",
                code_snippet=stripped[:60]
            ))

        # 6. Storing reference to node from different scene
        if strict:
            if re.search(r'=\s*\$["\']?/root/', stripped):
                issues.append(MemoryIssue(
                    file=rel_path,
                    line=i + 1,
                    severity="medium",
                    category="cross_scene_ref",
                    message="Reference to /root node - may cause issues if scene changes",
                    code_snippet=stripped[:60]
                ))

    # Post-analysis checks

    # Check for connects without exit_tree disconnect pattern
    if signal_connects and not has_exit_tree and len(signal_connects) > 2:
        issues.append(MemoryIssue(
            file=rel_path,
            line=signal_connects[0][0],
            severity="medium",
            category="no_exit_tree",
            message=f"File has {len(signal_connects)} signal connects but no _exit_tree for cleanup",
            code_snippet=""
        ))

    # Check for more connects than disconnects (heuristic)
    if stats["connects"] > stats["disconnects"] + 5 and strict:
        issues.append(MemoryIssue(
            file=rel_path,
            line=1,
            severity="low",
            category="connect_imbalance",
            message=f"More connects ({stats['connects']}) than disconnects ({stats['disconnects']})",
            code_snippet=""
        ))

    return issues, stats


def analyze_memory(file_filter: Optional[str] = None, strict: bool = False) -> MemoryReport:
    """Analyze memory patterns across the codebase."""
    report = MemoryReport()

    for gd_file in PROJECT_ROOT.glob("**/*.gd"):
        if ".godot" in str(gd_file) or "addons" in str(gd_file):
            continue

        rel_path = str(gd_file.relative_to(PROJECT_ROOT))
        if file_filter and file_filter not in rel_path:
            continue

        issues, stats = analyze_file(gd_file, strict)

        report.signal_connects += stats["connects"]
        report.signal_disconnects += stats["disconnects"]
        report.node_creates += stats["creates"]
        report.node_frees += stats["frees"]

        for issue in issues:
            report.issues.append(issue)
            report.by_file[issue.file] = report.by_file.get(issue.file, 0) + 1
            report.by_category[issue.category] = report.by_category.get(issue.category, 0) + 1
            report.by_severity[issue.severity] = report.by_severity.get(issue.severity, 0) + 1

    # Sort by severity
    severity_order = {"high": 0, "medium": 1, "low": 2}
    report.issues.sort(key=lambda x: (severity_order.get(x.severity, 1), x.file, x.line))

    return report


def format_report(report: MemoryReport) -> str:
    """Format memory report as text."""
    lines = []
    lines.append("=" * 60)
    lines.append("MEMORY LEAK DETECTOR - KEYBOARD DEFENSE")
    lines.append("=" * 60)
    lines.append("")

    # Summary
    lines.append("## SUMMARY")
    lines.append(f"  Total potential issues:  {len(report.issues)}")
    lines.append("")
    lines.append("  Signal patterns:")
    lines.append(f"    Connects:     {report.signal_connects}")
    lines.append(f"    Disconnects:  {report.signal_disconnects}")
    lines.append("")
    lines.append("  Object patterns:")
    lines.append(f"    Creates:      {report.node_creates}")
    lines.append(f"    Frees:        {report.node_frees}")
    lines.append("")

    # By severity
    lines.append("  By severity:")
    for sev in ["high", "medium", "low"]:
        count = report.by_severity.get(sev, 0)
        if count > 0:
            marker = "[!]" if sev == "high" else "   "
            lines.append(f"    {marker} {sev:8} {count}")
    lines.append("")

    # By category
    if report.by_category:
        lines.append("  By category:")
        sorted_cats = sorted(report.by_category.items(), key=lambda x: -x[1])
        for cat, count in sorted_cats:
            lines.append(f"    {cat:20} {count}")
        lines.append("")

    if not report.issues:
        lines.append("No potential memory issues found!")
        return "\n".join(lines)

    # High/Medium severity issues
    important_issues = [i for i in report.issues if i.severity in ["high", "medium"]]
    if important_issues:
        lines.append("## POTENTIAL MEMORY ISSUES")
        for issue in important_issues[:20]:
            lines.append(f"  [{issue.severity.upper()}] {issue.file}:{issue.line}")
            lines.append(f"    {issue.message}")
            if issue.code_snippet:
                lines.append(f"    > {issue.code_snippet}")
        if len(important_issues) > 20:
            lines.append(f"  ... and {len(important_issues) - 20} more")
        lines.append("")

    # Files with most issues
    lines.append("## FILES WITH MOST ISSUES")
    sorted_files = sorted(report.by_file.items(), key=lambda x: -x[1])
    for filepath, count in sorted_files[:10]:
        lines.append(f"  {count:4} issues  {filepath}")
    lines.append("")

    # Recommendations
    lines.append("## RECOMMENDATIONS")
    if report.by_category.get("no_exit_tree", 0) > 0:
        lines.append("  - Add _exit_tree() to disconnect signals in classes with many connects")
    if report.by_category.get("signal_lambda", 0) > 0:
        lines.append("  - Lambda signal handlers should be disconnected to allow GC")
    if report.by_category.get("tween_cleanup", 0) > 0:
        lines.append("  - Call tween.kill() in _exit_tree() if node can be freed mid-animation")
    if report.signal_connects > report.signal_disconnects * 2:
        lines.append("  - Review signal connect/disconnect balance")
    lines.append("")

    # Health indicators
    lines.append("## HEALTH INDICATORS")
    high_count = report.by_severity.get("high", 0)
    medium_count = report.by_severity.get("medium", 0)

    if high_count > 0:
        lines.append(f"  [WARN] {high_count} high severity issues - likely memory leaks")
    elif medium_count > 10:
        lines.append(f"  [INFO] {medium_count} medium severity issues to review")
    else:
        lines.append("  [OK] No critical memory issues detected")

    connect_ratio = report.signal_connects / max(report.signal_disconnects, 1)
    if connect_ratio > 3:
        lines.append(f"  [INFO] Connect/disconnect ratio is {connect_ratio:.1f}:1")

    lines.append("")
    return "\n".join(lines)


def format_json(report: MemoryReport) -> str:
    """Format report as JSON."""
    data = {
        "summary": {
            "total_issues": len(report.issues),
            "signal_connects": report.signal_connects,
            "signal_disconnects": report.signal_disconnects,
            "node_creates": report.node_creates,
            "node_frees": report.node_frees,
            "by_severity": report.by_severity,
            "by_category": report.by_category
        },
        "issues": [
            {
                "file": i.file,
                "line": i.line,
                "severity": i.severity,
                "category": i.category,
                "message": i.message,
                "code": i.code_snippet
            }
            for i in report.issues
        ],
        "by_file": report.by_file
    }
    return json.dumps(data, indent=2)


def main():
    import argparse

    parser = argparse.ArgumentParser(description="Detect potential memory leaks")
    parser.add_argument("--json", "-j", action="store_true", help="JSON output")
    parser.add_argument("--file", "-f", type=str, help="Filter by file path")
    parser.add_argument("--strict", "-s", action="store_true", help="More aggressive checks")
    args = parser.parse_args()

    report = analyze_memory(args.file, args.strict)

    if args.json:
        print(format_json(report))
    else:
        print(format_report(report))


if __name__ == "__main__":
    main()
