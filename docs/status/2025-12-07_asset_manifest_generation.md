# Asset Manifest Generation CLI - 2025-12-07

## Summary
- Added `scripts/assets/generateManifest.mjs` to scan sprite assets, emit an `images` map, and compute SHA-256 integrity hashes with optional `--verify-only` mode.
- Added `npm run assets:manifest` helper to regenerate `public/assets/manifest.json` from source sprites.
- New unit test covers manifest creation and integrity verification, including failure on mismatched hashes.
- Backlog #70 is addressed with a repeatable manifest pipeline and validation guardrails.

## Verification
- `cd apps/keyboard-defense && npx vitest run generateManifest.test.js`

## Related Work
- `apps/keyboard-defense/scripts/assets/generateManifest.mjs`
- `apps/keyboard-defense/tests/generateManifest.test.js`
- `apps/keyboard-defense/package.json` (`assets:manifest` script)
- Backlog #70
