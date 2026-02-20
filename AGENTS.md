# AGENTS

## Development Model

All development is AI-driven. The user provides product direction and requirements; implementation is code-first.

## Active Project and Archive Policy

- Active implementation target: `apps/keyboard-defense-monogame`
- Archived reference (do not delete yet): `apps/keyboard-defense-godot`
- Rule: new feature work lands in MonoGame. Godot is read-only reference for parity checks and historical lookup.

## MonoGame Project Structure

- `apps/keyboard-defense-monogame/src/KeyboardDefense.Core/**` - Deterministic gameplay sim/state logic (engine-agnostic).
- `apps/keyboard-defense-monogame/src/KeyboardDefense.Game/**` - MonoGame rendering, input, runtime services.
- `apps/keyboard-defense-monogame/src/KeyboardDefense.Tests/**` - Unit and flow regression tests.
- `apps/keyboard-defense-monogame/data/**` - Gameplay data and manifests.
- `apps/keyboard-defense-monogame/data/schemas/**` - JSON schemas for data contracts.
- `apps/keyboard-defense-monogame/Content/**` - Runtime textures/audio content.
- `apps/keyboard-defense-monogame/tools/**` - Build, content, and release tooling.

## Architecture Rules

- Keep deterministic sim in `KeyboardDefense.Core` (no render/input dependencies).
- Treat `KeyboardDefense.Game` as adapter/orchestration around core state.
- Keep data-driven systems in JSON under `data/`.
- Favor stable IDs and manifests for assets and content lookup.

## Pixel Lab Contract

Canonical contract files:

- `apps/keyboard-defense-monogame/docs/PIXEL_LAB_CONTRACT.md`
- `apps/keyboard-defense-monogame/data/pixel_lab_manifest.catalog.json`
- `apps/keyboard-defense-monogame/data/pixel_lab_manifest.active_runtime.json`
- `apps/keyboard-defense-monogame/data/schemas/pixel_lab_manifest.schema.json`

Validation/build tools:

- `apps/keyboard-defense-monogame/tools/pixel_lab/validate_manifest.py`
- `apps/keyboard-defense-monogame/tools/pixel_lab/build_texture_manifest.py`
- `apps/keyboard-defense-monogame/tools/pixel_lab/migrate_legacy_assets_manifest.py`
- `apps/keyboard-defense-monogame/tools/pixel_lab/split_runtime_subset.py`
- `apps/keyboard-defense-monogame/tools/pixel_lab/curate_active_runtime.py`
- `apps/keyboard-defense-monogame/tools/pixel_lab/verify_active_in_catalog.py`

Rules:

- Catalog entries are registered in `pixel_lab_manifest.catalog.json`.
- Runtime-shippable entries are registered in `pixel_lab_manifest.active_runtime.json`.
- Paths are MonoGame-relative (no `res://` paths in new entries).
- Runtime lookup manifest is generated from the source manifest.

## Implementation Workflow

When implementing a feature:

1. Check docs under `apps/keyboard-defense-monogame/docs/` first.
2. Keep deterministic logic in core; UI/rendering in game layer.
3. Extract constants/content into `data/`.
4. Add or update tests in `KeyboardDefense.Tests`.
5. Keep Pixel Lab/data manifests in sync.

## Testing and Build

Primary commands:

```bash
dotnet test apps/keyboard-defense-monogame/KeyboardDefense.sln --configuration Release
dotnet build apps/keyboard-defense-monogame/KeyboardDefense.sln --configuration Release
```

Root shortcuts:

- `scripts/test.ps1`
- `scripts/test.sh`
- `scripts/scenarios.ps1`
- `scripts/scenarios.sh`

Git hook setup (shared, repo-tracked):

- `scripts/install-hooks.ps1`
- `scripts/install-hooks.sh`
- Default pre-commit behavior runs MonoGame tests.
- Optional Godot checks can be enabled with `PRECOMMIT_FLAGS=--godot` or `PRECOMMIT_GODOT=1`.
- `SKIP_HOOKS=1` skips local hook checks.

## Release

Primary release workflow/tooling:

- `.github/workflows/monogame-release.yml`
- `apps/keyboard-defense-monogame/tools/publish.ps1`
- `apps/keyboard-defense-monogame/tools/publish.sh`

## Documentation

Primary references:

- `docs/MONOGAME_PROJECT.md`
- `docs/docs_index.md`
- `apps/keyboard-defense-monogame/docs/PIXEL_LAB_CONTRACT.md`

Archived references:

- `docs/GODOT_PROJECT.md`
- `apps/keyboard-defense-godot/**`
