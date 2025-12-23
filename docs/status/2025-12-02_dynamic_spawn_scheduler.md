# Dynamic Spawn Scheduler (Backlog #35)
> Note: This document targets the retired web version (`apps/keyboard-defense`). The current Godot project lives at `apps/keyboard-defense-godot`; see `docs/GODOT_PROJECT.md` and `apps/keyboard-defense-godot/README.md` for active workflows.

## Summary
- Added a lightweight dynamic spawn scheduler gated by `featureToggles.dynamicSpawns` (on by default).
- Each wave now rolls 1–3 micro-events (skirmish, gold-runner, shield-carrier) using deterministic RNG per wave; events are inserted mid-wave without disrupting base schedules.
- Upcoming spawns preview now surfaces these injections (order ≥ 1000) so planning/diagnostics remain predictable.

## Technical Notes
- Scheduler seeds per wave via `PRNG(seed ^ waveIndex*0x9e3779b1)`; events sorted by time with unique `order` offset.
- Dynamic events spawn through the existing pipeline; shield carriers add small barriers, gold-runners reuse runner tier with a taunt cue.
- Disabled cleanly when `featureToggles.dynamicSpawns` is false.

## Next Steps
- Pipe dynamic event metadata into diagnostics overlay and roadmap for better visibility.
- Consider reward bumps for gold-runners and analytics counters for injected events.

