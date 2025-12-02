# Wave-Themed Word Banks - 2025-12-08

## Summary
- Introduced wave-specific vocab packs layered onto the base and lane vocabularies: scouts/ambush terms for Wave 1, shield/brute themes for Wave 2, and archivist/arcane terms for Wave 3.
- EnemySystem now merges wave vocab (and wave lane vocab) into word buckets, preventing repeats while honoring tier word-length constraints.
- Added tests to lock wave vocab presence and ensure boss wave words are selectable.

## Verification
- `cd apps/keyboard-defense && npx vitest run waveWordBank.test.js`

## Related Work
- `apps/keyboard-defense/src/core/wordBank.ts`
- `apps/keyboard-defense/public/dist/src/systems/enemySystem.js`
- `apps/keyboard-defense/tests/waveWordBank.test.js`
- Backlog #89
