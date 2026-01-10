#!/usr/bin/env python3
"""
Run All Checks

Master script that runs all code analysis tools and generates a report:
- Runs all validators and analyzers
- Collects results and issues
- Generates summary report
- Can output to file or console

Usage:
    python scripts/run_all_checks.py              # Full report
    python scripts/run_all_checks.py --quick      # Quick checks only
    python scripts/run_all_checks.py --ci         # CI mode (exit code on failure)
    python scripts/run_all_checks.py -o report.md # Output to file
    python scripts/run_all_checks.py --json       # JSON output
"""

import json
import subprocess
import sys
import time
from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional, Any

# Project paths
SCRIPT_DIR = Path(__file__).parent
PROJECT_ROOT = SCRIPT_DIR.parent

# All available tools
TOOLS = {
    # Quick checks (fast)
    "validate_paths": {
        "script": "validate_paths.py",
        "name": "Resource Paths",
        "quick": True,
        "key_metric": ("summary", "broken"),
        "fail_threshold": 5
    },
    "check_types": {
        "script": "check_types.py",
        "name": "Type Coverage",
        "quick": True,
        "key_metric": ("summary", "coverage_percent"),
        "pass_threshold": 80
    },
    "check_naming": {
        "script": "check_naming.py",
        "name": "Naming Conventions",
        "quick": True,
        "key_metric": ("summary", "violations"),
        "fail_threshold": 10
    },
    "check_exports": {
        "script": "check_exports.py",
        "name": "Export Variables",
        "quick": True,
        "key_metric": ("summary", "issues"),
        "fail_threshold": 5
    },

    # Standard checks (medium speed)
    "analyze_signals": {
        "script": "analyze_signals.py",
        "name": "Signal Analysis",
        "quick": False,
        "key_metric": ("summary", "unused"),
        "fail_threshold": 10
    },
    "track_todos": {
        "script": "track_todos.py",
        "name": "TODO Tracking",
        "quick": False,
        "key_metric": ("summary", "by_priority", "high"),
        "fail_threshold": 5
    },
    "lint_performance": {
        "script": "lint_performance.py",
        "name": "Performance",
        "quick": False,
        "key_metric": ("summary", "by_severity", "high"),
        "fail_threshold": 10
    },
    "check_memory": {
        "script": "check_memory.py",
        "name": "Memory Safety",
        "quick": False,
        "key_metric": ("summary", "by_severity", "high"),
        "fail_threshold": 5
    },
    "validate_inputs": {
        "script": "validate_inputs.py",
        "name": "Input Actions",
        "quick": False,
        "key_metric": ("summary", "undefined_refs"),
        "fail_threshold": 1
    },
    "analyze_autoloads": {
        "script": "analyze_autoloads.py",
        "name": "Autoloads",
        "quick": False,
        "key_metric": ("summary", "circular_deps"),
        "fail_threshold": 1
    },

    # Comprehensive checks (slower)
    "analyze_complexity": {
        "script": "analyze_complexity.py",
        "name": "Complexity",
        "quick": False,
        "key_metric": ("summary", "high_risk"),
        "fail_threshold": 50
    },
    "find_duplicates": {
        "script": "find_duplicates.py",
        "name": "Duplicates",
        "quick": False,
        "key_metric": ("summary", "duplicate_percentage"),
        "fail_threshold": 10
    },
    "check_docs": {
        "script": "check_docs.py",
        "name": "Documentation",
        "quick": False,
        "key_metric": ("summary", "coverage_percent"),
        "pass_threshold": 20
    },
}


@dataclass
class ToolResult:
    """Result from running a tool."""
    name: str
    success: bool
    duration: float
    data: Optional[Dict] = None
    error: str = ""
    passed: bool = True
    message: str = ""


@dataclass
class CheckReport:
    """Complete check report."""
    timestamp: str = ""
    duration: float = 0.0
    results: List[ToolResult] = field(default_factory=list)
    passed: int = 0
    failed: int = 0
    warnings: int = 0
    overall_pass: bool = True


def run_tool(tool_id: str, tool_config: Dict) -> ToolResult:
    """Run a single tool and collect results."""
    script = tool_config["script"]
    name = tool_config["name"]

    start = time.time()

    try:
        result = subprocess.run(
            ["python3", f"scripts/{script}", "--json"],
            cwd=PROJECT_ROOT,
            capture_output=True,
            text=True,
            timeout=120
        )
        duration = time.time() - start

        if result.returncode == 0:
            try:
                data = json.loads(result.stdout)

                # Check pass/fail based on metrics
                passed = True
                message = "OK"

                key_metric = tool_config.get("key_metric")
                if key_metric and data:
                    # Navigate to metric value
                    value = data
                    for key in key_metric:
                        if isinstance(value, dict) and key in value:
                            value = value[key]
                        else:
                            value = 0
                            break

                    if isinstance(value, (int, float)):
                        fail_threshold = tool_config.get("fail_threshold")
                        pass_threshold = tool_config.get("pass_threshold")

                        if fail_threshold is not None and value >= fail_threshold:
                            passed = False
                            message = f"Failed: {value} >= {fail_threshold}"
                        elif pass_threshold is not None and value < pass_threshold:
                            passed = False
                            message = f"Below threshold: {value} < {pass_threshold}"
                        else:
                            message = f"Value: {value}"

                return ToolResult(
                    name=name,
                    success=True,
                    duration=duration,
                    data=data,
                    passed=passed,
                    message=message
                )

            except json.JSONDecodeError:
                return ToolResult(
                    name=name,
                    success=True,
                    duration=duration,
                    passed=True,
                    message="No JSON output"
                )
        else:
            return ToolResult(
                name=name,
                success=False,
                duration=duration,
                error=result.stderr[:200],
                passed=False,
                message="Script error"
            )

    except subprocess.TimeoutExpired:
        return ToolResult(
            name=name,
            success=False,
            duration=120,
            error="Timeout",
            passed=False,
            message="Timeout (120s)"
        )
    except Exception as e:
        return ToolResult(
            name=name,
            success=False,
            duration=time.time() - start,
            error=str(e),
            passed=False,
            message=str(e)[:50]
        )


