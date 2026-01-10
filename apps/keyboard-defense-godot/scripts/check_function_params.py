#!/usr/bin/env python3
"""
Function Parameters Checker

Analyzes function parameter patterns:
- Functions with too many parameters
- Unused parameters
- Parameters with default values placement
- Inconsistent parameter naming

Usage:
    python scripts/check_function_params.py              # Full report
    python scripts/check_function_params.py --file game/main.gd  # Single file
    python scripts/check_function_params.py --threshold 5  # Custom max params
    python scripts/check_function_params.py --json       # JSON output
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

# Default thresholds
DEFAULT_MAX_PARAMS = 5
MANY_PARAMS_THRESHOLD = 7


@dataclass
class FunctionParam:
    """A function parameter."""
    name: str
    type_hint: Optional[str]
    has_default: bool
    default_value: Optional[str]


@dataclass
class FunctionInfo:
    """Information about a function."""
    file: str
    line: int
    name: str
    params: List[FunctionParam]
    is_static: bool
    is_private: bool
    unused_params: List[str]
    issues: List[str]


@dataclass
class ParamReport:
    """Function parameters report."""
    files_checked: int = 0
    total_functions: int = 0
    functions_with_many_params: int = 0
    functions_with_unused_params: int = 0
    total_params: int = 0
    typed_params: int = 0
    functions: List[FunctionInfo] = field(default_factory=list)
    by_param_count: Dict[int, int] = field(default_factory=lambda: defaultdict(int))
    issues: List[Tuple[str, int, str]] = field(default_factory=list)  # (file, line, message)


def parse_parameters(param_string: str) -> List[FunctionParam]:
    """Parse function parameters from signature."""
    params = []
    if not param_string.strip():
        return params

    # Split by comma, but handle nested parentheses/brackets
    depth = 0
    current = ""
    for char in param_string:
        if char in '([{':
            depth += 1
        elif char in ')]}':
            depth -= 1
        elif char == ',' and depth == 0:
            if current.strip():
                params.append(parse_single_param(current.strip()))
            current = ""
            continue
        current += char

    if current.strip():
        params.append(parse_single_param(current.strip()))

    return params


def parse_single_param(param: str) -> FunctionParam:
    """Parse a single parameter."""
    # Handle: name, name: Type, name = default, name: Type = default
    has_default = '=' in param
    default_value = None
    type_hint = None

    if has_default:
        parts = param.split('=', 1)
        param_part = parts[0].strip()
        default_value = parts[1].strip()
    else:
        param_part = param

    if ':' in param_part:
        name_part, type_part = param_part.split(':', 1)
        name = name_part.strip()
        type_hint = type_part.strip()
    else:
        name = param_part.strip()

    return FunctionParam(
        name=name,
        type_hint=type_hint,
        has_default=has_default,
        default_value=default_value
    )


def find_unused_params(lines: List[str], start_idx: int, end_idx: int, params: List[FunctionParam]) -> List[str]:
    """Find parameters that are never used in function body."""
    unused = []

    # Build set of parameter names
    param_names = {p.name for p in params}

    # Collect function body
    body = "\n".join(lines[start_idx + 1:end_idx])

    for param in params:
        name = param.name
        # Skip if it's a common ignored pattern
        if name.startswith('_'):
            continue

        # Check if name appears in body (as word boundary)
        if not re.search(rf'\b{re.escape(name)}\b', body):
            unused.append(name)

    return unused


def analyze_file(file_path: Path, rel_path: str, max_params: int) -> Tuple[List[FunctionInfo], List[Tuple[str, int, str]]]:
    """Analyze a file for function parameter issues."""
    functions = []
    issues = []

    try:
        content = file_path.read_text(encoding='utf-8')
        lines = content.split('\n')
    except Exception:
        return functions, issues

    i = 0
    while i < len(lines):
        line = lines[i]
        stripped = line.strip()

        # Find function declaration
        func_match = re.match(r'^(static\s+)?func\s+(_?\w+)\s*\(([^)]*)\)', stripped)
        if func_match:
            is_static = func_match.group(1) is not None
            func_name = func_match.group(2)
            param_string = func_match.group(3)
            is_private = func_name.startswith('_')

            params = parse_parameters(param_string)

            # Find function end
            base_indent = len(line) - len(line.lstrip())
            end_idx = i + 1
            while end_idx < len(lines):
                next_line = lines[end_idx]
                if not next_line.strip():
                    end_idx += 1
                    continue
                next_indent = len(next_line) - len(next_line.lstrip())
                if next_indent <= base_indent and next_line.strip():
                    if re.match(r'^(func|static func|var|const|signal|class|enum)\s', next_line.strip()):
                        break
                end_idx += 1

            # Find unused parameters
            unused_params = find_unused_params(lines, i, end_idx, params)

            # Collect issues
            func_issues = []

            # Too many parameters
            if len(params) > max_params:
                msg = f"Function '{func_name}' has {len(params)} parameters (max {max_params})"
                func_issues.append(msg)
                issues.append((rel_path, i + 1, msg))

            # Unused parameters
            if unused_params and not is_private:
                msg = f"Function '{func_name}' has unused parameters: {', '.join(unused_params)}"
                func_issues.append(msg)
                issues.append((rel_path, i + 1, msg))

            # Default parameters not at end
            saw_default = False
            for param in params:
                if param.has_default:
                    saw_default = True
                elif saw_default:
                    msg = f"Function '{func_name}': non-default param '{param.name}' after default param"
                    func_issues.append(msg)
                    issues.append((rel_path, i + 1, msg))
                    break

            functions.append(FunctionInfo(
                file=rel_path,
                line=i + 1,
                name=func_name,
                params=params,
                is_static=is_static,
                is_private=is_private,
                unused_params=unused_params,
                issues=func_issues
            ))

            i = end_idx
            continue

        i += 1

    return functions, issues


def check_function_params(target_file: Optional[str] = None, max_params: int = DEFAULT_MAX_PARAMS) -> ParamReport:
    """Check function parameters across the project."""
    report = ParamReport()

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

        functions, issues = analyze_file(gd_file, rel_path, max_params)

        for func in functions:
            report.functions.append(func)
            report.total_functions += 1
            report.by_param_count[len(func.params)] += 1
            report.total_params += len(func.params)
            report.typed_params += sum(1 for p in func.params if p.type_hint)

            if len(func.params) > max_params:
                report.functions_with_many_params += 1

            if func.unused_params:
                report.functions_with_unused_params += 1

        report.issues.extend(issues)

    return report


def format_report(report: ParamReport, max_params: int) -> str:
    """Format parameter report as text."""
    lines = []
    lines.append("=" * 60)
    lines.append("FUNCTION PARAMETERS CHECKER - KEYBOARD DEFENSE")
    lines.append("=" * 60)
    lines.append("")

    # Summary
    lines.append("## SUMMARY")
    lines.append(f"  Files checked:            {report.files_checked}")
    lines.append(f"  Total functions:          {report.total_functions}")
    lines.append(f"  Functions with >{max_params} params: {report.functions_with_many_params}")
    lines.append(f"  Functions with unused:    {report.functions_with_unused_params}")
    lines.append(f"  Total parameters:         {report.total_params}")
    lines.append(f"  Typed parameters:         {report.typed_params}")
    if report.total_params > 0:
        typed_pct = report.typed_params / report.total_params * 100
        lines.append(f"  Type hint coverage:       {typed_pct:.0f}%")
    lines.append("")

    # Parameter count distribution
    lines.append("## PARAMETER COUNT DISTRIBUTION")
    for count in sorted(report.by_param_count.keys()):
        num_funcs = report.by_param_count[count]
        bar = "#" * min(num_funcs // 10, 30)
        lines.append(f"  {count} params: {num_funcs:4d} {bar}")
    lines.append("")

    # Functions with many parameters
    many_param_funcs = [f for f in report.functions if len(f.params) > max_params]
    if many_param_funcs:
        lines.append(f"## FUNCTIONS WITH >{max_params} PARAMETERS")
        sorted_funcs = sorted(many_param_funcs, key=lambda x: -len(x.params))
        for func in sorted_funcs[:20]:
            lines.append(f"  {func.file}:{func.line}")
            lines.append(f"    {func.name}(): {len(func.params)} parameters")
            param_names = [p.name for p in func.params]
            lines.append(f"    Params: {', '.join(param_names[:8])}" + ("..." if len(param_names) > 8 else ""))

        if len(many_param_funcs) > 20:
            lines.append(f"  ... and {len(many_param_funcs) - 20} more")
        lines.append("")

    # Functions with unused parameters
    unused_funcs = [f for f in report.functions if f.unused_params]
    if unused_funcs:
        lines.append("## FUNCTIONS WITH UNUSED PARAMETERS")
        for func in unused_funcs[:20]:
            lines.append(f"  {func.file}:{func.line}")
            lines.append(f"    {func.name}(): unused: {', '.join(func.unused_params)}")

        if len(unused_funcs) > 20:
            lines.append(f"  ... and {len(unused_funcs) - 20} more")
        lines.append("")

    # Health indicators
    lines.append("## HEALTH INDICATORS")
    if report.functions_with_many_params == 0:
        lines.append(f"  [OK] No functions with >{max_params} parameters")
    elif report.functions_with_many_params < 10:
        lines.append(f"  [INFO] {report.functions_with_many_params} functions with many parameters")
    else:
        lines.append(f"  [WARN] {report.functions_with_many_params} functions with too many parameters")

    if report.functions_with_unused_params == 0:
        lines.append("  [OK] No unused parameters detected")
    elif report.functions_with_unused_params < 20:
        lines.append(f"  [INFO] {report.functions_with_unused_params} functions with unused parameters")
    else:
        lines.append(f"  [WARN] {report.functions_with_unused_params} functions with unused parameters")

    avg_params = report.total_params / report.total_functions if report.total_functions > 0 else 0
    lines.append(f"  [INFO] Average parameters per function: {avg_params:.1f}")

    lines.append("")
    return "\n".join(lines)


def format_json(report: ParamReport) -> str:
    """Format report as JSON."""
    data = {
        "summary": {
            "files_checked": report.files_checked,
            "total_functions": report.total_functions,
            "functions_with_many_params": report.functions_with_many_params,
            "functions_with_unused_params": report.functions_with_unused_params,
            "total_params": report.total_params,
            "typed_params": report.typed_params
        },
        "param_distribution": dict(report.by_param_count),
        "functions_with_many_params": [
            {
                "file": f.file,
                "line": f.line,
                "name": f.name,
                "param_count": len(f.params),
                "params": [p.name for p in f.params]
            }
            for f in sorted(report.functions, key=lambda x: -len(x.params))[:30]
            if len(f.params) > DEFAULT_MAX_PARAMS
        ],
        "functions_with_unused_params": [
            {
                "file": f.file,
                "line": f.line,
                "name": f.name,
                "unused": f.unused_params
            }
            for f in report.functions if f.unused_params
        ][:30]
    }
    return json.dumps(data, indent=2)


def main():
    import argparse

    parser = argparse.ArgumentParser(description="Check function parameters")
    parser.add_argument("--json", "-j", action="store_true", help="JSON output")
    parser.add_argument("--file", "-f", type=str, help="Single file to check")
    parser.add_argument("--threshold", "-t", type=int, default=DEFAULT_MAX_PARAMS,
                        help=f"Max parameters threshold (default {DEFAULT_MAX_PARAMS})")
    args = parser.parse_args()

    report = check_function_params(args.file, args.threshold)

    if args.json:
        print(format_json(report))
    else:
        print(format_report(report, args.threshold))


if __name__ == "__main__":
    main()
