# Castle Passive Buffs - 2025-11-06

## Context
- Backlog **#30** called for surfacing castle passive buffs (regen/armor/gold) that unlock at higher levels.
- Prior builds updated stats internally but offered no clear in-game visibility or automation signal when passives came online.

## Summary
- Added `CastleState.passives` derived from `castleLevels`, stored on game state and updated during castle upgrades.
- Emitted `castle:passive-unlocked` events whenever regen/armor/gold bonuses increase; HUD log and castle status now announce new passives.
- Options overlay and HUD castle panel now list active passives with concise formatting (regen HP/s, armor, gold bonus).
- Introduced `deriveCastlePassives` helper and wired diagnostics/tests so automation can assert passive unlocks.
- `season1_backlog_status.md` updated to mark item **#30** Done.

## Next Steps
1. Expose passive deltas in analytics exports for economy/balance dashboards.
2. Add visual icons alongside passive entries in the HUD for quick parsing.
3. Extend tutorial messaging to call out passive unlocks during onboarding upgrades.
