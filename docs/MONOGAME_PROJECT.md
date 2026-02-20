# Keyboard Defense (MonoGame) Reference

The active project is the MonoGame version at:

- `apps/keyboard-defense-monogame`

Current implementation milestone:

- `docs/MONOGAME_VERTICAL_SLICE_PLAN.md` (completed first-playable loop baseline)
- `docs/MONOGAME_CAMPAIGN_M1_PLAN.md` (completed campaign progression baseline)
- `docs/MONOGAME_CAMPAIGN_M2_PLAN.md` (completed campaign hardening and retry-flow milestone)
- `docs/MONOGAME_CAMPAIGN_M3_PLAN.md` (completed campaign map readability and inspection milestone)
- `docs/MONOGAME_CAMPAIGN_M4_PLAN.md` (completed campaign map selection summary and inspection parity milestone)
- `docs/MONOGAME_CAMPAIGN_M5_PLAN.md` (completed campaign UX and traversal consistency milestone)
- `docs/MONOGAME_CAMPAIGN_M6_PLAN.md` (completed campaign onboarding and launch/return-flow clarity milestone)
- `docs/MONOGAME_CAMPAIGN_M7_PLAN.md` (completed campaign release-hardening and playtest-readiness milestone)
- `docs/MONOGAME_CAMPAIGN_M8_PLAN.md` (completed campaign pre-release polish and launch-readiness milestone)
- `apps/keyboard-defense-monogame/docs/VERTICAL_SLICE_BALANCE.md` (current single-wave tuning baseline)

Current focus after campaign M8 completion:

- Prepare final release notes and version/tag metadata from `docs/CAMPAIGN_RELEASE_NOTES_M1_M8_DRAFT.md`.
- Maintain RC confidence with periodic packaging + campaign sanity reruns before final release cut.

## Build and Test

```bash
dotnet restore apps/keyboard-defense-monogame/KeyboardDefense.sln
dotnet build apps/keyboard-defense-monogame/KeyboardDefense.sln --configuration Release
dotnet test apps/keyboard-defense-monogame/KeyboardDefense.sln --configuration Release
```

Root shortcuts:

```bash
./scripts/test.sh
# or
powershell -ExecutionPolicy Bypass -File .\scripts\test.ps1
```

Hook setup (shared, repo-tracked):

```bash
./scripts/install-hooks.sh
# or
powershell -ExecutionPolicy Bypass -File .\scripts\install-hooks.ps1
```

Pre-commit defaults to MonoGame tests. Godot checks are opt-in:

```bash
PRECOMMIT_FLAGS=--godot git commit -m "..."
# or
PRECOMMIT_GODOT=1 git commit -m "..."
```

## Pixel Lab Contract

Canonical files:

- `apps/keyboard-defense-monogame/docs/PIXEL_LAB_CONTRACT.md`
- `apps/keyboard-defense-monogame/data/pixel_lab_manifest.catalog.json`
- `apps/keyboard-defense-monogame/data/pixel_lab_manifest.active_runtime.json`
- `apps/keyboard-defense-monogame/data/schemas/pixel_lab_manifest.schema.json`

Tooling:

```bash
python apps/keyboard-defense-monogame/tools/pixel_lab/validate_manifest.py \
  --manifest apps/keyboard-defense-monogame/data/pixel_lab_manifest.active_runtime.json \
  --schema apps/keyboard-defense-monogame/data/schemas/pixel_lab_manifest.schema.json \
  --textures-root Content/Textures \
  --check-files
```

```bash
python apps/keyboard-defense-monogame/tools/pixel_lab/build_texture_manifest.py \
  --manifest apps/keyboard-defense-monogame/data/pixel_lab_manifest.active_runtime.json \
  --out apps/keyboard-defense-monogame/src/KeyboardDefense.Game/Content/Textures/texture_manifest.pixel_lab.json
```

Migrate legacy contract input:

```bash
python apps/keyboard-defense-monogame/tools/pixel_lab/migrate_legacy_assets_manifest.py \
  --legacy-manifest apps/keyboard-defense-monogame/data/assets_manifest.json \
  --out apps/keyboard-defense-monogame/data/pixel_lab_manifest.catalog.json
```

```bash
python apps/keyboard-defense-monogame/tools/pixel_lab/split_runtime_subset.py \
  --catalog apps/keyboard-defense-monogame/data/pixel_lab_manifest.catalog.json \
  --textures-root apps/keyboard-defense-monogame/Content/Textures \
  --out-active apps/keyboard-defense-monogame/data/pixel_lab_manifest.active_runtime.json
```

```bash
python apps/keyboard-defense-monogame/tools/pixel_lab/curate_active_runtime.py \
  --catalog apps/keyboard-defense-monogame/data/pixel_lab_manifest.catalog.json \
  --runtime-texture-manifest apps/keyboard-defense-monogame/Content/Textures/texture_manifest.json \
  --textures-root apps/keyboard-defense-monogame/Content/Textures \
  --out-catalog apps/keyboard-defense-monogame/data/pixel_lab_manifest.catalog.json \
  --out-active apps/keyboard-defense-monogame/data/pixel_lab_manifest.active_runtime.json
```

```bash
python apps/keyboard-defense-monogame/tools/pixel_lab/verify_active_in_catalog.py \
  --catalog apps/keyboard-defense-monogame/data/pixel_lab_manifest.catalog.json \
  --active apps/keyboard-defense-monogame/data/pixel_lab_manifest.active_runtime.json
```

## Release

- CI build/test: `.github/workflows/monogame-ci.yml`
- Release packaging: `.github/workflows/monogame-release.yml`
- Local packaging scripts:
- `apps/keyboard-defense-monogame/tools/publish.ps1`
- `apps/keyboard-defense-monogame/tools/publish.sh`

## Godot Archive

The Godot version remains in-repo as an archived reference:

- `apps/keyboard-defense-godot`
- `docs/GODOT_PROJECT.md`
