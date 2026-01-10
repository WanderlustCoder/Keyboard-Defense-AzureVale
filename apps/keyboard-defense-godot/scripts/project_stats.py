#!/usr/bin/env python3
"""
Project Statistics

Generates metrics and health overview for the codebase:
- Lines of code by type
- File counts by category
- Complexity estimates
- Documentation coverage
- Test coverage estimate

Usage:
    python scripts/project_stats.py              # Full report
    python scripts/project_stats.py --json       # JSON output
    python scripts/project_stats.py --brief      # Summary only
"""

import json
import re
import sys
from collections import defaultdict
from dataclasses import dataclass, field
from pathlib import Path
from typing import Dict, List, Any, Set

# Project paths
SCRIPT_DIR = Path(__file__).parent
PROJECT_ROOT = SCRIPT_DIR.parent


@dataclass
class FileStats:
    """Statistics for a single file."""
    path: str
    lines: int = 0
    code_lines: int = 0
    comment_lines: int = 0
    blank_lines: int = 0
    functions: int = 0
    classes: int = 0
    imports: int = 0
    todos: int = 0


@dataclass
class ProjectStats:
    """Aggregated project statistics."""
    total_files: int = 0
    total_lines: int = 0
    total_code_lines: int = 0
    total_comment_lines: int = 0
    total_blank_lines: int = 0
    total_functions: int = 0
    total_classes: int = 0
    total_todos: int = 0

    files_by_type: Dict[str, int] = field(default_factory=dict)
    lines_by_type: Dict[str, int] = field(default_factory=dict)
    files_by_dir: Dict[str, int] = field(default_factory=dict)

    largest_files: List[FileStats] = field(default_factory=list)
    most_complex: List[FileStats] = field(default_factory=list)

    # Data stats
    json_files: int = 0
    json_entries: int = 0

    # Asset stats
    svg_files: int = 0
    png_files: int = 0
    audio_files: int = 0

    # Test stats
    test_files: int = 0
    test_functions: int = 0

    # Doc stats
    doc_files: int = 0
    doc_lines: int = 0


def analyze_gdscript(filepath: Path) -> FileStats:
    """Analyze a GDScript file."""
    stats = FileStats(path=str(filepath.relative_to(PROJECT_ROOT)))

    try:
        content = filepath.read_text(encoding="utf-8")
        lines = content.split("\n")
    except Exception:
        return stats

    stats.lines = len(lines)

    in_multiline_string = False
    for line in lines:
        stripped = line.strip()

        # Track multiline strings
        if '"""' in stripped or "'''" in stripped:
            in_multiline_string = not in_multiline_string

        if not stripped:
            stats.blank_lines += 1
        elif stripped.startswith("#"):
            stats.comment_lines += 1
        elif in_multiline_string:
            stats.comment_lines += 1
        else:
            stats.code_lines += 1

        # Count functions
        if re.match(r"^(static\s+)?func\s+\w+", stripped):
            stats.functions += 1

        # Count classes
        if re.match(r"^class\s+\w+", stripped) or re.match(r"^class_name\s+\w+", stripped):
            stats.classes += 1

        # Count imports
        if "preload(" in stripped or "load(" in stripped:
            stats.imports += 1

        # Count TODOs
        if "TODO" in line.upper() or "FIXME" in line.upper():
            stats.todos += 1

    return stats


def analyze_json(filepath: Path) -> int:
    """Count entries in a JSON file."""
    try:
        content = filepath.read_text(encoding="utf-8")
        data = json.loads(content)

        # Count entries based on common structures
        if isinstance(data, dict):
            # Check for common array fields
            for key in ["lessons", "upgrades", "textures", "entries", "items"]:
                if key in data and isinstance(data[key], list):
                    return len(data[key])
            # Check for dict entries
            for key in ["entries", "dialogue", "graduation_paths"]:
                if key in data and isinstance(data[key], dict):
                    return len(data[key])
            return len(data)
        elif isinstance(data, list):
            return len(data)
    except Exception:
        pass
    return 0


def analyze_markdown(filepath: Path) -> int:
    """Count lines in a markdown file."""
    try:
        content = filepath.read_text(encoding="utf-8")
        return len(content.split("\n"))
    except Exception:
        return 0


