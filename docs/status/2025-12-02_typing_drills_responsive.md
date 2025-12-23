# Typing Drills HUD CTA & Responsive Layout - 2025-12-02
> Note: This document targets the retired web version (`apps/keyboard-defense`). The current Godot project lives at `apps/keyboard-defense-godot`; see `docs/GODOT_PROJECT.md` and `apps/keyboard-defense-godot/README.md` for active workflows.

## Summary
- HUD CTA now surfaces the recommended typing drill inline, with aria labels/tooltips fed by the live heuristic so players see the suggested mode without opening the overlay.
- Main menu now mirrors the recommendation under the Typing Drills button so players can pick the suggested mode before launching a session, and the quickstart button falls back to Burst Warmup when no recommendation exists.
- Drills overlay now shows a slim “No recommendation” banner with the fallback copy when the heuristic has no guidance, matching the main-menu wording and logging a brief HUD note when the fallback quickstart triggers.
- Telemetry now captures menu quickstarts via `ui.typingDrill.menuQuickstart`, with schema/docs covering the payload for downstream dashboards.
- Condensed layout now emits a brief pulse animation when it switches, calling attention to the stacked/mobile arrangement.
- Drills overlay is viewport-aware: it collapses into a stacked column when height < 760px or width < 960px, hides art on very small screens, and widens primary/ghost buttons for touch comfort.
- Recommendation badges inside the overlay use cleaner copy, and the container height is capped with scrolling to keep controls reachable on short windows.

## Next Steps
1. Pipe `ui.typingDrill.menuQuickstart` into Codex dashboards/portal tiles to compare menu vs HUD CTA adoption.
2. Surface a quick hint when the fallback Burst Warmup autostarts so players know which mode launched from the menu CTA (now shows an inline “No recommendation available. Starting Burst Warmup.” message).

## Related Work
- `apps/keyboard-defense/public/styles.css`
- `apps/keyboard-defense/src/ui/typingDrills.ts`

