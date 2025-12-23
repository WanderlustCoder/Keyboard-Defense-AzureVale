# HUD Font Scale Options - 2025-12-05
> Note: This document targets the retired web version (`apps/keyboard-defense`). The current Godot project lives at `apps/keyboard-defense-godot`; see `docs/GODOT_PROJECT.md` and `apps/keyboard-defense-godot/README.md` for active workflows.

## Summary
- HUD/options overlay now ships a HUD Font Size select with Small (0.85x), Default (1x), Large (1.15x), and Extra Large (1.3x) presets wired to the `hudFontScale` setting.
- Selection persists via player settings, updates the CSS `--hud-font-scale` var in real time, and logs the change in the HUD event feed for quick confirmation.
- Existing tests cover HUD option wiring and state sync; no gameplay changes required beyond the scaling multiplier.

## Next Steps
1. Add a small hint in the options overlay to teach the new `[` / `]` font size shortcut.
2. Evaluate allowing the font-size shortcut outside the options overlay for rapid adjustments during playtests.

## Related Work
- `apps/keyboard-defense/public/index.html` (font scale select)
- `src/controller/gameController.ts` (`setHudFontScale`, persistence)
- `tests/hud.test.js`

