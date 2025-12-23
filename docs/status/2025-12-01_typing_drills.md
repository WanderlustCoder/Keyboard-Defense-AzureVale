# Typing Drills Overlay - 2025-12-01
> Note: This document targets the retired web version (`apps/keyboard-defense`). The current Godot project lives at `apps/keyboard-defense-godot`; see `docs/GODOT_PROJECT.md` and `apps/keyboard-defense-godot/README.md` for active workflows.

## Summary
- Added a three-mode typing drills overlay (Burst Warmup, Endurance, Shield Breaker) that opens from the HUD CTA, options overlay, or main menu, pausing the run safely and resuming when closed.
- Drill completions now record analytics entries (`analytics.typingDrills`) with mode/source, accuracy, WPM, best combo, words cleared, errors, and timestamps, and surface a brief HUD log + debug analytics pills.
- Telemetry envelopes fire on drill start/complete (`typing-drill.started` / `typing-drill.completed`) including mode/source and accuracy/WPM rollups so dashboards/portal tiles can ingest drill usage.
- Added a recommended-drill quickstart: `Shift + R` opens and auto-runs the suggested mode, and the overlay surfaces a “Run it” CTA plus a shortcut reminder inline.
- Updated the analytics schema, docs, and `analyticsAggregate` export to include typing drill columns (count/last/historical string) with refreshed tests so downstream dashboards can ingest the new metrics.

## Next Steps
1. Add responsive polish (condensed/mobile layout) and a “recommended drill” hint based on recent accuracy dips or combo breaks.
2. Consider a quick shortcut to launch drills while paused without stacking overlays.
3. Thread the telemetry envelopes into the Codex dashboard/portal tiles once a backend consumer exists.

## Follow-up
- `docs/codex_pack/tasks/42-typing-drills-overlay.md`
- `apps/keyboard-defense/scripts/analyticsAggregate.mjs`
- `docs/analytics_schema.md`

