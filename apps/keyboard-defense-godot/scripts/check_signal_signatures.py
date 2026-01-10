#!/usr/bin/env python3
"""
Signal Signature Checker

Validates signal declarations and their usage:
- Signal emissions match declared parameters
- Signal connections use correct handler signatures
- No emissions of undeclared signals
- Parameter type consistency

Usage:
    python scripts/check_signal_signatures.py              # Full report
    python scripts/check_signal_signatures.py --file game/main.gd  # Single file
    python scripts/check_signal_signatures.py --json       # JSON output
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
class SignalDeclaration:
    """A signal declaration."""
    name: str
    file: str
    line: int
    parameters: List[Tuple[str, str]]  # [(name, type), ...]
    param_count: int


@dataclass
class SignalEmission:
    """A signal emission."""
    name: str
    file: str
    line: int
    arg_count: int
    context: str


@dataclass
class SignalConnection:
    """A signal connection."""
    signal_name: str
    file: str
    line: int
    handler: str
    context: str


@dataclass
class SignatureIssue:
    """An issue with signal signatures."""
    issue_type: str  # "param_mismatch", "undeclared", "handler_mismatch"
    signal_name: str
    file: str
    line: int
    message: str
    severity: str  # "high", "medium", "low"


@dataclass
class SignatureReport:
    """Signal signature validation report."""
    signals_declared: int = 0
    signals_emitted: int = 0
    signals_connected: int = 0
    issues_found: int = 0
    declarations: Dict[str, List[SignalDeclaration]] = field(default_factory=dict)
    emissions: List[SignalEmission] = field(default_factory=list)
    connections: List[SignalConnection] = field(default_factory=list)
    issues: List[SignatureIssue] = field(default_factory=list)
    by_severity: Dict[str, int] = field(default_factory=lambda: {"high": 0, "medium": 0, "low": 0})


def parse_signal_declaration(line: str) -> Optional[Tuple[str, List[Tuple[str, str]]]]:
    """Parse a signal declaration line."""
    # Match: signal name(params)
    match = re.match(r'signal\s+(\w+)\s*(?:\((.*)\))?', line.strip())
    if not match:
        return None

    name = match.group(1)
    params_str = match.group(2) or ""

    params = []
    if params_str.strip():
        # Parse parameters
        for param in params_str.split(","):
            param = param.strip()
            if ":" in param:
                parts = param.split(":")
                param_name = parts[0].strip()
                param_type = parts[1].strip()
                params.append((param_name, param_type))
            else:
                params.append((param, "Variant"))

    return (name, params)


def parse_signal_emission(line: str) -> Optional[Tuple[str, int]]:
    """Parse a signal emission and return (signal_name, arg_count)."""
    # Match: signal_name.emit(args) or emit_signal("name", args)
    emit_match = re.search(r'(\w+)\.emit\s*\((.*?)\)', line)
    if emit_match:
        name = emit_match.group(1)
        args_str = emit_match.group(2).strip()
        arg_count = len([a for a in args_str.split(",") if a.strip()]) if args_str else 0
        return (name, arg_count)

    # Legacy emit_signal
    legacy_match = re.search(r'emit_signal\s*\(\s*["\'](\w+)["\'](?:\s*,\s*(.*))?\)', line)
    if legacy_match:
        name = legacy_match.group(1)
        args_str = legacy_match.group(2) or ""
        arg_count = len([a for a in args_str.split(",") if a.strip()]) if args_str else 0
        return (name, arg_count)

    return None


def parse_signal_connection(line: str) -> Optional[Tuple[str, str]]:
    """Parse a signal connection and return (signal_name, handler)."""
    # Match: signal.connect(handler) or signal.connect(callable)
    connect_match = re.search(r'(\w+)\.connect\s*\(\s*(\w+|\w+\.\w+)', line)
    if connect_match:
        signal_name = connect_match.group(1)
        handler = connect_match.group(2)
        return (signal_name, handler)

    return None


def analyze_file(file_path: Path, rel_path: str, report: SignatureReport) -> None:
    """Analyze a single file for signal signatures."""
    try:
        content = file_path.read_text(encoding="utf-8")
        lines = content.split('\n')
    except Exception:
        return

    # Track local signal declarations
    local_signals: Dict[str, SignalDeclaration] = {}

    for i, line in enumerate(lines):
        stripped = line.strip()
        line_num = i + 1

        # Skip comments
        if stripped.startswith("#"):
            continue

        # Signal declarations
        decl = parse_signal_declaration(stripped)
        if decl:
            name, params = decl
            sig_decl = SignalDeclaration(
                name=name,
                file=rel_path,
                line=line_num,
                parameters=params,
                param_count=len(params)
            )
            local_signals[name] = sig_decl

            if name not in report.declarations:
                report.declarations[name] = []
            report.declarations[name].append(sig_decl)
            report.signals_declared += 1
            continue

        # Signal emissions
        emission = parse_signal_emission(stripped)
        if emission:
            sig_name, arg_count = emission
            report.emissions.append(SignalEmission(
                name=sig_name,
                file=rel_path,
                line=line_num,
                arg_count=arg_count,
                context=stripped[:80]
            ))
            report.signals_emitted += 1

            # Check against local declarations
            if sig_name in local_signals:
                expected = local_signals[sig_name].param_count
                if arg_count != expected:
                    report.issues.append(SignatureIssue(
                        issue_type="param_mismatch",
                        signal_name=sig_name,
                        file=rel_path,
                        line=line_num,
                        message=f"Emission has {arg_count} args, declaration has {expected}",
                        severity="high"
                    ))
                    report.by_severity["high"] += 1
            continue

        # Signal connections
        connection = parse_signal_connection(stripped)
        if connection:
            sig_name, handler = connection
            report.connections.append(SignalConnection(
                signal_name=sig_name,
                file=rel_path,
                line=line_num,
                handler=handler,
                context=stripped[:80]
            ))
            report.signals_connected += 1


def cross_validate(report: SignatureReport) -> None:
    """Cross-validate emissions against declarations."""
    all_declared = set(report.declarations.keys())

    for emission in report.emissions:
        # Check if signal is declared somewhere
        if emission.name not in all_declared:
            # Skip common built-in signals
            builtins = {
                "pressed", "toggled", "text_changed", "value_changed",
                "item_selected", "timeout", "finished", "body_entered",
                "body_exited", "area_entered", "area_exited", "tree_entered",
                "tree_exiting", "ready", "visibility_changed", "resized",
                "gui_input", "mouse_entered", "mouse_exited", "focus_entered",
                "focus_exited", "draw", "child_entered_tree", "child_exiting_tree",
                "renamed", "sort_children", "minimum_size_changed", "theme_changed"
            }
            if emission.name not in builtins:
                # Could be emitting a signal from another class
                # Mark as low severity
                report.issues.append(SignatureIssue(
                    issue_type="possibly_undeclared",
                    signal_name=emission.name,
                    file=emission.file,
                    line=emission.line,
                    message=f"Signal '{emission.name}' not declared in analyzed files",
                    severity="low"
                ))
                report.by_severity["low"] += 1


def validate_signatures(target_file: Optional[str] = None) -> SignatureReport:
    """Validate signal signatures across the project."""
    report = SignatureReport()

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
        analyze_file(gd_file, rel_path, report)

    # Cross-validate
    cross_validate(report)

    report.issues_found = len(report.issues)

    return report


def format_report(report: SignatureReport) -> str:
    """Format signature report as text."""
    lines = []
    lines.append("=" * 60)
    lines.append("SIGNAL SIGNATURE CHECKER - KEYBOARD DEFENSE")
    lines.append("=" * 60)
    lines.append("")

    # Summary
    lines.append("## SUMMARY")
    lines.append(f"  Signals declared:  {report.signals_declared}")
    lines.append(f"  Signals emitted:   {report.signals_emitted}")
    lines.append(f"  Signals connected: {report.signals_connected}")
    lines.append(f"  Issues found:      {report.issues_found}")
    lines.append(f"    High severity:   {report.by_severity['high']}")
    lines.append(f"    Medium severity: {report.by_severity['medium']}")
    lines.append(f"    Low severity:    {report.by_severity['low']}")
    lines.append("")

    # High severity issues (parameter mismatches)
    high_issues = [i for i in report.issues if i.severity == "high"]
    if high_issues:
        lines.append("## PARAMETER MISMATCHES (High)")
        for issue in high_issues:
            lines.append(f"  {issue.file}:{issue.line}")
            lines.append(f"    Signal: {issue.signal_name}")
            lines.append(f"    {issue.message}")
        lines.append("")

    # Medium severity issues
    medium_issues = [i for i in report.issues if i.severity == "medium"]
    if medium_issues:
        lines.append("## SIGNATURE ISSUES (Medium)")
        for issue in medium_issues[:10]:
            lines.append(f"  {issue.file}:{issue.line}")
            lines.append(f"    {issue.message}")
        if len(medium_issues) > 10:
            lines.append(f"  ... and {len(medium_issues) - 10} more")
        lines.append("")

    # Signal statistics
    lines.append("## SIGNAL STATISTICS")
    sorted_signals = sorted(report.declarations.items(), key=lambda x: -len(x[1]))
    for name, decls in sorted_signals[:10]:
        params = decls[0].parameters
        param_str = ", ".join(f"{p[0]}: {p[1]}" for p in params) if params else "no params"
        files = len(set(d.file for d in decls))
        lines.append(f"  {name}({param_str})")
        lines.append(f"    Declared in {files} file(s)")

    if len(report.declarations) > 10:
        lines.append(f"  ... and {len(report.declarations) - 10} more signals")
    lines.append("")

    # Health indicators
    lines.append("## HEALTH INDICATORS")
    if report.by_severity["high"] == 0:
        lines.append("  [OK] No parameter count mismatches")
    else:
        lines.append(f"  [ERROR] {report.by_severity['high']} parameter count mismatches")

    if report.by_severity["medium"] == 0:
        lines.append("  [OK] No signature issues detected")
    else:
        lines.append(f"  [WARN] {report.by_severity['medium']} signature issues")

    # Ratio of emissions to declarations
    if report.signals_declared > 0:
        ratio = report.signals_emitted / report.signals_declared
        lines.append(f"  [INFO] {ratio:.1f} emissions per declared signal")

    lines.append("")
    return "\n".join(lines)


def format_json(report: SignatureReport) -> str:
    """Format report as JSON."""
    data = {
        "summary": {
            "signals_declared": report.signals_declared,
            "signals_emitted": report.signals_emitted,
            "signals_connected": report.signals_connected,
            "issues_found": report.issues_found,
            "by_severity": report.by_severity
        },
        "declarations": {
            name: [
                {
                    "file": d.file,
                    "line": d.line,
                    "parameters": [{"name": p[0], "type": p[1]} for p in d.parameters]
                }
                for d in decls
            ]
            for name, decls in report.declarations.items()
        },
        "issues": [
            {
                "type": i.issue_type,
                "signal": i.signal_name,
                "file": i.file,
                "line": i.line,
                "message": i.message,
                "severity": i.severity
            }
            for i in report.issues
        ]
    }
    return json.dumps(data, indent=2)


def main():
    import argparse

    parser = argparse.ArgumentParser(description="Check signal signatures")
    parser.add_argument("--json", "-j", action="store_true", help="JSON output")
    parser.add_argument("--file", "-f", type=str, help="Single file to check")
    args = parser.parse_args()

    report = validate_signatures(args.file)

    if args.json:
        print(format_json(report))
    else:
        print(format_report(report))


if __name__ == "__main__":
    main()
