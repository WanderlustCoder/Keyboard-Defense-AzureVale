# Keyboard Navigation Focus Traps - 2025-12-11
> Note: This document targets the retired web version (`apps/keyboard-defense`). The current Godot project lives at `apps/keyboard-defense-godot`; see `docs/GODOT_PROJECT.md` and `apps/keyboard-defense-godot/README.md` for active workflows.

## Summary
- Added focus traps to the Options overlay, Season Roadmap overlay, Shortcut reference overlay, and Wave Scorecard so Tab/Shift+Tab cycle within the dialog instead of escaping to the page.
- Overlays now auto-focus their primary action (resume/close/continue) while remaining keyboard navigable with existing focus-visible outlines.
- Marked Season 3 backlog item 66 (fully keyboard-navigable menus with clear focus outlines) as Done.

## Verification
- `cd apps/keyboard-defense && npm run lint && npm run build:dist`
- Manual: open Options (pause), Roadmap, Shortcuts, and Wave Scorecard; press Tab/Shift+Tab and confirm focus stays inside and wraps from last to first (and vice versa) until the dialog closes.

## Related Work
- apps/keyboard-defense/src/ui/hud.ts
- apps/keyboard-defense/public/dist/src/systems/typingSystem.js
- apps/keyboard-defense/docs/season3_backlog_status.md

