# Sprite Atlas Generation CLI - 2025-12-07

## Summary
- Added `scripts/assets/buildAtlas.mjs` to pack sprite assets into a simple atlas JSON (fixed tile size, row wrapping) with optional dry-run.
- Exposed `npm run assets:atlas` to generate atlases on demand; defaults to scanning `public/assets` and writing `public/assets/atlas.json`.
- Added unit coverage for packing math and atlas writing with row wrap handling.
- Backlog #63 is now addressed with a lightweight atlas pipeline to build on for future sprite packing.

## Verification
- `cd apps/keyboard-defense && npx vitest run buildAtlas.test.js`

## Related Work
- `apps/keyboard-defense/scripts/assets/buildAtlas.mjs`
- `apps/keyboard-defense/tests/buildAtlas.test.js`
- `apps/keyboard-defense/package.json` (`assets:atlas`)
- Backlog #63
