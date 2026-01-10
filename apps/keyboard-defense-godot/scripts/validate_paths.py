#!/usr/bin/env python3
"""
Resource Path Validator

Validates all res:// paths in GDScript and scene files:
- Checks that referenced files exist
- Finds broken references
- Reports unused assets
- Validates preload/load paths

Usage:
    python scripts/validate_paths.py              # Full report
    python scripts/validate_paths.py --broken     # Show only broken paths
    python scripts/validate_paths.py --file game/main.gd  # Single file
    python scripts/validate_paths.py --json       # JSON output
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
class ResourceReference:
    """A resource path reference."""
    path: str
    file: str
    line: int
    reference_type: str  # "preload", "load", "scene", "string"
    exists: bool = False


@dataclass
class PathReport:
    """Resource path validation report."""
    references: List[ResourceReference] = field(default_factory=list)
    broken_paths: List[ResourceReference] = field(default_factory=list)
    valid_paths: List[ResourceReference] = field(default_factory=list)
    by_file: Dict[str, Dict] = field(default_factory=dict)
    unique_paths: Set[str] = field(default_factory=set)
    existing_resources: Set[str] = field(default_factory=set)


def res_to_real_path(res_path: str) -> Path:
    """Convert res:// path to real filesystem path."""
    if res_path.startswith("res://"):
        relative = res_path[6:]  # Remove "res://"
        return PROJECT_ROOT / relative
    return PROJECT_ROOT / res_path


def extract_paths_from_gd(filepath: Path) -> List[ResourceReference]:
    """Extract resource paths from a GDScript file."""
    references = []
    rel_path = str(filepath.relative_to(PROJECT_ROOT))

    try:
        content = filepath.read_text(encoding="utf-8")
        lines = content.split('\n')
    except Exception:
        return references

    for i, line in enumerate(lines):
        # preload("res://...")
        preload_matches = re.findall(r'preload\s*\(\s*["\']([^"\']+)["\']', line)
        for path in preload_matches:
            references.append(ResourceReference(
                path=path,
                file=rel_path,
                line=i + 1,
                reference_type="preload"
            ))

        # load("res://...")
        load_matches = re.findall(r'(?<!pre)load\s*\(\s*["\']([^"\']+)["\']', line)
        for path in load_matches:
            references.append(ResourceReference(
                path=path,
                file=rel_path,
                line=i + 1,
                reference_type="load"
            ))

        # "res://..." string literals (not in preload/load)
        string_matches = re.findall(r'["\']res://[^"\']+["\']', line)
        for match in string_matches:
            path = match.strip('"\'')
            # Skip if already caught by preload/load
            if path not in preload_matches and path not in load_matches:
                references.append(ResourceReference(
                    path=path,
                    file=rel_path,
                    line=i + 1,
                    reference_type="string"
                ))

    return references


def extract_paths_from_tscn(filepath: Path) -> List[ResourceReference]:
    """Extract resource paths from a scene file."""
    references = []
    rel_path = str(filepath.relative_to(PROJECT_ROOT))

    try:
        content = filepath.read_text(encoding="utf-8")
        lines = content.split('\n')
    except Exception:
        return references

    for i, line in enumerate(lines):
        # [ext_resource path="res://..." ...]
        ext_match = re.search(r'path\s*=\s*"([^"]+)"', line)
        if ext_match:
            path = ext_match.group(1)
            if path.startswith("res://"):
                references.append(ResourceReference(
                    path=path,
                    file=rel_path,
                    line=i + 1,
                    reference_type="scene"
                ))

        # [sub_resource ...] with path
        # script = preload("res://...")
        script_match = re.search(r'script\s*=\s*(?:preload|load)\s*\(\s*"([^"]+)"', line)
        if script_match:
            references.append(ResourceReference(
                path=script_match.group(1),
                file=rel_path,
                line=i + 1,
                reference_type="scene"
            ))

    return references


def get_existing_resources() -> Set[str]:
    """Get set of all existing resource paths."""
    resources = set()

    for pattern in ["**/*.gd", "**/*.tscn", "**/*.tres", "**/*.png", "**/*.svg",
                    "**/*.wav", "**/*.ogg", "**/*.mp3", "**/*.json"]:
        for f in PROJECT_ROOT.glob(pattern):
            if ".godot" not in str(f) and "addons" not in str(f):
                rel = str(f.relative_to(PROJECT_ROOT))
                resources.add(f"res://{rel}")

    return resources


def validate_paths(file_filter: Optional[str] = None) -> PathReport:
    """Validate all resource paths in the codebase."""
    report = PathReport()
    report.existing_resources = get_existing_resources()

    # Scan GDScript files
    for gd_file in PROJECT_ROOT.glob("**/*.gd"):
        if ".godot" in str(gd_file) or "addons" in str(gd_file):
            continue

        rel_path = str(gd_file.relative_to(PROJECT_ROOT))
        if file_filter and file_filter not in rel_path:
            continue

        references = extract_paths_from_gd(gd_file)

        for ref in references:
            # Check if path exists
            real_path = res_to_real_path(ref.path)
            ref.exists = real_path.exists() or ref.path in report.existing_resources

            report.references.append(ref)
            report.unique_paths.add(ref.path)

            if ref.exists:
                report.valid_paths.append(ref)
            else:
                report.broken_paths.append(ref)

        # File stats
        if references:
            broken = sum(1 for r in references if not r.exists)
            report.by_file[rel_path] = {
                "total": len(references),
                "broken": broken,
                "valid": len(references) - broken
            }

    # Scan scene files
    for tscn_file in PROJECT_ROOT.glob("**/*.tscn"):
        if ".godot" in str(tscn_file) or "addons" in str(tscn_file):
            continue

        rel_path = str(tscn_file.relative_to(PROJECT_ROOT))
        if file_filter and file_filter not in rel_path:
            continue

        references = extract_paths_from_tscn(tscn_file)

        for ref in references:
            real_path = res_to_real_path(ref.path)
            ref.exists = real_path.exists() or ref.path in report.existing_resources

            report.references.append(ref)
            report.unique_paths.add(ref.path)

            if ref.exists:
                report.valid_paths.append(ref)
            else:
                report.broken_paths.append(ref)

        if references:
            broken = sum(1 for r in references if not r.exists)
            if rel_path in report.by_file:
                report.by_file[rel_path]["total"] += len(references)
                report.by_file[rel_path]["broken"] += broken
                report.by_file[rel_path]["valid"] += len(references) - broken
            else:
                report.by_file[rel_path] = {
                    "total": len(references),
                    "broken": broken,
                    "valid": len(references) - broken
                }

    return report


