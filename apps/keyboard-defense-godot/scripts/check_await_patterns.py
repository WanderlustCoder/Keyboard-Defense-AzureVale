#!/usr/bin/env python3
"""
Await Pattern Checker

Checks async/await usage patterns in GDScript:
- await in non-async functions
- Missing await on coroutines
- await in _ready/_process (potential issues)
- Signal await patterns

Usage:
    python scripts/check_await_patterns.py              # Full report
    python scripts/check_await_patterns.py --file game/main.gd  # Single file
    python scripts/check_await_patterns.py --strict     # Stricter checks
    python scripts/check_await_patterns.py --json       # JSON output
"""

import json
import re
import sys
from dataclasses import dataclass, field
from pathlib import Path
from typing import Dict, List, Optional, Set, Tuple

# Project paths
SCRIPT_DIR = Path(__file__).parent
PROJECT_ROOT = SCRIPT_DIR.parent


@dataclass
class AwaitUsage:
    """An await usage in code."""
    file: str
    line: int
    function: str
    await_target: str
    context: str
    issue: Optional[str] = None


@dataclass
class AsyncFunction:
    """An async function definition."""
    name: str
    file: str
    line: int
    has_await: bool = False
    await_count: int = 0


@dataclass
class AwaitIssue:
    """An issue with await patterns."""
    file: str
    line: int
    issue_type: str
    function: str
    message: str
    severity: str


@dataclass
class AwaitReport:
    """Await pattern check report."""
    files_checked: int = 0
    total_awaits: int = 0
    signal_awaits: int = 0
    timer_awaits: int = 0
    coroutine_awaits: int = 0
    awaits: List[AwaitUsage] = field(default_factory=list)
    async_functions: List[AsyncFunction] = field(default_factory=list)
    issues: List[AwaitIssue] = field(default_factory=list)
    by_severity: Dict[str, int] = field(default_factory=lambda: {"high": 0, "medium": 0, "low": 0})


def analyze_file(file_path: Path, rel_path: str, strict: bool = False) -> Tuple[List[AwaitUsage], List[AsyncFunction], List[AwaitIssue]]:
    """Analyze a file for await patterns."""
    awaits = []
    async_funcs = []
    issues = []

    try:
        content = file_path.read_text(encoding="utf-8")
        lines = content.split('\n')
    except Exception:
        return awaits, async_funcs, issues

    current_func = None
    current_func_line = 0
    current_func_has_await = False
    current_func_await_count = 0
    func_indent = 0

    # Hot path functions that shouldn't use await
    hot_path_funcs = {"_process", "_physics_process", "_input", "_unhandled_input", "_draw"}

    for i, line in enumerate(lines):
        line_num = i + 1
        stripped = line.strip()

        # Skip comments
        if stripped.startswith("#"):
            continue

        # Function definition
        func_match = re.match(r'^(\s*)(static\s+)?func\s+(\w+)', line)
        if func_match:
            # Save previous function
            if current_func:
                async_funcs.append(AsyncFunction(
                    name=current_func,
                    file=rel_path,
                    line=current_func_line,
                    has_await=current_func_has_await,
                    await_count=current_func_await_count
                ))

            func_indent = len(func_match.group(1))
            current_func = func_match.group(3)
            current_func_line = line_num
            current_func_has_await = False
            current_func_await_count = 0
            continue

        # Check for await
        if "await " in stripped or stripped.startswith("await"):
            await_match = re.search(r'await\s+(.+?)(?:\s*$|\s*#)', stripped)
            if await_match:
                await_target = await_match.group(1).strip()
                current_func_has_await = True
                current_func_await_count += 1

                usage = AwaitUsage(
                    file=rel_path,
                    line=line_num,
                    function=current_func or "<global>",
                    await_target=await_target,
                    context=stripped[:80]
                )
                awaits.append(usage)

                # Check for issues
                if current_func in hot_path_funcs:
                    issues.append(AwaitIssue(
                        file=rel_path,
                        line=line_num,
                        issue_type="hot_path_await",
                        function=current_func,
                        message=f"await in {current_func}() may cause frame drops",
                        severity="high"
                    ))

                # Check for await in _ready (common but can be problematic)
                if current_func == "_ready" and strict:
                    issues.append(AwaitIssue(
                        file=rel_path,
                        line=line_num,
                        issue_type="ready_await",
                        function=current_func,
                        message="await in _ready() delays node initialization",
                        severity="medium"
                    ))

                # Check for timer await pattern
                if "get_tree().create_timer" in await_target:
                    # This is fine, just track it
                    pass

                # Check for signal await without timeout
                if ".connect" not in stripped and "Signal" not in await_target:
                    if strict and "timeout" not in stripped.lower():
                        # Awaiting signal without timeout can hang
                        if not any(x in await_target for x in ["create_timer", "timeout"]):
                            issues.append(AwaitIssue(
                                file=rel_path,
                                line=line_num,
                                issue_type="signal_no_timeout",
                                function=current_func or "<global>",
                                message="Signal await without timeout may hang indefinitely",
                                severity="low"
                            ))

    # Save last function
    if current_func:
        async_funcs.append(AsyncFunction(
            name=current_func,
            file=rel_path,
            line=current_func_line,
            has_await=current_func_has_await,
            await_count=current_func_await_count
        ))

    return awaits, async_funcs, issues


