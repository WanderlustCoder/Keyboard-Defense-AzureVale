#!/usr/bin/env python3
"""
Session Context Loader

Aggregates project context for Claude Code at session start:
- .claude/ directory files (current task, recent changes, known issues, etc.)
- Recent git history
- Diagnostic summary
- Project state overview

Usage:
    python scripts/session_context.py           # Full context
    python scripts/session_context.py --brief   # Quick summary only
    python scripts/session_context.py --json    # Machine-readable JSON output
"""

import json
import os
import subprocess
import sys
from datetime import datetime
from pathlib import Path
from typing import Dict, Any, List, Optional

# Project paths
SCRIPT_DIR = Path(__file__).parent
PROJECT_ROOT = SCRIPT_DIR.parent
REPO_ROOT = PROJECT_ROOT.parent.parent  # Go up to repo root
CLAUDE_DIR = REPO_ROOT / ".claude"


def run_command(cmd: List[str], cwd: Optional[Path] = None) -> str:
    """Run a command and return output."""
    try:
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            cwd=cwd or PROJECT_ROOT,
            timeout=30
        )
        return result.stdout.strip()
    except Exception:
        return ""


def get_git_info() -> Dict[str, Any]:
    """Get git repository information."""
    info = {}

    # Current branch
    info["branch"] = run_command(["git", "rev-parse", "--abbrev-ref", "HEAD"])

    # Last commit
    info["last_commit"] = run_command([
        "git", "log", "-1", "--format=%h %s (%ar)"
    ])

    # Recent commits (last 5)
    commits = run_command([
        "git", "log", "-5", "--format=%h %s"
    ])
    info["recent_commits"] = commits.split("\n") if commits else []

    # Uncommitted changes count
    status = run_command(["git", "status", "--porcelain"])
    if status:
        lines = [l for l in status.split("\n") if l.strip()]
        modified = len([l for l in lines if l.startswith(" M") or l.startswith("M ")])
        untracked = len([l for l in lines if l.startswith("??")])
        info["uncommitted"] = {"modified": modified, "untracked": untracked}
    else:
        info["uncommitted"] = {"modified": 0, "untracked": 0}

    return info


def read_claude_file(filename: str) -> Optional[str]:
    """Read a file from the .claude directory."""
    filepath = CLAUDE_DIR / filename
    if filepath.exists():
        try:
            content = filepath.read_text(encoding="utf-8")
            # Remove template comments at end
            if "<!-- Template" in content:
                content = content.split("<!-- Template")[0].strip()
            return content
        except Exception:
            return None
    return None


def get_current_task() -> Optional[str]:
    """Get the current task from .claude/CURRENT_TASK.md."""
    content = read_claude_file("CURRENT_TASK.md")
    if content:
        # Extract just the task description, not the template
        lines = content.split("\n")
        task_lines = []
        in_task = False
        for line in lines:
            if line.startswith("## Current"):
                in_task = True
                continue
            if in_task and line.startswith("## "):
                break
            if in_task and line.strip():
                task_lines.append(line)
        return "\n".join(task_lines).strip() if task_lines else None
    return None


def get_recent_changes() -> List[str]:
    """Get recent changes from .claude/RECENT_CHANGES.md."""
    content = read_claude_file("RECENT_CHANGES.md")
    if content:
        changes = []
        lines = content.split("\n")
        for line in lines:
            if line.startswith("## ") and not line.startswith("## Recent"):
                # Extract date and description
                changes.append(line[3:].strip())
            if len(changes) >= 5:
                break
        return changes
    return []


def get_known_issues() -> List[str]:
    """Get known issues from .claude/KNOWN_ISSUES.md."""
    content = read_claude_file("KNOWN_ISSUES.md")
    if content:
        issues = []
        lines = content.split("\n")
        for line in lines:
            if line.startswith("- ") or line.startswith("* "):
                issues.append(line[2:].strip())
            if len(issues) >= 10:
                break
        return issues
    return []


