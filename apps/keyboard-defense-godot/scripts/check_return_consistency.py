#!/usr/bin/env python3
"""
Return Consistency Checker

Finds issues with function return patterns:
- Functions with inconsistent return types
- Missing return statements in branches
- Functions that sometimes return void
- Return type mismatches with declaration

Usage:
    python scripts/check_return_consistency.py              # Full report
    python scripts/check_return_consistency.py --file game/main.gd  # Single file
    python scripts/check_return_consistency.py --strict     # More patterns
    python scripts/check_return_consistency.py --json       # JSON output
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
class FunctionInfo:
    """Information about a function."""
    file: str
    line: int
    name: str
    declared_return_type: Optional[str]
    has_return_value: bool
    has_void_return: bool
    return_count: int
    branch_count: int  # if/elif/else branches


@dataclass
class ReturnIssue:
    """A return consistency issue."""
    file: str
    line: int
    function: str
    issue_type: str
    message: str
    severity: str  # "error", "warning", "info"


@dataclass
class ReturnReport:
    """Return consistency report."""
    files_checked: int = 0
    total_functions: int = 0
    functions_with_returns: int = 0
    typed_returns: int = 0
    issues: List[ReturnIssue] = field(default_factory=list)
    functions: List[FunctionInfo] = field(default_factory=list)
    by_file: Dict[str, List[ReturnIssue]] = field(default_factory=lambda: defaultdict(list))


def analyze_function_returns(file_path: Path, rel_path: str, strict: bool) -> Tuple[List[FunctionInfo], List[ReturnIssue]]:
    """Analyze function return patterns in a file."""
    functions = []
    issues = []

    try:
        content = file_path.read_text(encoding='utf-8')
        lines = content.split('\n')
    except Exception:
        return functions, issues

    current_func = None
    current_func_line = 0
    current_func_indent = 0
    declared_return_type = None
    has_return_value = False
    has_void_return = False
    return_count = 0
    branch_count = 0
    in_match = False
    match_indent = 0

    for i, line in enumerate(lines):
        stripped = line.strip()
        current_indent = len(line) - len(line.lstrip()) if line.strip() else 0

        # Skip comments
        if stripped.startswith('#'):
            continue

        # Detect function start
        func_match = re.match(r'^func\s+(\w+)\s*\([^)]*\)\s*(?:->\s*(\w+))?', stripped)
        if func_match:
            # Save previous function
            if current_func:
                functions.append(FunctionInfo(
                    file=rel_path,
                    line=current_func_line,
                    name=current_func,
                    declared_return_type=declared_return_type,
                    has_return_value=has_return_value,
                    has_void_return=has_void_return,
                    return_count=return_count,
                    branch_count=branch_count
                ))

                # Check for issues
                func_issues = check_function_issues(
                    rel_path, current_func_line, current_func,
                    declared_return_type, has_return_value, has_void_return,
                    return_count, branch_count, strict
                )
                issues.extend(func_issues)

            # Start new function
            current_func = func_match.group(1)
            current_func_line = i + 1
            current_func_indent = current_indent
            declared_return_type = func_match.group(2)
            has_return_value = False
            has_void_return = False
            return_count = 0
            branch_count = 0
            in_match = False
            continue

        # Exit function on dedent to class level
        if current_func and stripped and current_indent <= current_func_indent:
            if re.match(r'^(func|var|const|signal|class|enum|@|static)', stripped):
                # Save function
                functions.append(FunctionInfo(
                    file=rel_path,
                    line=current_func_line,
                    name=current_func,
                    declared_return_type=declared_return_type,
                    has_return_value=has_return_value,
                    has_void_return=has_void_return,
                    return_count=return_count,
                    branch_count=branch_count
                ))

                func_issues = check_function_issues(
                    rel_path, current_func_line, current_func,
                    declared_return_type, has_return_value, has_void_return,
                    return_count, branch_count, strict
                )
                issues.extend(func_issues)

                # Reset if starting new func
                if func_match := re.match(r'^func\s+(\w+)\s*\([^)]*\)\s*(?:->\s*(\w+))?', stripped):
                    current_func = func_match.group(1)
                    current_func_line = i + 1
                    current_func_indent = current_indent
                    declared_return_type = func_match.group(2)
                    has_return_value = False
                    has_void_return = False
                    return_count = 0
                    branch_count = 0
                else:
                    current_func = None
                continue

        if not current_func:
            continue

        # Track match statements
        if stripped.startswith('match '):
            in_match = True
            match_indent = current_indent

        if in_match and current_indent <= match_indent and stripped and not stripped.startswith('match'):
            in_match = False

        # Count branches
        if re.match(r'^(if|elif|else)\b', stripped):
            branch_count += 1

        # Analyze return statements
        return_match = re.match(r'^return\b(.*)$', stripped)
        if return_match:
            return_count += 1
            return_value = return_match.group(1).strip()
            if return_value:
                has_return_value = True
            else:
                has_void_return = True

    # Handle last function
    if current_func:
        functions.append(FunctionInfo(
            file=rel_path,
            line=current_func_line,
            name=current_func,
            declared_return_type=declared_return_type,
            has_return_value=has_return_value,
            has_void_return=has_void_return,
            return_count=return_count,
            branch_count=branch_count
        ))

        func_issues = check_function_issues(
            rel_path, current_func_line, current_func,
            declared_return_type, has_return_value, has_void_return,
            return_count, branch_count, strict
        )
        issues.extend(func_issues)

    return functions, issues


def check_function_issues(
    file: str, line: int, name: str,
    declared_type: Optional[str], has_value: bool, has_void: bool,
    return_count: int, branch_count: int, strict: bool
) -> List[ReturnIssue]:
    """Check a function for return consistency issues."""
    issues = []

    # Skip special methods
    if name in ['_init', '_ready', '_process', '_physics_process', '_input',
                '_unhandled_input', '_enter_tree', '_exit_tree', '_draw',
                '_notification', '_get_configuration_warning']:
        return issues

    # Issue: Has both value returns and void returns
    if has_value and has_void:
        issues.append(ReturnIssue(
            file=file,
            line=line,
            function=name,
            issue_type="mixed_returns",
            message=f"Function '{name}' has both value returns and void returns",
            severity="warning"
        ))

    # Issue: Declared return type but has void return
    if declared_type and declared_type != "void" and has_void:
        issues.append(ReturnIssue(
            file=file,
            line=line,
            function=name,
            issue_type="void_with_type",
            message=f"Function '{name}' declared as -> {declared_type} but has void return",
            severity="warning"
        ))

    # Issue: Returns value but no declared type
    if has_value and not declared_type and strict:
        issues.append(ReturnIssue(
            file=file,
            line=line,
            function=name,
            issue_type="untyped_return",
            message=f"Function '{name}' returns value but has no return type annotation",
            severity="info"
        ))

    # Issue: Multiple branches but fewer returns (potential missing return)
    if branch_count >= 2 and return_count > 0 and return_count < branch_count and has_value:
        if strict:
            issues.append(ReturnIssue(
                file=file,
                line=line,
                function=name,
                issue_type="potential_missing_return",
                message=f"Function '{name}' has {branch_count} branches but only {return_count} returns",
                severity="info"
            ))

    return issues


def check_return_consistency(target_file: Optional[str] = None, strict: bool = False) -> ReturnReport:
    """Check return consistency across the project."""
    report = ReturnReport()

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

        functions, issues = analyze_function_returns(gd_file, rel_path, strict)

        for func in functions:
            report.functions.append(func)
            report.total_functions += 1

            if func.has_return_value:
                report.functions_with_returns += 1

            if func.declared_return_type:
                report.typed_returns += 1

        for issue in issues:
            report.issues.append(issue)
            report.by_file[issue.file].append(issue)

    return report


def format_report(report: ReturnReport) -> str:
    """Format return consistency report as text."""
    lines = []
    lines.append("=" * 60)
    lines.append("RETURN CONSISTENCY CHECKER - KEYBOARD DEFENSE")
    lines.append("=" * 60)
    lines.append("")

    # Summary
    lines.append("## SUMMARY")
    lines.append(f"  Files checked:         {report.files_checked}")
    lines.append(f"  Total functions:       {report.total_functions}")
    lines.append(f"  Functions with returns:{report.functions_with_returns}")
    lines.append(f"  Typed return funcs:    {report.typed_returns}")
    lines.append(f"  Issues found:          {len(report.issues)}")
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
        lines.append("## RETURN CONSISTENCY ISSUES")

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
        lines.append("## FILES WITH MOST RETURN ISSUES")
        sorted_files = sorted(report.by_file.items(), key=lambda x: -len(x[1]))[:10]
        for file_path, issues in sorted_files:
            warn_count = sum(1 for i in issues if i.severity == "warning")
            lines.append(f"  {file_path}: {len(issues)} ({warn_count} warnings)")
        lines.append("")

    # Health indicators
    lines.append("## HEALTH INDICATORS")

    mixed_returns = sum(1 for i in report.issues if i.issue_type == "mixed_returns")
    if mixed_returns == 0:
        lines.append("  [OK] No functions with mixed return types")
    else:
        lines.append(f"  [WARN] {mixed_returns} functions have inconsistent returns")

    if report.total_functions > 0:
        typed_ratio = report.typed_returns / report.total_functions * 100
        if typed_ratio >= 50:
            lines.append(f"  [OK] {typed_ratio:.0f}% functions have return type annotations")
        else:
            lines.append(f"  [INFO] Only {typed_ratio:.0f}% functions have return type annotations")

    lines.append("")
    return "\n".join(lines)


def format_json(report: ReturnReport) -> str:
    """Format report as JSON."""
    data = {
        "summary": {
            "files_checked": report.files_checked,
            "total_functions": report.total_functions,
            "functions_with_returns": report.functions_with_returns,
            "typed_returns": report.typed_returns,
            "issues": len(report.issues)
        },
        "issues": [
            {
                "file": i.file,
                "line": i.line,
                "function": i.function,
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

    parser = argparse.ArgumentParser(description="Check return consistency")
    parser.add_argument("--json", "-j", action="store_true", help="JSON output")
    parser.add_argument("--file", "-f", type=str, help="Single file to check")
    parser.add_argument("--strict", "-s", action="store_true", help="Include info-level checks")
    args = parser.parse_args()

    report = check_return_consistency(args.file, args.strict)

    if args.json:
        print(format_json(report))
    else:
        print(format_report(report))


if __name__ == "__main__":
    main()
