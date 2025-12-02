# Visual Regression Harness - 2025-12-07

## Summary
- Playwright visual project (`tests/visual`) now serves as the HUD layout regression harness with baselines for `hud-main`, `options overlay`, `tutorial summary`, and `wave scorecard` captured via `toHaveScreenshot`.
- Deterministic setup uses the debug API to seed gold/turrets/enemies, pauses gameplay, disables animations, and relies on the dev server webServer hook in `playwright.config.ts`.
- Commands:
  - `npm run test:visual` — run against existing baselines.
  - `npm run test:visual:update` — refresh baselines after intentional UI changes.
- Baselines live under `tests/visual/hud.spec.ts-snapshots/`; viewport 1280x720 defaults to keep shots consistent.

## Verification
- `cd apps/keyboard-defense && npm run test:visual` (requires Playwright browsers installed)

## Related Work
- `apps/keyboard-defense/tests/visual/hud.spec.ts`
- `apps/keyboard-defense/tests/visual/utils.ts`
- `apps/keyboard-defense/playwright.config.ts`
- Backlog #94
