---
id: responsive-condensed-audit
title: "Audit condensed HUD/options panels for small viewports"
priority: P2
effort: M
depends_on: [tutorial-ui-snapshot-publishing]
produces:
  - responsive condensed UX checklist/tests
  - updated analytics UI snapshot schema
status_note: docs/status/2025-11-17_hud_condensed_lists.md
backlog_refs:
  - "#53"
  - "#58"
---

**Context**  
Responsive HUD work (2025-11-17 notes) added collapsible castle passives and gold events, plus coarse
pointer tweaks, but short/landscape devices still surface inconsistencies (options overlay, diagnostics,
wave scorecard). We need a repeatable audit + test harness that ensures every long-form panel exposes a
condensed mode, persists player preferences, and records those states in the `uiSnapshot` data now
captured by automation.

## Steps

1. **Inventory & UX parity**
   - Enumerate panels that still lack condensed toggles (pause/options passives, diagnostics overlay,
     wave scorecard, tutorial log).
   - Implement collapsible headers + summary badges matching the HUD treatment, ensuring reduced-motion
     and screen-reader affordances remain intact.
   - Persist per-panel preferences alongside the existing HUD settings so players only expand once per device.
2. **Automation hooks**
   - Extend the `uiSnapshot` schema (and analytics exports) with explicit fields for each condensed panel.
   - Update `scripts/hudScreenshots.mjs` metadata + docs gallery to include the condensed states (depends on task 33).
3. **Testing + docs**
   - Add viewport-aware Vitest/Playwright coverage that toggles condensed states on tablets/phones.
   - Document the condensed UX checklist in `CODEX_PLAYBOOKS.md` so Codex can re-run audits whenever new panels are added.

## Implementation Notes

- **Panel inventory**
  - Track condensed readiness in a YAML/JSON checklist (`docs/codex_pack/fixtures/responsive/condensed-matrix.yml`) listing each panel vs breakpoint (short, narrow, landscape). Back it with `scripts/docs/condensedAudit.mjs` / `npm run docs:condensed-audit` so CI can fail fast when a snapshot goes stale and publish the results via `artifacts/summaries/condensed-audit.(json|md)` for dashboards.
  - Require each entry to specify: default state, toggle selector, persisted key, and screenshot coverage tag (`hud-main`, `options-overlay`, etc.).
  - Automation (`scripts/docs/condensedAudit.mjs`) should read the matrix, compare against `uiSnapshot` metadata, and flag missing states in CI.
- **UX parity work**
  - Options overlay: mirror the HUD accordion pattern for castle passives, diagnostics, gold events; include summary pills (e.g., “Passives · 3 active”).
  - Wave scorecard/tutorial log: collapse long lists into paginated/scrollable sections with “expand for details” buttons, ensuring screen-reader labels announce the summary.
  - Provide animation tokens (`CONDENSED_TOGGLE_DURATION_MS`) and respect reduced-motion preferences.
  - Persist per-panel preferences under `playerSettings.condensed.panels`, keyed by panel id + breakpoint hash (`options@short`, `waveScorecard@landscape`).
- **Automation & analytics**
  - Extend `uiSnapshot` to include a `condensedPanels` object with boolean flags and summary metadata.
  - Update `scripts/hudScreenshots.mjs` to fail if required condensed panels are missing for a given viewport matrix (leveraging the checklist file).
  - Teach analytics exports to capture the same fields so responsive regressions appear in dashboards.
- **Testing**
  - Vitest DOM tests for each panel to verify:
    - Toggles render at the expected breakpoints.
    - Preferences persist across reloads (via mocked storage).
    - `body.dataset` flags reflect condensed states.
  - Playwright suite (`tests/visual/responsive-condensed.spec.ts`) iterates over breakpoints from the matrix, toggles panels, and saves snapshots.
- **Docs & playbooks**
  - Add a “Condensed audit” subsection to `CODEX_PLAYBOOKS.md` outlining: run checklist script, regenerate screenshots, verify analytics fields, update docs.
  - Link the checklist + audit script from `docs/docs_index.md` and `CODEX_GUIDE.md`.
  - Update `docs/status/2025-11-17_hud_condensed_lists.md` once the audit tooling lands, noting how to re-run it.

## Deliverables & Artifacts

- `docs/codex_pack/fixtures/responsive/condensed-matrix.yml` + audit script.
- Updated panel components + persistence helpers across HUD/options/diagnostics/scorecard.
- `uiSnapshot` schema + fixture updates capturing per-panel condensed states.
- Playwright/Vitest tests + CI wiring to enforce the matrix.
- Documentation updates (guide, playbook, status) detailing the audit workflow.

## Acceptance criteria

- All long-form panels (HUD, pause/options, diagnostics, wave scorecard) expose condensed toggles with persisted preferences.
- Analytics `uiSnapshot` + screenshot metadata clearly record each panel's state.
- Responsive tests exercise condensed toggles across representative breakpoints.

## Verification

- npm run test -- hudResponsive
- npx playwright test responsive
- npm run codex:validate-pack
- npm run codex:validate-links
- npm run codex:status
