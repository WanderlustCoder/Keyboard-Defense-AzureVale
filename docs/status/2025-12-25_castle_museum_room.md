> Note: This document targets the retired web version (`apps/keyboard-defense`). The current Godot project lives at `apps/keyboard-defense-godot`; see `docs/GODOT_PROJECT.md` and `apps/keyboard-defense-godot/README.md` for active workflows.

## 2025-12-25 — Castle Museum room (Season 4 backlog #71)

### What changed
- Added a Castle Museum panel to the HUD plus a full overlay listing unlocked skins, reward artifacts, companion moods, lore scrolls, lesson medals, mastery certificates, and practice archives.
- Museum entries auto-populate from existing progress (season rewards, medals, scrolls, certificates) and adapt their locked/unlocked state dynamically.
- Options menu and HUD panel both open the overlay; includes focus management and reduced-motion-friendly styling.

### Verification
- Ran `npm test` (full suite) after wiring museum overlay/panel logic and HUD test coverage.
- Manual HUD test asserts museum overlay visibility and entry rendering.

