#!/usr/bin/env python3
"""
Dictionary Access Fixer

Automatically converts unsafe dictionary access to safe patterns:
- dict["key"] -> dict.get("key", null)
- dict["key"] -> dict.get("key", default) with smart defaults

Usage:
    python scripts/fix_dictionary_access.py              # Dry run (show changes)
    python scripts/fix_dictionary_access.py --apply      # Apply changes
    python scripts/fix_dictionary_access.py --default "" # Custom default value
    python scripts/fix_dictionary_access.py --file game/main.gd  # Single file
"""

import argparse
import re
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import List, Optional, Tuple, Dict

# Project paths
SCRIPT_DIR = Path(__file__).parent
PROJECT_ROOT = SCRIPT_DIR.parent

# Smart defaults based on common key names
SMART_DEFAULTS: Dict[str, str] = {
    # String keys
    "name": '""',
    "id": '""',
    "type": '""',
    "description": '""',
    "text": '""',
    "label": '""',
    "path": '""',
    "category": '""',
    "message": '""',
    "title": '""',

    # Numeric keys
    "count": "0",
    "amount": "0",
    "value": "0",
    "index": "0",
    "level": "0",
    "tier": "0",
    "cost": "0",
    "damage": "0",
    "health": "0",
    "hp": "0",
    "speed": "0",
    "size": "0",
    "width": "0",
    "height": "0",
    "x": "0",
    "y": "0",
    "z": "0",
    "duration": "0.0",
    "time": "0.0",
    "delay": "0.0",

    # Boolean keys
    "enabled": "false",
    "active": "false",
    "visible": "false",
    "locked": "false",
    "completed": "false",

    # Collection keys
    "items": "[]",
    "children": "[]",
    "entries": "[]",
    "list": "[]",
    "options": "[]",

    # Dictionary keys
    "data": "{}",
    "config": "{}",
    "settings": "{}",
    "properties": "{}",
}


@dataclass
class Fix:
    """A fix to apply."""
    file: str
    line: int
    original: str
    fixed: str
    key: str


def get_smart_default(key: str) -> str:
    """Get a smart default value based on key name."""
    key_lower = key.lower()

    # Check exact match
    if key_lower in SMART_DEFAULTS:
        return SMART_DEFAULTS[key_lower]

    # Check suffix patterns
    for pattern, default in SMART_DEFAULTS.items():
        if key_lower.endswith(f"_{pattern}") or key_lower.endswith(pattern):
            return default

    # Check prefix patterns
    if key_lower.startswith("is_") or key_lower.startswith("has_") or key_lower.startswith("can_"):
        return "false"

    if key_lower.startswith("num_") or key_lower.startswith("count_"):
        return "0"

    # Default to null
    return "null"


def find_dict_fixes(file_path: Path, rel_path: str, default_value: Optional[str]) -> List[Fix]:
    """Find dictionary accesses to fix in a file."""
    fixes = []

    try:
        content = file_path.read_text(encoding='utf-8')
        lines = content.split('\n')
    except Exception:
        return fixes

    for i, line in enumerate(lines):
        stripped = line.strip()

        # Skip comments
        if stripped.startswith('#'):
            continue

        # Skip lines that already use .get()
        if '.get(' in line:
            continue

        # Skip lines with .has() check on same line
        if '.has(' in line:
            continue

        # Find bracket access: variable["key"]
        # But avoid array access patterns
        pattern = r'(\w+)\[(["\'])([^"\']+)\2\]'

        for match in re.finditer(pattern, line):
            var_name = match.group(1)
            key = match.group(3)
            full_match = match.group(0)

            # Skip array-like variable names
            skip_vars = ['data', 'entries', 'items', 'list', 'array', 'lines',
                         'tokens', 'args', 'params', 'results', 'values', 'keys',
                         'OS', 'Engine', 'Input', 'ProjectSettings', 'ClassDB']
            if var_name in skip_vars:
                continue

            # Skip if it's an assignment target (left side of =)
            # This is tricky - check if this match is before an = but not ==
            line_before = line[:match.start()]
            line_after = line[match.end():]

            # If the next non-space char is = (but not ==), it's an assignment
            after_stripped = line_after.lstrip()
            if after_stripped.startswith('=') and not after_stripped.startswith('=='):
                continue

            # Determine default value
            if default_value is not None:
                default = default_value
            else:
                default = get_smart_default(key)

            # Create the fix
            new_access = f'{var_name}.get("{key}", {default})'

            # Replace in the line
            new_line = line[:match.start()] + new_access + line[match.end():]

            fixes.append(Fix(
                file=rel_path,
                line=i + 1,
                original=line,
                fixed=new_line,
                key=key
            ))

            # Only fix first occurrence per line to avoid cascading issues
            break

    return fixes


def apply_fixes(fixes: List[Fix]) -> int:
    """Apply fixes to files."""
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

        # Apply fixes (they don't overlap since we only fix first per line)
        for fix in file_fixes:
            line_idx = fix.line - 1
            lines[line_idx] = fix.fixed

        # Write back
        try:
            file_path.write_text('\n'.join(lines), encoding='utf-8')
            files_modified += 1
            print(f"  Fixed {rel_path}: {len(file_fixes)} access(es)")
        except Exception as e:
            print(f"  Error writing {rel_path}: {e}")

    return files_modified


def main():
    parser = argparse.ArgumentParser(description="Fix dictionary access")
    parser.add_argument("--apply", "-a", action="store_true", help="Apply fixes (default is dry run)")
    parser.add_argument("--default", "-d", type=str, help="Default value to use (overrides smart defaults)")
    parser.add_argument("--file", "-f", type=str, help="Single file to fix")
    args = parser.parse_args()

    print("=" * 60)
    print("DICTIONARY ACCESS FIXER - KEYBOARD DEFENSE")
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
        fixes = find_dict_fixes(gd_file, rel_path, args.default)
        all_fixes.extend(fixes)

    if not all_fixes:
        print("No unsafe dictionary accesses found to fix.")
        return

    # Show what would be changed
    print(f"Found {len(all_fixes)} dictionary access(es) to fix:")
    print("")

    for fix in all_fixes[:25]:
        print(f"  {fix.file}:{fix.line}")
        print(f"    - {fix.original.strip()[:70]}")
        print(f"    + {fix.fixed.strip()[:70]}")
        print("")

    if len(all_fixes) > 25:
        print(f"  ... and {len(all_fixes) - 25} more")
        print("")

    # Show default value info
    print("Default values used:")
    print("  - Smart defaults based on key name (name=\"\", count=0, enabled=false, etc.)")
    print("  - Use --default VALUE to override all defaults")
    print("")

    if args.apply:
        print("Applying fixes...")
        files_modified = apply_fixes(all_fixes)
        print(f"\nDone! Modified {files_modified} file(s), fixed {len(all_fixes)} access(es).")
    else:
        print("Dry run complete. Use --apply to apply fixes.")
        print(f"This would convert {len(all_fixes)} bracket access(es) to .get() calls.")


if __name__ == "__main__":
    main()
