> Note: This document targets the retired web version (`apps/keyboard-defense`). The current Godot project lives at `apps/keyboard-defense-godot`; see `docs/GODOT_PROJECT.md` and `apps/keyboard-defense-godot/README.md` for active workflows.

## 2025-12-26 - Side-mission quest log (Season 4 backlog #72)

### What changed
- Added a Side Quest HUD panel with a quick summary of active vs completed quests and a CTA to the overlay.
- Built a side-quest overlay that lists narrative quests (lessons completed, Gold/Platinum medal earned, lore scroll unlocked, practice drills played) with status pills, progress bars, and an options-menu shortcut.
- Overlay and panel reuse existing progress sources (lessons, medals, scrolls, drills), honor focus trapping/aria-hidden toggles, and work from both the HUD button and the options button.

### Verification
- Ran `npx vitest run tests/hud.test.js` to cover HUD behavior including the side-quest overlay render/toggle path.

