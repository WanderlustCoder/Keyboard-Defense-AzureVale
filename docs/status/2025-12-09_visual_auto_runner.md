# Visual Test Auto-Runner - 2025-12-09

## Summary
- Added `npm run test:visual:auto`, a convenience runner that auto-starts the dev server with `--no-build`, executes the Playwright visual suite, then stops the server unless `--keep-alive` is provided. Extra flags (e.g., `--grep`) pass through to Playwright; `--update` switches to snapshot refresh mode. Host/port overrides are supported (`--host`/`--port`) for remote device captures.
- Documented the workflow in `apps/keyboard-defense/docs/DEVELOPMENT.md` so contributors have a single-command path to run or update the HUD/overlay baselines without manually juggling the server lifecycle.

## Verification
- `cd apps/keyboard-defense && npm run test:visual:auto -- --update --grep hud-main` (dev server auto-starts, runs Playwright, updates `hud-main.png`, and stops afterward).
- `cd apps/keyboard-defense && npm run test:visual:auto -- --host 0.0.0.0 --port 4200 -- --grep options` (capture against a custom bind/port).

## Related Work
- `apps/keyboard-defense/scripts/runVisualTests.mjs`
- `apps/keyboard-defense/tests/visual/hud.spec.ts`
- `apps/keyboard-defense/docs/DEVELOPMENT.md`
