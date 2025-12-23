# Sprite Atlas Generation CLI - 2025-12-07
> Note: This document targets the retired web version (`apps/keyboard-defense`). The current Godot project lives at `apps/keyboard-defense-godot`; see `docs/GODOT_PROJECT.md` and `apps/keyboard-defense-godot/README.md` for active workflows.

## Summary
- Added `scripts/assets/buildAtlas.mjs` to pack sprite assets into a simple atlas JSON (fixed tile size, row wrapping) with optional dry-run (`npm run assets:atlas` writes `public/assets/atlas.json`).
- AssetLoader can now load an atlas (feature toggle `assetAtlas`) and render sprites directly from atlas frames via `drawFrame`, falling back to individual images when the atlas or frames are missing.
- Manifest loading skips atlas-backed keys to avoid redundant downloads while keeping integrity tracking for the remaining loose sprites.
- Unit coverage added for atlas packing plus atlas consumption/fallback in the loader; backlog #63 is covered end-to-end.

## Verification
- `cd apps/keyboard-defense && npx vitest run buildAtlas.test.js tests/assetAtlasLoader.test.js`

## Related Work
- `apps/keyboard-defense/scripts/assets/buildAtlas.mjs`
- `apps/keyboard-defense/tests/buildAtlas.test.js`
- `apps/keyboard-defense/tests/assetAtlasLoader.test.js`
- `apps/keyboard-defense/package.json` (`assets:atlas`)
- Backlog #63

