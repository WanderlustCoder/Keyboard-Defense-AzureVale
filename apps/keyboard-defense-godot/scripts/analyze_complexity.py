#!/usr/bin/env python3
"""
Code Complexity Analyzer

Analyzes GDScript files for complexity metrics:
- Cyclomatic complexity (decision points)
- Function length (lines)
- Nesting depth
- Parameter count
- Cognitive complexity

Usage:
    python scripts/analyze_complexity.py              # Full report
    python scripts/analyze_complexity.py --threshold 10  # Only show complex functions
    python scripts/analyze_complexity.py --file game/main.gd  # Single file
    python scripts/analyze_complexity.py --json       # JSON output
    python scripts/analyze_complexity.py --sort complexity  # Sort by metric
"""

import json
import re
import sys
from dataclasses import dataclass, field
from pathlib import Path
from typing import Dict, List, Optional, Tuple

# Project paths
SCRIPT_DIR = Path(__file__).parent
PROJECT_ROOT = SCRIPT_DIR.parent

# Complexity thresholds
THRESHOLDS = {
    "cyclomatic": {"low": 5, "medium": 10, "high": 20},
    "lines": {"low": 30, "medium": 50, "high": 100},
    "nesting": {"low": 3, "medium": 4, "high": 6},
    "params": {"low": 4, "medium": 6, "high": 8},
    "cognitive": {"low": 8, "medium": 15, "high": 25},
}

# Decision point patterns (add to cyclomatic complexity)
DECISION_PATTERNS = [
    r'\bif\b',
    r'\belif\b',
    r'\bwhile\b',
    r'\bfor\b',
    r'\band\b',
    r'\bor\b',
    r'\bmatch\b',
    r'\?\s*[^:]+\s*:',  # ternary
]

# Nesting keywords
NESTING_KEYWORDS = ['if', 'elif', 'else', 'while', 'for', 'match', 'func']


@dataclass
class FunctionMetrics:
    """Metrics for a single function."""
    name: str
    file: str
    line: int
    cyclomatic: int = 1  # Base complexity
    lines: int = 0
    max_nesting: int = 0
    params: int = 0
    cognitive: int = 0
    has_return: bool = False
    is_static: bool = False

    @property
    def risk_level(self) -> str:
        """Determine overall risk level."""
        if (self.cyclomatic >= THRESHOLDS["cyclomatic"]["high"] or
            self.lines >= THRESHOLDS["lines"]["high"] or
            self.cognitive >= THRESHOLDS["cognitive"]["high"]):
            return "high"
        if (self.cyclomatic >= THRESHOLDS["cyclomatic"]["medium"] or
            self.lines >= THRESHOLDS["lines"]["medium"] or
            self.cognitive >= THRESHOLDS["cognitive"]["medium"]):
            return "medium"
        return "low"


@dataclass
class FileMetrics:
    """Metrics for a file."""
    path: str
    total_lines: int = 0
    code_lines: int = 0
    functions: List[FunctionMetrics] = field(default_factory=list)
    avg_complexity: float = 0.0
    max_complexity: int = 0
    avg_function_lines: float = 0.0
    maintainability_index: float = 100.0


def count_params(signature: str) -> int:
    """Count parameters in function signature."""
    # Extract params between parentheses
    match = re.search(r'\(([^)]*)\)', signature)
    if not match:
        return 0
    params = match.group(1).strip()
    if not params:
        return 0
    # Count commas + 1, but handle default values and type hints
    param_list = params.split(',')
    return len([p for p in param_list if p.strip()])


def calculate_nesting(lines: List[str]) -> int:
    """Calculate maximum nesting depth."""
    max_depth = 0
    current_depth = 0

    for line in lines:
        stripped = line.strip()
        if not stripped or stripped.startswith('#'):
            continue

        # Calculate indentation level
        indent = len(line) - len(line.lstrip())
        # Assume tab = 4 spaces for GDScript
        indent_level = indent // 4 if '\t' not in line else line.count('\t')

        # Track nesting based on indent changes
        if any(stripped.startswith(kw) for kw in NESTING_KEYWORDS):
            current_depth = indent_level + 1
            max_depth = max(max_depth, current_depth)

    return max_depth


