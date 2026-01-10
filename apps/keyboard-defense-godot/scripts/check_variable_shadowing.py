#!/usr/bin/env python3
"""
Variable Shadowing Checker

Finds variables that shadow outer scope variables:
- Function parameters shadowing class variables
- Local variables shadowing parameters
- Loop variables shadowing outer variables

Usage:
    python scripts/check_variable_shadowing.py              # Full report
    python scripts/check_variable_shadowing.py --file game/main.gd  # Single file
    python scripts/check_variable_shadowing.py --strict     # Include minor issues
    python scripts/check_variable_shadowing.py --json       # JSON output
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
class ShadowingIssue:
    """A variable shadowing issue."""
    file: str
    line: int
    variable: str
    inner_scope: str  # "parameter", "local", "loop"
    outer_scope: str  # "class", "parameter", "outer_local"
    outer_line: Optional[int]
    severity: str  # "warning", "info"
    context: str


@dataclass
class ShadowingReport:
    """Variable shadowing report."""
    files_checked: int = 0
    total_issues: int = 0
    warnings: int = 0
    info: int = 0
    issues: List[ShadowingIssue] = field(default_factory=list)
    by_file: Dict[str, List[ShadowingIssue]] = field(default_factory=lambda: defaultdict(list))
    by_type: Dict[str, int] = field(default_factory=lambda: defaultdict(int))


def extract_class_variables(content: str) -> Dict[str, int]:
    """Extract class-level variable declarations."""
    variables = {}
    lines = content.split('\n')
    in_function = False

    for i, line in enumerate(lines):
        stripped = line.strip()

        # Track function scope
        if re.match(r'^func\s+', stripped) or re.match(r'^static\s+func\s+', stripped):
            in_function = True
            continue

        # Exit function on dedent (simplified)
        if in_function and stripped and not line.startswith('\t') and not line.startswith('    '):
            in_function = False

        if in_function:
            continue

        # Skip comments and empty lines
        if not stripped or stripped.startswith('#'):
            continue

        # Match var declarations
        var_match = re.match(r'^(?:@onready\s+)?(?:@export[^\s]*\s+)?var\s+(\w+)', stripped)
        if var_match:
            variables[var_match.group(1)] = i + 1
            continue

        # Match const declarations
        const_match = re.match(r'^const\s+(\w+)', stripped)
        if const_match:
            variables[const_match.group(1)] = i + 1
            continue

        # Match signal declarations (can be referenced as variables)
        signal_match = re.match(r'^signal\s+(\w+)', stripped)
        if signal_match:
            variables[signal_match.group(1)] = i + 1

    return variables


def extract_function_info(lines: List[str], start_idx: int) -> Tuple[List[str], int, int]:
    """Extract function parameters and body end line."""
    parameters = []
    line = lines[start_idx].strip()

    # Extract parameters from function signature
    param_match = re.search(r'\(([^)]*)\)', line)
    if param_match:
        param_str = param_match.group(1)
        for param in param_str.split(','):
            param = param.strip()
            if param:
                # Handle typed parameters: name: Type = default
                name_match = re.match(r'(\w+)', param)
                if name_match:
                    parameters.append(name_match.group(1))

    # Find function end (simplified: next function or class-level declaration)
    end_idx = start_idx + 1
    base_indent = len(lines[start_idx]) - len(lines[start_idx].lstrip())

    while end_idx < len(lines):
        if end_idx >= len(lines):
            break

        line = lines[end_idx]
        if not line.strip():
            end_idx += 1
            continue

        current_indent = len(line) - len(line.lstrip())

        # If we're back to base indent and it's a new declaration, function ended
        if current_indent <= base_indent and line.strip():
            if re.match(r'^(func|static func|var|const|signal|class|enum)\s', line.strip()):
                break

        end_idx += 1

    return parameters, start_idx, end_idx


def analyze_function_body(lines: List[str], start_idx: int, end_idx: int,
                          class_vars: Dict[str, int], parameters: List[str],
                          file_path: str, strict: bool) -> List[ShadowingIssue]:
    """Analyze function body for shadowing issues."""
    issues = []
    local_vars: Dict[str, int] = {}  # var_name -> line_number

    for i in range(start_idx + 1, min(end_idx, len(lines))):
        line = lines[i]
        stripped = line.strip()

        if not stripped or stripped.startswith('#'):
            continue

        # Check for local variable declarations
        var_match = re.match(r'^var\s+(\w+)', stripped)
        if var_match:
            var_name = var_match.group(1)
            line_num = i + 1

            # Check if shadows class variable
            if var_name in class_vars:
                issues.append(ShadowingIssue(
                    file=file_path,
                    line=line_num,
                    variable=var_name,
                    inner_scope="local",
                    outer_scope="class",
                    outer_line=class_vars[var_name],
                    severity="warning",
                    context=stripped[:60]
                ))
            # Check if shadows parameter
            elif var_name in parameters:
                issues.append(ShadowingIssue(
                    file=file_path,
                    line=line_num,
                    variable=var_name,
                    inner_scope="local",
                    outer_scope="parameter",
                    outer_line=start_idx + 1,
                    severity="warning",
                    context=stripped[:60]
                ))

            local_vars[var_name] = line_num
            continue

        # Check for loop variables
        for_match = re.match(r'^for\s+(\w+)\s+in\s', stripped)
        if for_match:
            var_name = for_match.group(1)
            line_num = i + 1

            # Check if shadows class variable
            if var_name in class_vars:
                issues.append(ShadowingIssue(
                    file=file_path,
                    line=line_num,
                    variable=var_name,
                    inner_scope="loop",
                    outer_scope="class",
                    outer_line=class_vars[var_name],
                    severity="warning",
                    context=stripped[:60]
                ))
            # Check if shadows parameter
            elif var_name in parameters:
                issues.append(ShadowingIssue(
                    file=file_path,
                    line=line_num,
                    variable=var_name,
                    inner_scope="loop",
                    outer_scope="parameter",
                    outer_line=start_idx + 1,
                    severity="warning",
                    context=stripped[:60]
                ))
            # Check if shadows local (info level in strict mode)
            elif strict and var_name in local_vars:
                issues.append(ShadowingIssue(
                    file=file_path,
                    line=line_num,
                    variable=var_name,
                    inner_scope="loop",
                    outer_scope="outer_local",
                    outer_line=local_vars[var_name],
                    severity="info",
                    context=stripped[:60]
                ))

    # Check if parameters shadow class variables
    for param in parameters:
        if param in class_vars:
            issues.append(ShadowingIssue(
                file=file_path,
                line=start_idx + 1,
                variable=param,
                inner_scope="parameter",
                outer_scope="class",
                outer_line=class_vars[param],
                severity="warning",
                context=lines[start_idx].strip()[:60]
            ))

    return issues


def analyze_file(file_path: Path, rel_path: str, strict: bool) -> List[ShadowingIssue]:
    """Analyze a file for variable shadowing."""
    issues = []

    try:
        content = file_path.read_text(encoding='utf-8')
        lines = content.split('\n')
    except Exception:
        return issues

    # Extract class-level variables
    class_vars = extract_class_variables(content)

    # Find and analyze each function
    for i, line in enumerate(lines):
        stripped = line.strip()

        if re.match(r'^(?:static\s+)?func\s+', stripped):
            parameters, start_idx, end_idx = extract_function_info(lines, i)
            func_issues = analyze_function_body(
                lines, start_idx, end_idx, class_vars, parameters, rel_path, strict
            )
            issues.extend(func_issues)

    return issues


def check_variable_shadowing(target_file: Optional[str] = None, strict: bool = False) -> ShadowingReport:
    """Check for variable shadowing across the project."""
    report = ShadowingReport()

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

        issues = analyze_file(gd_file, rel_path, strict)

        for issue in issues:
            report.issues.append(issue)
            report.by_file[issue.file].append(issue)
            report.total_issues += 1

            shadow_type = f"{issue.inner_scope}_shadows_{issue.outer_scope}"
            report.by_type[shadow_type] += 1

            if issue.severity == "warning":
                report.warnings += 1
            else:
                report.info += 1

    return report


def format_report(report: ShadowingReport) -> str:
    """Format shadowing report as text."""
    lines = []
    lines.append("=" * 60)
    lines.append("VARIABLE SHADOWING CHECKER - KEYBOARD DEFENSE")
    lines.append("=" * 60)
    lines.append("")

    # Summary
    lines.append("## SUMMARY")
    lines.append(f"  Files checked:      {report.files_checked}")
    lines.append(f"  Total issues:       {report.total_issues}")
    lines.append(f"  Warnings:           {report.warnings}")
    lines.append(f"  Info:               {report.info}")
    lines.append("")

    # By type
    if report.by_type:
        lines.append("## ISSUES BY TYPE")
        for shadow_type, count in sorted(report.by_type.items(), key=lambda x: -x[1]):
            lines.append(f"  {shadow_type}: {count}")
        lines.append("")

    # Issues by file
    if report.issues:
        lines.append("## SHADOWING ISSUES")

        # Sort by severity (warnings first) then by file
        sorted_issues = sorted(report.issues, key=lambda x: (0 if x.severity == "warning" else 1, x.file, x.line))

        for issue in sorted_issues[:50]:
            severity_marker = "[WARN]" if issue.severity == "warning" else "[INFO]"
            lines.append(f"  {severity_marker} {issue.file}:{issue.line}")
            lines.append(f"    '{issue.variable}' ({issue.inner_scope}) shadows {issue.outer_scope} variable")
            if issue.outer_line:
                lines.append(f"    Outer declaration at line {issue.outer_line}")

        if len(report.issues) > 50:
            lines.append(f"  ... and {len(report.issues) - 50} more issues")
        lines.append("")

    # Files with most issues
    if report.by_file:
        lines.append("## FILES WITH MOST SHADOWING")
        sorted_files = sorted(report.by_file.items(), key=lambda x: -len(x[1]))[:10]
        for file_path, issues in sorted_files:
            warning_count = sum(1 for i in issues if i.severity == "warning")
            lines.append(f"  {file_path}: {len(issues)} issues ({warning_count} warnings)")
        lines.append("")

    # Health indicators
    lines.append("## HEALTH INDICATORS")
    if report.warnings == 0:
        lines.append("  [OK] No variable shadowing warnings")
    elif report.warnings < 10:
        lines.append(f"  [INFO] {report.warnings} shadowing warnings")
    elif report.warnings < 30:
        lines.append(f"  [WARN] {report.warnings} shadowing warnings - consider fixing")
    else:
        lines.append(f"  [WARN] {report.warnings} shadowing warnings - needs attention")

    lines.append("")
    return "\n".join(lines)


def format_json(report: ShadowingReport) -> str:
    """Format report as JSON."""
    data = {
        "summary": {
            "files_checked": report.files_checked,
            "total_issues": report.total_issues,
            "warnings": report.warnings,
            "info": report.info
        },
        "by_type": dict(report.by_type),
        "issues": [
            {
                "file": i.file,
                "line": i.line,
                "variable": i.variable,
                "inner_scope": i.inner_scope,
                "outer_scope": i.outer_scope,
                "outer_line": i.outer_line,
                "severity": i.severity
            }
            for i in report.issues[:100]
        ],
        "files_with_most_issues": [
            {"file": f, "count": len(issues)}
            for f, issues in sorted(report.by_file.items(), key=lambda x: -len(x[1]))[:20]
        ]
    }
    return json.dumps(data, indent=2)


def main():
    import argparse

    parser = argparse.ArgumentParser(description="Check variable shadowing")
    parser.add_argument("--json", "-j", action="store_true", help="JSON output")
    parser.add_argument("--file", "-f", type=str, help="Single file to check")
    parser.add_argument("--strict", "-s", action="store_true", help="Include minor issues")
    args = parser.parse_args()

    report = check_variable_shadowing(args.file, args.strict)

    if args.json:
        print(format_json(report))
    else:
        print(format_report(report))


if __name__ == "__main__":
    main()
