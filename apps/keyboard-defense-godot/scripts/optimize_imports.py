#!/usr/bin/env python3
"""
Import Optimizer

Finds and reports unused imports (preload/load) in GDScript files:
- Preloaded scripts that are never used
- Loaded resources that are never referenced
- Const assignments from preload that are unused

Usage:
    python scripts/optimize_imports.py              # Full report
    python scripts/optimize_imports.py --file game/main.gd  # Single file
    python scripts/optimize_imports.py --fix        # Remove unused imports (dry run)
    python scripts/optimize_imports.py --fix --apply  # Actually remove
    python scripts/optimize_imports.py --json       # JSON output
"""

import json
import re
import sys
from dataclasses import dataclass, field
from pathlib import Path
from typing import Dict, List, Set, Tuple, Optional

# Project paths
SCRIPT_DIR = Path(__file__).parent
PROJECT_ROOT = SCRIPT_DIR.parent

# Patterns
PRELOAD_CONST_PATTERN = re.compile(
    r'^(const\s+(\w+)\s*=\s*preload\s*\(\s*["\']([^"\']+)["\']\s*\))',
    re.MULTILINE
)
PRELOAD_VAR_PATTERN = re.compile(
    r'^(var\s+(\w+)\s*=\s*preload\s*\(\s*["\']([^"\']+)["\']\s*\))',
    re.MULTILINE
)
ONREADY_PRELOAD_PATTERN = re.compile(
    r'^(@onready\s+var\s+(\w+)\s*=\s*preload\s*\(\s*["\']([^"\']+)["\']\s*\))',
    re.MULTILINE
)
INLINE_PRELOAD_PATTERN = re.compile(
    r'preload\s*\(\s*["\']([^"\']+)["\']\s*\)'
)
LOAD_PATTERN = re.compile(
    r'load\s*\(\s*["\']([^"\']+)["\']\s*\)'
)


@dataclass
class ImportInfo:
    """Information about an import."""
    name: str  # Variable/const name (or path for inline)
    path: str  # Resource path
    line: int
    full_match: str  # Full line for removal
    import_type: str  # "const", "var", "onready", "inline"
    is_used: bool = False
    usages: List[int] = field(default_factory=list)  # Line numbers where used


@dataclass
class FileImportReport:
    """Import analysis for a file."""
    path: str
    imports: List[ImportInfo] = field(default_factory=list)
    unused_count: int = 0
    total_count: int = 0

    @property
    def has_unused(self) -> bool:
        return self.unused_count > 0


def find_imports(content: str, lines: List[str]) -> List[ImportInfo]:
    """Find all imports in file content."""
    imports = []

    # Find const preloads
    for match in PRELOAD_CONST_PATTERN.finditer(content):
        full_match = match.group(1)
        name = match.group(2)
        path = match.group(3)
        line_num = content[:match.start()].count('\n') + 1
        imports.append(ImportInfo(
            name=name, path=path, line=line_num,
            full_match=full_match, import_type="const"
        ))

    # Find var preloads
    for match in PRELOAD_VAR_PATTERN.finditer(content):
        full_match = match.group(1)
        name = match.group(2)
        path = match.group(3)
        line_num = content[:match.start()].count('\n') + 1
        imports.append(ImportInfo(
            name=name, path=path, line=line_num,
            full_match=full_match, import_type="var"
        ))

    # Find @onready preloads
    for match in ONREADY_PRELOAD_PATTERN.finditer(content):
        full_match = match.group(1)
        name = match.group(2)
        path = match.group(3)
        line_num = content[:match.start()].count('\n') + 1
        imports.append(ImportInfo(
            name=name, path=path, line=line_num,
            full_match=full_match, import_type="onready"
        ))

    return imports


def check_usage(imp: ImportInfo, content: str, lines: List[str]) -> None:
    """Check if an import is used in the file."""
    # For named imports, search for the name being used
    if imp.import_type in ["const", "var", "onready"]:
        # Look for usage of the name (not the definition line)
        name_pattern = re.compile(r'\b' + re.escape(imp.name) + r'\b')

        for i, line in enumerate(lines):
            line_num = i + 1
            if line_num == imp.line:
                continue  # Skip definition line

            if name_pattern.search(line):
                imp.usages.append(line_num)

        imp.is_used = len(imp.usages) > 0


def analyze_file(filepath: Path) -> FileImportReport:
    """Analyze imports in a single file."""
    rel_path = str(filepath.relative_to(PROJECT_ROOT))
    report = FileImportReport(path=rel_path)

    try:
        content = filepath.read_text(encoding="utf-8")
        lines = content.split('\n')
    except Exception:
        return report

    # Find all imports
    report.imports = find_imports(content, lines)
    report.total_count = len(report.imports)

    # Check usage for each import
    for imp in report.imports:
        check_usage(imp, content, lines)

    report.unused_count = sum(1 for imp in report.imports if not imp.is_used)

    return report


def analyze_codebase(target_file: Optional[str] = None) -> List[FileImportReport]:
    """Analyze all GDScript files for unused imports."""
    results = []

    if target_file:
        filepath = PROJECT_ROOT / target_file
        if filepath.exists():
            results.append(analyze_file(filepath))
        return results

    for gd_file in PROJECT_ROOT.glob("**/*.gd"):
        if ".godot" in str(gd_file) or "addons" in str(gd_file):
            continue

        report = analyze_file(gd_file)
        if report.imports:  # Only include files with imports
            results.append(report)

    return results


