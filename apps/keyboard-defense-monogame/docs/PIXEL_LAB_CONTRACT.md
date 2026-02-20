# Pixel Lab Contract (MonoGame)

Status: Draft v1.0 (2026-02-20)
Scope: `apps/keyboard-defense-monogame`

## Purpose

Define one strict, code-first asset contract for Pixel Lab outputs so AI-driven development stays deterministic, testable, and CI-enforced.

## Design Goals

- Make Pixel Lab integration schema-driven instead of ad-hoc.
- Keep runtime loading simple (stable IDs + stable relative paths).
- Support repeatable regeneration without manual editor steps.
- Keep compatibility with current MonoGame runtime (`AssetLoader` + `texture_manifest.json`) during transition.

## Non-Goals

- Rebuild every existing asset in one pass.
- Delete or rewrite the Godot project right now.
- Require manual scene editing workflows.

## Canonical Folder Layout

```text
apps/keyboard-defense-monogame/
  data/
    pixel_lab_manifest.catalog.json                 # Full catalog (all known/imported assets)
    pixel_lab_manifest.active_runtime.json          # Runtime-shippable subset
    schemas/
      pixel_lab_manifest.schema.json                # Schema for manifest validation
  src/
    KeyboardDefense.Game/
      Content/
        Textures/
          ...                                       # Generated PNGs used at runtime
          texture_manifest.json                     # Runtime lookup map generated from source manifest
  tools/
    convert_svg.py                                  # Existing migration helper from Godot SVG
    pixel_lab/
      validate_manifest.py                          # Contract validator
      build_texture_manifest.py                     # Runtime texture_manifest generator
      migrate_legacy_assets_manifest.py             # Legacy assets_manifest -> contract migration
      curate_active_runtime.py                      # Curate runtime subset from runtime texture usage
      verify_active_in_catalog.py                   # CI gate: active_runtime is subset of catalog
```

## Archive Boundary (Godot)

Until full cutover is done:

- `apps/keyboard-defense-godot/**` is treated as archived/read-only reference.
- Allowed use: source data lookup, SVG lookup, behavior parity checks.
- Disallowed use: new feature implementation target.
- New feature work lands in `apps/keyboard-defense-monogame/**`.

## Manifest Contract

Two manifest layers are used:

- `data/pixel_lab_manifest.catalog.json` is the full source catalog.
- `data/pixel_lab_manifest.active_runtime.json` is the strict runtime subset.

Both files use the same schema and asset record format.

Top-level fields:

- `version`: contract version string.
- `generated_utc`: ISO-8601 UTC timestamp for last generation.
- `assets`: array of asset records.

Asset record fields:

- `id`: stable snake_case runtime ID (example: `enemy_runner_walk`).
- `category`: one of `icons`, `sprites`, `portraits`, `tiles`, `effects`, `ui`.
- `source`: Pixel Lab provenance.
- `output`: generated texture location + dimensions.
- `constraints`: budget and rendering expectations.
- `animation` (optional): clip metadata when sheet/animation exists.
- `tags` (optional): query labels for tooling.

Source fields:

- `provider`: expected `pixellab`.
- `artifact_type`: `character`, `animation`, `isometric_tile`, `map_object`, `topdown_tileset`, `sidescroller_tileset`, `other`.
- `artifact_id`: Pixel Lab object/job ID when available.
- `exported_utc`: export time for traceability.

Output fields:

- `relative_path`: path relative to `src/KeyboardDefense.Game/Content/Textures/`.
- `width`: expected width in pixels.
- `height`: expected height in pixels.

Constraint fields:

- `max_kb`: file size budget in kilobytes.
- `pixel_art`: whether nearest-neighbor/pixel-art assumptions apply.
- `alpha_required`: transparency requirement.

## Naming Rules

- `id` pattern: `^[a-z0-9_]+$`.
- `relative_path` must:
- Not start with `res://`, `/`, drive letters, or UNC prefixes.
- Use forward slashes.
- End with `.png`.
- Recommended category prefixes:
- `ico_` for icons.
- `enemy_`/`bld_`/`tile_` for entities.
- `portrait_` for portraits.
- `fx_`/`projectile_` for effects.

## Runtime Contract

- Runtime texture loading uses manifest `id` first.
- Build step generates `texture_manifest.json` under `Content/Textures`.
- Current MonoGame `AssetLoader` remains compatible while migration completes.
- Legacy `res://...` pathing is not valid in this contract.

## Build and Validation Contract

Required CI stages for Pixel Lab assets:

1. Validate `pixel_lab_manifest.catalog.json` against `pixel_lab_manifest.schema.json`.
2. Validate `pixel_lab_manifest.active_runtime.json` against `pixel_lab_manifest.schema.json`.
3. Enforce file/dimension/budget checks on `active_runtime`.
4. Enforce subset gate: every `active_runtime` asset ID exists in `catalog`.
5. Generate/refresh runtime `texture_manifest.json` from `active_runtime`.
6. Fail CI on drift between `active_runtime` and generated runtime manifest.

Command shape:

```bash
python tools/pixel_lab/validate_manifest.py \
  --manifest data/pixel_lab_manifest.catalog.json \
  --schema data/schemas/pixel_lab_manifest.schema.json

python tools/pixel_lab/build_texture_manifest.py \
  --manifest data/pixel_lab_manifest.active_runtime.json \
  --out src/KeyboardDefense.Game/Content/Textures/texture_manifest.pixel_lab.json

python tools/pixel_lab/verify_active_in_catalog.py \
  --catalog data/pixel_lab_manifest.catalog.json \
  --active data/pixel_lab_manifest.active_runtime.json

Legacy import command:

```bash
python tools/pixel_lab/migrate_legacy_assets_manifest.py \
  --legacy-manifest data/assets_manifest.json \
  --out data/pixel_lab_manifest.catalog.json

python tools/pixel_lab/split_runtime_subset.py \
  --catalog data/pixel_lab_manifest.catalog.json \
  --textures-root Content/Textures \
  --out-active data/pixel_lab_manifest.active_runtime.json

python tools/pixel_lab/curate_active_runtime.py \
  --catalog data/pixel_lab_manifest.catalog.json \
  --runtime-texture-manifest Content/Textures/texture_manifest.json \
  --textures-root Content/Textures \
  --out-catalog data/pixel_lab_manifest.catalog.json \
  --out-active data/pixel_lab_manifest.active_runtime.json
```
```

## Animation Contract

If `animation` exists:

- `layout` defines sprite-sheet slicing (`frame_width`, `frame_height`, `rows`).
- `clips` define clip behavior:
- `name`, `row`, `start_frame`, `frames`, `frame_ms`, `loop`.

Runtime behavior:

- Missing animation metadata means static sprite fallback.
- Invalid clip references fail validation.

## Migration Rules from Current State

1. Keep existing MonoGame runtime loader.
2. Move source-of-truth to `data/pixel_lab_manifest.catalog.json`.
3. Convert legacy paths:
- `res://assets/icons/ico_gold.png` -> `icons/ico_gold.png`.
4. Split runtime-shippable entries into `data/pixel_lab_manifest.active_runtime.json`.
5. Generate compatibility `texture_manifest.json` from runtime subset.
6. Remove legacy manifest formats only after CI and runtime parity.

## Done Criteria for Pixel Lab Integration

- All imported/known assets enter through `pixel_lab_manifest.catalog.json`.
- Runtime-shippable assets are explicitly curated in `pixel_lab_manifest.active_runtime.json`.
- Schema + validator enforced in CI.
- Runtime reads generated manifest without fallback path guessing for new assets.
- No new `res://` paths introduced in MonoGame manifests.
