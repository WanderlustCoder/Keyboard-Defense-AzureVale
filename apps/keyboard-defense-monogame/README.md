# Keyboard Defense (MonoGame)

Active implementation target for this repository.

## Quick Start

```bash
dotnet restore KeyboardDefense.sln
dotnet build KeyboardDefense.sln --configuration Release
dotnet test KeyboardDefense.sln --configuration Release
```

## Pixel Lab Contract

Source manifest:

- `data/pixel_lab_manifest.catalog.json`
- `data/pixel_lab_manifest.active_runtime.json`

Schema:

- `data/schemas/pixel_lab_manifest.schema.json`

Contract doc:

- `docs/PIXEL_LAB_CONTRACT.md`

Validate manifest:

```bash
python tools/pixel_lab/validate_manifest.py \
  --manifest data/pixel_lab_manifest.active_runtime.json \
  --schema data/schemas/pixel_lab_manifest.schema.json \
  --textures-root Content/Textures \
  --check-files
```

Generate runtime texture manifest:

```bash
python tools/pixel_lab/build_texture_manifest.py \
  --manifest data/pixel_lab_manifest.active_runtime.json \
  --out src/KeyboardDefense.Game/Content/Textures/texture_manifest.pixel_lab.json
```

Migrate legacy manifest entries:

```bash
python tools/pixel_lab/migrate_legacy_assets_manifest.py \
  --legacy-manifest data/assets_manifest.json \
  --out data/pixel_lab_manifest.catalog.json
```

```bash
python tools/pixel_lab/split_runtime_subset.py \
  --catalog data/pixel_lab_manifest.catalog.json \
  --textures-root Content/Textures \
  --out-active data/pixel_lab_manifest.active_runtime.json
```

```bash
python tools/pixel_lab/curate_active_runtime.py \
  --catalog data/pixel_lab_manifest.catalog.json \
  --runtime-texture-manifest Content/Textures/texture_manifest.json \
  --textures-root Content/Textures \
  --out-catalog data/pixel_lab_manifest.catalog.json \
  --out-active data/pixel_lab_manifest.active_runtime.json
```

```bash
python tools/pixel_lab/verify_active_in_catalog.py \
  --catalog data/pixel_lab_manifest.catalog.json \
  --active data/pixel_lab_manifest.active_runtime.json
```
