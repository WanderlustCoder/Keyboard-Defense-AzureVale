## Enemy Taunts & Wave Preview Callouts - 2025-11-19

**Summary**
- Added optional `taunt` metadata to wave spawns plus tier-level taunt pools (brutes/witches) so special deployments can announce themselves without hard-coding copy in the HUD.
- Wave scheduling now threads the taunt string all the way into `EnemyState`, and the engine keeps the value alive so downstream consumers (analytics, HUD, debug hooks) can react deterministically.
- `GameController` listens for `enemy:spawned` events, logs the taunt with lane + tier context, and feeds the text into a new `HudView.announceEnemyTaunt` helper that reuses the wave-preview hint region.
- The HUD surfaces taunts for ~5 seconds when the hint slot is available, respects tutorial pinning (falls back to the castle message ribbon), and gained targeted tests so condensed viewports keep working.
- Wave 2 shielded brutes and wave 3 witches/brutes now ship bespoke taunts, while tier-level pools give the system something to say when future waves opt in without adding per-spawn copy.

**Next Steps**
1. Broaden the taunt catalog to cover Episode 1 bosses/affixes once those systems land so analytics/tests have richer examples.
2. Consider piping the active taunt into screenshot/analytics metadata so regression galleries can flag when a capture happened during a special wave callout.

