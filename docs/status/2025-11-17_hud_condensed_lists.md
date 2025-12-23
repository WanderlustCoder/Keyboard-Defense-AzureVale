> Note: This document targets the retired web version (`apps/keyboard-defense`). The current Godot project lives at `apps/keyboard-defense-godot`; see `docs/GODOT_PROJECT.md` and `apps/keyboard-defense-godot/README.md` for active workflows.

## HUD Castle Panel Condensed Lists - 2025-11-17

**Summary**
- Castle passives and recent gold events inside the HUD now live inside collapsible cards with summary counts so the sidebar stays readable on tablets/phones without sacrificing the details desktop players expect.
- The toggle buttons announce how many passives or events are tracked (e.g., “Show Castle passives (3 passives)”); when collapsed they occupy a single row, and the lists expand inline without reflowing nearby controls.
- Viewports below 768px default to the collapsed state automatically, but players can expand either card at any time—state resets per session so HUD screenshots/tests remain deterministic.
- Gold event summaries surface the latest delta in the collapsed label (e.g., “3 recent events (last +40g)”), giving at-a-glance economy intel even when the list stays hidden.
- The pause/options overlay now mirrors the same condensed treatment for castle passives, complete with summary counts and a responsive toggle so small-screen players don’t scroll past a long passive list mid-battle.
- Player settings now persist each card's collapsed state (HUD passives, HUD gold events, pause-menu passives), so once a player expands on mobile the preference sticks across reloads without losing the responsive default on fresh sessions.
- Added `docs/codex_pack/fixtures/responsive/condensed-matrix.yml` plus `node scripts/docs/condensedAudit.mjs`, letting CI/locals verify that every required panel + breakpoint combination is covered by our HUD snapshot metadata (currently hud-main, options-overlay, wave-scorecard). The audit exposes `docs:condensed-audit` and surfaces missing badges/flags with actionable messages.
- `npm run docs:verify-hud-snapshots` now chains the condensed audit automatically, so the existing docs/HUD verification step fails as soon as a required panel badge or preference flag disappears. The matrix now covers the tutorial wrap-up overlay as well (`tutorial-summary` must report an expanded banner on desktop), preventing regressions where the banner ships condensed on large screens.
- CI e2e workflow (`ci-e2e-azure-vale.yml`) now publishes `artifacts/summaries/condensed-audit.md` straight into `$GITHUB_STEP_SUMMARY` after HUD verification, so reviewers can read the responsive matrix without downloading artifacts.
- `scripts/ci/emit-summary.mjs` loads `artifacts/summaries/condensed-audit.(json|md)` and prints the responsive audit status/coverage/issues directly into the GitHub step summary, so PR reviewers can spot regressions without chasing logs.

**Next Steps**
1. Expand the matrix once the tutorial log + scorecard condensed states ship (capture new snapshots + badges for those overlays).
2. Surface condensed audit results inside the Codex dashboard/CI summary so reviewers can see panel coverage without opening raw logs.

## Follow-up
- `docs/codex_pack/tasks/37-responsive-condensed-audit.md`

