# Lore Codex Entries - 2025-12-07

## Summary
- Added lore codex catalog (`apps/keyboard-defense/docs/lore/codex.json`) with wave-based unlocks for Episode 1.
- Lore module (`src/data/lore.ts`) exposes entries plus stage-based filtering; persistence helper (`src/utils/lorePersistence.ts`) stores unlocked ids in localStorage.
- GameController unlocks lore after each wave summary and logs codex unlocks in the HUD; tests validate catalog shape and persistence.

## Verification
- `cd apps/keyboard-defense && npx vitest tests/lorePersistence.test.js tests/dialogueCatalog.test.js`

## Related Work
- `apps/keyboard-defense/docs/lore/codex.json`
- `apps/keyboard-defense/src/data/lore.ts`
- `apps/keyboard-defense/src/utils/lorePersistence.ts`
- `apps/keyboard-defense/src/controller/gameController.ts` (unlock hook)
- `apps/keyboard-defense/tests/lorePersistence.test.js`
- Backlog #84
