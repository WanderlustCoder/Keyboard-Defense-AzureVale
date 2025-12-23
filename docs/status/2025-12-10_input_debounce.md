# Input Debounce / Forgiveness - 2025-12-10
> Note: This document targets the retired web version (`apps/keyboard-defense`). The current Godot project lives at `apps/keyboard-defense-godot`; see `docs/GODOT_PROJECT.md` and `apps/keyboard-defense-godot/README.md` for active workflows.

## Summary
- Added a lightweight debounce in `TypingSystem` to ignore rapid repeats of the same wrong key (within ~12ms) so held/ghost inputs no longer stack errors or wipe buffers, while still allowing fast double-letter progress.
- Tracked last input char/timestamp on the typing state to support the filter.
- Marked Season 2 backlog item 61 (input debounce/forgiveness) as Done and added coverage via `tests/typingFuzz.test.js`.

## Verification
- `cd apps/keyboard-defense && npm test` (pre-commit hook) to ensure the typing fuzz coverage and the new debounce guard pass.
- Manual: hold a wrong key during a wave; errors should not spike or clear buffers repeatedly, and correct double letters remain responsive.

## Related Work
- apps/keyboard-defense/public/dist/src/systems/typingSystem.js
- apps/keyboard-defense/src/core/types.ts
- apps/keyboard-defense/src/core/gameState.ts
- apps/keyboard-defense/tests/typingFuzz.test.js
- apps/keyboard-defense/docs/season2_backlog_status.md

