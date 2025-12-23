# Caps Lock Warning - 2025-12-10
> Note: This document targets the retired web version (`apps/keyboard-defense`). The current Godot project lives at `apps/keyboard-defense-godot`; see `docs/GODOT_PROJECT.md` and `apps/keyboard-defense-godot/README.md` for active workflows.

## Summary
- Added a caps-lock warning under the typing input. It listens for `getModifierState("CapsLock")` on keydown/keyup and shows a small, contrasty banner to remind players (ages 8–16) when caps is enabled.
- The warning is aria-live polite and auto-hides on focus/blur, keeping the HUD clear once caps is off.

## Verification
- `cd apps/keyboard-defense && npm run serve:open` then toggle Caps Lock while focusing the typing input; warning should appear/disappear instantly.

## Related Work
- `apps/keyboard-defense/public/index.html`
- `apps/keyboard-defense/public/styles.css`
- `apps/keyboard-defense/src/controller/gameController.ts`
- `apps/keyboard-defense/src/ui/hud.ts`

