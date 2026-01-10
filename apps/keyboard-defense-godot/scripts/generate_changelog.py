#!/usr/bin/env python3
"""
Changelog Generator

Generates human-readable changelogs from git commits.
Supports various formats and filtering options.

Usage:
    python scripts/generate_changelog.py                    # Last 20 commits
    python scripts/generate_changelog.py --since 2026-01-01
    python scripts/generate_changelog.py --tag v1.0.0
    python scripts/generate_changelog.py --format markdown
    python scripts/generate_changelog.py --category         # Group by type
"""

import re
import subprocess
import sys
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from typing import List, Dict, Optional, Tuple

# Project paths
SCRIPT_DIR = Path(__file__).parent
PROJECT_ROOT = SCRIPT_DIR.parent


@dataclass
class Commit:
    """Represents a git commit."""
    hash: str
    short_hash: str
    author: str
    date: str
    subject: str
    body: str
    category: str = "other"
    scope: str = ""


# Commit type patterns
COMMIT_PATTERNS = {
    "feat": ("Features", r"^(feat|add|new|implement)"),
    "fix": ("Bug Fixes", r"^(fix|bugfix|hotfix|patch)"),
    "docs": ("Documentation", r"^(docs?|documentation|readme)"),
    "style": ("Styling", r"^(style|format|lint)"),
    "refactor": ("Refactoring", r"^(refactor|restructure|reorganize|cleanup|clean)"),
    "perf": ("Performance", r"^(perf|performance|optimize|speed)"),
    "test": ("Testing", r"^(test|tests|testing)"),
    "build": ("Build", r"^(build|ci|cd|deploy|release)"),
    "chore": ("Chores", r"^(chore|misc|other|update)"),
}


def run_git(args: List[str]) -> str:
    """Run a git command and return output."""
    try:
        result = subprocess.run(
            ["git"] + args,
            capture_output=True,
            text=True,
            cwd=PROJECT_ROOT,
            timeout=30
        )
        return result.stdout.strip()
    except Exception as e:
        return ""


def get_commits(since: Optional[str] = None, until: Optional[str] = None,
                tag: Optional[str] = None, count: int = 20) -> List[Commit]:
    """Fetch commits from git log."""
    # Build git log command
    args = ["log", "--format=%H|%h|%an|%ad|%s|%b%x00", "--date=short"]

    if tag:
        args.append(f"{tag}..HEAD")
    elif since:
        args.append(f"--since={since}")
    if until:
        args.append(f"--until={until}")
    if not tag and not since:
        args.append(f"-n{count}")

    output = run_git(args)
    if not output:
        return []

    commits = []
    for entry in output.split("\x00"):
        entry = entry.strip()
        if not entry or "|" not in entry:
            continue

        parts = entry.split("|", 5)
        if len(parts) < 5:
            continue

        commit = Commit(
            hash=parts[0],
            short_hash=parts[1],
            author=parts[2],
            date=parts[3],
            subject=parts[4],
            body=parts[5] if len(parts) > 5 else ""
        )

        # Categorize commit
        commit.category, commit.scope = categorize_commit(commit.subject)
        commits.append(commit)

    return commits


def categorize_commit(subject: str) -> Tuple[str, str]:
    """Categorize a commit based on its subject line."""
    subject_lower = subject.lower()

    # Check for conventional commit format: type(scope): message
    conv_match = re.match(r"^(\w+)(?:\(([^)]+)\))?:\s*(.+)", subject)
    if conv_match:
        commit_type = conv_match.group(1).lower()
        scope = conv_match.group(2) or ""

        for category, (_, pattern) in COMMIT_PATTERNS.items():
            if re.match(pattern, commit_type, re.IGNORECASE):
                return category, scope

    # Fallback: check subject for keywords
    for category, (_, pattern) in COMMIT_PATTERNS.items():
        if re.search(pattern, subject_lower):
            return category, ""

    return "other", ""


