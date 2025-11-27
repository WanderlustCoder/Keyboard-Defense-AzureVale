## Enemy Taunts & Wave Preview Callouts - 2025-11-19

**Summary**
- Added optional `taunt` metadata to wave spawns plus tier-level taunt pools (brutes/witches) so special deployments can announce themselves without hard-coding copy in the HUD.
- Wave scheduling now threads the taunt string all the way into `EnemyState`, and the engine keeps the value alive so downstream consumers (analytics, HUD, debug hooks) can react deterministically.
- `GameController` listens for `enemy:spawned` events, logs the taunt with lane + tier context, and feeds the text into a new `HudView.announceEnemyTaunt` helper that reuses the wave-preview hint region.
- The HUD surfaces taunts for ~5 seconds when the hint slot is available, respects tutorial pinning (falls back to the castle message ribbon), and gained targeted tests so condensed viewports keep working.
- Wave 2 shielded brutes and wave 3 witches/brutes now ship bespoke taunts, while tier-level pools give the system something to say when future waves opt in without adding per-spawn copy.
- Analytics snapshots now record the latest taunt details (text, lane, wave, timestamp, counts) and `hudScreenshots` metadata includes the active taunt badge, so CI dashboards and galleries can flag captures that occur during special callouts without spelunking raw JSON.
- Episode 1 now has a dedicated taunt catalog (`apps/keyboard-defense/docs/taunts/catalog.json`) plus a validator CLI (`npm run taunts:validate`). The catalog feeds new tier pools and wave spawns (shield affixes, vanguard elites, Archivist Lyra) so HUD logs/analytics see stable taunt IDs instead of ad-hoc copy.

**Next Steps**
1. Wire the new catalog validator into nightly/PR automation so taunt additions fail CI when metadata drifts.
2. Add a "Taunt spotlight" panel to the Codex dashboard so reviewers can see the most recent taunt per scenario alongside the screenshot metadata. (Future automation task.)
