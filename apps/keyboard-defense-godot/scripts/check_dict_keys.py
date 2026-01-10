#!/usr/bin/env python3
"""
Dictionary Key Checker

Finds potential dictionary key issues:
- Inconsistent key naming (snake_case vs camelCase)
- Similar keys that might be typos
- Hardcoded keys used only once
- Keys that differ only by underscore/case

Usage:
    python scripts/check_dict_keys.py              # Full report
    python scripts/check_dict_keys.py --file game/main.gd  # Single file
    python scripts/check_dict_keys.py --json       # JSON output
"""

import json
import re
import sys
from collections import defaultdict
from dataclasses import dataclass, field
from difflib import SequenceMatcher
from pathlib import Path
from typing import Dict, List, Optional, Set, Tuple

# Project paths
SCRIPT_DIR = Path(__file__).parent
PROJECT_ROOT = SCRIPT_DIR.parent

# Similarity threshold for typo detection
SIMILARITY_THRESHOLD = 0.85


@dataclass
class KeyUsage:
    """A dictionary key usage."""
    key: str
    file: str
    line: int
    context: str
    access_type: str  # "get", "set", "has", "erase"


@dataclass
class KeyIssue:
    """An issue with dictionary keys."""
    issue_type: str  # "similar", "inconsistent", "single_use"
    keys: List[str]
    files: List[str]
    message: str
    severity: str


@dataclass
class DictKeyReport:
    """Dictionary key check report."""
    files_checked: int = 0
    total_keys: int = 0
    unique_keys: int = 0
    single_use_keys: int = 0
    key_usages: Dict[str, List[KeyUsage]] = field(default_factory=lambda: defaultdict(list))
    issues: List[KeyIssue] = field(default_factory=list)
    by_severity: Dict[str, int] = field(default_factory=lambda: {"high": 0, "medium": 0, "low": 0})


def extract_dict_keys(file_path: Path, rel_path: str) -> List[KeyUsage]:
    """Extract dictionary key usages from a file."""
    usages = []

    try:
        content = file_path.read_text(encoding="utf-8")
        lines = content.split('\n')
    except Exception:
        return usages

    for i, line in enumerate(lines):
        line_num = i + 1
        stripped = line.strip()

        # Skip comments
        if stripped.startswith("#"):
            continue

        # Pattern: dict["key"] or dict['key']
        bracket_matches = re.findall(r'\w+\[(["\'])(\w+)\1\]', line)
        for _, key in bracket_matches:
            usages.append(KeyUsage(
                key=key,
                file=rel_path,
                line=line_num,
                context=stripped[:60],
                access_type="access"
            ))

        # Pattern: dict.get("key") or dict.get('key')
        get_matches = re.findall(r'\.get\s*\(\s*(["\'])(\w+)\1', line)
        for _, key in get_matches:
            usages.append(KeyUsage(
                key=key,
                file=rel_path,
                line=line_num,
                context=stripped[:60],
                access_type="get"
            ))

        # Pattern: dict.has("key") or "key" in dict
        has_matches = re.findall(r'\.has\s*\(\s*(["\'])(\w+)\1', line)
        for _, key in has_matches:
            usages.append(KeyUsage(
                key=key,
                file=rel_path,
                line=line_num,
                context=stripped[:60],
                access_type="has"
            ))

        in_matches = re.findall(r'(["\'])(\w+)\1\s+in\s+\w+', line)
        for _, key in in_matches:
            usages.append(KeyUsage(
                key=key,
                file=rel_path,
                line=line_num,
                context=stripped[:60],
                access_type="has"
            ))

        # Pattern: dict.erase("key")
        erase_matches = re.findall(r'\.erase\s*\(\s*(["\'])(\w+)\1', line)
        for _, key in erase_matches:
            usages.append(KeyUsage(
                key=key,
                file=rel_path,
                line=line_num,
                context=stripped[:60],
                access_type="erase"
            ))

        # Pattern: {"key": value} dictionary literals
        literal_matches = re.findall(r'["\'](\w+)["\']\s*:', line)
        for key in literal_matches:
            usages.append(KeyUsage(
                key=key,
                file=rel_path,
                line=line_num,
                context=stripped[:60],
                access_type="set"
            ))

    return usages


