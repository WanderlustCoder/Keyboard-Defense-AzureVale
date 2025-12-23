# HUD Screenshot Expansion - 2025-11-28
> Note: This document targets the retired web version (`apps/keyboard-defense`). The current Godot project lives at `apps/keyboard-defense-godot`; see `docs/GODOT_PROJECT.md` and `apps/keyboard-defense-godot/README.md` for active workflows.

## Summary
- Added `diagnostics-overlay` and `shortcut-overlay` targets to `scripts/hudScreenshots.mjs`, opening/closing overlays deterministically and emitting metadata sidecars for both.
- Expanded the HUD gallery requirements to six shots and regenerated `docs/hud_gallery.md` + `artifacts/summaries/ui-snapshot-gallery.json` with fixture-backed entries (placeholder PNGs live under `artifacts/screenshots` until Playwright captures refresh).
- Updated HUD snapshot fixtures to include diagnostics + preference fields so `npm run docs:verify-hud-snapshots` still passes when running without Playwright.

## Next Steps
1. Refresh live screenshots via `node scripts/hudScreenshots.mjs --ci --out artifacts/screenshots --starfield-scene breach` once Playwright is available so diagnostics/shortcut overlays stop relying on placeholders.
2. Fold the new overlay IDs into the visual baseline run if Playwright visual diffs are exercised again.

## Follow-up
- `docs/codex_pack/tasks/40-hud-screenshot-expansion.md`