def gather_stats() -> ProjectStats:
    """Gather all project statistics."""
    stats = ProjectStats()
    file_stats: List[FileStats] = []

    # GDScript files
    for gd_file in PROJECT_ROOT.glob("**/*.gd"):
        # Skip addons and .godot
        if ".godot" in str(gd_file) or "addons" in str(gd_file):
            continue

        fs = analyze_gdscript(gd_file)
        file_stats.append(fs)

        stats.total_files += 1
        stats.total_lines += fs.lines
        stats.total_code_lines += fs.code_lines
        stats.total_comment_lines += fs.comment_lines
        stats.total_blank_lines += fs.blank_lines
        stats.total_functions += fs.functions
        stats.total_classes += fs.classes
        stats.total_todos += fs.todos

        # Categorize by directory
        parent = gd_file.parent.name
        stats.files_by_dir[parent] = stats.files_by_dir.get(parent, 0) + 1

        # Track extension
        ext = gd_file.suffix
        stats.files_by_type[ext] = stats.files_by_type.get(ext, 0) + 1
        stats.lines_by_type[ext] = stats.lines_by_type.get(ext, 0) + fs.code_lines

        # Test files
        if "test" in str(gd_file).lower():
            stats.test_files += 1
            stats.test_functions += fs.functions

    # Scene files
    for tscn_file in PROJECT_ROOT.glob("**/*.tscn"):
        if ".godot" in str(tscn_file):
            continue
        stats.files_by_type[".tscn"] = stats.files_by_type.get(".tscn", 0) + 1

    # JSON data files
    for json_file in (PROJECT_ROOT / "data").glob("*.json"):
        stats.json_files += 1
        stats.json_entries += analyze_json(json_file)
        stats.files_by_type[".json"] = stats.files_by_type.get(".json", 0) + 1

    # Asset files
    svg_dir = PROJECT_ROOT / "assets" / "art" / "src-svg"
    if svg_dir.exists():
        stats.svg_files = len(list(svg_dir.glob("**/*.svg")))

    sprite_dir = PROJECT_ROOT / "assets" / "sprites"
    if sprite_dir.exists():
        stats.png_files = len(list(sprite_dir.glob("**/*.png")))

    audio_dir = PROJECT_ROOT / "assets" / "audio"
    if audio_dir.exists():
        stats.audio_files = len(list(audio_dir.glob("**/*.wav"))) + \
                           len(list(audio_dir.glob("**/*.ogg"))) + \
                           len(list(audio_dir.glob("**/*.mp3")))

    # Documentation files
    for md_file in PROJECT_ROOT.glob("**/*.md"):
        stats.doc_files += 1
        stats.doc_lines += analyze_markdown(md_file)
        stats.files_by_type[".md"] = stats.files_by_type.get(".md", 0) + 1

    # Find largest files
    stats.largest_files = sorted(file_stats, key=lambda x: x.lines, reverse=True)[:10]

    # Find most complex (by function count)
    stats.most_complex = sorted(file_stats, key=lambda x: x.functions, reverse=True)[:10]

    return stats


