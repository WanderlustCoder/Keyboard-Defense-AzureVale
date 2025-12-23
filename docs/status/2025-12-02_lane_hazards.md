# Lane Hazards - Fog & Storm (Backlog #37)
> Note: This document targets the retired web version (`apps/keyboard-defense`). The current Godot project lives at `apps/keyboard-defense-godot`; see `docs/GODOT_PROJECT.md` and `apps/keyboard-defense-godot/README.md` for active workflows.

## Summary
- Added deterministic lane hazards (fog/storm) gated by `featureToggles.dynamicSpawns` (on by default).
- Hazards roll each wave (from wave 2+) with seeded timing, lane, and kind; hazards reduce turret fire-rate when active (storm) and show HUD messaging when they begin/end.
- Wave preview respects injected dynamic events; hazards do not spawn enemies but overlay lane state and persist for a short, deterministic duration.

## Technical Notes
- Hazards are scheduled per wave via PRNG(seed ^ waveIndex*0x9e3779b1), stored in `GameEngine` and materialized into `state.laneHazards` with ticking lifetimes.
- `TurretSystem.resolveLaneFireRateMultiplier` now applies lane hazard multipliers in addition to affixes/effects.
- Events emit `hazard:started`/`hazard:ended` for future UI/analytics wiring; current HUD logs castle messages.

## Next Steps
- Add lane overlay visuals and diagnostics panel badges for active hazards.
- Track hazard analytics (uptime, affected lanes) and surface in roadmap/scorecards.

