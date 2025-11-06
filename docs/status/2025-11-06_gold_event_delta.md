# Gold Event Delta & Timestamp - 2025-11-06

## Context
- Economy visibility was limited to raw gold totals; downstream tooling had to diff values manually.
- Tutorial automation (waveSim, castle breach drill) and HUD overlays benefit from consistent delta metadata for regression analysis.

## Summary
- `resources:gold` events now attach `{ delta, timestamp }`, with `GameEngine.grantGold` enforcing non-negative totals and emitting the new payload.
- Castle rewards, perfect-word bonuses, turret placements/upgrades/downgrades, presets, and castle repairs all funnel through the enriched event.
- HUD gold delta flashes reuse the computed delta, while analytics/startGold bookkeeping remains unchanged.
- Added defensive guards so negative or non-finite gold grants are ignored instead of corrupting state.

## Follow-ups
1. Surface gold delta streams in diagnostics overlay and debug telemetry dashboards.
2. Persist per-wave delta aggregates so analytics exports can plot economy swings directly.
3. Consider exposing the timestamped events via tutorial smoke artifacts for future economy regression charts.
