---
id: tutorial-ui-snapshot-publishing
title: "Expose tutorial UI snapshot metadata in galleries/dashboards"
priority: P2
effort: M
depends_on: [visual-diffs]
produces:
  - docs/hud_gallery.md (ui snapshot badges)
  - scripts/docs/renderHudGallery.mjs
status_note: docs/status/2025-11-18_tutorial_condensed_states.md
backlog_refs:
  - "#53"
  - "#59"
---
> Note: This document targets the retired web version (`apps/keyboard-defense`). The current Godot project lives at `apps/keyboard-defense-godot`; see `docs/GODOT_PROJECT.md` and `apps/keyboard-defense-godot/README.md` for active workflows.

**Context**  
Tutorial + castle panels now emit a `uiSnapshot` block describing condensed states,
but reviewers still open JSON artifacts to see whether screenshots captured mobile
layouts, collapsed passives, or diagnostics overlays. We need Codex automation that
surfaces the snapshot metadata directly in documentation, screenshot galleries,
and CI summaries so responsive regressions are obvious.

## Steps

1. **Screenshot pipeline**
   - Extend `scripts/hudScreenshots.mjs` to write a sidecar Markdown/JSON file per capture (`artifacts/screenshots/<name>.meta.json`) containing the `uiSnapshot`.
   - Update the CLI summary to embed a condensed badge table (banner mode, HUD condensed, diagnostics condensed, etc.) for each PNG.
2. **Docs/galleries**
   - Enhance `docs/docs_index.md` (or a new `docs/hud_gallery.md`) to render screenshot tables with snapshot badges, referencing the sidecar files, and emit a JSON gallery (`artifacts/summaries/ui-snapshot-gallery.json`) for dashboards.
   - Add a Codex dashboard section that links to the latest gallery and highlights mismatched states (e.g., tutorial banner not condensed when viewport is short).
3. **Analytics + tests**
   - Expand `scripts/analyticsAggregate.mjs` tests to assert that `uiSnapshot` columns survive CSV export and that Codex fixtures cover both tall + compact modes.
   - Provide `docs/codex_pack/fixtures/ui-snapshot/` JSON samples for automation dry-runs.
4. **Playbook updates**
   - Document how to regenerate the gallery + badges inside `CODEX_PLAYBOOKS.md` so Codex can refresh the responsive evidence whenever HUD changes land.

## Implementation Notes

- **Metadata structure**
  - Standardize the `uiSnapshot` schema: `{viewport: {width,height,label}, bannerMode, hudCondensed, diagnosticsCondensed, tutorialPanel, passivePanelCollapsed, diagnosticsSectionsCollapsed[]}`.
  - Ensure `scripts/hudScreenshots.mjs` writes this schema into `*.meta.json` along with a human-friendly summary and timestamp.
  - Include screenshot hash/commit metadata so galleries show when captures were refreshed.
- **Gallery generator**
  - Enhance `scripts/docs/renderHudGallery.mjs` to:
    - Sort screenshots by scenario (hud-main, options, tutorial-summary, wave-scorecard).
    - Render badge tables summarizing condensed states, viewport, and taunt/diagnostics context.
    - Emit both Markdown (`docs/hud_gallery.md`) and JSON (`artifacts/summaries/ui-snapshot-gallery.json`) so the Codex Portal can highlight discrepancies.
  - Support a `--verify` mode that fails when required scenarios are missing or when badge data is incomplete.
- **Analytics linkage**
  - Pipe `uiSnapshot` fields into `analyticsAggregate` exports so CI artifacts and dashboards can cross-check screenshot state vs runtime telemetry.
  - Create fixtures in `docs/codex_pack/fixtures/ui-snapshot/` representing tall + compact captures and wire them into tests.
- **CI & Portal integration**
  - Add a dashboard tile referencing the gallery + JSON rollup, and link it from `docs/CODEX_PORTAL.md`.
  - Update CI summary (`scripts/ci/emit-summary.mjs`) to note when new screenshots were captured and list condensed badges inline.
- **Playbooks/docs**
  - Expand `CODEX_PLAYBOOKS.md` with a responsive evidence checklist (capture screenshots, regenerate gallery, run analytics tests).
  - Update `CODEX_GUIDE.md` command table with `node scripts/docs/renderHudGallery.mjs --input artifacts/screenshots`.
  - Refresh the Nov-18/Nov-20 status notes when badges + gallery automation land.
- **Testing**
  - Add Vitest tests for the gallery generator (Markdown/JSON snapshots) and for `hudScreenshots` metadata writing.
  - Ensure analytics tests cover `uiSnapshot` columns (CSV + JSON).

## Deliverables & Artifacts

- `scripts/hudScreenshots.mjs` metadata enhancements.
- `scripts/docs/renderHudGallery.mjs` (Markdown + JSON output w/ `--verify`) + tests/fixtures.
- `docs/hud_gallery.md` + Codex dashboard tile referencing the gallery.
- Documentation updates (guide, playbook, portal, status) explaining the workflow.

## Acceptance criteria

- Every Hud/Tutorial screenshot published via Codex includes visible UI snapshot badges without opening JSON artifacts.
- Codex dashboard (and/or docs) highlights when condensed states change, enabling reviewers to catch responsive regressions at a glance.
- Analytics CLI + associated tests guard the `uiSnapshot` schema so future changes require deliberate updates.

## Verification

- npm run task:screenshots -- --ci --out artifacts/screenshots
- node scripts/docs/renderHudGallery.mjs --input artifacts/screenshots --meta artifacts/screenshots/*.meta.json
- npm run test -- hudScreenshots analyticsAggregate
- npm run codex:validate-pack
- npm run codex:validate-links
- npm run codex:status






