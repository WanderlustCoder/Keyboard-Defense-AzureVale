---
id: defeat-burst-diagnostics
title: "Expose defeat burst metrics in diagnostics & smoke"
priority: P2
effort: S
depends_on: []
produces:
  - diagnostics overlay updates showing burst counts
  - smoke/analytics fields capturing defeat burst metrics
status_note: docs/status/2025-11-07_enemy_defeat_animation.md
backlog_refs:
  - "#41"
---

**Context**  
We added defeat bursts but have no diagnostics metrics to ensure they keep
firing. Exposing counts in the overlay + smoke artifacts helps visual regression.

## Steps

1. **Diagnostics overlay**
   - Add a section listing recent defeat bursts (count per minute, last burst time).
   - Highlight if bursts stop firing unexpectedly.
2. **Telemetry/smoke**
   - Update smoke analytics to log burst counts for quick regression checks.
3. **CI summary**
   - Extend `scripts/ci/emit-summary.mjs` to surface burst stats when available.

## Implementation Notes

- **Diagnostics UI**
  - Add a “Defeat Bursts” card to the diagnostics overlay listing:
    - Total bursts this run / per-minute rate.
    - Last burst timestamp + enemy type.
    - Warnings when bursts pause for > N seconds while enemies are still dying (possible animation regression).
  - Include toggles in condensed mode (ties into task #28) so mobile HUDs can expand/collapse the section.
- **Instrumentation**
  - Extend the combat system to emit `combat.defeatBurst` events with payload `{enemyType, lane, burstMode("sprite"|"procedural"), durationMs}`.
  - Track rolling counters inside `analyticsSnapshot` (e.g., `defeatBurstCount`, `defeatBurstRatePerMin`, `spriteBurstUsagePct`).
  - When running in automation/smoke mode, persist raw events to `artifacts/analytics/defeatBursts.json` for troubleshooting.
- **CI summary**
  - Update `scripts/ci/emit-summary.mjs` (or new `ci/defeatBurstSummary.mjs`) to read the snapshot and print a table with scenario, count, sprite usage %, and last burst age. Fail or warn if counts drop to zero unexpectedly.
- **Testing**
  - Unit tests for the analytics tracking ensuring counters reset per wave/session and survive reduced-motion toggles.
  - Diagnostics overlay tests verifying the new section renders, updates in real time, and respects condensed mode preferences.
  - Fixture-based tests for the CI summary script to guarantee output formatting + threshold logic.
- **Docs**
  - Update `docs/status/2025-11-07_enemy_defeat_animation.md` when metrics land, documenting where to find the overlay section and artifacts.
  - Add instructions to `CODEX_PLAYBOOKS.md` (Automation + Gameplay) on how to verify burst metrics locally and regenerate fixtures.

## Deliverables & Artifacts

- Updated diagnostics overlay components/styles.
- Analytics + telemetry additions with fixtures under `docs/codex_pack/fixtures/defeat-bursts/`.
- CI summary helper output appended to `$GITHUB_STEP_SUMMARY`.
- Documentation updates (status note, playbook, analytics schema) referencing the new metrics.

## Acceptance criteria

- Diagnostics panel shows defeat burst metrics.
- Smoke artifacts record counts.
- CI summary surfaces the numbers.

## Verification

- npm run lint
- npm run test
- npm run codex:validate-pack
- npm run codex:validate-links
- npm run codex:status
- Run diagnostics overlay locally to confirm metrics display.
