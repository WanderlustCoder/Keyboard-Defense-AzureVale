# Practice Dummy Target (Backlog #40)

## Summary
- Added a stationary "practice dummy" enemy tier for turret DPS testing.
- Debug panel now exposes buttons to spawn a dummy (lane B by default) and clear all dummies; console API also supports `keyboardDefense.spawnPracticeDummy(lane)` / `clearPracticeDummies()`.
- Dummy enemies sit mid-lane, never advance or damage the castle, reward 0 gold, and can be typed down or cleared manually.

## Technical Notes
- New tier `dummy` lives in `defaultConfig.enemyTiers` with high health and zero speed/damage/reward.
- EnemySystem clamps dummy speed to 0 and distance ~0.6 so turrets can acquire targets immediately without breach risk.
- GameEngine exposes `removeEnemiesByTier` to clear debug targets; GameController wires UI + debug API.

## Next Steps
- Optionally add HUD badge when a dummy is active and track per-slot DPS accumulation for practice sessions.
