#!/usr/bin/env python3
"""
Unused Code Fixer

Automatically removes unused code:
- Unused constants
- Unused imports/preloads
- Commented-out code blocks

Usage:
    python scripts/fix_unused_code.py              # Dry run (show changes)
    python scripts/fix_unused_code.py --apply      # Apply changes
    python scripts/fix_unused_code.py --constants  # Only fix unused constants
    python scripts/fix_unused_code.py --imports    # Only fix unused imports
    python scripts/fix_unused_code.py --file game/main.gd  # Single file
"""

import argparse
import re
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import List, Optional, Set, Dict, Tuple

# Project paths
SCRIPT_DIR = Path(__file__).parent
PROJECT_ROOT = SCRIPT_DIR.parent


@dataclass
class Fix:
    """A fix to apply."""
    file: str
    line: int
    original: str
    fix_type: str  # "unused_constant", "unused_import"
    name: str


def find_unused_constants(file_path: Path, rel_path: str) -> List[Fix]:
    """Find unused constants in a file."""
    fixes = []

    try:
        content = file_path.read_text(encoding='utf-8')
        lines = content.split('\n')
    except Exception:
        return fixes

    # Find all constant declarations
    constants: Dict[str, int] = {}  # name -> line number

    for i, line in enumerate(lines):
        stripped = line.strip()

        # Skip comments
        if stripped.startswith('#'):
            continue

        # Find const declarations at class level (no indent)
        if line.startswith('const ') or (line.startswith('\t') and line.strip().startswith('const ')):
            const_match = re.match(r'^(?:\t)?const\s+(\w+)\s*', line)
            if const_match:
                name = const_match.group(1)
                constants[name] = i

    # Check usage of each constant
    for name, line_num in constants.items():
        # Count occurrences
        pattern = rf'\b{re.escape(name)}\b'
        matches = list(re.finditer(pattern, content))

        # If only appears once (the declaration), it's unused
        if len(matches) <= 1:
            fixes.append(Fix(
                file=rel_path,
                line=line_num + 1,
                original=lines[line_num],
                fix_type="unused_constant",
                name=name
            ))

    return fixes


def find_unused_imports(file_path: Path, rel_path: str) -> List[Fix]:
    """Find unused imports/preloads in a file."""
    fixes = []

    try:
        content = file_path.read_text(encoding='utf-8')
        lines = content.split('\n')
    except Exception:
        return fixes

    # Find all preload declarations
    imports: Dict[str, int] = {}  # name -> line number

    for i, line in enumerate(lines):
        stripped = line.strip()

        # Skip comments
        if stripped.startswith('#'):
            continue

        # Find const preload at class level
        preload_match = re.match(r'^const\s+(\w+)\s*=\s*preload\s*\(', stripped)
        if preload_match:
            name = preload_match.group(1)
            imports[name] = i
            continue

        # Find var preload
        var_preload_match = re.match(r'^var\s+(\w+)\s*=\s*preload\s*\(', stripped)
        if var_preload_match:
            name = var_preload_match.group(1)
            imports[name] = i
            continue

        # Find @onready preload
        onready_match = re.match(r'^@onready\s+var\s+(\w+)\s*=\s*preload\s*\(', stripped)
        if onready_match:
            name = onready_match.group(1)
            imports[name] = i

    # Check usage of each import
    for name, line_num in imports.items():
        # Count occurrences
        pattern = rf'\b{re.escape(name)}\b'
        matches = list(re.finditer(pattern, content))

        # If only appears once (the declaration), it's unused
        if len(matches) <= 1:
            fixes.append(Fix(
                file=rel_path,
                line=line_num + 1,
                original=lines[line_num],
                fix_type="unused_import",
                name=name
            ))

    return fixes


def apply_fixes(fixes: List[Fix]) -> int:
    """Apply fixes by removing lines."""
    # Group fixes by file
    by_file: Dict[str, List[Fix]] = {}
    for fix in fixes:
        if fix.file not in by_file:
            by_file[fix.file] = []
        by_file[fix.file].append(fix)

    files_modified = 0

    for rel_path, file_fixes in by_file.items():
        file_path = PROJECT_ROOT / rel_path

        try:
            content = file_path.read_text(encoding='utf-8')
            lines = content.split('\n')
        except Exception as e:
            print(f"  Error reading {rel_path}: {e}")
            continue

        # Sort by line number in reverse (so indices stay valid)
        file_fixes.sort(key=lambda f: f.line, reverse=True)

        for fix in file_fixes:
            line_idx = fix.line - 1
            # Remove the line
            del lines[line_idx]

        # Write back
        try:
            file_path.write_text('\n'.join(lines), encoding='utf-8')
            files_modified += 1
            const_count = sum(1 for f in file_fixes if f.fix_type == "unused_constant")
            import_count = sum(1 for f in file_fixes if f.fix_type == "unused_import")
            print(f"  Fixed {rel_path}: {const_count} constant(s), {import_count} import(s)")
        except Exception as e:
            print(f"  Error writing {rel_path}: {e}")

    return files_modified


def main():
    parser = argparse.ArgumentParser(description="Fix unused code")
    parser.add_argument("--apply", "-a", action="store_true", help="Apply fixes (default is dry run)")
    parser.add_argument("--constants", "-c", action="store_true", help="Only fix unused constants")
    parser.add_argument("--imports", "-i", action="store_true", help="Only fix unused imports")
    parser.add_argument("--file", "-f", type=str, help="Single file to fix")
    args = parser.parse_args()

    # Default to both if neither specified
    do_constants = args.constants or (not args.constants and not args.imports)
    do_imports = args.imports or (not args.constants and not args.imports)

    print("=" * 60)
    print("UNUSED CODE FIXER - KEYBOARD DEFENSE")
    print("=" * 60)
    print("")

    if args.file:
        gd_files = [PROJECT_ROOT / args.file]
    else:
        gd_files = list(PROJECT_ROOT.glob("**/*.gd"))

    all_fixes = []

    for gd_file in gd_files:
        if ".godot" in str(gd_file) or "addons" in str(gd_file):
            continue

        if not gd_file.exists():
            continue

        rel_path = str(gd_file.relative_to(PROJECT_ROOT))

        if do_constants:
            fixes = find_unused_constants(gd_file, rel_path)
            all_fixes.extend(fixes)

        if do_imports:
            fixes = find_unused_imports(gd_file, rel_path)
            all_fixes.extend(fixes)

    if not all_fixes:
        print("No unused code found to remove.")
        return

    # Categorize fixes
    const_fixes = [f for f in all_fixes if f.fix_type == "unused_constant"]
    import_fixes = [f for f in all_fixes if f.fix_type == "unused_import"]

    print(f"Found {len(all_fixes)} item(s) to remove:")
    print(f"  - {len(const_fixes)} unused constant(s)")
    print(f"  - {len(import_fixes)} unused import(s)")
    print("")

    # Show what would be changed
    print("Items to remove:")
    print("")

    for fix in all_fixes[:30]:
        print(f"  [{fix.fix_type}] {fix.file}:{fix.line}")
        print(f"    {fix.name}: {fix.original.strip()[:60]}")
        print("")

    if len(all_fixes) > 30:
        print(f"  ... and {len(all_fixes) - 30} more")
        print("")

    if args.apply:
        print("Applying fixes...")
        files_modified = apply_fixes(all_fixes)
        print(f"\nDone! Modified {files_modified} file(s), removed {len(all_fixes)} item(s).")
    else:
        print("Dry run complete. Use --apply to apply fixes.")
        print(f"This would remove {len(all_fixes)} unused item(s).")


if __name__ == "__main__":
    main()
