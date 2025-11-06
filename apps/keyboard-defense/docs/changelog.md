## Tutorial Wave Preview Highlight

- Combo, placement, and upgrade tutorial steps now surface an on-HUD hint for the upcoming enemies panel, reinforcing how to plan defenses.
- Wave preview adds an accessible tooltip with aria-live messaging so screen readers and automation pick up the guidance whenever the panel is highlighted.
- Pause/options overlay now lists the castle's current gold bonus alongside the exact benefits granted by the next upgrade (HP, regen, armor, slots, and bonus gold).

## Castle Gold Bonus Tracking

- Castle gold bonus now shows up in wave analytics, HUD scorecards, and CSV exports alongside existing objective bonuses.
- Analytics exports/leaderboards gained `castleBonusGold` and `totalCastleBonusGold` columns, keeping downstream tooling in sync with the new passive economy stat.

## Shield Telemetry Enhancements

- Wave HUD now marks shielded enemies with HP badges, lane highlights, and castle warnings.
- Diagnostics overlay surfaces live shield forecasts and damage splits.
- Analytics CSV export adds turret/typing damage, DPS, and shield-break columns.

## Crystal Pulse Turret Toggle

- Crystal Pulse turret archetype added behind a feature toggle with shield-burst damage and renderer assets.
- Pause/options menu, main menu, and debug panel can enable/disable the turret; player settings persist the choice.
- HUD highlights disabled turrets in slots/presets and lists shield bonuses in summaries.
- Projectile system now applies shield bonus damage prior to base damage with analytics coverage.

## Turret Downgrade Debug Mode

- Debug panel adds a turret downgrade toggle that exposes downgrade/refund controls on each turret slot.
- Downgrading refunds the appropriate gold, removes projectiles when clearing a slot, and has automated coverage for removal and level reduction.

## Turret Firing Animations

- Canvas renderer now adds coloured muzzle flashes per archetype whenever a turret fires.
- Animations respect reduced-motion settings and surface alongside impact effects for visual clarity.

## Analytics Leaderboard Export

- Added `analyticsLeaderboard.mjs` CLI plus `npm run analytics:leaderboard` to sort snapshot runs by combo, accuracy, and DPS.
- Outputs CSV or JSON with ranks and core performance stats for fast leaderboard generation.

## Castle Passive Buffs

- Castle upgrades now surface passive buffs (regen, armor, gold bonus) in the HUD and pause/options overlay.
- `castle:passive-unlocked` events drive automation logs/messages so tutorials and diagnostics can react.
- Options overlay lists active passives with totals and deltas, clarifying upgrade impact at a glance.

