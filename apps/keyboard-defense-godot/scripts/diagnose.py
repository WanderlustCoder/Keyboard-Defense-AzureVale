#!/usr/bin/env python3
"""
Diagnostic Script for Keyboard Defense

Checks for common issues that can cause problems during development:
- Orphaned assets (in manifest but missing on disk)
- Missing manifest entries (on disk but not in manifest)
- Invalid lesson configurations
- Broken references between files
- Balance anomalies

Usage:
    python scripts/diagnose.py              # Run all diagnostics
    python scripts/diagnose.py assets       # Check assets only
    python scripts/diagnose.py lessons      # Check lessons only
    python scripts/diagnose.py references   # Check cross-references
    python scripts/diagnose.py balance      # Check balance values
    python scripts/diagnose.py --fix        # Auto-fix simple issues

Exit codes:
    0 - No issues found
    1 - Issues found (see output)
    2 - Script error
"""

import json
import sys
import os
from pathlib import Path
from typing import Dict, List, Tuple, Optional, Set
import re


def find_project_root() -> Path:
    """Find the Godot project root."""
    current = Path(__file__).resolve().parent
    while current != current.parent:
        if (current / "project.godot").exists():
            return current
        current = current.parent
    return Path(__file__).resolve().parent.parent


def load_json_safe(path: Path) -> Tuple[Optional[dict], Optional[str]]:
    """Load JSON file, returning (data, None) or (None, error)."""
    try:
        with open(path, "r", encoding="utf-8") as f:
            return json.load(f), None
    except Exception as e:
        return None, str(e)


