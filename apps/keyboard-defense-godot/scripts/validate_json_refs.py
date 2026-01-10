#!/usr/bin/env python3
"""
JSON Reference Validator

Validates cross-references between JSON data files:
- Checks that referenced IDs exist
- Validates upgrade chains and prerequisites
- Finds orphan entries (never referenced)
- Checks resource path references

Usage:
    python scripts/validate_json_refs.py              # Full report
    python scripts/validate_json_refs.py --file data/lessons.json  # Single file
    python scripts/validate_json_refs.py --json       # JSON output
"""

import json
import re
import sys
from dataclasses import dataclass, field
from pathlib import Path
from typing import Dict, List, Optional, Set, Any

# Project paths
SCRIPT_DIR = Path(__file__).parent
PROJECT_ROOT = SCRIPT_DIR.parent
DATA_DIR = PROJECT_ROOT / "data"


@dataclass
class RefIssue:
    """A reference issue."""
    file: str
    path: str  # JSON path to the reference
    ref_type: str  # "missing", "circular", "orphan"
    ref_id: str
    message: str
    severity: str  # "high", "medium", "low"


@dataclass
class RefReport:
    """JSON reference validation report."""
    files_checked: int = 0
    total_refs: int = 0
    valid_refs: int = 0
    broken_refs: int = 0
    orphan_entries: int = 0
    issues: List[RefIssue] = field(default_factory=list)
    by_severity: Dict[str, int] = field(default_factory=lambda: {"high": 0, "medium": 0, "low": 0})
    id_registry: Dict[str, Set[str]] = field(default_factory=dict)  # file -> set of IDs


def load_json_file(file_path: Path) -> Optional[Dict]:
    """Load a JSON file."""
    try:
        content = file_path.read_text(encoding="utf-8")
        return json.loads(content)
    except Exception:
        return None


def extract_ids(data: Dict, file_name: str) -> Set[str]:
    """Extract all IDs from a data file."""
    ids = set()

    # Common patterns for ID extraction
    if isinstance(data, dict):
        # Top-level entries pattern: {"entries": {"id1": {...}, "id2": {...}}}
        if "entries" in data and isinstance(data["entries"], dict):
            ids.update(data["entries"].keys())

        # Direct entries pattern: {"id1": {...}, "id2": {...}}
        # Skip known non-ID keys
        skip_keys = {"version", "meta", "settings", "config", "schema"}
        for key in data.keys():
            if key not in skip_keys and isinstance(data[key], dict):
                ids.add(key)

        # Array entries with id field: [{"id": "x"}, {"id": "y"}]
        for key, value in data.items():
            if isinstance(value, list):
                for item in value:
                    if isinstance(item, dict) and "id" in item:
                        ids.add(item["id"])

    return ids


def find_references(obj: Any, path: str = "") -> List[tuple]:
    """Find all potential ID references in an object."""
    refs = []

    if isinstance(obj, dict):
        for key, value in obj.items():
            new_path = f"{path}.{key}" if path else key

            # Known reference field patterns
            ref_fields = [
                "requires", "prerequisite", "prerequisites", "unlocks",
                "upgrades_to", "upgrades_from", "next", "prev",
                "lesson_id", "building_id", "enemy_id", "item_id",
                "skill_id", "quest_id", "achievement_id", "region_id",
                "word_pool", "focus_lesson", "required_lessons"
            ]

            if key in ref_fields:
                if isinstance(value, str):
                    refs.append((new_path, value, key))
                elif isinstance(value, list):
                    for i, item in enumerate(value):
                        if isinstance(item, str):
                            refs.append((f"{new_path}[{i}]", item, key))

            # Recurse
            refs.extend(find_references(value, new_path))

    elif isinstance(obj, list):
        for i, item in enumerate(obj):
            refs.extend(find_references(item, f"{path}[{i}]"))

    return refs


