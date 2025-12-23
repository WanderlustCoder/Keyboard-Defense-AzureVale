# HUD Font Shortcuts & Diagnostics - 2025-12-06
> Note: This document targets the retired web version (`apps/keyboard-defense`). The current Godot project lives at `apps/keyboard-defense-godot`; see `docs/GODOT_PROJECT.md` and `apps/keyboard-defense-godot/README.md` for active workflows.

## Summary
- Diagnostics overlay now surfaces the active HUD font size with preset labels (Default/Large/etc.) so accessibility regressions are easy to spot in-session.
- The options overlay adds `[` / `]` shortcuts while open to cycle font size presets without leaving the keyboard; each change still persists and logs to the HUD feed.
- HUD options now include an inline hint reminding players of the `[` / `]` shortcut next to the font size selector.

## Verification
- `cd apps/keyboard-defense && npx vitest run diagnostics.test.js fontScale.test.js`

## Related Work
- `apps/keyboard-defense/src/controller/gameController.ts` (keyboard shortcut routing, font scale persistence)
- `apps/keyboard-defense/src/ui/diagnostics.ts` (HUD font scale line item)
- `apps/keyboard-defense/src/ui/fontScale.ts` (shared preset helpers)