def calculate_cyclomatic(content: str) -> int:
    """Calculate cyclomatic complexity."""
    complexity = 1  # Base complexity

    for pattern in DECISION_PATTERNS:
        matches = re.findall(pattern, content)
        complexity += len(matches)

    return complexity


def calculate_cognitive(lines: List[str]) -> int:
    """Calculate cognitive complexity (simplified)."""
    complexity = 0
    nesting_level = 0

    for line in lines:
        stripped = line.strip()
        if not stripped or stripped.startswith('#'):
            continue

        # Increment for control flow at current nesting
        if re.match(r'^(if|elif|while|for)\b', stripped):
            complexity += 1 + nesting_level
            nesting_level += 1
        elif stripped.startswith('else:'):
            complexity += 1
        elif re.match(r'^match\b', stripped):
            complexity += 1 + nesting_level
            nesting_level += 1

        # Boolean operators add complexity
        complexity += len(re.findall(r'\band\b|\bor\b', stripped))

        # Recursion adds complexity (simplified check)
        # Would need function name context for accurate detection

        # Decrease nesting when leaving blocks (simplified)
        indent = len(line) - len(line.lstrip())
        # This is a simplified approach; proper tracking would need more context

    return complexity


def analyze_function(lines: List[str], func_line: int, func_signature: str, filepath: str) -> FunctionMetrics:
    """Analyze a single function."""
    # Extract function name
    name_match = re.search(r'func\s+(\w+)', func_signature)
    name = name_match.group(1) if name_match else "unknown"

    metrics = FunctionMetrics(
        name=name,
        file=filepath,
        line=func_line,
        is_static='static' in func_signature,
        params=count_params(func_signature),
    )

    # Find function body (until next func or end of indent)
    func_lines = []
    base_indent = len(lines[0]) - len(lines[0].lstrip()) if lines else 0

    in_function = True
    for i, line in enumerate(lines):
        if i == 0:
            func_lines.append(line)
            continue

        # Check if we've exited the function
        stripped = line.strip()
        if stripped and not stripped.startswith('#'):
            current_indent = len(line) - len(line.lstrip())
            # New function or class at same/lower indent level
            if current_indent <= base_indent and (stripped.startswith('func ') or
                                                   stripped.startswith('static func ') or
                                                   stripped.startswith('class ')):
                break

        func_lines.append(line)

    # Calculate metrics
    content = '\n'.join(func_lines)
    metrics.lines = len([l for l in func_lines if l.strip() and not l.strip().startswith('#')])
    metrics.cyclomatic = calculate_cyclomatic(content)
    metrics.max_nesting = calculate_nesting(func_lines)
    metrics.cognitive = calculate_cognitive(func_lines)
    metrics.has_return = 'return ' in content or '-> ' in func_signature

    return metrics