def check_resource_paths(obj: Any, path: str = "") -> List[tuple]:
    """Find resource path references."""
    paths = []

    if isinstance(obj, dict):
        for key, value in obj.items():
            new_path = f"{path}.{key}" if path else key

            if isinstance(value, str) and value.startswith("res://"):
                paths.append((new_path, value))

            paths.extend(check_resource_paths(value, new_path))

    elif isinstance(obj, list):
        for i, item in enumerate(obj):
            paths.extend(check_resource_paths(item, f"{path}[{i}]"))

    return paths


def validate_json_refs(target_file: Optional[str] = None) -> RefReport:
    """Validate JSON references."""
    report = RefReport()

    # First pass: collect all IDs
    all_ids: Set[str] = set()
    file_ids: Dict[str, Set[str]] = {}

    if target_file:
        json_files = [PROJECT_ROOT / target_file]
    else:
        json_files = list(DATA_DIR.glob("*.json"))

    for json_file in json_files:
        if not json_file.exists():
            continue

        rel_path = str(json_file.relative_to(PROJECT_ROOT))
        report.files_checked += 1

        data = load_json_file(json_file)
        if data is None:
            report.issues.append(RefIssue(
                file=rel_path,
                path="",
                ref_type="parse_error",
                ref_id="",
                message="Could not parse JSON file",
                severity="high"
            ))
            report.by_severity["high"] += 1
            continue

        ids = extract_ids(data, json_file.name)
        file_ids[rel_path] = ids
        all_ids.update(ids)
        report.id_registry[rel_path] = ids

    # Second pass: validate references
    referenced_ids: Set[str] = set()

    for json_file in json_files:
        if not json_file.exists():
            continue

        rel_path = str(json_file.relative_to(PROJECT_ROOT))
        data = load_json_file(json_file)
        if data is None:
            continue

        # Find references
        refs = find_references(data)
        for path, ref_id, ref_type in refs:
            report.total_refs += 1
            referenced_ids.add(ref_id)

            # Check if reference exists
            if ref_id not in all_ids:
                # Skip some known valid patterns
                if ref_id in ("none", "null", "", "default"):
                    report.valid_refs += 1
                    continue

                # Skip word pool references (they're arrays of words, not IDs)
                if ref_type == "word_pool":
                    report.valid_refs += 1
                    continue

                report.broken_refs += 1
                report.issues.append(RefIssue(
                    file=rel_path,
                    path=path,
                    ref_type="missing",
                    ref_id=ref_id,
                    message=f"Referenced ID '{ref_id}' not found in any data file",
                    severity="high"
                ))
                report.by_severity["high"] += 1
            else:
                report.valid_refs += 1

        # Check resource paths
        res_paths = check_resource_paths(data)
        for path, res_path in res_paths:
            report.total_refs += 1

            # Check if resource exists
            actual_path = PROJECT_ROOT / res_path.replace("res://", "")
            if not actual_path.exists():
                report.broken_refs += 1
                report.issues.append(RefIssue(
                    file=rel_path,
                    path=path,
                    ref_type="missing_resource",
                    ref_id=res_path,
                    message=f"Resource path does not exist: {res_path}",
                    severity="high"
                ))
                report.by_severity["high"] += 1
            else:
                report.valid_refs += 1

    # Find orphan entries (IDs never referenced)
    orphan_ids = all_ids - referenced_ids

    # Some IDs are expected to be entry points (not referenced by other data)
    entry_points = {"home_row", "home_row_1", "tutorial", "basic", "default"}

    for orphan_id in orphan_ids:
        if orphan_id in entry_points:
            continue

        # Find which file contains this ID
        source_file = ""
        for file_path, ids in file_ids.items():
            if orphan_id in ids:
                source_file = file_path
                break

        report.orphan_entries += 1
        report.issues.append(RefIssue(
            file=source_file,
            path="",
            ref_type="orphan",
            ref_id=orphan_id,
            message=f"Entry '{orphan_id}' is never referenced",
            severity="low"
        ))
        report.by_severity["low"] += 1

    return report


