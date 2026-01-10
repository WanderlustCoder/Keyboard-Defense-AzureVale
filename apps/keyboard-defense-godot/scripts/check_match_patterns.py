#!/usr/bin/env python3
"""
Match Pattern Checker

Analyzes match statement patterns:
- Missing default cases
- Large match statements
- Potential enum coverage
- Duplicate patterns

Usage:
    python scripts/check_match_patterns.py              # Full report
    python scripts/check_match_patterns.py --file game/main.gd  # Single file
    python scripts/check_match_patterns.py --strict     # Stricter checks
    python scripts/check_match_patterns.py --json       # JSON output
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

# Thresholds
LARGE_MATCH_THRESHOLD = 10


@dataclass
class MatchStatement:
    """A match statement."""
    file: str
    line: int
    subject: str
    cases: List[str]
    has_default: bool
    case_count: int
    context: str


@dataclass
class MatchIssue:
    """An issue with a match statement."""
    file: str
    line: int
    issue_type: str
    message: str
    severity: str


@dataclass
class MatchReport:
    """Match pattern check report."""
    files_checked: int = 0
    total_matches: int = 0
    missing_default: int = 0
    large_matches: int = 0
    matches: List[MatchStatement] = field(default_factory=list)
    issues: List[MatchIssue] = field(default_factory=list)
    by_severity: Dict[str, int] = field(default_factory=lambda: {"high": 0, "medium": 0, "low": 0})
    case_patterns: Dict[str, int] = field(default_factory=lambda: {})  # pattern -> count


def analyze_file(file_path: Path, rel_path: str, strict: bool = False) -> Tuple[List[MatchStatement], List[MatchIssue]]:
    """Analyze a file for match statements."""
    matches = []
    issues = []

    try:
        content = file_path.read_text(encoding="utf-8")
        lines = content.split('\n')
    except Exception:
        return matches, issues

    i = 0
    while i < len(lines):
        line = lines[i]
        line_num = i + 1
        stripped = line.strip()

        # Find match statement
        match_stmt = re.match(r'^(\s*)match\s+(.+):', stripped)
        if match_stmt:
            indent = len(line) - len(line.lstrip())
            subject = match_stmt.group(2).strip()
            cases = []
            has_default = False

            # Collect cases
            j = i + 1
            while j < len(lines):
                case_line = lines[j]
                case_stripped = case_line.strip()

                # Check if we've exited the match block
                if case_stripped and not case_line.startswith('\t' * (indent // 4 + 1)) and not case_line.startswith(' ' * (indent + 1)):
                    case_indent = len(case_line) - len(case_line.lstrip())
                    if case_indent <= indent and case_stripped and not case_stripped.startswith("#"):
                        break

                # Parse case
                case_match = re.match(r'^\s*([^:]+):', case_stripped)
                if case_match and not case_stripped.startswith("#"):
                    pattern = case_match.group(1).strip()
                    cases.append(pattern)

                    if pattern == "_":
                        has_default = True

                j += 1

            match_info = MatchStatement(
                file=rel_path,
                line=line_num,
                subject=subject,
                cases=cases,
                has_default=has_default,
                case_count=len(cases),
                context=stripped[:60]
            )
            matches.append(match_info)

            # Check for issues
            if not has_default:
                # Check if this might be an enum match
                is_enum_like = all(
                    re.match(r'^[A-Z][A-Z_0-9]*$', c) or c.startswith('"') or c.isdigit()
                    for c in cases
                )

                if is_enum_like and len(cases) > 2:
                    issues.append(MatchIssue(
                        file=rel_path,
                        line=line_num,
                        issue_type="missing_default_enum",
                        message=f"Match on '{subject}' ({len(cases)} cases) has no default - may miss enum values",
                        severity="medium"
                    ))
                elif strict:
                    issues.append(MatchIssue(
                        file=rel_path,
                        line=line_num,
                        issue_type="missing_default",
                        message=f"Match on '{subject}' has no default case",
                        severity="low"
                    ))

            if len(cases) > LARGE_MATCH_THRESHOLD:
                issues.append(MatchIssue(
                    file=rel_path,
                    line=line_num,
                    issue_type="large_match",
                    message=f"Large match statement ({len(cases)} cases) - consider refactoring",
                    severity="low"
                ))

            # Check for duplicate patterns
            seen_patterns = set()
            for pattern in cases:
                if pattern in seen_patterns:
                    issues.append(MatchIssue(
                        file=rel_path,
                        line=line_num,
                        issue_type="duplicate_pattern",
                        message=f"Duplicate pattern '{pattern}' in match",
                        severity="high"
                    ))
                seen_patterns.add(pattern)

            i = j
            continue

        i += 1

    return matches, issues


def check_match_patterns(target_file: Optional[str] = None, strict: bool = False) -> MatchReport:
    """Check match patterns across the project."""
    report = MatchReport()

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

        matches, issues = analyze_file(gd_file, rel_path, strict)

        for match_info in matches:
            report.total_matches += 1
            report.matches.append(match_info)

            if not match_info.has_default:
                report.missing_default += 1

            if match_info.case_count > LARGE_MATCH_THRESHOLD:
                report.large_matches += 1

            # Track case patterns
            for pattern in match_info.cases:
                report.case_patterns[pattern] = report.case_patterns.get(pattern, 0) + 1

        for issue in issues:
            report.issues.append(issue)
            report.by_severity[issue.severity] += 1

    return report


def format_report(report: MatchReport, strict: bool = False) -> str:
    """Format match pattern report as text."""
    lines = []
    lines.append("=" * 60)
    lines.append("MATCH PATTERN CHECKER - KEYBOARD DEFENSE")
    lines.append("=" * 60)
    lines.append("")

    # Summary
    lines.append("## SUMMARY")
    lines.append(f"  Files checked:      {report.files_checked}")
    lines.append(f"  Total matches:      {report.total_matches}")
    lines.append(f"  Missing default:    {report.missing_default}")
    lines.append(f"  Large matches:      {report.large_matches}")
    lines.append(f"  Issues found:       {len(report.issues)}")
    lines.append("")

    # Issues by severity
    if report.issues:
        high_issues = [i for i in report.issues if i.severity == "high"]
        if high_issues:
            lines.append("## HIGH SEVERITY ISSUES")
            for issue in high_issues:
                lines.append(f"  {issue.file}:{issue.line}")
                lines.append(f"    {issue.message}")
            lines.append("")

        medium_issues = [i for i in report.issues if i.severity == "medium"]
        if medium_issues:
            lines.append("## MEDIUM SEVERITY ISSUES")
            for issue in medium_issues[:15]:
                lines.append(f"  {issue.file}:{issue.line}")
                lines.append(f"    {issue.message}")
            if len(medium_issues) > 15:
                lines.append(f"  ... and {len(medium_issues) - 15} more")
            lines.append("")

    # Large match statements
    large_matches = [m for m in report.matches if m.case_count > LARGE_MATCH_THRESHOLD]
    if large_matches:
        lines.append(f"## LARGE MATCH STATEMENTS (>{LARGE_MATCH_THRESHOLD} cases)")
        for match_info in sorted(large_matches, key=lambda m: -m.case_count)[:10]:
            lines.append(f"  {match_info.file}:{match_info.line}")
            lines.append(f"    match {match_info.subject}: {match_info.case_count} cases")
        lines.append("")

    # Most common patterns
    lines.append("## MOST COMMON PATTERNS")
    sorted_patterns = sorted(report.case_patterns.items(), key=lambda x: -x[1])
    for pattern, count in sorted_patterns[:15]:
        if count > 1:
            display = pattern[:40] + "..." if len(pattern) > 40 else pattern
            lines.append(f"  '{display}': {count} uses")
    lines.append("")

    # Match statistics by file
    files_with_matches: Dict[str, int] = {}
    for match_info in report.matches:
        files_with_matches[match_info.file] = files_with_matches.get(match_info.file, 0) + 1

    if files_with_matches:
        lines.append("## MATCHES BY FILE")
        sorted_files = sorted(files_with_matches.items(), key=lambda x: -x[1])
        for file_path, count in sorted_files[:10]:
            lines.append(f"  {file_path}: {count} match statements")
        lines.append("")

    # Health indicators
    lines.append("## HEALTH INDICATORS")
    if report.by_severity["high"] == 0:
        lines.append("  [OK] No duplicate patterns")
    else:
        lines.append(f"  [ERROR] {report.by_severity['high']} duplicate patterns found")

    default_pct = ((report.total_matches - report.missing_default) / report.total_matches * 100) if report.total_matches > 0 else 100
    if default_pct >= 80:
        lines.append(f"  [OK] {default_pct:.0f}% of matches have default case")
    elif default_pct >= 50:
        lines.append(f"  [INFO] {default_pct:.0f}% of matches have default case")
    else:
        lines.append(f"  [WARN] Only {default_pct:.0f}% of matches have default case")

    if report.large_matches == 0:
        lines.append("  [OK] No oversized match statements")
    else:
        lines.append(f"  [INFO] {report.large_matches} large match statements")

    lines.append("")
    return "\n".join(lines)


def format_json(report: MatchReport) -> str:
    """Format report as JSON."""
    data = {
        "summary": {
            "files_checked": report.files_checked,
            "total_matches": report.total_matches,
            "missing_default": report.missing_default,
            "large_matches": report.large_matches,
            "issues_found": len(report.issues),
            "by_severity": report.by_severity
        },
        "issues": [
            {
                "file": i.file,
                "line": i.line,
                "type": i.issue_type,
                "message": i.message,
                "severity": i.severity
            }
            for i in report.issues
        ],
        "large_matches": [
            {
                "file": m.file,
                "line": m.line,
                "subject": m.subject,
                "case_count": m.case_count,
                "has_default": m.has_default
            }
            for m in report.matches if m.case_count > LARGE_MATCH_THRESHOLD
        ]
    }
    return json.dumps(data, indent=2)


def main():
    import argparse

    parser = argparse.ArgumentParser(description="Check match patterns")
    parser.add_argument("--json", "-j", action="store_true", help="JSON output")
    parser.add_argument("--file", "-f", type=str, help="Single file to check")
    parser.add_argument("--strict", "-s", action="store_true", help="Stricter checks")
    args = parser.parse_args()

    report = check_match_patterns(args.file, args.strict)

    if args.json:
        print(format_json(report))
    else:
        print(format_report(report, args.strict))


if __name__ == "__main__":
    main()
