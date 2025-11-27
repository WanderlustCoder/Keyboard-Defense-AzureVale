---
id: combo-accuracy-analytics
title: "Log combo warning accuracy deltas to analytics"
priority: P2
effort: S
depends_on: []
produces:
  - analytics snapshot fields for accuracy deltas
  - telemetry export updates + CI summary display
status_note: docs/status/2025-11-14_combo_accuracy_delta.md
backlog_refs:
  - "#14"
  - "#41"
---

**Context**  
Players now see an accuracy delta badge during combo warnings. We’d like to track
those deltas in analytics/smoke artifacts to correlate combo drops with accuracy
swings.

## Steps

1. **Analytics snapshot**
   - Extend `analyticsSnapshot` to include:
     - `comboWarningAccuracyDelta`
     - `comboWarningActive` timestamp/duration
   - Ensure the data resets when combo resets.
2. **Telemetry/smoke exports**
   - Update `scripts/analyticsAggregate.mjs` and smoke artifacts to log the new
     fields (mean delta, min/max) for dashboards.
3. **CI summary**
   - Extend `scripts/ci/emit-summary.mjs` so Build/Test job prints accuracy delta stats (e.g., “Combo warning delta: -4%”).
4. **Docs**
   - Update the combo accuracy status note once analytics logging is live.

## Implementation Notes

- **Data capture**
  - Extend the combo system to log the player’s rolling accuracy at the moment the warning badge activates, along with the baseline/target accuracy (pre-warning). Store this inside `gameState.analytics.comboWarning`.
  - Track multiple warnings per wave; keep an array with timestamps, `deltaPercent`, `comboBefore`, `comboAfter`, and `waveIndex`.
  - When combo resets, flush the array into the analytics snapshot and clear the live buffer.
- **Analytics schema**
  - Snapshot fields: `comboWarningAccuracyDeltaLast`, `comboWarningAccuracyDeltaAvg`, `comboWarningAccuracyDeltaMin`, `comboWarningAccuracyDeltaMax`, `comboWarningCount`.
  - For timeline exports, include the per-warning entries so dashboards can plot delta trends.
  - Update `docs/analytics_schema.md` and fixtures to reflect the new fields and column ordering.
- **Telemetry & CI**
  - Emit a telemetry event (`combat.comboWarningDelta`) per warning containing delta, combo, accuracy, and `timeSinceLastWarning`.
  - Update `scripts/ci/emit-summary.mjs` to read the aggregated stats and render a table:
    | Scenario | Warnings | Avg Δ | Worst Δ |
  - Optionally expose thresholds (`--warn-max-delta`) to alert when accuracy swings exceed expectations.
- **Testing**
  - Vitest tests for the combo system covering:
    - Accurate delta calculation with floating-point rounding.
    - Buffer reset behavior across waves/combos.
    - Analytics snapshot serialization.
  - CLI/analytics tests verifying CSV + JSON exports include the new fields and maintain deterministic ordering.
- **Docs/playbooks**
  - Update `docs/status/2025-11-14_combo_accuracy_delta.md` with instructions on where to find the analytics output.
  - Add a troubleshooting note to `CODEX_PLAYBOOKS.md` (analytics section) describing how to regenerate combo delta fixtures.
- **Analytics exports**
  - Persist the aggregated values under `analytics.comboWarning` and surface them via `analyticsAggregate.mjs` (`comboWarningCount`, `comboWarningDeltaLast/Avg/Min/Max`, `comboWarningHistory`) so dashboards ingest the metrics without parsing JSON.

## Deliverables & Artifacts

- Combo system + analytics updates with unit tests.
- Updated fixtures (`docs/codex_pack/fixtures/gold-summary.json` or new combo-specific fixtures).
- CI summary output referencing the new metrics.
- Documentation updates (status note, analytics schema, playbook).

## Acceptance criteria

- Analytics artifacts include combo warning accuracy deltas.
- CI summary surfaces the metric per run.
- Tests cover analytics snapshot changes.

## Verification

- npm run lint
- npm run test
- npm run codex:validate-pack
- npm run codex:validate-links
- npm run codex:status
- Run analytics CLI on a fixture with combo warnings to confirm the fields populate.
