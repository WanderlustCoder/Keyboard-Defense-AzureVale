> Note: This document targets the retired web version (`apps/keyboard-defense`). The current Godot project lives at `apps/keyboard-defense-godot`; see `docs/GODOT_PROJECT.md` and `apps/keyboard-defense-godot/README.md` for active workflows.

## Diagnostics Overlay Compact Mode - 2025-11-18

**Summary**
- Diagnostics overlay now watches viewport height/width breakpoints and flips into a condensed card along the bottom edge on short or landscape-first screens, preventing it from obscuring the canvas.
- CSS adds scrollable max-height, reduced typography, and wider padding for the condensed state so telemetry lines remain readable without forcing desktop dimensions.
- Tests stub `window.matchMedia` to assert that the overlay automatically adds/removes the `data-condensed` flag, ensuring the behavior survives future refactors.
- Added a floating toggle that collapses verbose sections (gold events, turret DPS, passive details) when condensed, trimming scrolling to a single summary line until expanded.
- Automation can now detect condensed + collapsed state via `body.dataset.diagnosticsCondensed` and `body.dataset.diagnosticsSectionsCollapsed`, keeping screenshot tooling in sync with the responsive HUD.
- Per-section collapse preferences now persist in player settings (`diagnosticsSections`) and are exported in analytics (`ui.diagnostics.collapsedSections` + `ui.preferences.diagnosticsSections`), enabling dashboards to badge individual cards without rehydrating JSON manually.
- `scripts/hudScreenshots.mjs` writes the enriched snapshot data into every `*.meta.json`, the gallery renderer renders badges + summaries for each diagnostics section, and `npm run docs:verify-hud-snapshots` now fails if any metadata goes missing.
- The dist build is now automated: `npm run build` runs `scripts/buildDist.mjs`, recompiles `src/ui/diagnostics.ts`, and overwrites `public/dist/src/ui/diagnostics.*` so condensed controls ship without manual `temp-build` copies.
- Playwright coverage landed in `tests/visual/diagnostics-condensed.spec.ts`, using the HUD reset helpers to skip the welcome overlay, toggle each condensed section, and assert preferences persist across reloads.

**Next Steps**
1. Promote the condensed Playwright spec + HUD metadata verification into CI so PRs fail fast when diagnostics regress.
2. Expand the responsive checklist (`docs/codex_pack/fixtures/responsive/condensed-matrix.yml`) before surfacing analytics deltas, covering the options overlay + wave scorecard panels.