def format_report(stats: ProjectStats, brief: bool = False) -> str:
    """Format statistics report."""
    lines = []
    lines.append("=" * 60)
    lines.append("PROJECT STATISTICS - KEYBOARD DEFENSE")
    lines.append("=" * 60)
    lines.append("")

    # Summary
    lines.append("## SUMMARY")
    lines.append(f"  Total GDScript files:  {stats.total_files}")
    lines.append(f"  Total lines of code:   {stats.total_code_lines:,}")
    lines.append(f"  Total functions:       {stats.total_functions}")
    lines.append(f"  Total classes:         {stats.total_classes}")
    lines.append(f"  TODOs/FIXMEs:          {stats.total_todos}")
    lines.append("")

    # Code breakdown
    lines.append("## CODE BREAKDOWN")
    lines.append(f"  Code lines:            {stats.total_code_lines:,} ({stats.total_code_lines * 100 // max(stats.total_lines, 1)}%)")
    lines.append(f"  Comment lines:         {stats.total_comment_lines:,} ({stats.total_comment_lines * 100 // max(stats.total_lines, 1)}%)")
    lines.append(f"  Blank lines:           {stats.total_blank_lines:,} ({stats.total_blank_lines * 100 // max(stats.total_lines, 1)}%)")
    lines.append("")

    if not brief:
        # Files by directory
        lines.append("## FILES BY DIRECTORY")
        for dir_name, count in sorted(stats.files_by_dir.items(), key=lambda x: -x[1]):
            lines.append(f"  {dir_name:20} {count:4} files")
        lines.append("")

        # Files by type
        lines.append("## FILES BY TYPE")
        for ext, count in sorted(stats.files_by_type.items(), key=lambda x: -x[1]):
            code = stats.lines_by_type.get(ext, 0)
            lines.append(f"  {ext:10} {count:4} files  {code:6,} lines")
        lines.append("")

    # Data files
    lines.append("## DATA FILES")
    lines.append(f"  JSON files:            {stats.json_files}")
    lines.append(f"  Total entries:         {stats.json_entries}")
    lines.append("")

    # Assets
    lines.append("## ASSETS")
    lines.append(f"  SVG sources:           {stats.svg_files}")
    lines.append(f"  PNG sprites:           {stats.png_files}")
    lines.append(f"  Audio files:           {stats.audio_files}")
    lines.append("")

    # Documentation
    lines.append("## DOCUMENTATION")
    lines.append(f"  Markdown files:        {stats.doc_files}")
    lines.append(f"  Documentation lines:   {stats.doc_lines:,}")
    lines.append("")

    # Tests
    lines.append("## TESTING")
    lines.append(f"  Test files:            {stats.test_files}")
    lines.append(f"  Test functions:        {stats.test_functions}")
    if stats.total_functions > 0:
        coverage_est = stats.test_functions * 100 // stats.total_functions
        lines.append(f"  Est. test coverage:    ~{coverage_est}% (by function count)")
    lines.append("")

    if not brief:
        # Largest files
        lines.append("## LARGEST FILES (by lines)")
        for fs in stats.largest_files[:5]:
            lines.append(f"  {fs.lines:5} lines  {fs.path}")
        lines.append("")

        # Most complex
        lines.append("## MOST COMPLEX (by functions)")
        for fs in stats.most_complex[:5]:
            lines.append(f"  {fs.functions:4} funcs   {fs.path}")
        lines.append("")

    # Health indicators
    lines.append("## HEALTH INDICATORS")
    comment_ratio = stats.total_comment_lines * 100 // max(stats.total_code_lines, 1)
    if comment_ratio < 5:
        lines.append(f"  [WARN] Low comment ratio: {comment_ratio}%")
    else:
        lines.append(f"  [OK] Comment ratio: {comment_ratio}%")

    if stats.total_todos > 20:
        lines.append(f"  [WARN] Many TODOs: {stats.total_todos}")
    else:
        lines.append(f"  [OK] TODOs: {stats.total_todos}")

    avg_file_size = stats.total_lines // max(stats.total_files, 1)
    if avg_file_size > 500:
        lines.append(f"  [WARN] Large avg file size: {avg_file_size} lines")
    else:
        lines.append(f"  [OK] Avg file size: {avg_file_size} lines")

    if stats.svg_files > stats.png_files + 50:
        lines.append(f"  [WARN] Many SVGs not converted: {stats.svg_files - stats.png_files} pending")
    lines.append("")

    return "\n".join(lines)


def format_json(stats: ProjectStats) -> str:
    """Format as JSON."""
    data = {
        "summary": {
            "total_files": stats.total_files,
            "total_lines": stats.total_lines,
            "total_code_lines": stats.total_code_lines,
            "total_comment_lines": stats.total_comment_lines,
            "total_functions": stats.total_functions,
            "total_classes": stats.total_classes,
            "total_todos": stats.total_todos,
        },
        "files_by_type": stats.files_by_type,
        "files_by_dir": stats.files_by_dir,
        "data": {
            "json_files": stats.json_files,
            "json_entries": stats.json_entries,
        },
        "assets": {
            "svg_files": stats.svg_files,
            "png_files": stats.png_files,
            "audio_files": stats.audio_files,
        },
        "docs": {
            "doc_files": stats.doc_files,
            "doc_lines": stats.doc_lines,
        },
        "tests": {
            "test_files": stats.test_files,
            "test_functions": stats.test_functions,
        },
        "largest_files": [
            {"path": fs.path, "lines": fs.lines}
            for fs in stats.largest_files[:10]
        ],
    }
    return json.dumps(data, indent=2)


def main():
    import argparse

    parser = argparse.ArgumentParser(description="Generate project statistics")
    parser.add_argument("--json", "-j", action="store_true", help="JSON output")
    parser.add_argument("--brief", "-b", action="store_true", help="Brief summary only")
    args = parser.parse_args()

    stats = gather_stats()

    if args.json:
        print(format_json(stats))
    else:
        print(format_report(stats, args.brief))


if __name__ == "__main__":
    main()