def generate_fix(report: FileImportReport) -> List[Tuple[int, str]]:
    """Generate fixes for unused imports (lines to remove)."""
    fixes = []
    for imp in report.imports:
        if not imp.is_used:
            fixes.append((imp.line, imp.full_match))
    return fixes


def apply_fixes(filepath: Path, fixes: List[Tuple[int, str]], dry_run: bool = True) -> str:
    """Apply fixes to remove unused imports."""
    try:
        content = filepath.read_text(encoding="utf-8")
        lines = content.split('\n')
    except Exception:
        return ""

    # Sort fixes by line number (descending) to avoid index shifts
    fixes_sorted = sorted(fixes, key=lambda x: x[0], reverse=True)

    removed = []
    for line_num, _ in fixes_sorted:
        if 0 < line_num <= len(lines):
            removed.append(f"  Line {line_num}: {lines[line_num - 1].strip()}")
            if not dry_run:
                lines[line_num - 1] = ""  # Remove line

    if not dry_run:
        # Remove empty lines that were imports
        new_lines = [l for l in lines if l.strip() or l == ""]
        # Clean up multiple consecutive blank lines
        cleaned = []
        prev_blank = False
        for line in new_lines:
            is_blank = not line.strip()
            if is_blank and prev_blank:
                continue
            cleaned.append(line)
            prev_blank = is_blank

        filepath.write_text('\n'.join(cleaned), encoding="utf-8")

    return '\n'.join(removed)


def format_report(results: List[FileImportReport]) -> str:
    """Format the import analysis report."""
    lines = []
    lines.append("=" * 60)
    lines.append("IMPORT OPTIMIZER - KEYBOARD DEFENSE")
    lines.append("=" * 60)
    lines.append("")

    # Summary
    total_imports = sum(r.total_count for r in results)
    total_unused = sum(r.unused_count for r in results)
    files_with_unused = sum(1 for r in results if r.has_unused)

    lines.append("## SUMMARY")
    lines.append(f"  Files with imports: {len(results)}")
    lines.append(f"  Total imports: {total_imports}")
    lines.append(f"  Unused imports: {total_unused}")
    lines.append(f"  Files with unused: {files_with_unused}")
    lines.append("")

    if total_unused == 0:
        lines.append("No unused imports found!")
        return "\n".join(lines)

    # Files with unused imports
    lines.append("## UNUSED IMPORTS BY FILE")
    for report in sorted(results, key=lambda r: r.unused_count, reverse=True):
        if not report.has_unused:
            continue

        lines.append(f"\n### {report.path}")
        for imp in report.imports:
            if not imp.is_used:
                lines.append(f"  Line {imp.line}: {imp.import_type} {imp.name}")
                lines.append(f"    → {imp.path}")

    lines.append("")

    # Health indicators
    lines.append("## HEALTH INDICATORS")
    unused_pct = total_unused * 100 // max(total_imports, 1)
    if unused_pct > 20:
        lines.append(f"  [WARN] High unused import ratio: {unused_pct}%")
    elif unused_pct > 10:
        lines.append(f"  [INFO] Unused import ratio: {unused_pct}%")
    else:
        lines.append(f"  [OK] Unused import ratio: {unused_pct}%")

    lines.append("")
    lines.append("Run with --fix to see removal suggestions")
    lines.append("Run with --fix --apply to remove unused imports")

    return "\n".join(lines)


def format_json(results: List[FileImportReport]) -> str:
    """Format as JSON."""
    data = {
        "summary": {
            "files_analyzed": len(results),
            "total_imports": sum(r.total_count for r in results),
            "unused_imports": sum(r.unused_count for r in results),
            "files_with_unused": sum(1 for r in results if r.has_unused),
        },
        "files": [],
    }

    for report in results:
        if report.imports:
            file_data = {
                "path": report.path,
                "total_imports": report.total_count,
                "unused_imports": report.unused_count,
                "imports": [
                    {
                        "name": imp.name,
                        "path": imp.path,
                        "line": imp.line,
                        "type": imp.import_type,
                        "is_used": imp.is_used,
                        "usage_count": len(imp.usages),
                    }
                    for imp in report.imports
                ],
            }
            data["files"].append(file_data)

    return json.dumps(data, indent=2)


def main():
    import argparse

    parser = argparse.ArgumentParser(description="Find and fix unused imports")
    parser.add_argument("--json", "-j", action="store_true", help="JSON output")
    parser.add_argument("--file", "-f", type=str, help="Analyze single file")
    parser.add_argument("--fix", action="store_true", help="Show fixes to apply")
    parser.add_argument("--apply", action="store_true", help="Actually apply fixes")
    args = parser.parse_args()

    results = analyze_codebase(args.file)

    if args.json:
        print(format_json(results))
    elif args.fix:
        print("=" * 60)
        print("IMPORT OPTIMIZER - FIX MODE")
        print("=" * 60)
        print("")

        if args.apply:
            print("!!! APPLYING FIXES - MODIFYING FILES !!!")
        else:
            print("DRY RUN - No files will be modified")
        print("")

        total_removed = 0
        for report in results:
            if report.has_unused:
                fixes = generate_fix(report)
                if fixes:
                    filepath = PROJECT_ROOT / report.path
                    print(f"### {report.path}")
                    removed = apply_fixes(filepath, fixes, dry_run=not args.apply)
                    print(removed)
                    total_removed += len(fixes)
                    print("")

        print(f"Total imports {'removed' if args.apply else 'to remove'}: {total_removed}")
    else:
        print(format_report(results))


if __name__ == "__main__":
    main()