def format_plain(commits: List[Commit], group_by_category: bool = False) -> str:
    """Format commits as plain text."""
    lines = []
    lines.append("=" * 60)
    lines.append("CHANGELOG")
    lines.append("=" * 60)
    lines.append(f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M')}")
    lines.append(f"Commits: {len(commits)}")
    lines.append("")

    if group_by_category:
        # Group commits by category
        categories: Dict[str, List[Commit]] = {}
        for commit in commits:
            cat = commit.category
            if cat not in categories:
                categories[cat] = []
            categories[cat].append(commit)

        # Output in order
        category_order = ["feat", "fix", "docs", "refactor", "perf", "test", "build", "chore", "other"]
        for cat in category_order:
            if cat not in categories:
                continue
            cat_name = COMMIT_PATTERNS.get(cat, ("Other", ""))[0]
            lines.append(f"### {cat_name}")
            lines.append("")
            for commit in categories[cat]:
                lines.append(f"  - {commit.subject} ({commit.short_hash})")
            lines.append("")
    else:
        # Chronological list
        current_date = ""
        for commit in commits:
            if commit.date != current_date:
                current_date = commit.date
                lines.append(f"### {current_date}")
                lines.append("")
            lines.append(f"  - {commit.subject} ({commit.short_hash})")

    return "\n".join(lines)


def format_markdown(commits: List[Commit], group_by_category: bool = False) -> str:
    """Format commits as markdown."""
    lines = []
    lines.append("# Changelog")
    lines.append("")
    lines.append(f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M')}")
    lines.append("")

    if group_by_category:
        categories: Dict[str, List[Commit]] = {}
        for commit in commits:
            cat = commit.category
            if cat not in categories:
                categories[cat] = []
            categories[cat].append(commit)

        category_order = ["feat", "fix", "docs", "refactor", "perf", "test", "build", "chore", "other"]
        for cat in category_order:
            if cat not in categories:
                continue
            cat_name = COMMIT_PATTERNS.get(cat, ("Other", ""))[0]
            lines.append(f"## {cat_name}")
            lines.append("")
            for commit in categories[cat]:
                scope_str = f"**{commit.scope}:** " if commit.scope else ""
                lines.append(f"- {scope_str}{commit.subject} (`{commit.short_hash}`)")
            lines.append("")
    else:
        current_date = ""
        for commit in commits:
            if commit.date != current_date:
                if current_date:
                    lines.append("")
                current_date = commit.date
                lines.append(f"## {current_date}")
                lines.append("")
            lines.append(f"- {commit.subject} (`{commit.short_hash}`)")

    return "\n".join(lines)


def format_json(commits: List[Commit]) -> str:
    """Format commits as JSON."""
    import json
    data = {
        "generated": datetime.now().isoformat(),
        "count": len(commits),
        "commits": [
            {
                "hash": c.hash,
                "short_hash": c.short_hash,
                "author": c.author,
                "date": c.date,
                "subject": c.subject,
                "category": c.category,
                "scope": c.scope,
            }
            for c in commits
        ]
    }
    return json.dumps(data, indent=2)


def format_release_notes(commits: List[Commit], version: str = "Unreleased") -> str:
    """Format commits as release notes."""
    lines = []
    lines.append(f"# Release Notes - {version}")
    lines.append("")
    lines.append(f"Release Date: {datetime.now().strftime('%Y-%m-%d')}")
    lines.append("")

    # Group by category
    categories: Dict[str, List[Commit]] = {}
    for commit in commits:
        cat = commit.category
        if cat not in categories:
            categories[cat] = []
        categories[cat].append(commit)

    # Features first
    if "feat" in categories:
        lines.append("## New Features")
        lines.append("")
        for commit in categories["feat"]:
            lines.append(f"- {commit.subject}")
        lines.append("")

    # Bug fixes
    if "fix" in categories:
        lines.append("## Bug Fixes")
        lines.append("")
        for commit in categories["fix"]:
            lines.append(f"- {commit.subject}")
        lines.append("")

    # Improvements
    improvements = []
    for cat in ["refactor", "perf", "docs"]:
        if cat in categories:
            improvements.extend(categories[cat])

    if improvements:
        lines.append("## Improvements")
        lines.append("")
        for commit in improvements:
            lines.append(f"- {commit.subject}")
        lines.append("")

    # Other changes
    other = []
    for cat in ["test", "build", "chore", "other"]:
        if cat in categories:
            other.extend(categories[cat])

    if other:
        lines.append("## Other Changes")
        lines.append("")
        for commit in other:
            lines.append(f"- {commit.subject}")
        lines.append("")

    return "\n".join(lines)


def main():
    import argparse

    parser = argparse.ArgumentParser(description="Generate changelog from git commits")
    parser.add_argument("--since", "-s", type=str,
                        help="Include commits since date (YYYY-MM-DD)")
    parser.add_argument("--until", "-u", type=str,
                        help="Include commits until date (YYYY-MM-DD)")
    parser.add_argument("--tag", "-t", type=str,
                        help="Include commits since tag")
    parser.add_argument("--count", "-n", type=int, default=20,
                        help="Number of commits (default: 20)")
    parser.add_argument("--format", "-f", type=str, default="plain",
                        choices=["plain", "markdown", "json", "release"],
                        help="Output format")
    parser.add_argument("--category", "-c", action="store_true",
                        help="Group by category instead of date")
    parser.add_argument("--version", "-v", type=str, default="Unreleased",
                        help="Version for release notes format")
    parser.add_argument("--output", "-o", type=str,
                        help="Output file (default: stdout)")

    args = parser.parse_args()

    # Fetch commits
    commits = get_commits(
        since=args.since,
        until=args.until,
        tag=args.tag,
        count=args.count
    )

    if not commits:
        print("No commits found", file=sys.stderr)
        sys.exit(1)

    # Format output
    if args.format == "plain":
        output = format_plain(commits, args.category)
    elif args.format == "markdown":
        output = format_markdown(commits, args.category)
    elif args.format == "json":
        output = format_json(commits)
    elif args.format == "release":
        output = format_release_notes(commits, args.version)
    else:
        output = format_plain(commits, args.category)

    # Output
    if args.output:
        Path(args.output).write_text(output, encoding="utf-8")
        print(f"Written to {args.output}")
    else:
        print(output)


if __name__ == "__main__":
    main()
