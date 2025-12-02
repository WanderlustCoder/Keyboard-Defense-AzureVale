# Visual Regression Harness - 2025-12-07

## Summary
- Playwright visual project (`tests/visual`) now writes baselines under `baselines/visual/visual/<spec>/` via `snapshotPathTemplate`, removing platform suffixes while keeping one folder per spec.
- Baselines cover `hud-main`, `options overlay`, `tutorial summary`, and `wave scorecard` using the debug API to seed gold/turrets/enemies, pause gameplay, and disable animations against a fixed 1280x720 viewport.
- Commands:
  - `npm run test:visual` - run against existing baselines.
  - `npm run test:visual:update` - refresh baselines after intentional UI changes.

## Verification
- `cd apps/keyboard-defense && npm run test:visual` (requires Playwright browsers installed)

## Related Work
- `apps/keyboard-defense/tests/visual/hud.spec.ts`
- `apps/keyboard-defense/tests/visual/utils.ts`
- `apps/keyboard-defense/playwright.config.ts`
- Backlog #94
