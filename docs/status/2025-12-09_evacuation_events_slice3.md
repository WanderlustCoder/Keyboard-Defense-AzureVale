# Evacuation Events - Slice 3 (2025-12-09)
> Note: This document targets the retired web version (`apps/keyboard-defense`). The current Godot project lives at `apps/keyboard-defense-godot`; see `docs/GODOT_PROJECT.md` and `apps/keyboard-defense-godot/README.md` for active workflows.

## What shipped
- Evacuation scheduling now respects lane reservation: the event avoids lanes already booked for hazards or dynamic spawns and skips entirely when every lane is occupied, preventing double-booked events.
- Dynamic/hazard windows are considered during scheduling to keep one special event per lane at a time, improving balance and readability for designers and QA.

## How to use
- Keep `featureToggles.dynamicSpawns` and `evacuationEvents` enabled (default). Evac transports will pick a lane/time window that does not conflict with hazards or dynamic events; if no lane is free, the evacuation is skipped for that wave.
- Existing HUD banner/reward/penalty behavior is unchanged.

## Verification
- `cd apps/keyboard-defense && npx vitest run evacuationEvent`

## Backlog
- #36 Evacuation Event (Slice 3 complete)

