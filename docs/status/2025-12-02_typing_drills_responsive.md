# Typing Drills HUD CTA & Responsive Layout - 2025-12-02

## Summary
- HUD CTA now surfaces the recommended typing drill inline, with aria labels/tooltips fed by the live heuristic so players see the suggested mode without opening the overlay.
- Drills overlay is viewport-aware: it collapses into a stacked column when height < 760px or width < 960px, hides art on very small screens, and widens primary/ghost buttons for touch comfort.
- Recommendation badges inside the overlay use cleaner copy, and the container height is capped with scrolling to keep controls reachable on short windows.

## Next Steps
1. Add an explicit “Tap to focus input” hint for mobile users when the drills overlay opens in condensed mode.
2. Consider moving the recommended CTA into the main menu as well, showing the current suggestion before launching the drills overlay.
3. Add visual feedback for window resize (e.g., gentle fade) when the layout toggles condensed mode mid-session.

## Related Work
- `apps/keyboard-defense/public/styles.css`
- `apps/keyboard-defense/src/ui/typingDrills.ts`
