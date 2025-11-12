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
