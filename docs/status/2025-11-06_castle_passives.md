# Castle Passive Buffs - 2025-11-06

## Context
- Backlog **#30** called for surfacing castle passive buffs (regen/armor/gold) that unlock at higher levels.
- Prior builds updated stats internally but offered no clear in-game visibility or automation signal when passives came online.

## Summary
- Added `CastleState.passives` derived from `castleLevels`, stored on game state and updated during castle upgrades.
- Emitted `castle:passive-unlocked` events whenever regen/armor/gold bonuses increase; HUD log and castle status now announce new passives.
- Options overlay and HUD castle panel now list active passives with concise formatting (regen HP/s, armor, gold bonus).
- HUD + options overlay now render dedicated regen/armor/gold icons (SVG) with accessible labels so players can scan buffs at a glance, even in condensed layouts.
- Tutorial now pauses after the castle upgrade to call out the newest passive, highlights the HUD entry, and emits `tutorial.passiveAnnounced` telemetry so onboarding signals awareness.
- Introduced `deriveCastlePassives` helper and wired diagnostics/tests so automation can assert passive unlocks.
- `season1_backlog_status.md` updated to mark item **#30** Done.

## Next Steps
- Complete (passive analytics exports now land via `analyticsAggregate --passive-summary`).
