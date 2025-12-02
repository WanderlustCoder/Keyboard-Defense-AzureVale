# Evacuation Event – Slice 1 (2025-12-02)

## What shipped
- Added `featureToggles.evacuationEvents` (default on, gated by `dynamicSpawns`) and a new enemy tier `evac-transport` (long words, zero damage, bonus reward).
- Wave-level scheduling: per-wave deterministic RNG picks a mid-wave time and lane (waves ≥2, duration >12s). On trigger, spawns a transport with a long-form word and a countdown.
- Runtime state for evacuation attempts, success, and failure with new events: `evac:start`, `evac:complete`, `evac:fail`.
- Countdown resolution: success when the transport is destroyed/typed; failure when the timer expires (transport despawns). Analytics track attempts/success/failure counts.

## Files touched
- `src/core/config.ts` – new toggle, new `evac-transport` tier.
- `src/core/types.ts`, `src/core/gameState.ts`, `src/core/events.ts` – evacuation state/analytics and events.
- `src/engine/gameEngine.ts` – scheduling, spawn hook, timer handling, and event emissions.
- `tests/evacuationEvent.test.js` – deterministic scheduling plus success/failure coverage.

## How to exercise
- Run `npx vitest tests/evacuationEvent.test.js --run` for automated coverage.
- In-game with toggles on: play wave 2+; expect a mid-wave transport spawning with a long word and a countdown banner (event hooks ready; HUD surface TBD). Toggling `evacuationEvents` or `dynamicSpawns` off removes the scheduling.

## Next slices (per slicing doc)
- HUD/flow polish ✅ now added: HUD banner with timer/progress, reward (+80g) and penalty (-40g) applied via engine and HUD messaging.
- Coexistence/balance: lane reservation with hazards/affixes, reduced-motion visuals, optional penalties on failure.
