#!/usr/bin/env python3
"""
Comment Quality Checker

Analyzes comment quality and patterns:
- Comment density and distribution
- Potentially outdated comments
- Comment-to-code ratio
- Commented-out code detection

Usage:
    python scripts/check_comments.py              # Full report
    python scripts/check_comments.py --file game/main.gd  # Single file
    python scripts/check_comments.py --strict     # Stricter checks
    python scripts/check_comments.py --json       # JSON output
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


@dataclass
class CommentInfo:
    """Information about a comment."""
    file: str
    line: int
    content: str
    comment_type: str  # "doc", "inline", "block", "code"
    issue: Optional[str] = None


@dataclass
class FileCommentStats:
    """Comment statistics for a file."""
    file: str
    total_lines: int
    code_lines: int
    comment_lines: int
    blank_lines: int
    ratio: float
    doc_comments: int
    inline_comments: int
    commented_code: int


@dataclass
class CommentReport:
    """Comment quality report."""
    files_checked: int = 0
    total_lines: int = 0
    total_comments: int = 0
    doc_comments: int = 0
    inline_comments: int = 0
    commented_code: int = 0
    avg_ratio: float = 0.0
    file_stats: List[FileCommentStats] = field(default_factory=list)
    issues: List[CommentInfo] = field(default_factory=list)
    by_type: Dict[str, int] = field(default_factory=lambda: {"doc": 0, "inline": 0, "block": 0, "code": 0})


def is_commented_code(line: str) -> bool:
    """Check if a comment line looks like commented-out code."""
    content = line.strip().lstrip("#").strip()

    if not content:
        return False

    # Patterns that indicate code
    code_patterns = [
        r'^(var|const|func|class|signal|enum|extends|if|elif|else|for|while|match|return|break|continue)\s',
        r'^@(onready|export|tool)',
        r'^\w+\s*[=:]\s*',  # Assignment
        r'^\w+\s*\(',  # Function call
        r'^[}\])]',  # Closing brackets
        r'^pass$',
    ]

    for pattern in code_patterns:
        if re.match(pattern, content):
            return True

    return False


def analyze_file(file_path: Path, rel_path: str, strict: bool = False) -> Tuple[FileCommentStats, List[CommentInfo]]:
    """Analyze comments in a file."""
    comments = []

    try:
        content = file_path.read_text(encoding="utf-8")
        lines = content.split('\n')
    except Exception:
        return FileCommentStats(file=rel_path, total_lines=0, code_lines=0, comment_lines=0,
                               blank_lines=0, ratio=0, doc_comments=0, inline_comments=0, commented_code=0), []

    total_lines = len(lines)
    code_lines = 0
    comment_lines = 0
    blank_lines = 0
    doc_comments = 0
    inline_comments = 0
    commented_code_count = 0

    in_doc_comment = False
    prev_was_comment = False

    for i, line in enumerate(lines):
        line_num = i + 1
        stripped = line.strip()

        if not stripped:
            blank_lines += 1
            prev_was_comment = False
            continue

        # Check for doc comment (## at start)
        if stripped.startswith("##"):
            comment_lines += 1
            doc_comments += 1
            comment_content = stripped[2:].strip()

            comments.append(CommentInfo(
                file=rel_path,
                line=line_num,
                content=comment_content[:60],
                comment_type="doc"
            ))
            prev_was_comment = True
            continue

        # Check for regular comment
        if stripped.startswith("#"):
            comment_lines += 1
            comment_content = stripped[1:].strip()

            # Check if it's commented-out code
            if is_commented_code(stripped):
                commented_code_count += 1
                comments.append(CommentInfo(
                    file=rel_path,
                    line=line_num,
                    content=comment_content[:60],
                    comment_type="code",
                    issue="Commented-out code"
                ))
            else:
                inline_comments += 1
                comments.append(CommentInfo(
                    file=rel_path,
                    line=line_num,
                    content=comment_content[:60],
                    comment_type="inline"
                ))

            prev_was_comment = True
            continue

        # Check for inline comment at end of code line
        if "#" in stripped and not stripped.startswith("#"):
            # Make sure it's not in a string
            code_part = stripped.split("#")[0]
            if code_part.count('"') % 2 == 0 and code_part.count("'") % 2 == 0:
                code_lines += 1
                inline_comments += 1
                comment_content = stripped.split("#", 1)[1].strip()

                if len(comment_content) > 2:  # Skip trivial comments
                    comments.append(CommentInfo(
                        file=rel_path,
                        line=line_num,
                        content=comment_content[:60],
                        comment_type="inline"
                    ))
                continue

        code_lines += 1
        prev_was_comment = False

    # Calculate ratio
    ratio = comment_lines / code_lines if code_lines > 0 else 0

    stats = FileCommentStats(
        file=rel_path,
        total_lines=total_lines,
        code_lines=code_lines,
        comment_lines=comment_lines,
        blank_lines=blank_lines,
        ratio=ratio,
        doc_comments=doc_comments,
        inline_comments=inline_comments,
        commented_code=commented_code_count
    )

    # Check for issues
    issues = []

    # Flag files with lots of commented-out code
    if commented_code_count > 10:
        for c in comments:
            if c.comment_type == "code":
                c.issue = f"Commented-out code (file has {commented_code_count} instances)"
                issues.append(c)

    # Flag low comment ratio in complex files
    if strict and code_lines > 100 and ratio < 0.05:
        issues.append(CommentInfo(
            file=rel_path,
            line=0,
            content=f"Low comment ratio ({ratio:.1%}) in {code_lines}-line file",
            comment_type="meta",
            issue="Low comment density"
        ))

    return stats, issues


def check_comments(target_file: Optional[str] = None, strict: bool = False) -> CommentReport:
    """Check comments across the project."""
    report = CommentReport()

    if target_file:
        gd_files = [PROJECT_ROOT / target_file]
    else:
        gd_files = list(PROJECT_ROOT.glob("**/*.gd"))

    total_ratio = 0

    for gd_file in gd_files:
        if ".godot" in str(gd_file) or "addons" in str(gd_file):
            continue

        if not gd_file.exists():
            continue

        rel_path = str(gd_file.relative_to(PROJECT_ROOT))
        report.files_checked += 1

        stats, issues = analyze_file(gd_file, rel_path, strict)
        report.file_stats.append(stats)

        report.total_lines += stats.total_lines
        report.total_comments += stats.comment_lines
        report.doc_comments += stats.doc_comments
        report.inline_comments += stats.inline_comments
        report.commented_code += stats.commented_code
        total_ratio += stats.ratio

        report.issues.extend(issues)

    if report.files_checked > 0:
        report.avg_ratio = total_ratio / report.files_checked

    # Update by_type counts
    report.by_type["doc"] = report.doc_comments
    report.by_type["inline"] = report.inline_comments
    report.by_type["code"] = report.commented_code

    return report


def format_report(report: CommentReport, strict: bool = False) -> str:
    """Format comment report as text."""
    lines = []
    lines.append("=" * 60)
    lines.append("COMMENT QUALITY CHECKER - KEYBOARD DEFENSE")
    lines.append("=" * 60)
    lines.append("")

    # Summary
    lines.append("## SUMMARY")
    lines.append(f"  Files checked:      {report.files_checked}")
    lines.append(f"  Total lines:        {report.total_lines}")
    lines.append(f"  Comment lines:      {report.total_comments}")
    lines.append(f"    Doc comments:     {report.doc_comments}")
    lines.append(f"    Inline comments:  {report.inline_comments}")
    lines.append(f"    Commented code:   {report.commented_code}")
    lines.append(f"  Avg comment ratio:  {report.avg_ratio:.1%}")
    lines.append("")

    # Files with most commented-out code
    files_with_code = sorted(
        [s for s in report.file_stats if s.commented_code > 0],
        key=lambda s: -s.commented_code
    )
    if files_with_code:
        lines.append("## FILES WITH COMMENTED-OUT CODE")
        for stats in files_with_code[:15]:
            lines.append(f"  {stats.file}: {stats.commented_code} lines")
        if len(files_with_code) > 15:
            lines.append(f"  ... and {len(files_with_code) - 15} more")
        lines.append("")

    # Files with best comment ratios
    well_commented = sorted(
        [s for s in report.file_stats if s.code_lines > 50],
        key=lambda s: -s.ratio
    )[:10]
    if well_commented:
        lines.append("## BEST COMMENTED FILES")
        for stats in well_commented:
            lines.append(f"  {stats.file}")
            lines.append(f"    Ratio: {stats.ratio:.1%}, Doc: {stats.doc_comments}, Inline: {stats.inline_comments}")
        lines.append("")

    # Files with lowest comment ratios
    poorly_commented = sorted(
        [s for s in report.file_stats if s.code_lines > 100],
        key=lambda s: s.ratio
    )[:10]
    if poorly_commented:
        lines.append("## LEAST COMMENTED FILES (>100 lines)")
        for stats in poorly_commented:
            lines.append(f"  {stats.file}")
            lines.append(f"    {stats.code_lines} lines, {stats.ratio:.1%} comments")
        lines.append("")

    # Health indicators
    lines.append("## HEALTH INDICATORS")
    if report.commented_code < 50:
        lines.append(f"  [OK] Low commented-out code ({report.commented_code} lines)")
    elif report.commented_code < 200:
        lines.append(f"  [INFO] {report.commented_code} lines of commented-out code")
    else:
        lines.append(f"  [WARN] {report.commented_code} lines of commented-out code - consider cleanup")

    if report.avg_ratio >= 0.1:
        lines.append(f"  [OK] Good average comment ratio ({report.avg_ratio:.1%})")
    elif report.avg_ratio >= 0.05:
        lines.append(f"  [INFO] Moderate comment ratio ({report.avg_ratio:.1%})")
    else:
        lines.append(f"  [WARN] Low comment ratio ({report.avg_ratio:.1%})")

    doc_pct = report.doc_comments / report.total_comments * 100 if report.total_comments > 0 else 0
    lines.append(f"  [INFO] {doc_pct:.0f}% of comments are doc comments (##)")

    lines.append("")
    return "\n".join(lines)


def format_json(report: CommentReport) -> str:
    """Format report as JSON."""
    data = {
        "summary": {
            "files_checked": report.files_checked,
            "total_lines": report.total_lines,
            "total_comments": report.total_comments,
            "doc_comments": report.doc_comments,
            "inline_comments": report.inline_comments,
            "commented_code": report.commented_code,
            "avg_ratio": round(report.avg_ratio, 3)
        },
        "files_with_commented_code": [
            {
                "file": s.file,
                "commented_code_lines": s.commented_code
            }
            for s in sorted(report.file_stats, key=lambda s: -s.commented_code)[:20]
            if s.commented_code > 0
        ],
        "comment_ratios": [
            {
                "file": s.file,
                "code_lines": s.code_lines,
                "comment_lines": s.comment_lines,
                "ratio": round(s.ratio, 3)
            }
            for s in sorted(report.file_stats, key=lambda s: -s.ratio)[:20]
        ]
    }
    return json.dumps(data, indent=2)


def main():
    import argparse

    parser = argparse.ArgumentParser(description="Check comment quality")
    parser.add_argument("--json", "-j", action="store_true", help="JSON output")
    parser.add_argument("--file", "-f", type=str, help="Single file to check")
    parser.add_argument("--strict", "-s", action="store_true", help="Stricter checks")
    args = parser.parse_args()

    report = check_comments(args.file, args.strict)

    if args.json:
        print(format_json(report))
    else:
        print(format_report(report, args.strict))


if __name__ == "__main__":
    main()
