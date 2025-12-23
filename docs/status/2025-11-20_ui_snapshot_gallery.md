> Note: This document targets the retired web version (`apps/keyboard-defense`). The current Godot project lives at `apps/keyboard-defense-godot`; see `docs/GODOT_PROJECT.md` and `apps/keyboard-defense-godot/README.md` for active workflows.

## UI Snapshot Gallery & Metadata - 2025-11-20

**Summary**
- `scripts/hudScreenshots.mjs` now emits per-shot metadata (`*.meta.json`) capturing the `uiSnapshot`, a condensed badge list, and a human-readable summary for every PNG (`hud-main`, `options-overlay`, `tutorial-summary`, `wave-scorecard`). CI summaries now list those badges alongside each screenshot, and the sidecars land next to the PNGs for downstream tooling.
- Added `scripts/docs/renderHudGallery.mjs`, a lightweight doc generator that walks the metadata files and rebuilds `docs/hud_gallery.md` with badge tables, snapshot descriptions, and links to the captured PNGs. Fixtures under `docs/codex_pack/fixtures/ui-snapshot/` allow local dry-runs without rerunning Playwright.
- `docs/CODEX_GUIDE.md`, `docs/CODEX_PLAYBOOKS.md`, and `docs/codex_dashboard.md` now call out the gallery workflow so Codex contributors always regenerate the badges/doc whenever HUD screenshots change.
- `npm run docs:gallery` now wraps the gallery builder with JSON/verification flags so contributors can regenerate both Markdown + `artifacts/summaries/ui-snapshot-gallery.json` in one command.

**Next Steps**
1. Wire the HUD gallery link into the Codex Portal once the responsive docs section is reorganized.
2. Integrate `npm run docs:verify-hud-snapshots` across every workflow that captures HUD screenshots (ci-e2e, nightly matrix, static dashboard). Static dashboard + nightly matrix now run it; if future jobs (e.g., docs preview) capture HUD PNGs, wire the guard there too.
3. Consider embedding thumbnail previews (once stable assets exist) to make condensed-state regressions even faster to review.

## Follow-up
- `docs/codex_pack/tasks/33-tutorial-ui-snapshot-publishing.md`

