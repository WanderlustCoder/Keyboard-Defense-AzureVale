# Accessibility Self-Test - 2025-12-15
> Note: This document targets the retired web version (`apps/keyboard-defense`). The current Godot project lives at `apps/keyboard-defense-godot`; see `docs/GODOT_PROJECT.md` and `apps/keyboard-defense-godot/README.md` for active workflows.

## Summary
- Added an Accessibility Self-Test card in the Options overlay that plays a chime, visual flash, and motion check (screen shake preview) so players can confirm each cue before enabling effects; motion automatically skips when Reduced Motion is enabled.
- Self-test confirmations for sound/visual/motion and the last run timestamp persist via player settings schema v27 (`accessibilitySelfTest`), with UI indicators disabling when audio or motion are unavailable.
- HUD wiring animates inline indicators and emits callbacks for run/confirm actions, with tests covering UI state plus persistence of the new settings.

## Verification
- `cd apps/keyboard-defense && npm test`
- Manual: open Options, run the Accessibility Self-Test with sound on/off and Reduced Motion toggled to see the skip/disable states; confirm checkboxes persist after reload.

## Related Work
- apps/keyboard-defense/public/index.html
- apps/keyboard-defense/public/styles.css
- apps/keyboard-defense/src/controller/gameController.ts
- apps/keyboard-defense/src/ui/hud.ts
- apps/keyboard-defense/public/dist/src/utils/playerSettings.{js,d.ts}
- apps/keyboard-defense/tests/hud.test.js
- apps/keyboard-defense/tests/playerSettings.test.js
- apps/keyboard-defense/docs/season4_backlog_status.md (#59)
- apps/keyboard-defense/docs/changelog.md

