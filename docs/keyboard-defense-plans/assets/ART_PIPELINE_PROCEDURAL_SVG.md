# Art pipeline - Procedural SVG to PNG atlas

## Why SVG-first?
SVG is plain text that Codex can generate reliably, review in diff, and keep consistent.
Then a build step converts SVG to PNG for Godot import.

## Folder structure
Recommended:
```
apps/keyboard-defense-godot/assets/
  art/
    style/
      palette.json
      style.json
    src-svg/
      icons/
      sprites/
      tiles/
    generated/
      atlas.png            # optional
      atlas.json           # optional
      atlas_manifest.json  # optional frame metadata
      preview.png
```

## Build tooling
Use open tooling only:
- SVG converter (Inkscape CLI or rsvg-convert)
- optional packer to combine PNGs into an atlas
- a build script under `apps/keyboard-defense-godot/scripts/tools/`

## Generation strategy
1. Write `palette.json` and `style.json`.
2. A generator script emits SVG files under `src-svg/`.
3. A build script converts SVG -> PNG at a fixed scale.
4. Optionally pack into `atlas.png` and emit `atlas.json`.
5. Update `apps/keyboard-defense-godot/data/assets_manifest.json` with new PNGs.

## Determinism requirements
- All generators take a `--seed` integer.
- Any randomness uses a seeded RNG.
- Output must be stable across OSes.

## Acceptance criteria
- A build script produces PNGs and a preview sheet.
- Godot imports with pixel art filtering off.
- Asset manifest updated and `scripts/run_tests.ps1` passes.
