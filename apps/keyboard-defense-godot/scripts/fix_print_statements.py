#!/usr/bin/env python3
"""
Print Statement Fixer

Automatically fixes debug print statements:
- Comments out print() calls
- Optionally removes them entirely
- Wraps in OS.is_debug_build() check
- Skips test files

Usage:
    python scripts/fix_print_statements.py              # Dry run (show changes)
    python scripts/fix_print_statements.py --apply      # Apply changes
    python scripts/fix_print_statements.py --remove     # Remove instead of comment
    python scripts/fix_print_statements.py --wrap       # Wrap in debug check
    python scripts/fix_print_statements.py --file game/main.gd  # Single file
"""

import argparse
import re
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import List, Optional, Tuple

# Project paths
SCRIPT_DIR = Path(__file__).parent
PROJECT_ROOT = SCRIPT_DIR.parent


@dataclass
class Fix:
    """A fix to apply."""
    file: str
    line: int
    original: str
    fixed: str
    fix_type: str


def find_print_fixes(file_path: Path, rel_path: str, remove: bool, wrap: bool) -> List[Fix]:
    """Find print statements to fix in a file."""
    fixes = []

    # Skip test files
    if 'test' in rel_path.lower() or rel_path.startswith('tests/'):
        return fixes

    # Skip tool files that legitimately use print
    if rel_path.startswith('tools/') or rel_path.startswith('scripts/'):
        return fixes

    try:
        content = file_path.read_text(encoding='utf-8')
        lines = content.split('\n')
    except Exception:
        return fixes

    for i, line in enumerate(lines):
        stripped = line.strip()

        # Skip already commented lines
        if stripped.startswith('#'):
            continue

        # Skip lines that are already wrapped in debug check
        if 'is_debug_build' in line:
            continue

        # Find print calls
        print_patterns = [
            (r'^(\s*)(print\s*\(.+\))$', 'print'),
            (r'^(\s*)(prints\s*\(.+\))$', 'prints'),
            (r'^(\s*)(printt\s*\(.+\))$', 'printt'),
            (r'^(\s*)(print_debug\s*\(.+\))$', 'print_debug'),
            (r'^(\s*)(print_rich\s*\(.+\))$', 'print_rich'),
        ]

        for pattern, print_type in print_patterns:
            match = re.match(pattern, line)
            if match:
                indent = match.group(1)
                print_call = match.group(2)

                if remove:
                    # Remove the line entirely
                    fixed = None  # Mark for removal
                    fix_type = "remove"
                elif wrap:
                    # Wrap in debug check
                    fixed = f"{indent}if OS.is_debug_build(): {print_call}"
                    fix_type = "wrap"
                else:
                    # Comment out
                    fixed = f"{indent}# {print_call}  # DEBUG: commented out"
                    fix_type = "comment"

                fixes.append(Fix(
                    file=rel_path,
                    line=i + 1,
                    original=line,
                    fixed=fixed,
                    fix_type=fix_type
                ))
                break

    return fixes


def apply_fixes(fixes: List[Fix]) -> int:
    """Apply fixes to files."""
    # Group fixes by file
    by_file = {}
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

        # Sort fixes by line number in reverse order (so indices stay valid)
        file_fixes.sort(key=lambda f: f.line, reverse=True)

        for fix in file_fixes:
            line_idx = fix.line - 1
            if fix.fixed is None:
                # Remove the line
                del lines[line_idx]
            else:
                lines[line_idx] = fix.fixed

        # Write back
        try:
            file_path.write_text('\n'.join(lines), encoding='utf-8')
            files_modified += 1
            print(f"  Fixed {rel_path}: {len(file_fixes)} print(s)")
        except Exception as e:
            print(f"  Error writing {rel_path}: {e}")

    return files_modified


def main():
    parser = argparse.ArgumentParser(description="Fix print statements")
    parser.add_argument("--apply", "-a", action="store_true", help="Apply fixes (default is dry run)")
    parser.add_argument("--remove", "-r", action="store_true", help="Remove prints instead of commenting")
    parser.add_argument("--wrap", "-w", action="store_true", help="Wrap in OS.is_debug_build() check")
    parser.add_argument("--file", "-f", type=str, help="Single file to fix")
    args = parser.parse_args()

    print("=" * 60)
    print("PRINT STATEMENT FIXER - KEYBOARD DEFENSE")
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
        fixes = find_print_fixes(gd_file, rel_path, args.remove, args.wrap)
        all_fixes.extend(fixes)

    if not all_fixes:
        print("No print statements found to fix.")
        return

    # Show what would be changed
    print(f"Found {len(all_fixes)} print statement(s) to fix:")
    print("")

    for fix in all_fixes[:30]:
        print(f"  {fix.file}:{fix.line}")
        print(f"    - {fix.original.strip()}")
        if fix.fixed:
            print(f"    + {fix.fixed.strip()}")
        else:
            print(f"    + (removed)")
        print("")

    if len(all_fixes) > 30:
        print(f"  ... and {len(all_fixes) - 30} more")
        print("")

    if args.apply:
        print("Applying fixes...")
        files_modified = apply_fixes(all_fixes)
        print(f"\nDone! Modified {files_modified} file(s), fixed {len(all_fixes)} print(s).")
    else:
        print("Dry run complete. Use --apply to apply fixes.")
        fix_type = "remove" if args.remove else ("wrap" if args.wrap else "comment out")
        print(f"This would {fix_type} {len(all_fixes)} print statement(s).")


if __name__ == "__main__":
    main()
