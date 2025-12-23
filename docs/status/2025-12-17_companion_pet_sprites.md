> Note: This document targets the retired web version (`apps/keyboard-defense`). The current Godot project lives at `apps/keyboard-defense-godot`; see `docs/GODOT_PROJECT.md` and `apps/keyboard-defense-godot/README.md` for active workflows.

## 2025-12-17 - Companion Pet Sprites

- HUD gains a companion pet panel with a pixel sprite that shifts mood based on live performance: cheering on high accuracy/combos, happy on solid play, concerned when breaches/low health appear.
- Mood text/aria labels update alongside the sprite, and reduced-motion settings automatically soften the animation cadence.
- Tests cover mood transitions and the new DOM wiring; styles reuse castle skin variables so themes tint the pet card.

