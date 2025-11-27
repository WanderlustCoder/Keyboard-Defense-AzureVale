---
id: hud-screenshot-expansion
title: "Expand HUD screenshot coverage"
priority: P2
effort: S
depends_on: []
produces:
  - docs/hud_gallery.md
  - apps/keyboard-defense/artifacts/summaries/ui-snapshot-gallery.json
status_note: docs/status/2025-11-28_hud_screenshot_expansion.md
backlog_refs:
  - "#72"
---

**Context**  
Backlog #72 calls for broader automated HUD screenshots beyond the initial set so docs/regression sweeps cover the diagnostics overlay and keyboard shortcut reference. The gallery + guards should accept fixture metadata when Playwright isn't available while still requiring the extra shots.

## Steps

1. Add `diagnostics-overlay` and `shortcut-overlay` capture targets to `scripts/hudScreenshots.mjs`, opening/closing overlays deterministically and writing metadata sidecars.
2. Extend HUD snapshot fixtures and gallery verification defaults so the new shots are required and available without live captures (fixtures must include diagnostics + preference fields).
3. Refresh `docs/hud_gallery.md`/JSON with the expanded shot list and ensure placeholder PNGs exist until CI regenerates live captures.
4. Update docs/backlog/status to point at the new task and note how to refresh real screenshots in CI.

## Acceptance criteria

- hudScreenshots emits `diagnostics-overlay` and `shortcut-overlay` shots with cleaned-up state between captures.
- Gallery verification now requires six shots (hud-main, diagnostics-overlay, options-overlay, shortcut-overlay, tutorial-summary, wave-scorecard).
- Fixture metadata includes diagnostics + preference fields so `npm run docs:verify-hud-snapshots` passes even without Playwright.
- `docs/hud_gallery.md` lists the new shots and metadata sources.

## Verification

- `npm run docs:verify-hud-snapshots -- --meta artifacts/screenshots ../../docs/codex_pack/fixtures/ui-snapshot`
- `npm run docs:gallery`
- `node scripts/hudScreenshots.mjs --ci --out artifacts/screenshots --starfield-scene warning` (optional live refresh)