def analyze_file(filepath: Path) -> FileMetrics:
    """Analyze a single file."""
    rel_path = str(filepath.relative_to(PROJECT_ROOT))
    metrics = FileMetrics(path=rel_path)

    try:
        content = filepath.read_text(encoding="utf-8")
        lines = content.split('\n')
    except Exception:
        return metrics

    metrics.total_lines = len(lines)
    metrics.code_lines = len([l for l in lines if l.strip() and not l.strip().startswith('#')])

    # Find all functions
    func_pattern = re.compile(r'^(\s*)(static\s+)?func\s+\w+\s*\(')

    for i, line in enumerate(lines):
        match = func_pattern.match(line)
        if match:
            # Get remaining lines from this function
            remaining_lines = lines[i:]
            func_metrics = analyze_function(remaining_lines, i + 1, line, rel_path)
            metrics.functions.append(func_metrics)

    # Calculate aggregates
    if metrics.functions:
        complexities = [f.cyclomatic for f in metrics.functions]
        metrics.avg_complexity = sum(complexities) / len(complexities)
        metrics.max_complexity = max(complexities)
        metrics.avg_function_lines = sum(f.lines for f in metrics.functions) / len(metrics.functions)

        # Simplified maintainability index
        # Based on Halstead volume, cyclomatic complexity, and lines of code
        avg_loc = metrics.avg_function_lines
        avg_cc = metrics.avg_complexity
        metrics.maintainability_index = max(0, min(100,
            171 - 5.2 * (avg_cc ** 0.5) - 0.23 * avg_loc - 16.2 * 0  # simplified
        ))

    return metrics


def analyze_codebase(target_file: Optional[str] = None) -> List[FileMetrics]:
    """Analyze all GDScript files."""
    results = []

    if target_file:
        filepath = PROJECT_ROOT / target_file
        if filepath.exists():
            results.append(analyze_file(filepath))
        return results

    for gd_file in PROJECT_ROOT.glob("**/*.gd"):
        if ".godot" in str(gd_file) or "addons" in str(gd_file):
            continue
        results.append(analyze_file(gd_file))

    return results


def format_report(results: List[FileMetrics], threshold: int = 0, sort_by: str = "complexity") -> str:
    """Format complexity report."""
    lines = []
    lines.append("=" * 70)
    lines.append("CODE COMPLEXITY ANALYSIS - KEYBOARD DEFENSE")
    lines.append("=" * 70)
    lines.append("")

    # Collect all functions
    all_functions = []
    for file_metrics in results:
        for func in file_metrics.functions:
            if threshold == 0 or func.cyclomatic >= threshold:
                all_functions.append(func)

    # Sort
    if sort_by == "complexity":
        all_functions.sort(key=lambda f: f.cyclomatic, reverse=True)
    elif sort_by == "lines":
        all_functions.sort(key=lambda f: f.lines, reverse=True)
    elif sort_by == "cognitive":
        all_functions.sort(key=lambda f: f.cognitive, reverse=True)
    elif sort_by == "nesting":
        all_functions.sort(key=lambda f: f.max_nesting, reverse=True)

    # Summary
    lines.append("## SUMMARY")
    lines.append(f"  Total files analyzed: {len(results)}")
    lines.append(f"  Total functions: {sum(len(f.functions) for f in results)}")

    high_risk = [f for f in all_functions if f.risk_level == "high"]
    medium_risk = [f for f in all_functions if f.risk_level == "medium"]
    lines.append(f"  High risk functions: {len(high_risk)}")
    lines.append(f"  Medium risk functions: {len(medium_risk)}")
    lines.append("")

    # Thresholds reference
    lines.append("## THRESHOLDS")
    lines.append("  Cyclomatic: low < 5, medium < 10, high >= 20")
    lines.append("  Lines: low < 30, medium < 50, high >= 100")
    lines.append("  Nesting: low < 3, medium < 4, high >= 6")
    lines.append("")

    # High risk functions
    if high_risk:
        lines.append("## HIGH RISK FUNCTIONS (need refactoring)")
        for func in high_risk[:20]:
            lines.append(f"  {func.file}:{func.line}  {func.name}()")
            lines.append(f"    CC={func.cyclomatic}  Lines={func.lines}  Nesting={func.max_nesting}  Cognitive={func.cognitive}")
        if len(high_risk) > 20:
            lines.append(f"  ... and {len(high_risk) - 20} more")
        lines.append("")

    # Medium risk functions
    if medium_risk and threshold == 0:
        lines.append("## MEDIUM RISK FUNCTIONS (consider simplifying)")
        for func in medium_risk[:15]:
            lines.append(f"  {func.file}:{func.line}  {func.name}()")
            lines.append(f"    CC={func.cyclomatic}  Lines={func.lines}  Nesting={func.max_nesting}")
        if len(medium_risk) > 15:
            lines.append(f"  ... and {len(medium_risk) - 15} more")
        lines.append("")

    # Most complex files
    lines.append("## MOST COMPLEX FILES (by avg complexity)")
    complex_files = sorted(results, key=lambda f: f.avg_complexity, reverse=True)
    for fm in complex_files[:10]:
        if fm.functions:
            lines.append(f"  {fm.path}")
            lines.append(f"    Avg CC={fm.avg_complexity:.1f}  Max CC={fm.max_complexity}  Functions={len(fm.functions)}")
    lines.append("")

    # Longest functions
    lines.append("## LONGEST FUNCTIONS")
    by_lines = sorted(all_functions, key=lambda f: f.lines, reverse=True)
    for func in by_lines[:10]:
        lines.append(f"  {func.lines:4} lines  {func.file}:{func.line}  {func.name}()")
    lines.append("")

    # Deepest nesting
    lines.append("## DEEPEST NESTING")
    by_nesting = sorted(all_functions, key=lambda f: f.max_nesting, reverse=True)
    for func in by_nesting[:10]:
        if func.max_nesting > 2:
            lines.append(f"  depth {func.max_nesting}  {func.file}:{func.line}  {func.name}()")
    lines.append("")

    # Health indicators
    lines.append("## HEALTH INDICATORS")
    if len(high_risk) > 10:
        lines.append(f"  [WARN] Many high-risk functions: {len(high_risk)}")
    else:
        lines.append(f"  [OK] High-risk functions: {len(high_risk)}")

    avg_all = sum(f.cyclomatic for f in all_functions) / max(len(all_functions), 1)
    if avg_all > 8:
        lines.append(f"  [WARN] High average complexity: {avg_all:.1f}")
    else:
        lines.append(f"  [OK] Average complexity: {avg_all:.1f}")

    lines.append("")
    return "\n".join(lines)


