#!/usr/bin/env python3
"""
Code Health Dashboard

Aggregates metrics from all code analysis tools:
- Runs all analyzers and collectors
- Generates a unified health report
- Calculates overall health score
- Tracks trends over time

Usage:
    python scripts/health_dashboard.py              # Full dashboard
    python scripts/health_dashboard.py --quick      # Quick summary only
    python scripts/health_dashboard.py --json       # JSON output
    python scripts/health_dashboard.py --save       # Save to file
"""

import json
import subprocess
import sys
from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional, Any

# Project paths
SCRIPT_DIR = Path(__file__).parent
PROJECT_ROOT = SCRIPT_DIR.parent
HISTORY_FILE = PROJECT_ROOT / ".health_history.json"


@dataclass
class HealthMetric:
    """A health metric."""
    name: str
    value: float
    max_value: float = 100.0
    unit: str = ""
    status: str = "ok"  # "ok", "warn", "error"
    details: str = ""


@dataclass
class HealthReport:
    """Complete health report."""
    timestamp: str = ""
    overall_score: float = 0.0
    grade: str = ""
    metrics: Dict[str, HealthMetric] = field(default_factory=dict)
    issues: List[str] = field(default_factory=list)
    improvements: List[str] = field(default_factory=list)


def run_tool(script_name: str, args: List[str] = None) -> Optional[Dict]:
    """Run a tool and parse JSON output."""
    args = args or []
    try:
        result = subprocess.run(
            ["python3", f"scripts/{script_name}", "--json"] + args,
            cwd=PROJECT_ROOT,
            capture_output=True,
            text=True,
            timeout=60
        )
        if result.returncode == 0:
            return json.loads(result.stdout)
    except Exception as e:
        pass
    return None


