# Castle Visual Morphing - 2025-12-07
> Note: This document targets the retired web version (`apps/keyboard-defense`). The current Godot project lives at `apps/keyboard-defense-godot`; see `docs/GODOT_PROJECT.md` and `apps/keyboard-defense-godot/README.md` for active workflows.

## Summary
- Castle levels now include sprite keys plus visual palettes; renderer swaps level-specific sprites (atlas or fallback SVG) with HP overlay as the keep upgrades.
- GameEngine metrics surface the active castle visual (level + sprite key) and diagnostics overlay displays it to aid QA.
- Added palette/visual resolver helper and tests to ensure distinct palettes and sprite keys per level with safe fallback when missing.
- Backlog #67 is covered; future work can replace fallback SVGs with production art.

## Verification
- `cd apps/keyboard-defense && npx vitest run castleVisuals.test.js`

## Related Work
- `apps/keyboard-defense/src/core/config.ts` (castle level visuals)
- `apps/keyboard-defense/src/rendering/castlePalette.ts`
- `apps/keyboard-defense/src/rendering/canvasRenderer.ts`
- `apps/keyboard-defense/src/engine/gameEngine.ts`
- `apps/keyboard-defense/src/ui/diagnostics.ts`
- `apps/keyboard-defense/tests/castleVisuals.test.js`
- Backlog #67

