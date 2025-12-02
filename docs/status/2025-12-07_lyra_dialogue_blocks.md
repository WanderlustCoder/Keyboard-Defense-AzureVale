# Archivist Lyra Dialogue Blocks - 2025-12-07

## Summary
- Added Episode 1 dialogue catalog for Archivist Lyra (intro, phase shift, pressure call, breach warning, finale, retreat) under `apps/keyboard-defense/docs/dialogue/lyra.json`.
- New runtime-facing helper (`src/data/dialogue.ts`) exposes ids/stages and speaker metadata; future UI/boss scripting can pull lines by stage.
- Tests validate catalog shape, stage filters, and unique ids.

## Verification
- `cd apps/keyboard-defense && npx vitest tests/dialogueCatalog.test.js`

## Related Work
- `apps/keyboard-defense/docs/dialogue/lyra.json`
- `apps/keyboard-defense/src/data/dialogue.ts`
- `apps/keyboard-defense/tests/dialogueCatalog.test.js`
- Backlog #83
