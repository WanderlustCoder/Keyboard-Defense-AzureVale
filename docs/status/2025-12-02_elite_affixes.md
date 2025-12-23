# Elite Enemy Affixes - Slow Aura, Shielded, Armored
> Note: This document targets the retired web version (`apps/keyboard-defense`). The current Godot project lives at `apps/keyboard-defense-godot`; see `docs/GODOT_PROJECT.md` and `apps/keyboard-defense-godot/README.md` for active workflows.

## Summary
- Added an elite affix catalog (Frost Aura, Armored, Aegis Shield) gated by the existing `featureToggles.eliteAffixes` flag (default on).
- GameEngine now deterministically decorates eligible elite spawns (brute/witch/vanguard/embermancer/archivist) using a derived seed so wave previews and actual spawns match.
- Enemy spawns apply affix effects: bonus shields, turret damage mitigation, and lane-wide fire-rate slows; shield preview and affix badges now appear in the wave preview with HUD messaging.
- Options/main menu/debug toggles allow enabling/disabling affixes; player settings persist the new flag.

## Notes
- Lane slow aura clamps turret fire rates per-lane (min multiplier 0.2) and stacks by taking the strongest slow.
- Armored applies to turret damage only; typing damage remains unchanged.
- Shield affix injects 35 bonus barrier HP even when a spawn lacked a shield, with analytics guarded.
- Tests cover roll determinism, affix application (shield/armor), and lane slow aggregation.

