# Visual Baselines (HUD & Overlays)

Playwright visuals guard the HUD, loading screen, options overlay, tutorial summary, wave scorecard, and caps-lock warning. Baselines live under `apps/keyboard-defense/baselines/visual/hud.spec.ts/`.

## Commands
- `npm run test:visual` - run visual assertions against the current dev server (auto-starts with `npm run start` if needed).
- `npm run test:visual:update` - update baselines after intentional UI changes.

## Tips
- Ensure `npm run start` is serving `public/` (the Playwright config starts it automatically in CI).
- Animations are disabled in tests; keep HUD stable (pause the game, set deterministic state via debug API, as in `tests/visual/hud.spec.ts`).
- Dist docs are staged automatically during `npm run build` so Playwright can load lore/taunt/roadmap JSON without 404s.

## Screens Covered
- HUD main state (active wave, turrets placed).
- Options overlay (accessibility/audio controls).
- Tutorial summary and wave scorecard overlays.
- Loading screen with rotating tip.
- Caps-lock warning beneath the typing input.
