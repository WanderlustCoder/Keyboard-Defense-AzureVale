# Tutorial Replay/Skip Soak Test - 2025-12-07
> Note: This document targets the retired web version (`apps/keyboard-defense`). The current Godot project lives at `apps/keyboard-defense-godot`; see `docs/GODOT_PROJECT.md` and `apps/keyboard-defense-godot/README.md` for active workflows.

## Summary
- Added a soak test that alternates tutorial completion writes and skip-driven clears to validate persistence stability under rapid replay/skip cycles.
- Confirms version integrity: mismatched versions do not count as completion, while the active version still reads true when written last.
- Tracks storage operation counts to ensure repeated reads/writes/clears do not throw or leave storage in an inconsistent state.
- Backlog #98 is now covered by automated persistence validation.

## Verification
- `cd apps/keyboard-defense && npx vitest run tutorialReplaySkipSoak.test.js`

## Related Work
- `apps/keyboard-defense/tests/tutorialReplaySkipSoak.test.js`
- `apps/keyboard-defense/public/dist/src/tutorial/tutorialPersistence.js`
- Backlog #98

