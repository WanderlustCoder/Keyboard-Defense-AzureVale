# Castle Visual Morphing - 2025-12-07

## Summary
- Castle levels now carry visual palettes (fill/border/accent) and the renderer swaps colors based on the current level, giving a distinct look as the keep upgrades.
- Added palette resolver helper and tests to ensure distinct palettes per level with a safe fallback when missing.
- Backlog #67 is covered at a baseline; future work can swap in sprite frames once assets land.

## Verification
- `cd apps/keyboard-defense && npx vitest run castleVisuals.test.js`

## Related Work
- `apps/keyboard-defense/src/core/config.ts` (castle level visuals)
- `apps/keyboard-defense/src/rendering/castlePalette.ts`
- `apps/keyboard-defense/src/rendering/canvasRenderer.ts`
- `apps/keyboard-defense/tests/castleVisuals.test.js`
- Backlog #67