def similar(a: str, b: str) -> float:
    """Calculate similarity ratio between two strings."""
    return SequenceMatcher(None, a.lower(), b.lower()).ratio()


def normalize_key(key: str) -> str:
    """Normalize a key for comparison (remove underscores, lowercase)."""
    return key.lower().replace("_", "")


def find_similar_keys(keys: Set[str]) -> List[Tuple[str, str, float]]:
    """Find pairs of similar keys that might be typos."""
    similar_pairs = []
    key_list = list(keys)

    for i, key1 in enumerate(key_list):
        for key2 in key_list[i + 1:]:
            # Skip if same normalized form (intentional variations)
            if normalize_key(key1) == normalize_key(key2):
                continue

            ratio = similar(key1, key2)
            if ratio >= SIMILARITY_THRESHOLD:
                similar_pairs.append((key1, key2, ratio))

    return similar_pairs


def check_naming_consistency(keys: Set[str]) -> List[Tuple[str, str]]:
    """Find keys with inconsistent naming conventions."""
    inconsistent = []

    snake_case = set()
    camel_case = set()
    other = set()

    for key in keys:
        if "_" in key:
            snake_case.add(key)
        elif key[0].islower() and any(c.isupper() for c in key[1:]):
            camel_case.add(key)
        else:
            other.add(key)

    # If we have both snake_case and camelCase, flag the minority
    if snake_case and camel_case:
        if len(snake_case) > len(camel_case):
            for key in camel_case:
                inconsistent.append((key, "camelCase in snake_case codebase"))
        else:
            for key in snake_case:
                inconsistent.append((key, "snake_case in camelCase codebase"))

    return inconsistent


def check_dict_keys(target_file: Optional[str] = None) -> DictKeyReport:
    """Check dictionary keys across the project."""
    report = DictKeyReport()

    if target_file:
        gd_files = [PROJECT_ROOT / target_file]
    else:
        gd_files = list(PROJECT_ROOT.glob("**/*.gd"))

    # Collect all key usages
    for gd_file in gd_files:
        if ".godot" in str(gd_file) or "addons" in str(gd_file):
            continue

        if not gd_file.exists():
            continue

        rel_path = str(gd_file.relative_to(PROJECT_ROOT))
        report.files_checked += 1

        usages = extract_dict_keys(gd_file, rel_path)
        for usage in usages:
            report.total_keys += 1
            report.key_usages[usage.key].append(usage)

    report.unique_keys = len(report.key_usages)

    # Find single-use keys (potential typos or dead code)
    for key, usages in report.key_usages.items():
        if len(usages) == 1:
            report.single_use_keys += 1
            # Only flag longer keys (short keys like "id", "x", "y" are fine)
            if len(key) > 4:
                report.issues.append(KeyIssue(
                    issue_type="single_use",
                    keys=[key],
                    files=[usages[0].file],
                    message=f"Key '{key}' used only once - potential typo or dead code",
                    severity="low"
                ))
                report.by_severity["low"] += 1

    # Find similar keys (potential typos)
    all_keys = set(report.key_usages.keys())
    similar_pairs = find_similar_keys(all_keys)

    for key1, key2, ratio in similar_pairs:
        files1 = list(set(u.file for u in report.key_usages[key1]))
        files2 = list(set(u.file for u in report.key_usages[key2]))

        report.issues.append(KeyIssue(
            issue_type="similar",
            keys=[key1, key2],
            files=files1 + files2,
            message=f"Similar keys '{key1}' and '{key2}' ({ratio:.0%} similar) - potential typo",
            severity="medium"
        ))
        report.by_severity["medium"] += 1

    # Check naming consistency
    inconsistent = check_naming_consistency(all_keys)
    for key, reason in inconsistent[:10]:  # Limit to avoid noise
        files = list(set(u.file for u in report.key_usages[key]))
        report.issues.append(KeyIssue(
            issue_type="inconsistent",
            keys=[key],
            files=files,
            message=f"Inconsistent naming: '{key}' ({reason})",
            severity="low"
        ))
        report.by_severity["low"] += 1

    return report


