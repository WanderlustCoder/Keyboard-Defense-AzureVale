# Project Documentation Index

## Current Project (MonoGame)

- `docs/MONOGAME_PROJECT.md` - Active project workflow, commands, and structure.
- `apps/keyboard-defense-monogame/KeyboardDefense.sln` - MonoGame solution entrypoint.
- `apps/keyboard-defense-monogame/src/KeyboardDefense.Core/` - Deterministic simulation/domain logic.
- `apps/keyboard-defense-monogame/src/KeyboardDefense.Game/` - Runtime game/render/input layer.
- `apps/keyboard-defense-monogame/src/KeyboardDefense.Tests/` - Unit and integration/e2e-style tests.
- `apps/keyboard-defense-monogame/data/` - Game data and manifests.
- `apps/keyboard-defense-monogame/data/pixel_lab_manifest.catalog.json` - Full Pixel Lab catalog manifest.
- `apps/keyboard-defense-monogame/data/pixel_lab_manifest.active_runtime.json` - Runtime-shippable asset subset.
- `apps/keyboard-defense-monogame/data/schemas/pixel_lab_manifest.schema.json` - Pixel Lab manifest schema.
- `apps/keyboard-defense-monogame/docs/PIXEL_LAB_CONTRACT.md` - Pixel Lab integration contract.
- `apps/keyboard-defense-monogame/tools/pixel_lab/validate_manifest.py` - Manifest validation.
- `apps/keyboard-defense-monogame/tools/pixel_lab/build_texture_manifest.py` - Runtime manifest generation.
- `apps/keyboard-defense-monogame/tools/pixel_lab/split_runtime_subset.py` - Catalog/runtime subset split.
- `apps/keyboard-defense-monogame/tools/pixel_lab/curate_active_runtime.py` - Runtime-usage-based active subset curation.
- `apps/keyboard-defense-monogame/tools/pixel_lab/verify_active_in_catalog.py` - CI subset gate for active vs catalog.

## Archived Project (Godot)

- `docs/GODOT_PROJECT.md` - Archived Godot reference and migration boundary.
- `apps/keyboard-defense-godot/` - Archived Godot project retained for parity/reference only.

## Notes

- New features should target MonoGame.
- Godot remains in-repo and is not deleted, but is not the active implementation target.