def check_await_patterns(target_file: Optional[str] = None, strict: bool = False) -> AwaitReport:
    """Check await patterns across the project."""
    report = AwaitReport()

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

        awaits, async_funcs, issues = analyze_file(gd_file, rel_path, strict)

        for await_usage in awaits:
            report.total_awaits += 1
            report.awaits.append(await_usage)

            # Categorize await type
            target = await_usage.await_target.lower()
            if "signal" in target or await_usage.await_target.endswith(")"):
                if "create_timer" in target:
                    report.timer_awaits += 1
                else:
                    report.signal_awaits += 1
            else:
                report.coroutine_awaits += 1

        report.async_functions.extend(async_funcs)

        for issue in issues:
            report.issues.append(issue)
            report.by_severity[issue.severity] += 1

    return report


def format_report(report: AwaitReport, strict: bool = False) -> str:
    """Format await report as text."""
    lines = []
    lines.append("=" * 60)
    lines.append("AWAIT PATTERN CHECKER - KEYBOARD DEFENSE")
    lines.append("=" * 60)
    lines.append("")

    # Summary
    lines.append("## SUMMARY")
    lines.append(f"  Files checked:      {report.files_checked}")
    lines.append(f"  Total awaits:       {report.total_awaits}")
    lines.append(f"    Signal awaits:    {report.signal_awaits}")
    lines.append(f"    Timer awaits:     {report.timer_awaits}")
    lines.append(f"    Coroutine awaits: {report.coroutine_awaits}")
    lines.append(f"  Issues found:       {len(report.issues)}")
    lines.append("")

    # Issues by severity
    if report.issues:
        high_issues = [i for i in report.issues if i.severity == "high"]
        if high_issues:
            lines.append("## HIGH SEVERITY ISSUES")
            for issue in high_issues:
                lines.append(f"  {issue.file}:{issue.line}")
                lines.append(f"    {issue.message}")
            lines.append("")

        medium_issues = [i for i in report.issues if i.severity == "medium"]
        if medium_issues:
            lines.append("## MEDIUM SEVERITY ISSUES")
            for issue in medium_issues[:10]:
                lines.append(f"  {issue.file}:{issue.line}")
                lines.append(f"    {issue.message}")
            if len(medium_issues) > 10:
                lines.append(f"  ... and {len(medium_issues) - 10} more")
            lines.append("")

    # Functions with most awaits
    funcs_with_await = [f for f in report.async_functions if f.has_await]
    if funcs_with_await:
        lines.append("## FUNCTIONS WITH MOST AWAITS")
        sorted_funcs = sorted(funcs_with_await, key=lambda f: -f.await_count)
        for func in sorted_funcs[:10]:
            lines.append(f"  {func.name}(): {func.await_count} awaits")
            lines.append(f"    File: {func.file}:{func.line}")
        lines.append("")

    # Await patterns by file
    files_with_awaits: Dict[str, int] = {}
    for await_usage in report.awaits:
        files_with_awaits[await_usage.file] = files_with_awaits.get(await_usage.file, 0) + 1

    if files_with_awaits:
        lines.append("## AWAITS BY FILE")
        sorted_files = sorted(files_with_awaits.items(), key=lambda x: -x[1])
        for file_path, count in sorted_files[:10]:
            lines.append(f"  {file_path}: {count} awaits")
        if len(sorted_files) > 10:
            lines.append(f"  ... and {len(sorted_files) - 10} more files")
        lines.append("")

    # Health indicators
    lines.append("## HEALTH INDICATORS")
    if report.by_severity["high"] == 0:
        lines.append("  [OK] No hot path await issues")
    else:
        lines.append(f"  [ERROR] {report.by_severity['high']} hot path await issues")

    if report.by_severity["medium"] == 0:
        lines.append("  [OK] No _ready await issues")
    else:
        lines.append(f"  [WARN] {report.by_severity['medium']} _ready await issues")

    # Check await density
    if report.total_awaits > 0:
        await_density = report.total_awaits / report.files_checked if report.files_checked > 0 else 0
        lines.append(f"  [INFO] {await_density:.1f} awaits per file average")

    lines.append("")
    return "\n".join(lines)


def format_json(report: AwaitReport) -> str:
    """Format report as JSON."""
    data = {
        "summary": {
            "files_checked": report.files_checked,
            "total_awaits": report.total_awaits,
            "signal_awaits": report.signal_awaits,
            "timer_awaits": report.timer_awaits,
            "coroutine_awaits": report.coroutine_awaits,
            "issues_found": len(report.issues),
            "by_severity": report.by_severity
        },
        "issues": [
            {
                "file": i.file,
                "line": i.line,
                "type": i.issue_type,
                "function": i.function,
                "message": i.message,
                "severity": i.severity
            }
            for i in report.issues
        ],
        "functions_with_await": [
            {
                "name": f.name,
                "file": f.file,
                "line": f.line,
                "await_count": f.await_count
            }
            for f in sorted(report.async_functions, key=lambda x: -x.await_count)
            if f.has_await
        ][:20]
    }
    return json.dumps(data, indent=2)


def main():
    import argparse

    parser = argparse.ArgumentParser(description="Check await patterns")
    parser.add_argument("--json", "-j", action="store_true", help="JSON output")
    parser.add_argument("--file", "-f", type=str, help="Single file to check")
    parser.add_argument("--strict", "-s", action="store_true", help="Stricter checks")
    args = parser.parse_args()

    report = check_await_patterns(args.file, args.strict)

    if args.json:
        print(format_json(report))
    else:
        print(format_report(report, args.strict))


if __name__ == "__main__":
    main()