def collect_metrics() -> HealthReport:
    """Collect all metrics from various tools."""
    report = HealthReport()
    report.timestamp = datetime.now().isoformat()

    # Type coverage
    type_data = run_tool("check_types.py")
    if type_data and "summary" in type_data:
        pct = type_data["summary"].get("coverage_percent", 0)
        report.metrics["type_coverage"] = HealthMetric(
            name="Type Coverage",
            value=pct,
            unit="%",
            status="ok" if pct >= 80 else "warn" if pct >= 50 else "error",
            details=f"{type_data['summary'].get('typed_functions', 0)}/{type_data['summary'].get('total_functions', 0)} functions typed"
        )

    # Documentation coverage
    doc_data = run_tool("check_docs.py")
    if doc_data and "summary" in doc_data:
        pct = doc_data["summary"].get("coverage_percent", 0)
        report.metrics["doc_coverage"] = HealthMetric(
            name="Documentation Coverage",
            value=pct,
            unit="%",
            status="ok" if pct >= 50 else "warn" if pct >= 20 else "error",
            details=f"{doc_data['summary'].get('documented_functions', 0)}/{doc_data['summary'].get('total_functions', 0)} functions documented"
        )

    # Test coverage
    test_data = run_tool("analyze_test_coverage.py")
    if test_data and "summary" in test_data:
        pct = test_data["summary"].get("coverage_percent", 0)
        report.metrics["test_coverage"] = HealthMetric(
            name="Test Coverage",
            value=pct,
            unit="%",
            status="ok" if pct >= 50 else "warn" if pct >= 20 else "error",
            details=f"{test_data['summary'].get('tested', 0)}/{test_data['summary'].get('total_functions', 0)} functions tested"
        )

    # Export variables
    export_data = run_tool("check_exports.py")
    if export_data and "summary" in export_data:
        total = export_data["summary"].get("total", 0)
        typed = export_data["summary"].get("typed", 0)
        pct = (typed / max(total, 1)) * 100
        report.metrics["export_typed"] = HealthMetric(
            name="Export Type Hints",
            value=pct,
            unit="%",
            status="ok" if pct >= 90 else "warn",
            details=f"{typed}/{total} exports typed"
        )

    # Performance issues
    perf_data = run_tool("lint_performance.py")
    if perf_data and "summary" in perf_data:
        high = perf_data["summary"].get("by_severity", {}).get("high", 0)
        medium = perf_data["summary"].get("by_severity", {}).get("medium", 0)
        # Score: 100 - (high * 10) - (medium * 2)
        score = max(0, 100 - high * 10 - medium * 2)
        report.metrics["performance"] = HealthMetric(
            name="Performance",
            value=score,
            unit="score",
            status="ok" if high == 0 else "warn" if high < 5 else "error",
            details=f"{high} high, {medium} medium issues"
        )
        if high > 0:
            report.issues.append(f"{high} high-severity performance issues")

    # Memory issues
    mem_data = run_tool("check_memory.py")
    if mem_data and "summary" in mem_data:
        high = mem_data["summary"].get("by_severity", {}).get("high", 0)
        medium = mem_data["summary"].get("by_severity", {}).get("medium", 0)
        score = max(0, 100 - high * 15 - medium * 3)
        report.metrics["memory_safety"] = HealthMetric(
            name="Memory Safety",
            value=score,
            unit="score",
            status="ok" if high == 0 and medium < 10 else "warn" if high < 3 else "error",
            details=f"{high} high, {medium} medium issues"
        )
        if medium > 10:
            report.issues.append(f"{medium} potential memory leak patterns")

    # Resource paths
    path_data = run_tool("validate_paths.py")
    if path_data and "summary" in path_data:
        total = path_data["summary"].get("total_references", 0)
        broken = path_data["summary"].get("broken", 0)
        valid_pct = ((total - broken) / max(total, 1)) * 100
        report.metrics["resource_paths"] = HealthMetric(
            name="Resource Paths",
            value=valid_pct,
            unit="%",
            status="ok" if broken == 0 else "warn" if broken < 5 else "error",
            details=f"{broken} broken paths out of {total}"
        )
        if broken > 0:
            report.issues.append(f"{broken} broken resource paths")

    # Signals
    signal_data = run_tool("analyze_signals.py")
    if signal_data and "summary" in signal_data:
        unused = signal_data["summary"].get("unused", 0)
        total = signal_data["summary"].get("declarations", 0)
        used_pct = ((total - unused) / max(total, 1)) * 100
        report.metrics["signals"] = HealthMetric(
            name="Signal Usage",
            value=used_pct,
            unit="%",
            status="ok" if unused == 0 else "warn",
            details=f"{unused} unused signals"
        )

    # TODOs/FIXMEs
    todo_data = run_tool("track_todos.py")
    if todo_data and "summary" in todo_data:
        total = todo_data["summary"].get("total", 0)
        high = todo_data["summary"].get("by_priority", {}).get("high", 0)
        bugs = todo_data["summary"].get("by_type", {}).get("BUG", 0)
        bugs += todo_data["summary"].get("by_type", {}).get("FIXME", 0)
        # Lower is better, so invert
        score = max(0, 100 - high * 10 - bugs * 5)
        report.metrics["tech_debt"] = HealthMetric(
            name="Tech Debt",
            value=score,
            unit="score",
            status="ok" if high == 0 and bugs < 5 else "warn" if high < 3 else "error",
            details=f"{total} TODOs, {bugs} bugs/fixmes, {high} high priority"
        )

    # Magic numbers
    magic_data = run_tool("find_magic_numbers.py")
    if magic_data and "summary" in magic_data:
        repeated = magic_data["summary"].get("repeated", 0)
        score = max(0, 100 - repeated)
        report.metrics["magic_numbers"] = HealthMetric(
            name="Magic Numbers",
            value=score,
            unit="score",
            status="ok" if repeated < 10 else "warn" if repeated < 50 else "error",
            details=f"{repeated} repeated magic numbers"
        )
        if repeated > 20:
            report.improvements.append(f"Extract {repeated} repeated numbers to constants")

    # Calculate overall score
    weights = {
        "type_coverage": 15,
        "doc_coverage": 10,
        "test_coverage": 15,
        "export_typed": 5,
        "performance": 15,
        "memory_safety": 15,
        "resource_paths": 10,
        "signals": 5,
        "tech_debt": 5,
        "magic_numbers": 5
    }

    total_weight = 0
    weighted_sum = 0
    for name, metric in report.metrics.items():
        weight = weights.get(name, 5)
        weighted_sum += metric.value * weight
        total_weight += weight

    if total_weight > 0:
        report.overall_score = weighted_sum / total_weight

    # Assign grade
    if report.overall_score >= 90:
        report.grade = "A"
    elif report.overall_score >= 80:
        report.grade = "B"
    elif report.overall_score >= 70:
        report.grade = "C"
    elif report.overall_score >= 60:
        report.grade = "D"
    else:
        report.grade = "F"

    return report