def format_report(report: DictKeyReport) -> str:
    """Format dictionary key report as text."""
    lines = []
    lines.append("=" * 60)
    lines.append("DICTIONARY KEY CHECKER - KEYBOARD DEFENSE")
    lines.append("=" * 60)
    lines.append("")

    # Summary
    lines.append("## SUMMARY")
    lines.append(f"  Files checked:     {report.files_checked}")
    lines.append(f"  Total key usages:  {report.total_keys}")
    lines.append(f"  Unique keys:       {report.unique_keys}")
    lines.append(f"  Single-use keys:   {report.single_use_keys}")
    lines.append(f"  Issues found:      {len(report.issues)}")
    lines.append("")

    # Similar keys (potential typos)
    similar_issues = [i for i in report.issues if i.issue_type == "similar"]
    if similar_issues:
        lines.append("## SIMILAR KEYS (Potential Typos)")
        for issue in similar_issues[:15]:
            lines.append(f"  '{issue.keys[0]}' vs '{issue.keys[1]}'")
            lines.append(f"    Files: {', '.join(issue.files[:3])}")
        if len(similar_issues) > 15:
            lines.append(f"  ... and {len(similar_issues) - 15} more")
        lines.append("")

    # Most used keys
    lines.append("## MOST USED KEYS")
    sorted_keys = sorted(report.key_usages.items(), key=lambda x: -len(x[1]))
    for key, usages in sorted_keys[:15]:
        file_count = len(set(u.file for u in usages))
        lines.append(f"  '{key}': {len(usages)} uses in {file_count} files")
    lines.append("")

    # Health indicators
    lines.append("## HEALTH INDICATORS")
    if report.by_severity["medium"] == 0:
        lines.append("  [OK] No similar keys detected")
    else:
        lines.append(f"  [WARN] {report.by_severity['medium']} pairs of similar keys")

    single_use_pct = (report.single_use_keys / report.unique_keys * 100) if report.unique_keys > 0 else 0
    if single_use_pct < 30:
        lines.append(f"  [OK] {single_use_pct:.1f}% single-use keys (good reuse)")
    else:
        lines.append(f"  [INFO] {single_use_pct:.1f}% single-use keys")

    lines.append("")
    return "\n".join(lines)


def format_json(report: DictKeyReport) -> str:
    """Format report as JSON."""
    data = {
        "summary": {
            "files_checked": report.files_checked,
            "total_keys": report.total_keys,
            "unique_keys": report.unique_keys,
            "single_use_keys": report.single_use_keys,
            "issues_found": len(report.issues),
            "by_severity": report.by_severity
        },
        "similar_keys": [
            {
                "keys": i.keys,
                "files": i.files,
                "message": i.message
            }
            for i in report.issues if i.issue_type == "similar"
        ],
        "most_used_keys": [
            {
                "key": key,
                "usage_count": len(usages),
                "file_count": len(set(u.file for u in usages))
            }
            for key, usages in sorted(report.key_usages.items(), key=lambda x: -len(x[1]))[:20]
        ]
    }
    return json.dumps(data, indent=2)


def main():
    import argparse

    parser = argparse.ArgumentParser(description="Check dictionary keys")
    parser.add_argument("--json", "-j", action="store_true", help="JSON output")
    parser.add_argument("--file", "-f", type=str, help="Single file to check")
    args = parser.parse_args()

    report = check_dict_keys(args.file)

    if args.json:
        print(format_json(report))
    else:
        print(format_report(report))


if __name__ == "__main__":
    main()
