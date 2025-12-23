# Asset Manifest Generation CLI - 2025-12-07
> Note: This document targets the retired web version (`apps/keyboard-defense`). The current Godot project lives at `apps/keyboard-defense-godot`; see `docs/GODOT_PROJECT.md` and `apps/keyboard-defense-godot/README.md` for active workflows.

## Summary
- Added `scripts/assets/generateManifest.mjs` to scan sprite assets, emit an `images` map, and compute SHA-256 integrity hashes with optional `--verify-only` mode.
- Added `npm run assets:manifest` helper to regenerate `public/assets/manifest.json` from source sprites.
- Build now invokes `assets:manifest` automatically and a `assets:manifest:verify` helper is available for CI/local audits.
- New unit test covers manifest creation and integrity verification, including failure on mismatched hashes.
- Backlog #70 is addressed with a repeatable manifest pipeline and validation guardrails.

## Verification
- `cd apps/keyboard-defense && npx vitest run generateManifest.test.js`

## Related Work
- `apps/keyboard-defense/scripts/assets/generateManifest.mjs`
- `apps/keyboard-defense/tests/generateManifest.test.js`
- `apps/keyboard-defense/package.json` (`assets:manifest` script)
- Backlog #70

