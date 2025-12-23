> Note: This document targets the retired web version (`apps/keyboard-defense`). The current Godot project lives at `apps/keyboard-defense-godot`; see `docs/GODOT_PROJECT.md` and `apps/keyboard-defense-godot/README.md` for active workflows.

## Combo Warning Accuracy Delta - 2025-11-14

**Summary**
- Added an `Accuracy delta` badge under the combo counter that appears whenever the combo warning timer is active. It compares the current typing accuracy to the last stable (non-warning) value so players immediately see if they are trending up or down before the streak expires.
- Badge text is announced via `aria-live`, adopts success/danger colours for positive/negative deltas, and hides automatically once the warning clears or the combo resets.
- HUD tests now exercise the new element, and the tutorial smoke harness inherits the extra DOM id without additional work.

**Telemetry Refresh (2025-11-21)**
- `GameAnalyticsState.comboWarning` now records every warning: count, last delta, min/max, rolling average (via `deltaSum`), and a capped history with `{ timestamp, waveIndex, comboBefore/After, deltaPercent, durationMs }`.
- `analyticsAggregate.mjs` (and the smoke artifacts/CSV) emit `comboWarningCount`, `comboWarningDeltaLast/Avg/Min/Max`, and `comboWarningHistory`, while `scripts/ci/emit-summary.mjs` renders the same stats so CI shows warning counts plus worst deltas per run. *(Codex: `docs/codex_pack/tasks/26-combo-accuracy-analytics.md`)*
- Vitest coverage (`tests/comboWarningAnalytics.test.js`) drives the engine to trigger warnings and confirms telemetry (`combat.comboWarningDelta`) is queued with the expected combo/accuracy metadata.

**Next Steps**
1. Surface the new warning metrics on the Codex/static dashboards once those cards are scoped (future Codex task TBD).
