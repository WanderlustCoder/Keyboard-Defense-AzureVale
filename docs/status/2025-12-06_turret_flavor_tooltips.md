# Turret Flavor Tooltips - 2025-12-06
> Note: This document targets the retired web version (`apps/keyboard-defense`). The current Godot project lives at `apps/keyboard-defense-godot`; see `docs/GODOT_PROJECT.md` and `apps/keyboard-defense-godot/README.md` for active workflows.

## Summary
- Added flavor blurbs to Arrow, Arcane, Flame, and Crystal Pulse turrets and surfaced them in the HUD selector/status tooltips to give players narrative texture while choosing defenses.
- Slot controls and action buttons now expose the turret flavor/description via titles so hover/focus surfaces context without changing existing status copy.

## Verification
- `cd apps/keyboard-defense && npx vitest run hud.test.js`

## Related Work
- `apps/keyboard-defense/src/core/config.ts` (turret flavor text)
- `apps/keyboard-defense/src/ui/hud.ts` (tooltip wiring)
- `apps/keyboard-defense/tests/hud.test.js`
- Backlog #85

