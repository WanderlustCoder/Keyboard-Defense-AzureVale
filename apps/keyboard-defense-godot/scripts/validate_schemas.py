#!/usr/bin/env python3
"""
Schema Validation Script for Keyboard Defense

Validates JSON data files against their corresponding JSON schemas.
Run this before commits to catch data errors early.

Usage:
    python scripts/validate_schemas.py          # Validate all files
    python scripts/validate_schemas.py --quick  # Only files with schemas
    python scripts/validate_schemas.py lessons  # Validate specific file(s)

Exit codes:
    0 - All validations passed
    1 - Validation errors found
    2 - Script error (missing dependencies, etc.)
"""

import json
import sys
import os
from pathlib import Path
from typing import Dict, List, Tuple, Optional

# Schema mapping: data file basename -> schema file basename
# Files not in this map will be checked for basic JSON validity only
SCHEMA_MAP = {
    "assets_manifest.json": "assets_manifest.schema.json",
    "buffs.json": "buffs.schema.json",
    "building_upgrades.json": "building_upgrades.schema.json",
    "buildings.json": "buildings.schema.json",
    "drills.json": "drills.schema.json",
    "expeditions.json": "expeditions.schema.json",
    "kingdom_upgrades.json": "kingdom_upgrades.schema.json",
    "lessons.json": "lessons.schema.json",
    "loot_tables.json": "loot_tables.schema.json",
    "map.json": "map.schema.json",
    "research.json": "research.schema.json",
    "resource_nodes.json": "resource_nodes.schema.json",
    "scenarios.json": "scenarios.schema.json",
    "tower_upgrades.json": "tower_upgrades.schema.json",
    "towers.json": "towers.schema.json",
    "unit_upgrades.json": "unit_upgrades.schema.json",
}

# Files to skip validation (generated, temporary, etc.)
SKIP_FILES = set()


def find_project_root() -> Path:
    """Find the Godot project root (directory containing project.godot)."""
    current = Path(__file__).resolve().parent
    while current != current.parent:
        if (current / "project.godot").exists():
            return current
        current = current.parent
    # Fallback: assume we're in scripts/
    return Path(__file__).resolve().parent.parent


def load_json(path: Path) -> Tuple[Optional[dict], Optional[str]]:
    """Load a JSON file, returning (data, None) or (None, error_message)."""
    try:
        with open(path, "r", encoding="utf-8") as f:
            return json.load(f), None
    except json.JSONDecodeError as e:
        return None, f"JSON parse error: {e}"
    except Exception as e:
        return None, f"Read error: {e}"


def validate_with_jsonschema(data: dict, schema: dict, filename: str) -> List[str]:
    """Validate data against schema using jsonschema library."""
    try:
        import jsonschema
        from jsonschema import Draft202012Validator
    except ImportError:
        return ["jsonschema library not installed - run: pip install jsonschema"]

    errors = []
    validator = Draft202012Validator(schema)
    for error in validator.iter_errors(data):
        path = " -> ".join(str(p) for p in error.absolute_path) if error.absolute_path else "(root)"
        errors.append(f"  [{path}] {error.message}")
    return errors


def validate_basic_structure(data: dict, filename: str) -> List[str]:
    """Basic structural validation for files without schemas."""
    errors = []

    # Check for version field (convention for most data files)
    if "version" not in data and filename not in ["story.json"]:
        errors.append("  Missing 'version' field (recommended for all data files)")

    # Check version is an integer
    if "version" in data and not isinstance(data["version"], int):
        errors.append(f"  'version' should be an integer, got {type(data['version']).__name__}")

    return errors