def format_report(report: RefReport) -> str:
    """Format reference report as text."""
    lines = []
    lines.append("=" * 60)
    lines.append("JSON REFERENCE VALIDATOR - KEYBOARD DEFENSE")
    lines.append("=" * 60)
    lines.append("")

    # Summary
    lines.append("## SUMMARY")
    lines.append(f"  Files checked:     {report.files_checked}")
    lines.append(f"  Total references:  {report.total_refs}")
    lines.append(f"  Valid references:  {report.valid_refs}")
    lines.append(f"  Broken references: {report.broken_refs}")
    lines.append(f"  Orphan entries:    {report.orphan_entries}")
    lines.append("")

    # Broken references (high severity)
    broken = [i for i in report.issues if i.ref_type in ("missing", "missing_resource")]
    if broken:
        lines.append("## BROKEN REFERENCES")
        for issue in broken[:20]:
            lines.append(f"  {issue.file}")
            lines.append(f"    Path: {issue.path}")
            lines.append(f"    Missing: {issue.ref_id}")
        if len(broken) > 20:
            lines.append(f"  ... and {len(broken) - 20} more")
        lines.append("")

    # Orphan entries
    orphans = [i for i in report.issues if i.ref_type == "orphan"]
    if orphans:
        lines.append("## ORPHAN ENTRIES (Never Referenced)")
        for issue in orphans[:15]:
            lines.append(f"  {issue.file}: {issue.ref_id}")
        if len(orphans) > 15:
            lines.append(f"  ... and {len(orphans) - 15} more")
        lines.append("")

    # ID registry
    lines.append("## ID REGISTRY")
    for file_path, ids in sorted(report.id_registry.items()):
        lines.append(f"  {file_path}: {len(ids)} entries")
    lines.append("")

    # Health indicators
    lines.append("## HEALTH INDICATORS")
    if report.broken_refs == 0:
        lines.append("  [OK] All references are valid")
    else:
        lines.append(f"  [ERROR] {report.broken_refs} broken references")

    if report.orphan_entries == 0:
        lines.append("  [OK] No orphan entries")
    elif report.orphan_entries < 10:
        lines.append(f"  [INFO] {report.orphan_entries} orphan entries (may be intentional)")
    else:
        lines.append(f"  [WARN] {report.orphan_entries} orphan entries")

    if report.total_refs > 0:
        valid_pct = report.valid_refs / report.total_refs * 100
        lines.append(f"  [INFO] {valid_pct:.1f}% reference validity")

    lines.append("")
    return "\n".join(lines)


def format_json(report: RefReport) -> str:
    """Format report as JSON."""
    data = {
        "summary": {
            "files_checked": report.files_checked,
            "total_refs": report.total_refs,
            "valid_refs": report.valid_refs,
            "broken_refs": report.broken_refs,
            "orphan_entries": report.orphan_entries,
            "by_severity": report.by_severity
        },
        "broken_references": [
            {
                "file": i.file,
                "path": i.path,
                "ref_id": i.ref_id,
                "message": i.message
            }
            for i in report.issues if i.ref_type in ("missing", "missing_resource")
        ],
        "orphan_entries": [
            {
                "file": i.file,
                "id": i.ref_id
            }
            for i in report.issues if i.ref_type == "orphan"
        ],
        "id_registry": {
            file_path: list(ids)
            for file_path, ids in report.id_registry.items()
        }
    }
    return json.dumps(data, indent=2)


def main():
    import argparse

    parser = argparse.ArgumentParser(description="Validate JSON references")
    parser.add_argument("--json", "-j", action="store_true", help="JSON output")
    parser.add_argument("--file", "-f", type=str, help="Single file to check")
    args = parser.parse_args()

    report = validate_json_refs(args.file)

    if args.json:
        print(format_json(report))
    else:
        print(format_report(report))


if __name__ == "__main__":
    main()