def format_json(results: List[FileMetrics]) -> str:
    """Format as JSON."""
    data = {
        "summary": {
            "total_files": len(results),
            "total_functions": sum(len(f.functions) for f in results),
            "high_risk": sum(1 for f in results for fn in f.functions if fn.risk_level == "high"),
            "medium_risk": sum(1 for f in results for fn in f.functions if fn.risk_level == "medium"),
        },
        "files": [],
    }

    for fm in results:
        file_data = {
            "path": fm.path,
            "total_lines": fm.total_lines,
            "code_lines": fm.code_lines,
            "avg_complexity": fm.avg_complexity,
            "max_complexity": fm.max_complexity,
            "maintainability_index": fm.maintainability_index,
            "functions": [
                {
                    "name": f.name,
                    "line": f.line,
                    "cyclomatic": f.cyclomatic,
                    "lines": f.lines,
                    "max_nesting": f.max_nesting,
                    "cognitive": f.cognitive,
                    "params": f.params,
                    "risk_level": f.risk_level,
                }
                for f in fm.functions
            ],
        }
        data["files"].append(file_data)

    return json.dumps(data, indent=2)


def main():
    import argparse

    parser = argparse.ArgumentParser(description="Analyze code complexity")
    parser.add_argument("--json", "-j", action="store_true", help="JSON output")
    parser.add_argument("--file", "-f", type=str, help="Analyze single file")
    parser.add_argument("--threshold", "-t", type=int, default=0, help="Min complexity to show")
    parser.add_argument("--sort", "-s", choices=["complexity", "lines", "cognitive", "nesting"],
                       default="complexity", help="Sort by metric")
    args = parser.parse_args()

    results = analyze_codebase(args.file)

    if args.json:
        print(format_json(results))
    else:
        print(format_report(results, args.threshold, args.sort))


if __name__ == "__main__":
    main()