def run_all_checks(quick: bool = False) -> CheckReport:
    """Run all checks."""
    report = CheckReport()
    report.timestamp = datetime.now().isoformat()

    start_time = time.time()

    tools_to_run = TOOLS
    if quick:
        tools_to_run = {k: v for k, v in TOOLS.items() if v.get("quick", False)}

    print(f"Running {len(tools_to_run)} checks...", file=sys.stderr)

    for tool_id, tool_config in tools_to_run.items():
        print(f"  {tool_config['name']}...", end=" ", file=sys.stderr, flush=True)

        result = run_tool(tool_id, tool_config)
        report.results.append(result)

        if result.success and result.passed:
            report.passed += 1
            print("✓", file=sys.stderr)
        elif result.success:
            report.warnings += 1
            print("!", file=sys.stderr)
        else:
            report.failed += 1
            print("✗", file=sys.stderr)

    report.duration = time.time() - start_time
    report.overall_pass = report.failed == 0

    return report


def format_report(report: CheckReport) -> str:
    """Format check report as text."""
    lines = []
    lines.append("=" * 60)
    lines.append("CODE CHECK REPORT - KEYBOARD DEFENSE")
    lines.append("=" * 60)
    lines.append("")

    # Summary
    status = "PASSED" if report.overall_pass else "FAILED"
    lines.append(f"## STATUS: {status}")
    lines.append("")
    lines.append(f"  Checks passed:   {report.passed}")
    lines.append(f"  Warnings:        {report.warnings}")
    lines.append(f"  Checks failed:   {report.failed}")
    lines.append(f"  Total duration:  {report.duration:.1f}s")
    lines.append("")

    # Results table
    lines.append("## RESULTS")
    lines.append("")
    lines.append(f"  {'Check':<25} {'Status':<10} {'Time':>8}  Details")
    lines.append("  " + "-" * 60)

    for result in report.results:
        if result.success and result.passed:
            status = "✓ PASS"
        elif result.success:
            status = "! WARN"
        else:
            status = "✗ FAIL"

        lines.append(f"  {result.name:<25} {status:<10} {result.duration:>6.1f}s  {result.message}")

    lines.append("")

    # Failed checks details
    failed = [r for r in report.results if not r.success or not r.passed]
    if failed:
        lines.append("## ISSUES TO ADDRESS")
        for result in failed:
            lines.append(f"  {result.name}:")
            if result.error:
                lines.append(f"    Error: {result.error[:100]}")
            else:
                lines.append(f"    {result.message}")
        lines.append("")

    # Timestamp
    lines.append(f"  Generated: {report.timestamp}")
    lines.append("")

    return "\n".join(lines)


def format_markdown(report: CheckReport) -> str:
    """Format report as Markdown."""
    lines = []
    lines.append("# Code Check Report")
    lines.append("")
    lines.append(f"**Status:** {'✓ PASSED' if report.overall_pass else '✗ FAILED'}")
    lines.append(f"**Date:** {report.timestamp}")
    lines.append(f"**Duration:** {report.duration:.1f}s")
    lines.append("")

    # Summary
    lines.append("## Summary")
    lines.append("")
    lines.append(f"- Passed: {report.passed}")
    lines.append(f"- Warnings: {report.warnings}")
    lines.append(f"- Failed: {report.failed}")
    lines.append("")

    # Results table
    lines.append("## Results")
    lines.append("")
    lines.append("| Check | Status | Time | Details |")
    lines.append("|-------|--------|------|---------|")

    for result in report.results:
        if result.success and result.passed:
            status = "✓"
        elif result.success:
            status = "⚠️"
        else:
            status = "✗"

        lines.append(f"| {result.name} | {status} | {result.duration:.1f}s | {result.message} |")

    lines.append("")
    return "\n".join(lines)


def format_json(report: CheckReport) -> str:
    """Format report as JSON."""
    data = {
        "timestamp": report.timestamp,
        "duration": round(report.duration, 1),
        "overall_pass": report.overall_pass,
        "summary": {
            "passed": report.passed,
            "warnings": report.warnings,
            "failed": report.failed
        },
        "results": [
            {
                "name": r.name,
                "success": r.success,
                "passed": r.passed,
                "duration": round(r.duration, 1),
                "message": r.message,
                "error": r.error if r.error else None
            }
            for r in report.results
        ]
    }
    return json.dumps(data, indent=2)


def main():
    import argparse

    parser = argparse.ArgumentParser(description="Run all code checks")
    parser.add_argument("--json", "-j", action="store_true", help="JSON output")
    parser.add_argument("--markdown", "-m", action="store_true", help="Markdown output")
    parser.add_argument("--quick", "-q", action="store_true", help="Quick checks only")
    parser.add_argument("--ci", action="store_true", help="CI mode (exit 1 on failure)")
    parser.add_argument("-o", "--output", type=str, help="Output file")
    args = parser.parse_args()

    report = run_all_checks(args.quick)

    if args.json:
        output = format_json(report)
    elif args.markdown:
        output = format_markdown(report)
    else:
        output = format_report(report)

    if args.output:
        Path(args.output).write_text(output)
        print(f"Report saved to {args.output}", file=sys.stderr)
    else:
        print(output)

    if args.ci and not report.overall_pass:
        sys.exit(1)


if __name__ == "__main__":
    main()
