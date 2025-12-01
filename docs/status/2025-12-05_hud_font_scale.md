# HUD Font Scale Options - 2025-12-05

## Summary
- HUD/options overlay now ships a HUD Font Size select with Small (0.85x), Default (1x), Large (1.15x), and Extra Large (1.3x) presets wired to the `hudFontScale` setting.
- Selection persists via player settings, updates the CSS `--hud-font-scale` var in real time, and logs the change in the HUD event feed for quick confirmation.
- Existing tests cover HUD option wiring and state sync; no gameplay changes required beyond the scaling multiplier.

## Next Steps
1. Consider surfacing the selected font size in the diagnostics overlay for debugging accessibility regressions.
2. Add a quick keyboard shortcut to cycle font sizes when the options overlay is open.

## Related Work
- `apps/keyboard-defense/public/index.html` (font scale select)
- `src/controller/gameController.ts` (`setHudFontScale`, persistence)
- `tests/hud.test.js`
