#!/usr/bin/env python3
"""
Class Structure Checker

Validates GDScript class organization follows conventions:
- Correct ordering: class_name, extends, signals, enums, constants, exports, vars, onready, funcs
- Tool annotation placement
- Static function grouping
- Private method organization

Usage:
    python scripts/check_class_structure.py              # Full report
    python scripts/check_class_structure.py --file game/main.gd  # Single file
    python scripts/check_class_structure.py --strict     # More patterns
    python scripts/check_class_structure.py --json       # JSON output
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

# Expected order of class elements
ELEMENT_ORDER = [
    "tool",
    "class_name",
    "extends",
    "signal",
    "enum",
    "const",
    "export",
    "var",
    "onready",
    "static_func",
    "func"
]

ELEMENT_NAMES = {
    "tool": "@tool annotation",
    "class_name": "class_name declaration",
    "extends": "extends declaration",
    "signal": "signal declarations",
    "enum": "enum declarations",
    "const": "constant declarations",
    "export": "@export variables",
    "var": "class variables",
    "onready": "@onready variables",
    "static_func": "static functions",
    "func": "instance functions"
}


@dataclass
class ClassElement:
    """A class structural element."""
    element_type: str
    line: int
    name: str


@dataclass
class StructureIssue:
    """A class structure issue."""
    file: str
    line: int
    issue_type: str
    message: str
    severity: str  # "error", "warning", "info"


@dataclass
class StructureReport:
    """Class structure report."""
    files_checked: int = 0
    well_organized: int = 0
    has_issues: int = 0
    issues: List[StructureIssue] = field(default_factory=list)
    by_file: Dict[str, List[StructureIssue]] = field(default_factory=lambda: defaultdict(list))
    element_counts: Dict[str, int] = field(default_factory=lambda: defaultdict(int))


def classify_line(line: str, stripped: str, prev_stripped: str) -> Optional[Tuple[str, str]]:
    """Classify a line into an element type."""
    # @tool
    if stripped == '@tool':
        return ("tool", "@tool")

    # class_name
    if stripped.startswith('class_name '):
        match = re.match(r'class_name\s+(\w+)', stripped)
        name = match.group(1) if match else "?"
        return ("class_name", name)

    # extends
    if stripped.startswith('extends '):
        match = re.match(r'extends\s+(\w+)', stripped)
        name = match.group(1) if match else "?"
        return ("extends", name)

    # signal
    if stripped.startswith('signal '):
        match = re.match(r'signal\s+(\w+)', stripped)
        name = match.group(1) if match else "?"
        return ("signal", name)

    # enum
    if stripped.startswith('enum ') or stripped == 'enum':
        match = re.match(r'enum\s+(\w+)?', stripped)
        name = match.group(1) if match and match.group(1) else "anonymous"
        return ("enum", name)

    # const
    if stripped.startswith('const '):
        match = re.match(r'const\s+(\w+)', stripped)
        name = match.group(1) if match else "?"
        return ("const", name)

    # @export (check previous line for annotation)
    if prev_stripped.startswith('@export'):
        if stripped.startswith('var '):
            match = re.match(r'var\s+(\w+)', stripped)
            name = match.group(1) if match else "?"
            return ("export", name)

    # @export on same line
    if stripped.startswith('@export'):
        if 'var ' in stripped:
            match = re.search(r'var\s+(\w+)', stripped)
            name = match.group(1) if match else "?"
            return ("export", name)
        # Annotation only, will be handled with next line
        return None

    # @onready
    if stripped.startswith('@onready'):
        match = re.search(r'var\s+(\w+)', stripped)
        name = match.group(1) if match else "?"
        return ("onready", name)

    # var (plain class variable)
    if stripped.startswith('var ') and not prev_stripped.startswith('@'):
        match = re.match(r'var\s+(\w+)', stripped)
        name = match.group(1) if match else "?"
        return ("var", name)

    # static func
    if stripped.startswith('static func '):
        match = re.match(r'static func\s+(\w+)', stripped)
        name = match.group(1) if match else "?"
        return ("static_func", name)

    # func
    if stripped.startswith('func '):
        match = re.match(r'func\s+(\w+)', stripped)
        name = match.group(1) if match else "?"
        return ("func", name)

    return None


def analyze_file_structure(file_path: Path, rel_path: str, strict: bool) -> Tuple[List[ClassElement], List[StructureIssue]]:
    """Analyze class structure in a file."""
    elements = []
    issues = []

    try:
        content = file_path.read_text(encoding='utf-8')
        lines = content.split('\n')
    except Exception:
        return elements, issues

    prev_stripped = ""
    last_element_type = None
    last_element_line = 0
    seen_types: Set[str] = set()

    for i, line in enumerate(lines):
        # Only check class-level declarations (no indentation)
        if line and not line[0].isspace() and not line.startswith('#'):
            stripped = line.strip()

            result = classify_line(line, stripped, prev_stripped)
            if result:
                element_type, name = result
                elements.append(ClassElement(element_type, i + 1, name))

                # Check ordering
                if last_element_type:
                    try:
                        last_order = ELEMENT_ORDER.index(last_element_type)
                        curr_order = ELEMENT_ORDER.index(element_type)

                        if curr_order < last_order:
                            issues.append(StructureIssue(
                                file=rel_path,
                                line=i + 1,
                                issue_type="wrong_order",
                                message=f"{ELEMENT_NAMES[element_type]} should come before {ELEMENT_NAMES[last_element_type]} (line {last_element_line})",
                                severity="warning"
                            ))
                    except ValueError:
                        pass  # Unknown element type

                # Check for re-opening sections
                if element_type in seen_types and element_type not in ['func', 'static_func', 'signal', 'const', 'var', 'export', 'onready', 'enum']:
                    issues.append(StructureIssue(
                        file=rel_path,
                        line=i + 1,
                        issue_type="duplicate_section",
                        message=f"Duplicate {ELEMENT_NAMES[element_type]} (already declared)",
                        severity="warning"
                    ))

                seen_types.add(element_type)
                last_element_type = element_type
                last_element_line = i + 1

            prev_stripped = stripped
        elif line.startswith('#'):
            pass  # Keep prev_stripped
        else:
            prev_stripped = line.strip() if line.strip() else prev_stripped

    # Check for missing class_name (strict mode)
    if strict and "class_name" not in seen_types:
        # Only warn for files that aren't tests or tools
        if not any(p in rel_path for p in ['test', 'tool', 'script']):
            issues.append(StructureIssue(
                file=rel_path,
                line=1,
                issue_type="missing_class_name",
                message="File has no class_name declaration",
                severity="info"
            ))

    # Check for private function organization
    if strict:
        private_funcs = [e for e in elements if e.element_type == "func" and e.name.startswith('_') and e.name not in ['_init', '_ready', '_process', '_physics_process', '_input', '_unhandled_input', '_draw', '_enter_tree', '_exit_tree', '_notification']]
        public_funcs = [e for e in elements if e.element_type == "func" and not e.name.startswith('_')]

        # Check if private functions are mixed with public
        if private_funcs and public_funcs:
            # Find if any private func comes before a public func
            first_private = min(f.line for f in private_funcs) if private_funcs else 9999
            last_public = max(f.line for f in public_funcs) if public_funcs else 0

            if first_private < last_public:
                # There's interleaving - check if it's significant
                private_after_public = [f for f in private_funcs if f.line > min(p.line for p in public_funcs)]
                public_after_private = [f for f in public_funcs if f.line > first_private]

                if private_after_public and public_after_private:
                    issues.append(StructureIssue(
                        file=rel_path,
                        line=first_private,
                        issue_type="mixed_visibility",
                        message="Private and public functions are interleaved (consider grouping)",
                        severity="info"
                    ))

    return elements, issues


def check_class_structure(target_file: Optional[str] = None, strict: bool = False) -> StructureReport:
    """Check class structure across the project."""
    report = StructureReport()

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

        elements, issues = analyze_file_structure(gd_file, rel_path, strict)

        # Count elements
        for elem in elements:
            report.element_counts[elem.element_type] += 1

        if issues:
            report.has_issues += 1
            for issue in issues:
                report.issues.append(issue)
                report.by_file[issue.file].append(issue)
        else:
            report.well_organized += 1

    return report


def format_report(report: StructureReport) -> str:
    """Format structure report as text."""
    lines = []
    lines.append("=" * 60)
    lines.append("CLASS STRUCTURE CHECKER - KEYBOARD DEFENSE")
    lines.append("=" * 60)
    lines.append("")

    # Summary
    lines.append("## SUMMARY")
    lines.append(f"  Files checked:      {report.files_checked}")
    lines.append(f"  Well organized:     {report.well_organized}")
    lines.append(f"  With issues:        {report.has_issues}")
    lines.append(f"  Total issues:       {len(report.issues)}")
    lines.append("")

    # Element counts
    lines.append("## ELEMENT COUNTS")
    for elem_type in ELEMENT_ORDER:
        count = report.element_counts.get(elem_type, 0)
        if count > 0:
            lines.append(f"  {ELEMENT_NAMES[elem_type]}: {count}")
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
        lines.append("## STRUCTURE ISSUES")

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
        lines.append("## FILES WITH MOST STRUCTURE ISSUES")
        sorted_files = sorted(report.by_file.items(), key=lambda x: -len(x[1]))[:10]
        for file_path, issues in sorted_files:
            lines.append(f"  {file_path}: {len(issues)}")
        lines.append("")

    # Health indicators
    lines.append("## HEALTH INDICATORS")

    if report.files_checked > 0:
        well_ratio = report.well_organized / report.files_checked * 100
        if well_ratio >= 80:
            lines.append(f"  [OK] {well_ratio:.0f}% of files follow structure conventions")
        else:
            lines.append(f"  [WARN] Only {well_ratio:.0f}% of files follow structure conventions")

    wrong_order = sum(1 for i in report.issues if i.issue_type == "wrong_order")
    if wrong_order == 0:
        lines.append("  [OK] No declaration ordering issues")
    else:
        lines.append(f"  [WARN] {wrong_order} files have declaration ordering issues")

    lines.append("")
    lines.append("## EXPECTED ORDER")
    lines.append("  1. @tool (if applicable)")
    lines.append("  2. class_name")
    lines.append("  3. extends")
    lines.append("  4. signal declarations")
    lines.append("  5. enum declarations")
    lines.append("  6. const declarations")
    lines.append("  7. @export variables")
    lines.append("  8. class variables (var)")
    lines.append("  9. @onready variables")
    lines.append("  10. static functions")
    lines.append("  11. instance functions")
    lines.append("")

    return "\n".join(lines)


def format_json(report: StructureReport) -> str:
    """Format report as JSON."""
    data = {
        "summary": {
            "files_checked": report.files_checked,
            "well_organized": report.well_organized,
            "has_issues": report.has_issues,
            "total_issues": len(report.issues)
        },
        "element_counts": dict(report.element_counts),
        "issues": [
            {
                "file": i.file,
                "line": i.line,
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

    parser = argparse.ArgumentParser(description="Check class structure")
    parser.add_argument("--json", "-j", action="store_true", help="JSON output")
    parser.add_argument("--file", "-f", type=str, help="Single file to check")
    parser.add_argument("--strict", "-s", action="store_true", help="Include info-level checks")
    args = parser.parse_args()

    report = check_class_structure(args.file, args.strict)

    if args.json:
        print(format_json(report))
    else:
        print(format_report(report))


if __name__ == "__main__":
    main()
