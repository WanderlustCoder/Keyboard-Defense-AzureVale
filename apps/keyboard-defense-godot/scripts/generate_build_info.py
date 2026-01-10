#!/usr/bin/env python3
"""
Build Info Generator

Generates build metadata for the project:
- Version from project.godot
- Git commit hash and branch
- Build date/time
- File counts and sizes
- Creates build_info.gd or exports JSON

Usage:
    python scripts/generate_build_info.py              # Generate build_info.gd
    python scripts/generate_build_info.py --json       # JSON output
    python scripts/generate_build_info.py --export     # Export to file
    python scripts/generate_build_info.py --check      # Show build info without writing
"""

import json
import os
import re
import subprocess
import sys
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional

# Project paths
SCRIPT_DIR = Path(__file__).parent
PROJECT_ROOT = SCRIPT_DIR.parent
BUILD_INFO_FILE = PROJECT_ROOT / "game" / "build_info.gd"


def run_git_command(args: List[str]) -> Optional[str]:
    """Run a git command and return output."""
    try:
        result = subprocess.run(
            ["git"] + args,
            cwd=PROJECT_ROOT,
            capture_output=True,
            text=True,
            timeout=5
        )
        if result.returncode == 0:
            return result.stdout.strip()
        return None
    except Exception:
        return None


def get_git_info() -> Dict:
    """Get git repository information."""
    info = {
        "commit_hash": "unknown",
        "commit_short": "unknown",
        "branch": "unknown",
        "tag": "",
        "dirty": False,
        "commit_date": "",
        "commit_message": ""
    }

    # Get commit hash
    commit_hash = run_git_command(["rev-parse", "HEAD"])
    if commit_hash:
        info["commit_hash"] = commit_hash
        info["commit_short"] = commit_hash[:8]

    # Get branch
    branch = run_git_command(["rev-parse", "--abbrev-ref", "HEAD"])
    if branch:
        info["branch"] = branch

    # Get tag if on one
    tag = run_git_command(["describe", "--tags", "--exact-match"])
    if tag:
        info["tag"] = tag

    # Check if dirty
    status = run_git_command(["status", "--porcelain"])
    if status:
        info["dirty"] = True

    # Get commit date
    commit_date = run_git_command(["log", "-1", "--format=%ci"])
    if commit_date:
        info["commit_date"] = commit_date

    # Get commit message
    commit_msg = run_git_command(["log", "-1", "--format=%s"])
    if commit_msg:
        info["commit_message"] = commit_msg[:80]

    return info


def get_version_from_project() -> str:
    """Extract version from project.godot."""
    project_file = PROJECT_ROOT / "project.godot"
    if not project_file.exists():
        return "0.0.0"

    try:
        content = project_file.read_text(encoding="utf-8")
        # Look for config/version
        match = re.search(r'config/version\s*=\s*"([^"]+)"', content)
        if match:
            return match.group(1)

        # Look for application/config/version
        match = re.search(r'application/config/version\s*=\s*"([^"]+)"', content)
        if match:
            return match.group(1)

    except Exception:
        pass

    return "0.0.0"


def get_project_stats() -> Dict:
    """Get project statistics."""
    stats = {
        "gd_files": 0,
        "tscn_files": 0,
        "json_files": 0,
        "svg_files": 0,
        "png_files": 0,
        "total_lines": 0,
        "code_lines": 0
    }

    # Count files
    for ext, key in [(".gd", "gd_files"), (".tscn", "tscn_files"),
                     (".json", "json_files"), (".svg", "svg_files"),
                     (".png", "png_files")]:
        for f in PROJECT_ROOT.glob(f"**/*{ext}"):
            if ".godot" not in str(f) and "addons" not in str(f):
                stats[key] += 1

    # Count lines in GD files
    for gd_file in PROJECT_ROOT.glob("**/*.gd"):
        if ".godot" in str(gd_file) or "addons" in str(gd_file):
            continue
        try:
            lines = gd_file.read_text(encoding="utf-8").split('\n')
            stats["total_lines"] += len(lines)
            stats["code_lines"] += sum(1 for line in lines
                                        if line.strip() and not line.strip().startswith('#'))
        except Exception:
            pass

    return stats


