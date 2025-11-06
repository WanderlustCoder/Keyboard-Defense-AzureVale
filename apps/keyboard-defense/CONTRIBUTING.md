# Contributing Guide

This project targets a fully automated delivery pipeline (see `docs/CODEX_AUTONOMOUS_TESTING_DIRECTIVE_Siege_of_the_Azure_Vale.md`). The commands below provide the initial scaffolding; additional tooling (Vitest, Playwright visual regression, StrykerJS) will be layered on top in future iterations.

## Local Workflow

| Command | Purpose |
| --- | --- |
| `node scripts/build.mjs` | Clean + lint + prettier check + compile TypeScript (artifacts under `artifacts/build/`). |
| `npm run lint` | Run ESLint across `src/`, `tests/`, and `scripts/` with zero-warning budget. |
| `npm run format:check` | Verify Prettier formatting without modifying files. |
| `node scripts/unit.mjs` | Run the Vitest unit suite (`vitest run --coverage`). |
| `node scripts/integration.mjs` | Execute `*.integration.test.js` files (skips when none exist). |
| `node scripts/smoke.mjs` | Trigger the tutorial smoke CLI (`--mode skip` by default). |
| `node scripts/e2e.mjs` | Start the dev server, run tutorial & campaign smokes, and archive artifacts. |
| `node scripts/tutorialSmoke.mjs --mode full` | Full tutorial playback via Playwright (existing workflow). |
| `node scripts/seed.mjs` | Generate deterministic localStorage/save fixtures under `artifacts/seed/`. |
| `node scripts/hudScreenshots.mjs` | Capture HUD/options overlay screenshots under `artifacts/screenshots/`. |

All scripts accept `--ci` to emit artifacts under `apps/keyboard-defense/artifacts/**`.

## Roadmap

- Harden coverage thresholds for Vitest (pending suite expansion).
- Introduce integration/e2e segmentation, StrykerJS, Playwright visual regression, and traceability reporting.
- Add GitHub Actions workflow (`ci-e2e-azure-vale.yml`) wrapping the scripts above.

Contributions should preserve deterministic behaviour (seeded PRNG, no reliance on wall-clock timing) to keep automation reliable.