def get_blockers() -> List[str]:
    """Get current blockers from .claude/BLOCKED.md."""
    content = read_claude_file("BLOCKED.md")
    if content:
        blockers = []
        lines = content.split("\n")
        in_active = False
        for line in lines:
            if "Active Blockers" in line or "Current Blockers" in line:
                in_active = True
                continue
            if in_active and line.startswith("## "):
                break
            if in_active and (line.startswith("- ") or line.startswith("* ")):
                blockers.append(line[2:].strip())
        return blockers
    return []


def run_diagnostics_summary() -> Dict[str, int]:
    """Run diagnostics and get summary counts."""
    try:
        result = subprocess.run(
            ["python3", "scripts/diagnose.py"],
            capture_output=True,
            text=True,
            cwd=PROJECT_ROOT,
            timeout=60
        )
        output = result.stdout + result.stderr

        # Parse summary
        errors = 0
        warnings = 0
        for line in output.split("\n"):
            if "ERROR(S)" in line:
                try:
                    errors = int(line.split()[0])
                except (ValueError, IndexError):
                    pass
            if "WARNING(S)" in line:
                try:
                    warnings = int(line.split()[0])
                except (ValueError, IndexError):
                    pass

        return {"errors": errors, "warnings": warnings}
    except Exception:
        return {"errors": -1, "warnings": -1}


def get_project_stats() -> Dict[str, Any]:
    """Get project statistics."""
    stats = {}

    # Count GDScript files
    gd_files = list(PROJECT_ROOT.glob("**/*.gd"))
    stats["gdscript_files"] = len(gd_files)

    # Count scenes
    tscn_files = list(PROJECT_ROOT.glob("**/*.tscn"))
    stats["scene_files"] = len(tscn_files)

    # Count JSON data files
    json_files = list((PROJECT_ROOT / "data").glob("*.json"))
    stats["data_files"] = len(json_files)

    # Count documentation files
    md_files = list(PROJECT_ROOT.glob("**/*.md"))
    stats["doc_files"] = len(md_files)

    # Count SVG assets
    svg_files = list((PROJECT_ROOT / "assets" / "art" / "src-svg").glob("**/*.svg"))
    stats["svg_assets"] = len(svg_files)

    # Count PNG assets
    png_files = list((PROJECT_ROOT / "assets" / "sprites").glob("**/*.png"))
    stats["png_assets"] = len(png_files)

    return stats


def format_brief_output(context: Dict[str, Any]) -> str:
    """Format brief text output."""
    lines = []
    lines.append("=" * 60)
    lines.append("SESSION CONTEXT - KEYBOARD DEFENSE")
    lines.append("=" * 60)
    lines.append(f"Generated: {context['timestamp']}")
    lines.append("")

    # Git status
    git = context.get("git", {})
    lines.append(f"Branch: {git.get('branch', 'unknown')}")
    lines.append(f"Last commit: {git.get('last_commit', 'unknown')}")
    uncommitted = git.get("uncommitted", {})
    if uncommitted.get("modified", 0) > 0 or uncommitted.get("untracked", 0) > 0:
        lines.append(f"Uncommitted: {uncommitted.get('modified', 0)} modified, {uncommitted.get('untracked', 0)} untracked")
    lines.append("")

    # Current task
    task = context.get("current_task")
    if task:
        lines.append("CURRENT TASK:")
        lines.append(f"  {task[:100]}..." if len(task) > 100 else f"  {task}")
        lines.append("")

    # Blockers
    blockers = context.get("blockers", [])
    if blockers:
        lines.append("BLOCKERS:")
        for b in blockers[:3]:
            lines.append(f"  - {b}")
        lines.append("")

    # Diagnostics
    diag = context.get("diagnostics", {})
    if diag.get("errors", 0) > 0 or diag.get("warnings", 0) > 0:
        lines.append(f"Diagnostics: {diag.get('errors', 0)} errors, {diag.get('warnings', 0)} warnings")
        lines.append("")

    return "\n".join(lines)


