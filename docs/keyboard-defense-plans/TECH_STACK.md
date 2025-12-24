# Recommended tech stack (Keyboard Defense)

## Rationale
Godot 4 provides a fast iteration loop for a 2D typing game and supports
headless tests for content and logic validation.

## Stack
- Godot 4.2
- GDScript
- JSON content files in data/
- Headless tests via scripts/run_tests.ps1

## Build targets
- Windows desktop (primary).
- Other desktop platforms as follow-up.

## Engineering constraints
- Keep gameplay logic in scripts/ with minimal scene coupling.
- Data-driven content in data/ so tests can validate it.
- Asset validation through data/assets_manifest.json and test_asset_integrity.gd.
