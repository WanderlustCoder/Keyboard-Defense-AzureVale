# Enemy Biographies in Wave Preview - 2025-12-08

## Summary
- Added Season 1 bestiary catalog (`apps/keyboard-defense/docs/enemies/bestiary.json`) and loader (`src/data/bestiary.ts`) to surface narrative dossiers for each enemy tier.
- HUD wave preview now supports selectable rows; selecting an enemy (or auto-selecting the first in view) shows a biography card with role, danger rating, abilities, and tips. Selection is keyboard-accessible and highlighted within the preview.
- Wave preview rows gained hover/focus affordances and the biography card is hidden when no preview entries exist.

## Verification
- `cd apps/keyboard-defense && npx vitest run wavePreviewBiography.test.js`

## Related Work
- `apps/keyboard-defense/public/index.html`
- `apps/keyboard-defense/public/styles.css`
- `apps/keyboard-defense/src/ui/hud.ts`
- `apps/keyboard-defense/src/ui/wavePreview.ts`
- `apps/keyboard-defense/src/data/bestiary.ts`
- `apps/keyboard-defense/tests/wavePreviewBiography.test.js`
- Backlog #87
