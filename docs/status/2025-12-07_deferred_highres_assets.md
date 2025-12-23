# Deferred High-Res Asset Loading - 2025-12-07
> Note: This document targets the retired web version (`apps/keyboard-defense`). The current Godot project lives at `apps/keyboard-defense-godot`; see `docs/GODOT_PROJECT.md` and `apps/keyboard-defense-godot/README.md` for active workflows.

## Summary
- Added tiered asset loading in `AssetLoader`: `loadWithTiers` loads a low-res manifest first, triggers a ready callback, then attempts a high-res manifest with forced reloads to overwrite cached sprites.
- Added a force reload option to image loading so high-res assets replace low-res copies when available.
- Unit tests cover sequencing (low-res then high-res) and graceful fallback when high-res fetch fails, ensuring cached low-res assets remain intact.
- Backlog #64 is now addressed with a deterministic dual-tier loader and tests.

## Verification
- `cd apps/keyboard-defense && npx vitest run deferredHighResAssets.test.js`

## Related Work
- `apps/keyboard-defense/public/dist/src/assets/assetLoader.js`
- `apps/keyboard-defense/tests/deferredHighResAssets.test.js`
- Backlog #64

