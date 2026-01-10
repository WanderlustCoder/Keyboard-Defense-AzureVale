#!/usr/bin/env python3
"""
Type Checker

Finds missing type annotations in GDScript code:
- Functions missing return types
- Parameters missing type hints
- Variables missing type annotations
- Reports type coverage percentage

Usage:
    python scripts/check_types.py              # Full report
    python scripts/check_types.py --strict     # Include private functions
    python scripts/check_types.py --layer sim  # Only sim layer
    python scripts/check_types.py --file game/main.gd  # Single file
    python scripts/check_types.py --json       # JSON output
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
class TypeIssue:
    """A type annotation issue."""
    file: str
    line: int
    issue_type: str  # "missing_return", "missing_param", "missing_var"
    name: str
    context: str = ""


@dataclass
class FunctionTypeInfo:
    """Type information for a function."""
    name: str
    file: str
    line: int
    has_return_type: bool = False
    return_type: str = ""
    params: List[Tuple[str, bool, str]] = field(default_factory=list)  # (name, has_type, type)
    is_private: bool = False
    is_static: bool = False


@dataclass
class TypeReport:
    """Type checking report."""
    functions: List[FunctionTypeInfo] = field(default_factory=list)
    issues: List[TypeIssue] = field(default_factory=list)
    by_file: Dict[str, Dict] = field(default_factory=dict)
    by_layer: Dict[str, Dict] = field(default_factory=dict)
    total_functions: int = 0
    typed_functions: int = 0
    total_params: int = 0
    typed_params: int = 0
    coverage_percent: float = 0.0


def get_layer(filepath: str) -> str:
    """Determine which architectural layer a file belongs to."""
    if filepath.startswith("sim/"):
        return "sim"
    elif filepath.startswith("game/"):
        return "game"
    elif filepath.startswith("ui/"):
        return "ui"
    elif filepath.startswith("scripts/"):
        return "scripts"
    elif filepath.startswith("tests/"):
        return "tests"
    return "other"


def parse_function(line: str) -> Optional[FunctionTypeInfo]:
    """Parse a function declaration line."""
    # Match: [static] func name(params) [-> ReturnType]:
    match = re.match(
        r'^(static\s+)?func\s+(\w+)\s*\(([^)]*)\)\s*(?:->\s*(\w+(?:\[[\w,\s]+\])?))?',
        line.strip()
    )
    if not match:
        return None

    is_static = match.group(1) is not None
    func_name = match.group(2)
    params_str = match.group(3)
    return_type = match.group(4)

    is_private = func_name.startswith('_')
    has_return_type = return_type is not None

    # Parse parameters
    params = []
    if params_str.strip():
        # Handle complex parameter patterns
        param_parts = []
        depth = 0
        current = ""
        for char in params_str:
            if char in '([{':
                depth += 1
            elif char in ')]}':
                depth -= 1
            elif char == ',' and depth == 0:
                param_parts.append(current.strip())
                current = ""
                continue
            current += char
        if current.strip():
            param_parts.append(current.strip())

        for param in param_parts:
            param = param.strip()
            if not param:
                continue

            # Check for type annotation
            # name: Type
            # name: Type = default
            # name := value (inferred)
            # name = value (no type)
            if ':=' in param:
                # Type inferred
                name = param.split(':=')[0].strip()
                params.append((name, True, "inferred"))
            elif ':' in param:
                # Explicit type
                parts = param.split(':')
                name = parts[0].strip()
                type_part = parts[1].split('=')[0].strip()
                params.append((name, True, type_part))
            else:
                # No type
                name = param.split('=')[0].strip()
                params.append((name, False, ""))

    return FunctionTypeInfo(
        name=func_name,
        file="",
        line=0,
        has_return_type=has_return_type,
        return_type=return_type or "",
        params=params,
        is_private=is_private,
        is_static=is_static
    )


def analyze_file(filepath: Path) -> Tuple[List[FunctionTypeInfo], List[TypeIssue]]:
    """Analyze a file for type annotations."""
    functions = []
    issues = []
    rel_path = str(filepath.relative_to(PROJECT_ROOT))

    try:
        content = filepath.read_text(encoding="utf-8")
        lines = content.split('\n')
    except Exception:
        return functions, issues

    for i, line in enumerate(lines):
        stripped = line.strip()

        # Check for function definition
        if stripped.startswith('func ') or stripped.startswith('static func '):
            func_info = parse_function(stripped)
            if func_info:
                func_info.file = rel_path
                func_info.line = i + 1
                functions.append(func_info)

                # Check for missing return type
                if not func_info.has_return_type:
                    issues.append(TypeIssue(
                        file=rel_path,
                        line=i + 1,
                        issue_type="missing_return",
                        name=func_info.name
                    ))

                # Check for untyped parameters
                for param_name, has_type, type_str in func_info.params:
                    if not has_type:
                        issues.append(TypeIssue(
                            file=rel_path,
                            line=i + 1,
                            issue_type="missing_param",
                            name=param_name,
                            context=func_info.name
                        ))

        # Check for untyped variable declarations (var without type)
        # var name = value  (no type)
        # var name: Type = value  (has type)
        # var name := value  (inferred type)
        var_match = re.match(r'^var\s+(\w+)\s*(?::\s*(\w+))?\s*(?::?=|$)', stripped)
        if var_match:
            var_name = var_match.group(1)
            has_type = var_match.group(2) is not None or ':=' in stripped
            if not has_type and '=' in stripped:
                # Variable assigned without type
                issues.append(TypeIssue(
                    file=rel_path,
                    line=i + 1,
                    issue_type="missing_var",
                    name=var_name
                ))

    return functions, issues


def analyze_types(layer_filter: Optional[str] = None, file_filter: Optional[str] = None,
                  include_private: bool = False) -> TypeReport:
    """Analyze type annotations across the codebase."""
    report = TypeReport()

    for gd_file in PROJECT_ROOT.glob("**/*.gd"):
        if ".godot" in str(gd_file) or "addons" in str(gd_file):
            continue

        rel_path = str(gd_file.relative_to(PROJECT_ROOT))
        layer = get_layer(rel_path)

        # Apply filters
        if layer_filter and layer != layer_filter:
            continue
        if file_filter and file_filter not in rel_path:
            continue

        functions, issues = analyze_file(gd_file)

        for func in functions:
            # Skip private functions unless strict mode
            if func.is_private and not include_private:
                continue

            report.functions.append(func)
            report.total_functions += 1

            if func.has_return_type:
                report.typed_functions += 1

            for param_name, has_type, type_str in func.params:
                report.total_params += 1
                if has_type:
                    report.typed_params += 1

        # Filter issues for private functions
        for issue in issues:
            if issue.issue_type in ["missing_return", "missing_param"]:
                # Find the corresponding function
                func = next((f for f in functions if f.name == issue.name or f.name == issue.context), None)
                if func and func.is_private and not include_private:
                    continue
            report.issues.append(issue)

        # File stats
        if functions:
            typed = sum(1 for f in functions if f.has_return_type and (include_private or not f.is_private))
            total = sum(1 for f in functions if include_private or not f.is_private)
            report.by_file[rel_path] = {
                "total": total,
                "typed": typed,
                "percent": (typed / max(total, 1)) * 100
            }

            # Layer stats
            if layer not in report.by_layer:
                report.by_layer[layer] = {"total": 0, "typed": 0}
            report.by_layer[layer]["total"] += total
            report.by_layer[layer]["typed"] += typed

    # Calculate overall coverage
    if report.total_functions > 0:
        report.coverage_percent = (report.typed_functions / report.total_functions) * 100

    return report


def format_report(report: TypeReport, show_all: bool = False) -> str:
    """Format type report as text."""
    lines = []
    lines.append("=" * 60)
    lines.append("TYPE CHECKER - KEYBOARD DEFENSE")
    lines.append("=" * 60)
    lines.append("")

    # Summary
    lines.append("## SUMMARY")
    lines.append(f"  Total functions:     {report.total_functions}")
    lines.append(f"  With return types:   {report.typed_functions}")
    lines.append(f"  Function coverage:   {report.coverage_percent:.1f}%")
    lines.append("")
    lines.append(f"  Total parameters:    {report.total_params}")
    lines.append(f"  With type hints:     {report.typed_params}")
    param_pct = (report.typed_params / max(report.total_params, 1)) * 100
    lines.append(f"  Parameter coverage:  {param_pct:.1f}%")
    lines.append("")

    # Coverage bar
    bar_width = 40
    filled = int(bar_width * report.coverage_percent / 100)
    bar = "[" + "=" * filled + " " * (bar_width - filled) + "]"
    lines.append(f"  {bar} {report.coverage_percent:.1f}%")
    lines.append("")

    # By layer
    lines.append("## COVERAGE BY LAYER")
    for layer in ["sim", "game", "ui", "scripts", "tests", "other"]:
        stats = report.by_layer.get(layer, {"total": 0, "typed": 0})
        if stats["total"] > 0:
            pct = (stats["typed"] / stats["total"]) * 100
            bar_filled = int(20 * pct / 100)
            mini_bar = "[" + "=" * bar_filled + " " * (20 - bar_filled) + "]"
            lines.append(f"  {layer:10} {mini_bar} {pct:5.1f}% ({stats['typed']}/{stats['total']})")
    lines.append("")

    # Issue summary by type
    missing_return = sum(1 for i in report.issues if i.issue_type == "missing_return")
    missing_param = sum(1 for i in report.issues if i.issue_type == "missing_param")
    missing_var = sum(1 for i in report.issues if i.issue_type == "missing_var")

    lines.append("## ISSUES BY TYPE")
    lines.append(f"  Missing return types:     {missing_return}")
    lines.append(f"  Missing parameter types:  {missing_param}")
    lines.append(f"  Untyped variables:        {missing_var}")
    lines.append("")

    # Files with lowest coverage
    lines.append("## FILES NEEDING TYPE ANNOTATIONS")
    file_coverage = [
        (f, d["percent"], d["total"] - d["typed"])
        for f, d in report.by_file.items()
        if d["total"] >= 3
    ]
    file_coverage.sort(key=lambda x: (x[1], -x[2]))

    for filepath, pct, missing in file_coverage[:15]:
        lines.append(f"  {pct:5.1f}%  ({missing} missing)  {filepath}")
    lines.append("")

    # Sample issues
    if not show_all:
        lines.append("## SAMPLE ISSUES (first 20)")
        for issue in report.issues[:20]:
            if issue.issue_type == "missing_return":
                lines.append(f"  {issue.file}:{issue.line}")
                lines.append(f"    func {issue.name}() missing return type")
            elif issue.issue_type == "missing_param":
                lines.append(f"  {issue.file}:{issue.line}")
                lines.append(f"    param '{issue.name}' in {issue.context}() missing type")
        if len(report.issues) > 20:
            lines.append(f"  ... and {len(report.issues) - 20} more issues")
        lines.append("")

    # Health indicators
    lines.append("## HEALTH INDICATORS")
    if report.coverage_percent >= 80:
        lines.append("  [OK] Good type coverage")
    elif report.coverage_percent >= 50:
        lines.append("  [INFO] Moderate type coverage")
    else:
        lines.append("  [WARN] Low type coverage - consider adding types")

    sim_stats = report.by_layer.get("sim", {"total": 0, "typed": 0})
    if sim_stats["total"] > 0:
        sim_pct = (sim_stats["typed"] / sim_stats["total"]) * 100
        if sim_pct < 50:
            lines.append(f"  [WARN] Sim layer at {sim_pct:.0f}% - critical layer needs types")
        else:
            lines.append(f"  [OK] Sim layer at {sim_pct:.0f}%")

    lines.append("")
    return "\n".join(lines)


def format_json(report: TypeReport) -> str:
    """Format report as JSON."""
    data = {
        "summary": {
            "total_functions": report.total_functions,
            "typed_functions": report.typed_functions,
            "coverage_percent": round(report.coverage_percent, 1),
            "total_params": report.total_params,
            "typed_params": report.typed_params
        },
        "by_layer": {
            layer: {
                "total": stats["total"],
                "typed": stats["typed"],
                "percent": round((stats["typed"] / max(stats["total"], 1)) * 100, 1)
            }
            for layer, stats in report.by_layer.items()
        },
        "by_file": {
            filepath: {
                "total": stats["total"],
                "typed": stats["typed"],
                "percent": round(stats["percent"], 1)
            }
            for filepath, stats in report.by_file.items()
        },
        "issues": [
            {
                "file": i.file,
                "line": i.line,
                "type": i.issue_type,
                "name": i.name,
                "context": i.context
            }
            for i in report.issues
        ]
    }
    return json.dumps(data, indent=2)


def main():
    import argparse

    parser = argparse.ArgumentParser(description="Check type annotations")
    parser.add_argument("--json", "-j", action="store_true", help="JSON output")
    parser.add_argument("--layer", "-l", type=str, help="Filter by layer")
    parser.add_argument("--file", "-f", type=str, help="Filter by file path")
    parser.add_argument("--strict", "-s", action="store_true", help="Include private functions")
    parser.add_argument("--all", "-a", action="store_true", help="Show all issues")
    args = parser.parse_args()

    report = analyze_types(args.layer, args.file, args.strict)

    if args.json:
        print(format_json(report))
    else:
        print(format_report(report, args.all))


if __name__ == "__main__":
    main()