def format_full_output(context: Dict[str, Any]) -> str:
    """Format full text output."""
    lines = []
    lines.append("=" * 60)
    lines.append("SESSION CONTEXT - KEYBOARD DEFENSE")
    lines.append("=" * 60)
    lines.append(f"Generated: {context['timestamp']}")
    lines.append("")

    # Git info
    lines.append("-" * 40)
    lines.append("GIT STATUS")
    lines.append("-" * 40)
    git = context.get("git", {})
    lines.append(f"Branch: {git.get('branch', 'unknown')}")
    lines.append(f"Last commit: {git.get('last_commit', 'unknown')}")
    uncommitted = git.get("uncommitted", {})
    lines.append(f"Uncommitted: {uncommitted.get('modified', 0)} modified, {uncommitted.get('untracked', 0)} untracked")
    lines.append("")
    lines.append("Recent commits:")
    for commit in git.get("recent_commits", [])[:5]:
        lines.append(f"  {commit}")
    lines.append("")

    # Current task
    lines.append("-" * 40)
    lines.append("CURRENT TASK")
    lines.append("-" * 40)
    task = context.get("current_task")
    if task:
        lines.append(task)
    else:
        lines.append("No current task set.")
    lines.append("")

    # Blockers
    lines.append("-" * 40)
    lines.append("BLOCKERS")
    lines.append("-" * 40)
    blockers = context.get("blockers", [])
    if blockers:
        for b in blockers:
            lines.append(f"  - {b}")
    else:
        lines.append("No blockers.")
    lines.append("")

    # Known issues
    lines.append("-" * 40)
    lines.append("KNOWN ISSUES")
    lines.append("-" * 40)
    issues = context.get("known_issues", [])
    if issues:
        for issue in issues[:10]:
            lines.append(f"  - {issue}")
    else:
        lines.append("No known issues documented.")
    lines.append("")

    # Recent changes
    lines.append("-" * 40)
    lines.append("RECENT CHANGES")
    lines.append("-" * 40)
    changes = context.get("recent_changes", [])
    if changes:
        for change in changes:
            lines.append(f"  - {change}")
    else:
        lines.append("No recent changes documented.")
    lines.append("")

    # Diagnostics
    lines.append("-" * 40)
    lines.append("DIAGNOSTICS")
    lines.append("-" * 40)
    diag = context.get("diagnostics", {})
    if diag.get("errors", -1) >= 0:
        lines.append(f"Errors: {diag.get('errors', 0)}")
        lines.append(f"Warnings: {diag.get('warnings', 0)}")
    else:
        lines.append("Diagnostics not run.")
    lines.append("")

    # Project stats
    lines.append("-" * 40)
    lines.append("PROJECT STATS")
    lines.append("-" * 40)
    stats = context.get("stats", {})
    lines.append(f"GDScript files: {stats.get('gdscript_files', 0)}")
    lines.append(f"Scene files: {stats.get('scene_files', 0)}")
    lines.append(f"Data files: {stats.get('data_files', 0)}")
    lines.append(f"Documentation: {stats.get('doc_files', 0)}")
    lines.append(f"SVG assets: {stats.get('svg_assets', 0)}")
    lines.append(f"PNG assets: {stats.get('png_assets', 0)}")
    lines.append("")

    lines.append("=" * 60)

    return "\n".join(lines)


def main():
    import argparse

    parser = argparse.ArgumentParser(description="Load session context for Claude Code")
    parser.add_argument("--brief", action="store_true", help="Show brief summary only")
    parser.add_argument("--json", action="store_true", help="Output as JSON")
    parser.add_argument("--no-diagnostics", action="store_true", help="Skip running diagnostics")
    args = parser.parse_args()

    # Build context
    context = {
        "timestamp": datetime.now().isoformat(),
        "project": "keyboard-defense-godot",
    }

    # Git info
    context["git"] = get_git_info()

    # Claude context files
    context["current_task"] = get_current_task()
    context["recent_changes"] = get_recent_changes()
    context["known_issues"] = get_known_issues()
    context["blockers"] = get_blockers()

    # Diagnostics (optional)
    if not args.no_diagnostics:
        context["diagnostics"] = run_diagnostics_summary()

    # Project stats
    context["stats"] = get_project_stats()

    # Output
    if args.json:
        print(json.dumps(context, indent=2))
    elif args.brief:
        print(format_brief_output(context))
    else:
        print(format_full_output(context))


if __name__ == "__main__":
    main()
