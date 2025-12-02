# Episode 1 Boss Mechanics – Archivist (2025-12-02)

## What shipped
- Added a `featureToggles.bossMechanics` gate (default **on**). Archivist spawns on wave 3 with bespoke scripting instead of a vanilla elite.
- Boss runtime now has segmented shields (3x75 HP) that **rotate every ~9s** (6s after phase shift). Each rotation refreshes the segment and opens a 3.5s vulnerability window (1.35x damage).
- Periodic **shockwave** (10s cadence, then 7.5s) slows turrets on the boss lane to 65% fire-rate for 3.5s without touching hazards/affixes.
- Phase shift at ~50% HP: removes lingering shields, shortens rotation cadence, extends the current vulnerability window, and emits a phase banner event.
- Boss analytics: wave summaries now include `bossEvents`, `bossPhase`, `bossActive`, and `bossLane`. Event bus emits `boss:intro`, `boss:phase`, `boss:shield-rotated`, `boss:vulnerability`, and `boss:shockwave` for HUD/debug wiring.

## Files touched
- `src/core/config.ts` – new `bossMechanics` toggle; boss spawn shield tuned to 90.
- `src/core/types.ts`, `src/core/gameState.ts`, `src/core/events.ts` – boss runtime/analytics types + defaults and events.
- `src/engine/gameEngine.ts` – boss state machine (spawn hook, rotation, vulnerability, shockwave, phase shift, analytics).
- `public/dist/src/systems/enemySystem.js` – boss vulnerability multiplier applied to shield/health damage.
- `public/dist/src/systems/turretSystem.js` – boss shockwave lane slow affects fire-rate resolution.
- `tests/bossMechanics.test.js` – coverage for intro activation, vulnerability damage multiplier, and lane slow.

## How to exercise
- Run `npm run test -- --run tests/bossMechanics.test.js` (or `npx vitest tests/bossMechanics.test.js --run`) for the new cases.
- In-game: play to wave 3 (or spawn archivist via `spawnEnemy`) with `bossMechanics` enabled. Watch for rotating shield pips, vulnerability timing, and lane slow cadence. Disable via feature toggle to revert to vanilla boss stats.

## Next follow-ups
- HUD polish: segmented boss bar, vulnerability/shockwave banners, and debug skip-to-phase control.
- Optional boss-only taunt cadence per phase for narrative hooks.