class Diagnostics:
    def __init__(self, project_root: Path):
        self.root = project_root
        self.issues: List[str] = []
        self.warnings: List[str] = []
        self.fixes: List[str] = []

    def error(self, msg: str):
        self.issues.append(f"[ERROR] {msg}")

    def warn(self, msg: str):
        self.warnings.append(f"[WARN] {msg}")

    def fix(self, msg: str):
        self.fixes.append(f"[FIX] {msg}")

    # ─────────────────────────────────────────────────────────────
    # Asset Diagnostics
    # ─────────────────────────────────────────────────────────────

    def check_assets(self) -> int:
        """Check asset manifest against actual files."""
        print("\n=== ASSET DIAGNOSTICS ===\n")

        manifest_path = self.root / "data" / "assets_manifest.json"
        manifest, err = load_json_safe(manifest_path)
        if err:
            self.error(f"Cannot load assets_manifest.json: {err}")
            return 1

        issues_found = 0

        # Check textures
        print("Checking textures...")
        for texture in manifest.get("textures", []):
            tex_id = texture.get("id", "unknown")
            tex_path = texture.get("path", "")

            # Convert res:// path to filesystem path
            if tex_path.startswith("res://"):
                fs_path = self.root / tex_path[6:]
            else:
                fs_path = self.root / tex_path

            if not fs_path.exists():
                # Check if source SVG exists
                svg_path = texture.get("source_svg", "")
                if svg_path:
                    svg_fs = self.root / svg_path[6:] if svg_path.startswith("res://") else self.root / svg_path
                    if svg_fs.exists():
                        self.warn(f"Texture '{tex_id}' missing but SVG exists: {svg_path}")
                    else:
                        self.error(f"Texture '{tex_id}' missing: {tex_path} (no SVG either)")
                        issues_found += 1
                else:
                    self.error(f"Texture '{tex_id}' missing: {tex_path}")
                    issues_found += 1

        # Check audio
        print("Checking audio...")
        for audio in manifest.get("audio", []):
            audio_id = audio.get("id", "unknown")
            audio_path = audio.get("path", "")

            if audio_path.startswith("res://"):
                fs_path = self.root / audio_path[6:]
            else:
                fs_path = self.root / audio_path

            if not fs_path.exists():
                self.warn(f"Audio '{audio_id}' missing: {audio_path}")

        # Check for unmanifested assets
        print("Checking for unmanifested assets...")
        manifest_paths = set()
        for texture in manifest.get("textures", []):
            p = texture.get("path", "")
            if p.startswith("res://"):
                manifest_paths.add(p[6:])

        # Scan actual asset directories
        asset_dirs = [
            self.root / "assets" / "sprites",
            self.root / "assets" / "icons",
            self.root / "assets" / "ui",
            self.root / "assets" / "tiles",
        ]

        for asset_dir in asset_dirs:
            if not asset_dir.exists():
                continue
            for png_file in asset_dir.glob("*.png"):
                rel_path = str(png_file.relative_to(self.root)).replace("\\", "/")
                if rel_path not in manifest_paths:
                    self.warn(f"Unmanifested asset: {rel_path}")

        return issues_found

    # ─────────────────────────────────────────────────────────────
    # Lesson Diagnostics
    # ─────────────────────────────────────────────────────────────

    def check_lessons(self) -> int:
        """Check lesson configurations."""
        print("\n=== LESSON DIAGNOSTICS ===\n")

        lessons_path = self.root / "data" / "lessons.json"
        lessons_data, err = load_json_safe(lessons_path)
        if err:
            self.error(f"Cannot load lessons.json: {err}")
            return 1

        issues_found = 0
        lesson_ids: Set[str] = set()

        print("Checking lesson definitions...")
        for lesson in lessons_data.get("lessons", []):
            lid = lesson.get("id", "unknown")

            # Check for duplicate IDs
            if lid in lesson_ids:
                self.error(f"Duplicate lesson ID: {lid}")
                issues_found += 1
            lesson_ids.add(lid)

            mode = lesson.get("mode", "")

            # Mode-specific checks
            if mode == "charset":
                charset = lesson.get("charset", "")
                if not charset:
                    self.error(f"Lesson '{lid}': charset mode but no charset defined")
                    issues_found += 1
                elif len(charset) < 2:
                    self.warn(f"Lesson '{lid}': charset has only {len(charset)} character(s)")

            elif mode == "wordlist":
                wordlist = lesson.get("wordlist", [])
                if not wordlist:
                    self.error(f"Lesson '{lid}': wordlist mode but no words defined")
                    issues_found += 1
                elif len(wordlist) < 5:
                    self.warn(f"Lesson '{lid}': wordlist has only {len(wordlist)} word(s)")

                # Check for invalid characters in words
                for word in wordlist:
                    if not word.isprintable():
                        self.error(f"Lesson '{lid}': word contains non-printable characters: {repr(word)}")
                        issues_found += 1

            elif mode == "sentence":
                sentences = lesson.get("sentences", [])
                if not sentences:
                    self.error(f"Lesson '{lid}': sentence mode but no sentences defined")
                    issues_found += 1

            else:
                self.error(f"Lesson '{lid}': unknown mode '{mode}'")
                issues_found += 1

            # Check lengths (required for charset and wordlist)
            if mode in ["charset", "wordlist"]:
                lengths = lesson.get("lengths", {})
                for enemy_type in ["scout", "raider", "armored"]:
                    if enemy_type not in lengths:
                        self.error(f"Lesson '{lid}': missing length range for '{enemy_type}'")
                        issues_found += 1
                    else:
                        range_val = lengths[enemy_type]
                        if len(range_val) != 2:
                            self.error(f"Lesson '{lid}': length range for '{enemy_type}' should have 2 values")
                            issues_found += 1
                        elif range_val[0] > range_val[1]:
                            self.error(f"Lesson '{lid}': length range for '{enemy_type}' is inverted: {range_val}")
                            issues_found += 1

        # Check graduation paths reference valid lessons
        print("Checking graduation paths...")
        for path_id, path_data in lessons_data.get("graduation_paths", {}).items():
            for stage in path_data.get("stages", []):
                for ref_lesson in stage.get("lessons", []):
                    if ref_lesson not in lesson_ids:
                        self.error(f"Graduation path '{path_id}': references unknown lesson '{ref_lesson}'")
                        issues_found += 1

        # Check default lesson exists
        default_lesson = lessons_data.get("default_lesson", "")
        if default_lesson and default_lesson not in lesson_ids:
            self.error(f"Default lesson '{default_lesson}' does not exist")
            issues_found += 1

        return issues_found

    # ─────────────────────────────────────────────────────────────
    # Cross-Reference Diagnostics
    # ─────────────────────────────────────────────────────────────

    def check_references(self) -> int:
        """Check cross-references between data files."""
        print("\n=== REFERENCE DIAGNOSTICS ===\n")

        issues_found = 0

        # Load all data files
        data_files = {}
        data_dir = self.root / "data"
        for json_file in data_dir.glob("*.json"):
            data, err = load_json_safe(json_file)
            if err:
                self.warn(f"Cannot load {json_file.name}: {err}")
            else:
                data_files[json_file.stem] = data

        # Check map references lessons
        print("Checking map -> lesson references...")
        if "map" in data_files and "lessons" in data_files:
            lesson_ids = {l["id"] for l in data_files["lessons"].get("lessons", [])}
            for node in data_files["map"].get("nodes", []):
                lesson_ref = node.get("lesson_id", "")
                if lesson_ref and lesson_ref not in lesson_ids:
                    self.error(f"Map node '{node.get('id', '?')}' references unknown lesson: {lesson_ref}")
                    issues_found += 1

        # Check upgrade references
        print("Checking upgrade references...")
        for upgrade_file in ["kingdom_upgrades", "unit_upgrades"]:
            if upgrade_file in data_files:
                upgrade_ids = {u["id"] for u in data_files[upgrade_file].get("upgrades", [])}
                for upgrade in data_files[upgrade_file].get("upgrades", []):
                    for req in upgrade.get("requires", []):
                        if req not in upgrade_ids:
                            self.error(f"Upgrade '{upgrade['id']}' requires unknown upgrade: {req}")
                            issues_found += 1

        # Check drills reference valid lessons
        print("Checking drill -> lesson references...")
        if "drills" in data_files and "lessons" in data_files:
            lesson_ids = {l["id"] for l in data_files["lessons"].get("lessons", [])}
            for drill in data_files["drills"].get("drills", []):
                lesson_ref = drill.get("lesson_id", "")
                if lesson_ref and lesson_ref not in lesson_ids:
                    self.error(f"Drill '{drill.get('id', '?')}' references unknown lesson: {lesson_ref}")
                    issues_found += 1

        return issues_found

    # ─────────────────────────────────────────────────────────────
    # Balance Diagnostics
    # ─────────────────────────────────────────────────────────────

    def check_balance(self) -> int:
        """Check for balance anomalies."""
        print("\n=== BALANCE DIAGNOSTICS ===\n")

        issues_found = 0

        # Check upgrade costs make sense
        print("Checking upgrade balance...")
        for upgrade_file in ["kingdom_upgrades", "unit_upgrades"]:
            path = self.root / "data" / f"{upgrade_file}.json"
            data, err = load_json_safe(path)
            if err:
                continue

            upgrades_by_tier: Dict[int, List[dict]] = {}
            for upgrade in data.get("upgrades", []):
                tier = upgrade.get("tier", 1)
                if tier not in upgrades_by_tier:
                    upgrades_by_tier[tier] = []
                upgrades_by_tier[tier].append(upgrade)

            # Check tier costs are increasing
            prev_avg_cost = 0
            for tier in sorted(upgrades_by_tier.keys()):
                costs = [u.get("cost", 0) for u in upgrades_by_tier[tier]]
                avg_cost = sum(costs) / len(costs) if costs else 0
                if avg_cost < prev_avg_cost:
                    self.warn(f"{upgrade_file}: Tier {tier} avg cost ({avg_cost:.0f}) < Tier {tier-1} ({prev_avg_cost:.0f})")
                prev_avg_cost = avg_cost

        # Check building costs
        print("Checking building balance...")
        buildings_path = self.root / "data" / "buildings.json"
        buildings, err = load_json_safe(buildings_path)
        if not err and buildings:
            for bid, bdata in buildings.get("buildings", {}).items():
                cost = bdata.get("cost", {})
                total_cost = sum(cost.values())
                if total_cost == 0:
                    self.warn(f"Building '{bid}' has zero cost")
                if total_cost > 200:
                    self.warn(f"Building '{bid}' has very high cost: {total_cost}")

        return issues_found

    # ─────────────────────────────────────────────────────────────
    # Run All
    # ─────────────────────────────────────────────────────────────

    def run_all(self) -> int:
        """Run all diagnostics."""
        total_issues = 0
        total_issues += self.check_assets()
        total_issues += self.check_lessons()
        total_issues += self.check_references()
        total_issues += self.check_balance()
        return total_issues

    def print_summary(self):
        """Print summary of all issues found."""
        print("\n" + "=" * 60)
        print("DIAGNOSTIC SUMMARY")
        print("=" * 60)

        if self.issues:
            print(f"\n{len(self.issues)} ERROR(S):")
            for issue in self.issues:
                print(f"  {issue}")

        if self.warnings:
            print(f"\n{len(self.warnings)} WARNING(S):")
            for warning in self.warnings:
                print(f"  {warning}")

        if self.fixes:
            print(f"\n{len(self.fixes)} AUTO-FIX(ES) AVAILABLE:")
            for fix in self.fixes:
                print(f"  {fix}")

        if not self.issues and not self.warnings:
            print("\nNo issues found!")

        print()


def main():
    project_root = find_project_root()

    if not (project_root / "project.godot").exists():
        print(f"ERROR: Not in a Godot project directory: {project_root}")
        sys.exit(2)

    args = sys.argv[1:]
    do_fix = "--fix" in args
    args = [a for a in args if not a.startswith("--")]

    diag = Diagnostics(project_root)

    print("=" * 60)
    print("KEYBOARD DEFENSE - DIAGNOSTICS")
    print("=" * 60)
    print(f"Project: {project_root}")

    if not args or "all" in args:
        diag.run_all()
    else:
        for check in args:
            if check == "assets":
                diag.check_assets()
            elif check == "lessons":
                diag.check_lessons()
            elif check == "references":
                diag.check_references()
            elif check == "balance":
                diag.check_balance()
            else:
                print(f"Unknown check: {check}")
                print("Available: assets, lessons, references, balance, all")
                sys.exit(2)

    diag.print_summary()

    if diag.issues:
        sys.exit(1)
    sys.exit(0)


if __name__ == "__main__":
    main()
