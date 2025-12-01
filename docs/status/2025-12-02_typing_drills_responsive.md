# Typing Drills HUD CTA & Responsive Layout - 2025-12-02

## Summary
- HUD CTA now surfaces the recommended typing drill inline, with aria labels/tooltips fed by the live heuristic so players see the suggested mode without opening the overlay.
- Main menu now mirrors the recommendation under the Typing Drills button so players can pick the suggested mode before launching a session.
- Condensed layout now emits a brief pulse animation when it switches, calling attention to the stacked/mobile arrangement.
- Drills overlay is viewport-aware: it collapses into a stacked column when height < 760px or width < 960px, hides art on very small screens, and widens primary/ghost buttons for touch comfort.
- Recommendation badges inside the overlay use cleaner copy, and the container height is capped with scrolling to keep controls reachable on short windows.

## Next Steps
1. Track analytics for main-menu "Run Recommended Drill" usage and compare against HUD CTA to tune placement.
2. Add a slim toast/banner when no recommendation is available (e.g., "You’re in the groove—pick any drill").
3. Wire a quick fallback that opens drills in burst mode if the recommendation cannot be computed (offline/edge state).

## Related Work
- `apps/keyboard-defense/public/styles.css`
- `apps/keyboard-defense/src/ui/typingDrills.ts`
