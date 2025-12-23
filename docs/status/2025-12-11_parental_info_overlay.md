# Parental Info Overlay - 2025-12-11
> Note: This document targets the retired web version (`apps/keyboard-defense`). The current Godot project lives at `apps/keyboard-defense-godot`; see `docs/GODOT_PROJECT.md` and `apps/keyboard-defense-godot/README.md` for active workflows.

## Summary
- Added a Parental Info dialog in the pause/options menu with clear guardrails: no accounts or ads, progress stays local, telemetry is opt-in/off by default, exports are manual, and language is kid-safe.
- Overlay is keyboard-trapped, announced as a dialog, and auto-focuses its close control for quick dismissal.
- Season 2 backlog item 74 (parental info screen) marked Done.

## Verification
- `cd apps/keyboard-defense && npm run lint && npm run build:dist`
- Open the pause/options menu → click “Parental Info”; Tab/Shift+Tab should cycle within the dialog, and closing should return focus to the triggering button.

## Related Work
- apps/keyboard-defense/public/index.html
- apps/keyboard-defense/public/styles.css
- apps/keyboard-defense/src/ui/hud.ts
- apps/keyboard-defense/docs/season2_backlog_status.md

