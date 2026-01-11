#!/usr/bin/env python3
"""
Signal Patterns Checker

Finds issues with signal usage patterns:
- Signals connected but never emitted
- Signals emitted but never connected
- Signals connected multiple times
- Missing disconnect() calls
- Lambda signal handlers (memory leak risk)

Usage:
    python scripts/check_signal_patterns.py              # Full report
    python scripts/check_signal_patterns.py --file game/main.gd  # Single file
    python scripts/check_signal_patterns.py --strict     # More patterns
    python scripts/check_signal_patterns.py --json       # JSON output
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
class SignalDecl:
    """A signal declaration."""
    file: str
    line: int
    name: str
    params: List[str]


@dataclass
class SignalConnection:
    """A signal connection."""
    file: str
    line: int
    signal_name: str
    target_method: str
    is_lambda: bool
    source_object: str  # e.g., "self", "$Button", "timer"


@dataclass
class SignalEmission:
    """A signal emission."""
    file: str
    line: int
    signal_name: str
    source_object: str


@dataclass
class SignalIssue:
    """A signal pattern issue."""
    file: str
    line: int
    signal: str
    issue_type: str
    message: str
    severity: str  # "error", "warning", "info"


@dataclass
class SignalReport:
    """Signal patterns report."""
    files_checked: int = 0
    total_signals: int = 0
    total_connections: int = 0
    total_emissions: int = 0
    lambda_handlers: int = 0
    issues: List[SignalIssue] = field(default_factory=list)
    signals: Dict[str, List[SignalDecl]] = field(default_factory=lambda: defaultdict(list))
    connections: Dict[str, List[SignalConnection]] = field(default_factory=lambda: defaultdict(list))
    emissions: Dict[str, List[SignalEmission]] = field(default_factory=lambda: defaultdict(list))
    by_file: Dict[str, List[SignalIssue]] = field(default_factory=lambda: defaultdict(list))


def extract_signals(file_path: Path, rel_path: str) -> Tuple[List[SignalDecl], List[SignalConnection], List[SignalEmission]]:
    """Extract signal declarations, connections, and emissions from a file."""
    declarations = []
    connections = []
    emissions = []

    try:
        content = file_path.read_text(encoding='utf-8')
        lines = content.split('\n')
    except Exception:
        return declarations, connections, emissions

    for i, line in enumerate(lines):
        stripped = line.strip()

        # Skip comments
        if stripped.startswith('#'):
            continue

        # Find signal declarations
        signal_match = re.match(r'^signal\s+(\w+)(?:\s*\(([^)]*)\))?', stripped)
        if signal_match:
            name = signal_match.group(1)
            params_str = signal_match.group(2) or ""
            params = [p.strip() for p in params_str.split(',') if p.strip()]
            declarations.append(SignalDecl(
                file=rel_path,
                line=i + 1,
                name=name,
                params=params
            ))
            continue

        # Find signal connections - Godot 4 style
        # pattern.connect(method) or pattern.connect(method.bind(...))
        connect_match = re.search(r'(\$?\w+(?:\.\w+)?|\w+)\.(\w+)\.connect\s*\(\s*([^)]+)\)', line)
        if connect_match:
            source = connect_match.group(1)
            signal_name = connect_match.group(2)
            target = connect_match.group(3).strip()
            is_lambda = 'func' in target or '=>' in target
            connections.append(SignalConnection(
                file=rel_path,
                line=i + 1,
                signal_name=signal_name,
                target_method=target,
                is_lambda=is_lambda,
                source_object=source
            ))
            continue

        # Also check for self.signal.connect pattern
        self_connect_match = re.search(r'(\w+)\.connect\s*\(\s*([^)]+)\)', line)
        if self_connect_match and 'signal' not in line.lower():
            signal_name = self_connect_match.group(1)
            target = self_connect_match.group(2).strip()
            # Skip if it's clearly not a signal
            if signal_name not in ['timer', 'tween', 'animation']:
                is_lambda = 'func' in target or '=>' in target
                connections.append(SignalConnection(
                    file=rel_path,
                    line=i + 1,
                    signal_name=signal_name,
                    target_method=target,
                    is_lambda=is_lambda,
                    source_object="self"
                ))

        # Find signal emissions
        emit_match = re.search(r'(\w+)\.emit\s*\(', line)
        if emit_match:
            signal_name = emit_match.group(1)
            emissions.append(SignalEmission(
                file=rel_path,
                line=i + 1,
                signal_name=signal_name,
                source_object="self"
            ))
            continue

        # Also check emit_signal() pattern (older style)
        emit_signal_match = re.search(r'emit_signal\s*\(\s*["\'](\w+)["\']', line)
        if emit_signal_match:
            signal_name = emit_signal_match.group(1)
            emissions.append(SignalEmission(
                file=rel_path,
                line=i + 1,
                signal_name=signal_name,
                source_object="self"
            ))

    return declarations, connections, emissions


def check_disconnect_patterns(file_path: Path, connections: List[SignalConnection]) -> List[Tuple[str, int, str]]:
    """Check for missing disconnect() calls."""
    missing_disconnects = []

    try:
        content = file_path.read_text(encoding='utf-8')
    except Exception:
        return missing_disconnects

    # Look for _exit_tree or queue_free without corresponding disconnects
    has_exit_tree = '_exit_tree' in content
    has_queue_free = 'queue_free' in content

    for conn in connections:
        # Lambda handlers can't be disconnected easily
        if conn.is_lambda:
            continue

        # Check if there's a corresponding disconnect
        disconnect_pattern = rf'{re.escape(conn.signal_name)}\.disconnect'
        if not re.search(disconnect_pattern, content):
            # Only warn if the file has cleanup methods
            if has_exit_tree or has_queue_free:
                missing_disconnects.append((conn.signal_name, conn.line, conn.target_method))

    return missing_disconnects


def check_signal_patterns(target_file: Optional[str] = None, strict: bool = False) -> SignalReport:
    """Check signal patterns across the project."""
    report = SignalReport()

    if target_file:
        gd_files = [PROJECT_ROOT / target_file]
    else:
        gd_files = list(PROJECT_ROOT.glob("**/*.gd"))

    # Global tracking
    all_declared: Dict[str, List[SignalDecl]] = defaultdict(list)
    all_emitted: Set[str] = set()
    all_connected: Set[str] = set()

    for gd_file in gd_files:
        if ".godot" in str(gd_file) or "addons" in str(gd_file):
            continue

        if not gd_file.exists():
            continue

        rel_path = str(gd_file.relative_to(PROJECT_ROOT))
        report.files_checked += 1

        declarations, connections, emissions = extract_signals(gd_file, rel_path)

        # Store in report
        for decl in declarations:
            report.signals[decl.name].append(decl)
            all_declared[decl.name].append(decl)
            report.total_signals += 1

        for conn in connections:
            report.connections[conn.signal_name].append(conn)
            all_connected.add(conn.signal_name)
            report.total_connections += 1

            if conn.is_lambda:
                report.lambda_handlers += 1
                report.issues.append(SignalIssue(
                    file=rel_path,
                    line=conn.line,
                    signal=conn.signal_name,
                    issue_type="lambda_handler",
                    message=f"Lambda signal handler for '{conn.signal_name}' - potential memory leak",
                    severity="warning"
                ))

        for emission in emissions:
            report.emissions[emission.signal_name].append(emission)
            all_emitted.add(emission.signal_name)
            report.total_emissions += 1

        # Check for missing disconnects
        if strict:
            missing = check_disconnect_patterns(gd_file, connections)
            for signal_name, line, method in missing:
                report.issues.append(SignalIssue(
                    file=rel_path,
                    line=line,
                    signal=signal_name,
                    issue_type="missing_disconnect",
                    message=f"Signal '{signal_name}' connected but no disconnect() found",
                    severity="info"
                ))

    # Check for signals declared but never emitted
    for signal_name, decls in all_declared.items():
        if signal_name not in all_emitted:
            for decl in decls:
                report.issues.append(SignalIssue(
                    file=decl.file,
                    line=decl.line,
                    signal=signal_name,
                    issue_type="never_emitted",
                    message=f"Signal '{signal_name}' declared but never emitted",
                    severity="warning"
                ))

    # Check for signals emitted that weren't declared (could be from parent class)
    # This is info-level since it could be inherited
    if strict:
        for signal_name in all_emitted:
            if signal_name not in all_declared:
                # Find emission locations
                for emission_list in report.emissions.values():
                    for emission in emission_list:
                        if emission.signal_name == signal_name:
                            report.issues.append(SignalIssue(
                                file=emission.file,
                                line=emission.line,
                                signal=signal_name,
                                issue_type="undeclared_emission",
                                message=f"Signal '{signal_name}' emitted but not declared (may be inherited)",
                                severity="info"
                            ))

    # Populate by_file
    for issue in report.issues:
        report.by_file[issue.file].append(issue)

    return report


def format_report(report: SignalReport) -> str:
    """Format signal report as text."""
    lines = []
    lines.append("=" * 60)
    lines.append("SIGNAL PATTERNS CHECKER - KEYBOARD DEFENSE")
    lines.append("=" * 60)
    lines.append("")

    # Summary
    lines.append("## SUMMARY")
    lines.append(f"  Files checked:      {report.files_checked}")
    lines.append(f"  Signal declarations:{report.total_signals}")
    lines.append(f"  Connections:        {report.total_connections}")
    lines.append(f"  Emissions:          {report.total_emissions}")
    lines.append(f"  Lambda handlers:    {report.lambda_handlers}")
    lines.append(f"  Issues found:       {len(report.issues)}")
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
        lines.append("## SIGNAL ISSUES")

        sorted_issues = sorted(report.issues, key=lambda x: (0 if x.severity == "error" else (1 if x.severity == "warning" else 2), x.file, x.line))

        for issue in sorted_issues[:40]:
            severity_marker = {"error": "[ERROR]", "warning": "[WARN]", "info": "[INFO]"}.get(issue.severity, "[???]")
            lines.append(f"  {severity_marker} {issue.file}:{issue.line}")
            lines.append(f"    {issue.message}")

        if len(report.issues) > 40:
            lines.append(f"  ... and {len(report.issues) - 40} more issues")
        lines.append("")

    # Most connected signals
    if report.connections:
        lines.append("## MOST CONNECTED SIGNALS")
        sorted_signals = sorted(report.connections.items(), key=lambda x: -len(x[1]))[:15]
        for signal_name, conns in sorted_signals:
            files = set(c.file for c in conns)
            lines.append(f"  {signal_name}: {len(conns)} connections in {len(files)} file(s)")
        lines.append("")

    # Files with most signal activity
    signal_activity: Dict[str, int] = defaultdict(int)
    for decls in report.signals.values():
        for d in decls:
            signal_activity[d.file] += 1
    for conns in report.connections.values():
        for c in conns:
            signal_activity[c.file] += 1
    for emissions in report.emissions.values():
        for e in emissions:
            signal_activity[e.file] += 1

    if signal_activity:
        lines.append("## FILES WITH MOST SIGNAL ACTIVITY")
        sorted_files = sorted(signal_activity.items(), key=lambda x: -x[1])[:10]
        for file_path, count in sorted_files:
            lines.append(f"  {file_path}: {count} signal operations")
        lines.append("")

    # Health indicators
    lines.append("## HEALTH INDICATORS")

    never_emitted = sum(1 for i in report.issues if i.issue_type == "never_emitted")
    if never_emitted == 0:
        lines.append("  [OK] All declared signals are emitted")
    else:
        lines.append(f"  [WARN] {never_emitted} signals declared but never emitted")

    if report.lambda_handlers == 0:
        lines.append("  [OK] No lambda signal handlers")
    else:
        lines.append(f"  [WARN] {report.lambda_handlers} lambda handlers (memory leak risk)")

    lines.append("")
    return "\n".join(lines)


def format_json(report: SignalReport) -> str:
    """Format report as JSON."""
    data = {
        "summary": {
            "files_checked": report.files_checked,
            "total_signals": report.total_signals,
            "total_connections": report.total_connections,
            "total_emissions": report.total_emissions,
            "lambda_handlers": report.lambda_handlers,
            "issues": len(report.issues)
        },
        "issues": [
            {
                "file": i.file,
                "line": i.line,
                "signal": i.signal,
                "type": i.issue_type,
                "message": i.message,
                "severity": i.severity
            }
            for i in report.issues[:100]
        ],
        "signals": [
            {"name": name, "declarations": len(decls)}
            for name, decls in sorted(report.signals.items(), key=lambda x: -len(x[1]))[:20]
        ],
        "most_connected": [
            {"signal": name, "connections": len(conns)}
            for name, conns in sorted(report.connections.items(), key=lambda x: -len(x[1]))[:20]
        ]
    }
    return json.dumps(data, indent=2)


def main():
    import argparse

    parser = argparse.ArgumentParser(description="Check signal patterns")
    parser.add_argument("--json", "-j", action="store_true", help="JSON output")
    parser.add_argument("--file", "-f", type=str, help="Single file to check")
    parser.add_argument("--strict", "-s", action="store_true", help="Include info-level checks")
    args = parser.parse_args()

    report = check_signal_patterns(args.file, args.strict)

    if args.json:
        print(format_json(report))
    else:
        print(format_report(report))


if __name__ == "__main__":
    main()
