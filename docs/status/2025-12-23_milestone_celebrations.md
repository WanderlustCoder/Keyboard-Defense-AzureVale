> Note: This document targets the retired web version (`apps/keyboard-defense`). The current Godot project lives at `apps/keyboard-defense-godot`; see `docs/GODOT_PROJECT.md` and `apps/keyboard-defense-godot/README.md` for active workflows.

## 2025-12-23 — Milestone celebrations (Season 4 backlog #69)

### What changed
- Added a reduced-motion-safe milestone celebration banner that highlights big moments (lesson milestones and Gold/Platinum medal wins) without breaking accessibility.
- Celebration includes a subtle spotlight/firework treatment for regular motion users and a calm static glow when Reduced Motion is enabled.
- Hooks fire automatically when lesson counts hit 5/10/20/30/50/75/100 or when a Gold/Platinum medal is earned; mastery certificates with 95%+ accuracy also celebrate.

### Verification
- Ran `npm test` (full suite) after adding the celebration overlay logic and HUD hooks.
- Manually exercised HUD overlay toggles in tests to confirm visibility toggles and reduced-motion guards.