def get_data_info() -> Dict:
    """Get information about data files."""
    data = {
        "lessons": 0,
        "buildings": 0,
        "upgrades": 0,
        "enemies": 0
    }

    data_dir = PROJECT_ROOT / "data"
    if not data_dir.exists():
        return data

    # Count lessons
    lessons_file = data_dir / "lessons.json"
    if lessons_file.exists():
        try:
            content = json.loads(lessons_file.read_text(encoding="utf-8"))
            if "entries" in content:
                data["lessons"] = len(content["entries"])
            elif "lessons" in content:
                data["lessons"] = len(content["lessons"])
        except Exception:
            pass

    # Count buildings
    buildings_file = data_dir / "buildings.json"
    if buildings_file.exists():
        try:
            content = json.loads(buildings_file.read_text(encoding="utf-8"))
            if "buildings" in content:
                data["buildings"] = len(content["buildings"])
        except Exception:
            pass

    # Count kingdom upgrades
    for upgrade_file in ["kingdom_upgrades.json", "unit_upgrades.json"]:
        ufile = data_dir / upgrade_file
        if ufile.exists():
            try:
                content = json.loads(ufile.read_text(encoding="utf-8"))
                if "upgrades" in content:
                    data["upgrades"] += len(content["upgrades"])
            except Exception:
                pass

    # Count enemies from enemies.gd
    enemies_file = PROJECT_ROOT / "sim" / "enemies.gd"
    if enemies_file.exists():
        try:
            content = enemies_file.read_text(encoding="utf-8")
            matches = re.findall(r'"([a-z_]+)":\s*\{[^}]*"hp"', content)
            data["enemies"] = len(matches)
        except Exception:
            pass

    return data


def generate_build_info() -> Dict:
    """Generate complete build information."""
    git_info = get_git_info()
    stats = get_project_stats()
    data_info = get_data_info()

    return {
        "version": get_version_from_project(),
        "build_date": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        "build_timestamp": int(datetime.now().timestamp()),
        "git": git_info,
        "stats": stats,
        "data": data_info
    }


def format_gdscript(info: Dict) -> str:
    """Format build info as GDScript."""
    lines = [
        "# Build Information",
        "# Auto-generated by scripts/generate_build_info.py",
        "# DO NOT EDIT MANUALLY",
        "",
        "class_name BuildInfo",
        "extends RefCounted",
        "",
        f'const VERSION: String = "{info["version"]}"',
        f'const BUILD_DATE: String = "{info["build_date"]}"',
        f'const BUILD_TIMESTAMP: int = {info["build_timestamp"]}',
        "",
        "# Git Information",
        f'const GIT_COMMIT: String = "{info["git"]["commit_hash"]}"',
        f'const GIT_COMMIT_SHORT: String = "{info["git"]["commit_short"]}"',
        f'const GIT_BRANCH: String = "{info["git"]["branch"]}"',
        f'const GIT_TAG: String = "{info["git"]["tag"]}"',
        f'const GIT_DIRTY: bool = {"true" if info["git"]["dirty"] else "false"}',
        "",
        "# Project Statistics",
        f'const STAT_GD_FILES: int = {info["stats"]["gd_files"]}',
        f'const STAT_CODE_LINES: int = {info["stats"]["code_lines"]}',
        f'const STAT_SCENES: int = {info["stats"]["tscn_files"]}',
        "",
        "# Data Counts",
        f'const DATA_LESSONS: int = {info["data"]["lessons"]}',
        f'const DATA_BUILDINGS: int = {info["data"]["buildings"]}',
        f'const DATA_UPGRADES: int = {info["data"]["upgrades"]}',
        f'const DATA_ENEMIES: int = {info["data"]["enemies"]}',
        "",
        "",
        "static func get_version_string() -> String:",
        '\tvar v = VERSION',
        '\tif GIT_DIRTY:',
        '\t\tv += "-dirty"',
        '\tif GIT_TAG:',
        '\t\treturn GIT_TAG',
        '\treturn v + "+" + GIT_COMMIT_SHORT',
        "",
        "",
        "static func get_build_string() -> String:",
        '\treturn "Build %s (%s)" % [get_version_string(), BUILD_DATE]',
        "",
        "",
        "static func get_full_info() -> Dictionary:",
        "\treturn {",
        '\t\t"version": VERSION,',
        '\t\t"build_date": BUILD_DATE,',
        '\t\t"git_commit": GIT_COMMIT,',
        '\t\t"git_branch": GIT_BRANCH,',
        '\t\t"git_dirty": GIT_DIRTY,',
        '\t\t"code_lines": STAT_CODE_LINES,',
        '\t\t"lessons": DATA_LESSONS,',
        "\t}",
        "",
    ]
    return "\n".join(lines)