def format_dashboard(report: HealthReport, quick: bool = False) -> str:
    """Format the health dashboard."""
    lines = []
    lines.append("=" * 60)
    lines.append("CODE HEALTH DASHBOARD - KEYBOARD DEFENSE")
    lines.append("=" * 60)
    lines.append("")

    # Overall score
    lines.append("## OVERALL HEALTH")
    lines.append("")

    # Big grade display
    grade_art = {
        "A": "  █████╗ ",
        "B": "  ██████╗",
        "C": "  ██████╗",
        "D": "  ██████╗",
        "F": "  ██████╗"
    }
    lines.append(f"  Grade: {report.grade}  Score: {report.overall_score:.1f}/100")
    lines.append("")

    # Score bar
    bar_width = 50
    filled = int(bar_width * report.overall_score / 100)
    bar = "[" + "=" * filled + " " * (bar_width - filled) + "]"
    lines.append(f"  {bar} {report.overall_score:.1f}%")
    lines.append("")

    if quick:
        # Quick summary only
        lines.append("## QUICK SUMMARY")
        for name, metric in report.metrics.items():
            status_icon = "✓" if metric.status == "ok" else "!" if metric.status == "warn" else "✗"
            lines.append(f"  [{status_icon}] {metric.name}: {metric.value:.1f}{metric.unit}")
        lines.append("")
    else:
        # Detailed metrics
        lines.append("## METRICS")
        lines.append("")

        # Group by status
        for status, label in [("error", "NEEDS ATTENTION"), ("warn", "COULD IMPROVE"), ("ok", "HEALTHY")]:
            status_metrics = [(n, m) for n, m in report.metrics.items() if m.status == status]
            if status_metrics:
                icon = "✗" if status == "error" else "!" if status == "warn" else "✓"
                lines.append(f"  [{icon}] {label}:")
                for name, metric in status_metrics:
                    mini_bar_width = 20
                    mini_filled = int(mini_bar_width * metric.value / metric.max_value)
                    mini_bar = "[" + "=" * mini_filled + " " * (mini_bar_width - mini_filled) + "]"
                    lines.append(f"      {metric.name:25} {mini_bar} {metric.value:.1f}{metric.unit}")
                    lines.append(f"        {metric.details}")
                lines.append("")

        # Issues
        if report.issues:
            lines.append("## ISSUES TO ADDRESS")
            for issue in report.issues:
                lines.append(f"  • {issue}")
            lines.append("")

        # Improvements
        if report.improvements:
            lines.append("## SUGGESTED IMPROVEMENTS")
            for imp in report.improvements:
                lines.append(f"  • {imp}")
            lines.append("")

    # Timestamp
    lines.append(f"  Generated: {report.timestamp}")
    lines.append("")

    return "\n".join(lines)


def format_json(report: HealthReport) -> str:
    """Format report as JSON."""
    data = {
        "timestamp": report.timestamp,
        "overall_score": round(report.overall_score, 1),
        "grade": report.grade,
        "metrics": {
            name: {
                "name": m.name,
                "value": round(m.value, 1),
                "unit": m.unit,
                "status": m.status,
                "details": m.details
            }
            for name, m in report.metrics.items()
        },
        "issues": report.issues,
        "improvements": report.improvements
    }
    return json.dumps(data, indent=2)


def save_history(report: HealthReport) -> None:
    """Save report to history file."""
    history = []
    if HISTORY_FILE.exists():
        try:
            history = json.loads(HISTORY_FILE.read_text())
        except Exception:
            pass

    # Add current report
    history.append({
        "timestamp": report.timestamp,
        "score": round(report.overall_score, 1),
        "grade": report.grade
    })

    # Keep last 100 entries
    history = history[-100:]

    HISTORY_FILE.write_text(json.dumps(history, indent=2))


def main():
    import argparse

    parser = argparse.ArgumentParser(description="Code health dashboard")
    parser.add_argument("--json", "-j", action="store_true", help="JSON output")
    parser.add_argument("--quick", "-q", action="store_true", help="Quick summary only")
    parser.add_argument("--save", "-s", action="store_true", help="Save to history")
    args = parser.parse_args()

    print("Collecting metrics...", file=sys.stderr)
    report = collect_metrics()

    if args.save:
        save_history(report)
        print("Saved to history.", file=sys.stderr)

    if args.json:
        print(format_json(report))
    else:
        print(format_dashboard(report, args.quick))


if __name__ == "__main__":
    main()
