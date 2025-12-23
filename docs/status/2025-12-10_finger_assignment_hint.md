# Finger Assignment Hint - 2025-12-10
> Note: This document targets the retired web version (`apps/keyboard-defense`). The current Godot project lives at `apps/keyboard-defense-godot`; see `docs/GODOT_PROJECT.md` and `apps/keyboard-defense-godot/README.md` for active workflows.

## Summary
- Added a finger-hint pill beside the typing input that surfaces the recommended finger and key for the next character (or the expected key after an error), announced via an ARIA live region for screen readers.
- Built a QWERTY-based mapping covering letters, numbers, common punctuation, and space/tab/enter, hiding the hint automatically when there is no active word or no reliable mapping.
- Cleared notes in the Season 3 backlog to mark item 65 complete (expanded key hints showing finger assignment per character).

## Verification
- `cd apps/keyboard-defense && npm start` (or `npm run serve:open`), start a wave, and type an enemy word: the pill should show a finger label (e.g., "Left index") and the next key; when you mistype and an expected key is shown, the hint should match that key; when no word is active, the pill hides.

## Related Work
- apps/keyboard-defense/public/index.html
- apps/keyboard-defense/public/styles.css
- apps/keyboard-defense/src/ui/hud.ts
- apps/keyboard-defense/docs/season3_backlog_status.md