def format_json(info: Dict) -> str:
    """Format build info as JSON."""
    return json.dumps(info, indent=2)


def format_report(info: Dict) -> str:
    """Format build info as human-readable report."""
    lines = []
    lines.append("=" * 60)
    lines.append("BUILD INFORMATION - KEYBOARD DEFENSE")
    lines.append("=" * 60)
    lines.append("")

    lines.append("## VERSION")
    lines.append(f"  Version:      {info['version']}")
    lines.append(f"  Build Date:   {info['build_date']}")
    lines.append("")

    lines.append("## GIT")
    lines.append(f"  Branch:       {info['git']['branch']}")
    lines.append(f"  Commit:       {info['git']['commit_short']}")
    if info['git']['tag']:
        lines.append(f"  Tag:          {info['git']['tag']}")
    lines.append(f"  Dirty:        {'Yes' if info['git']['dirty'] else 'No'}")
    if info['git']['commit_date']:
        lines.append(f"  Commit Date:  {info['git']['commit_date']}")
    if info['git']['commit_message']:
        lines.append(f"  Message:      {info['git']['commit_message']}")
    lines.append("")

    lines.append("## PROJECT STATS")
    lines.append(f"  GDScript files:   {info['stats']['gd_files']}")
    lines.append(f"  Code lines:       {info['stats']['code_lines']:,}")
    lines.append(f"  Total lines:      {info['stats']['total_lines']:,}")
    lines.append(f"  Scene files:      {info['stats']['tscn_files']}")
    lines.append(f"  JSON files:       {info['stats']['json_files']}")
    lines.append(f"  SVG assets:       {info['stats']['svg_files']}")
    lines.append(f"  PNG sprites:      {info['stats']['png_files']}")
    lines.append("")

    lines.append("## DATA CONTENT")
    lines.append(f"  Lessons:          {info['data']['lessons']}")
    lines.append(f"  Buildings:        {info['data']['buildings']}")
    lines.append(f"  Upgrades:         {info['data']['upgrades']}")
    lines.append(f"  Enemy types:      {info['data']['enemies']}")
    lines.append("")

    # Version string
    version_str = info['version']
    if info['git']['tag']:
        version_str = info['git']['tag']
    elif info['git']['dirty']:
        version_str += f"-dirty+{info['git']['commit_short']}"
    else:
        version_str += f"+{info['git']['commit_short']}"

    lines.append("## VERSION STRING")
    lines.append(f"  {version_str}")
    lines.append("")

    return "\n".join(lines)


def main():
    import argparse

    parser = argparse.ArgumentParser(description="Generate build info")
    parser.add_argument("--json", "-j", action="store_true", help="JSON output")
    parser.add_argument("--check", "-c", action="store_true", help="Show info without writing")
    parser.add_argument("--export", "-e", action="store_true", help="Export to build_info.gd")
    parser.add_argument("--output", "-o", type=str, help="Output file path")
    args = parser.parse_args()

    info = generate_build_info()

    if args.json:
        print(format_json(info))
    elif args.check:
        print(format_report(info))
    elif args.export or args.output:
        output_file = Path(args.output) if args.output else BUILD_INFO_FILE
        gdscript = format_gdscript(info)
        output_file.write_text(gdscript, encoding="utf-8")
        print(f"Generated: {output_file}")
        print(f"Version: {info['version']}+{info['git']['commit_short']}")
    else:
        # Default: show report
        print(format_report(info))


if __name__ == "__main__":
    main()
