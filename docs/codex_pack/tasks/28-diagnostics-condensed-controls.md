---
id: diagnostics-condensed-controls
title: "Expose diagnostics condensed state & controls"
priority: P2
effort: S
depends_on: []
produces:
  - diagnostics overlay updates surfacing condensed controls (toggle, collapsed sections)
  - settings persistence + analytics metadata for condensed mode
status_note: docs/status/2025-11-18_diagnostics_overlay_condensed.md
backlog_refs:
  - "#41"
---
> Note: This document targets the retired web version (`apps/keyboard-defense`). The current Godot project lives at `apps/keyboard-defense-godot`; see `docs/GODOT_PROJECT.md` and `apps/keyboard-defense-godot/README.md` for active workflows.

**Context**  
Diagnostics overlay now has a condensed mode, but there are outstanding next steps:
adding more condensed toggles, persisting preferences, and exposing the state to
automation.

## Steps

1. **Controls**
   - Add individual collapse toggles for heavy sections (gold events, turret DPS, passive details).
   - Provide "expand all" / "collapse all" buttons in condensed mode.
2. **Settings persistence**
   - Store condensed preferences in player settings (similar to HUD collapse).
   - Ensure `Codex`/analytics captures the state.
3. **Analytics**
   - Extend diagnostics analytics snapshot to include condensed state per section.
4. **Docs/tests**
   - Update docs and unit tests to cover the new controls + persistence.

## Implementation Notes

- **Component structure**
  - Extract the diagnostics overlay sections (gold, turret DPS, passives, logs)
    into a small accordion/section list so each block can render its own header,
    toggle button, and condensed summary line.
  - Gate the new controls behind `body.dataset.diagnosticsCondensed` so desktop
    layouts remain untouched.
- **State management**
  - Persist state under `playerSettings.diagnostics.sections`, e.g.
    `{gold: "expanded" | "collapsed"}` plus a `sectionsCollapsedAt` timestamp
    for analytics diffing.
  - Provide a helper (`DiagnosticsCondensedStore`) that exposes `setSection()`,
    `reset()`, and `hydrateFromSnapshot()` to keep UI, telemetry, and tests in sync.
  - Respect persisted preferences during boot, but always allow automation to
    override them via `window.__KEYBOARD_DEFENSE_TEST_PROPS`.
- **Analytics + automation**
  - Extend `analyticsAggregate` to emit `ui.diagnostics` fields such as
    `condensed`, `collapsedSections`, and `lastToggleMs`.
  - Update `uiSnapshot` metadata + HUD screenshot sidecars to include the same
    fields so docs and CI summaries can surface the condensed layout status.
  - Emit a lightweight event (`ui.diagnosticsCondensedChanged`) whenever the
    player toggles condensed mode; smoke tests can assert at least one event fired.
  - `ui.diagnostics.collapsedSections` + `ui.preferences.diagnosticsSections*`
    now ship inside analytics exports—dashboards should key off these fields
    instead of parsing overlay text.
- **Testing**
  - Add Vitest coverage for the store (serialization, persistence, hydration).
  - Create DOM-oriented tests (or Playwright fixtures once visual-diffs returns)
    that ensure toggles appear only in condensed mode, expand/collapse all works,
    and persisted state survives a reload.
  - When asserting rendered lines, prefer `container.textContent` over
    `innerHTML` so the tests read human strings (no `&gt;` entity surprises) and
    call `applySectionPreferences(..., { silent: true })` to re-render without
    spamming observers.
  - Snapshot the analytics payload to lock column ordering for the new fields.
  - Run `npm run docs:verify-hud-snapshots` (backed by `scripts/docs/verifyHudSnapshots.mjs`)
    so CI fails whenever HUD screenshot metadata is missing diagnostics collapse data.
- **Docs + playbooks**
  - Update `docs/status/2025-11-18_diagnostics_overlay_condensed.md` with the
    richer plan and link to any new CLI helpers.
  - Expand `CODEX_PLAYBOOKS.md` (Gameplay/UI + Automation sections) with a short
    “Diagnostics condensed checklist” reminding contributors to refresh
    screenshots + analytics fixtures whenever they touch the overlay.

## Artifacts

- `apps/keyboard-defense/src/ui/diagnostics/condensedStore.ts` (or similar) with unit tests.
- Updated diagnostics overlay components/templates + SCSS hooks for condensed controls.
- Persisted settings schema bump under `playerSettings`.
- Analytics fixture updates (`docs/codex_pack/fixtures/analytics/diagnostics-condensed.json`).
- Documentation refresh: `docs/status/...`, `docs/CODEX_PLAYBOOKS.md`,
  `docs/docs_index.md`, and any dashboard tiles referencing diagnostics state.

## Acceptance criteria

- Diagnostics overlay offers fine-grained condensed controls with persistence.
- Analytics/smoke artifacts record the condensed state.
- Tests cover the new UI/integration.

## Verification

- npm run lint
- npm run test
- npm run codex:validate-pack
- npm run codex:validate-links
- npm run codex:status
- Manual test: toggle condensed sections and reload to ensure settings persist.






