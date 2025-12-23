# Victory/Defeat Stingers - 2025-12-08
> Note: This document targets the retired web version (`apps/keyboard-defense`). The current Godot project lives at `apps/keyboard-defense-godot`; see `docs/GODOT_PROJECT.md` and `apps/keyboard-defense-godot/README.md` for active workflows.

## Summary
- Added lightweight WebAudio stingers for victory and defeat: poly-chord bursts that fade in/out and respect global volume/intensity/mute.
- GameController now tracks game status transitions and triggers stingers once per transition; ambient tracks continue to run until muted.
- SoundManager handles stinger buffers with intensity scaling and coexists with existing ambient pads.

## Verification
- `cd apps/keyboard-defense && npx vitest run ambientProfiles.test.js`

## Related Work
- `apps/keyboard-defense/src/audio/soundManager.ts`
- `apps/keyboard-defense/src/controller/gameController.ts`
- Backlog #90