def validate_file(data_path: Path, schema_path: Optional[Path]) -> Tuple[bool, List[str]]:
    """
    Validate a single data file.
    Returns (success, list_of_messages).
    """
    messages = []
    filename = data_path.name

    # Load data file
    data, error = load_json(data_path)
    if error:
        return False, [f"  {error}"]

    if schema_path and schema_path.exists():
        # Validate against schema
        schema, error = load_json(schema_path)
        if error:
            return False, [f"  Schema load error: {error}"]

        errors = validate_with_jsonschema(data, schema, filename)
        if errors:
            return False, errors
        messages.append("  Schema validation passed")
    else:
        # Basic validation only
        errors = validate_basic_structure(data, filename)
        if errors:
            return False, errors
        messages.append("  Basic validation passed (no schema)")

    return True, messages


def validate_sim_no_nodes(project_root: Path) -> List[str]:
    """Check that sim/ files don't import Node classes."""
    errors = []
    sim_dir = project_root / "sim"

    if not sim_dir.exists():
        return errors

    forbidden_patterns = [
        "extends Node",
        "extends Control",
        "extends CanvasItem",
        "extends Node2D",
        "extends Node3D",
        "extends Sprite2D",
        "extends Label",
        "extends Button",
    ]

    for gd_file in sim_dir.glob("*.gd"):
        try:
            content = gd_file.read_text(encoding="utf-8")
            for pattern in forbidden_patterns:
                if pattern in content:
                    errors.append(f"  sim/{gd_file.name}: Contains '{pattern}' (sim/ should be Node-free)")
        except Exception as e:
            errors.append(f"  sim/{gd_file.name}: Could not read: {e}")

    return errors


def main():
    project_root = find_project_root()
    data_dir = project_root / "data"
    schema_dir = data_dir / "schemas"

    if not data_dir.exists():
        print(f"ERROR: Data directory not found: {data_dir}")
        sys.exit(2)

    # Parse arguments
    args = sys.argv[1:]
    quick_mode = "--quick" in args
    args = [a for a in args if not a.startswith("--")]

    # Determine which files to validate
    if args:
        # Specific files requested
        files_to_check = []
        for arg in args:
            # Allow partial names like "lessons" or full "lessons.json"
            if not arg.endswith(".json"):
                arg = arg + ".json"
            path = data_dir / arg
            if path.exists():
                files_to_check.append(path)
            else:
                print(f"WARNING: File not found: {path}")
    else:
        # All JSON files in data/
        files_to_check = sorted(data_dir.glob("*.json"))

    if quick_mode:
        # Only files with schemas
        files_to_check = [f for f in files_to_check if f.name in SCHEMA_MAP]

    # Filter out skipped files
    files_to_check = [f for f in files_to_check if f.name not in SKIP_FILES]

    print("=" * 60)
    print("KEYBOARD DEFENSE - SCHEMA VALIDATION")
    print("=" * 60)
    print(f"Project root: {project_root}")
    print(f"Validating {len(files_to_check)} file(s)")
    print()

    passed = 0
    failed = 0
    warnings = 0

    for data_path in files_to_check:
        filename = data_path.name
        schema_path = schema_dir / SCHEMA_MAP.get(filename, "")
        has_schema = schema_path.exists() if filename in SCHEMA_MAP else False

        schema_indicator = "[SCHEMA]" if has_schema else "[BASIC]"
        print(f"{schema_indicator} {filename}")

        success, messages = validate_file(data_path, schema_path if has_schema else None)

        for msg in messages:
            print(msg)

        if success:
            passed += 1
        else:
            failed += 1
        print()

    # Additional checks
    print("-" * 60)
    print("ARCHITECTURE CHECKS")
    print("-" * 60)

    sim_errors = validate_sim_no_nodes(project_root)
    if sim_errors:
        print("[FAIL] sim/ Node independence:")
        for err in sim_errors:
            print(err)
        failed += 1
    else:
        print("[PASS] sim/ contains no Node dependencies")
        passed += 1

    print()
    print("=" * 60)
    print(f"RESULTS: {passed} passed, {failed} failed")
    print("=" * 60)

    if failed > 0:
        print("\nValidation FAILED - fix errors before committing")
        sys.exit(1)
    else:
        print("\nAll validations PASSED")
        sys.exit(0)


if __name__ == "__main__":
    main()