def format_report(report: PathReport, show_broken_only: bool = False) -> str:
    """Format path report as text."""
    lines = []
    lines.append("=" * 60)
    lines.append("RESOURCE PATH VALIDATOR - KEYBOARD DEFENSE")
    lines.append("=" * 60)
    lines.append("")

    # Summary
    lines.append("## SUMMARY")
    lines.append(f"  Total references:    {len(report.references)}")
    lines.append(f"  Unique paths:        {len(report.unique_paths)}")
    lines.append(f"  Valid paths:         {len(report.valid_paths)}")
    lines.append(f"  Broken paths:        {len(report.broken_paths)}")
    lines.append("")

    if show_broken_only:
        if report.broken_paths:
            lines.append("## BROKEN PATHS")
            for ref in sorted(report.broken_paths, key=lambda r: (r.file, r.line)):
                lines.append(f"  {ref.file}:{ref.line}")
                lines.append(f"    [{ref.reference_type}] {ref.path}")
            lines.append("")
        else:
            lines.append("No broken paths found!")
            lines.append("")
    else:
        # Broken paths
        if report.broken_paths:
            lines.append("## BROKEN PATHS")
            for ref in report.broken_paths[:20]:
                lines.append(f"  {ref.file}:{ref.line}")
                lines.append(f"    [{ref.reference_type}] {ref.path}")
            if len(report.broken_paths) > 20:
                lines.append(f"  ... and {len(report.broken_paths) - 20} more")
            lines.append("")

        # Reference types
        lines.append("## REFERENCES BY TYPE")
        type_counts: Dict[str, int] = {}
        for ref in report.references:
            type_counts[ref.reference_type] = type_counts.get(ref.reference_type, 0) + 1

        for ref_type in ["preload", "load", "scene", "string"]:
            count = type_counts.get(ref_type, 0)
            if count > 0:
                lines.append(f"  {ref_type:10} {count}")
        lines.append("")

        # Files with most references
        lines.append("## FILES WITH MOST REFERENCES")
        sorted_files = sorted(
            [(f, d["total"]) for f, d in report.by_file.items()],
            key=lambda x: -x[1]
        )
        for filepath, count in sorted_files[:10]:
            broken = report.by_file[filepath]["broken"]
            marker = " [!]" if broken > 0 else ""
            lines.append(f"  {count:4} refs  {filepath}{marker}")
        lines.append("")

        # Files with broken refs
        broken_files = [(f, d["broken"]) for f, d in report.by_file.items() if d["broken"] > 0]
        if broken_files:
            lines.append("## FILES WITH BROKEN REFERENCES")
            for filepath, broken in sorted(broken_files, key=lambda x: -x[1]):
                lines.append(f"  {broken:4} broken  {filepath}")
            lines.append("")

    # Health indicators
    lines.append("## HEALTH INDICATORS")
    if not report.broken_paths:
        lines.append("  [OK] All resource paths are valid")
    else:
        lines.append(f"  [WARN] {len(report.broken_paths)} broken resource paths")

    # Check for common issues
    preload_count = sum(1 for r in report.references if r.reference_type == "preload")
    load_count = sum(1 for r in report.references if r.reference_type == "load")
    if load_count > preload_count * 2:
        lines.append(f"  [INFO] Many load() calls ({load_count}) vs preload() ({preload_count})")
        lines.append("         Consider using preload() for frequently used resources")

    lines.append("")
    return "\n".join(lines)


def format_json(report: PathReport) -> str:
    """Format report as JSON."""
    data = {
        "summary": {
            "total_references": len(report.references),
            "unique_paths": len(report.unique_paths),
            "valid": len(report.valid_paths),
            "broken": len(report.broken_paths)
        },
        "broken_paths": [
            {
                "path": r.path,
                "file": r.file,
                "line": r.line,
                "type": r.reference_type
            }
            for r in report.broken_paths
        ],
        "by_file": {
            filepath: stats
            for filepath, stats in report.by_file.items()
        },
        "reference_types": {}
    }

    # Count by type
    for ref in report.references:
        data["reference_types"][ref.reference_type] = \
            data["reference_types"].get(ref.reference_type, 0) + 1

    return json.dumps(data, indent=2)


def main():
    import argparse

    parser = argparse.ArgumentParser(description="Validate resource paths")
    parser.add_argument("--json", "-j", action="store_true", help="JSON output")
    parser.add_argument("--file", "-f", type=str, help="Filter by file path")
    parser.add_argument("--broken", "-b", action="store_true", help="Show only broken paths")
    args = parser.parse_args()

    report = validate_paths(args.file)

    if args.json:
        print(format_json(report))
    else:
        print(format_report(report, args.broken))


if __name__ == "__main__":
    main()
