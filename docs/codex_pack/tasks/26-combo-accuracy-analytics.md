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
