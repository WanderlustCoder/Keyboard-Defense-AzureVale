# HUD Screenshot Automation - 2025-11-06

## Context
- Backlog **#72** targeted automated HUD captures for docs and regression review.
- Directive requires durable Playwright-based screenshots for visual audits before enabling full visual regression.

## Summary
- Added `node scripts/hudScreenshots.mjs` which:
  - Starts the dev server via `startMonitored.mjs` (unless `--no-server` is supplied).
  - Uses Playwright Chromium to drive the game via debug hooks.
  - Captures `hud-main.png` (active wave with turret + enemy) and `options-overlay.png` (pause/options overlay).
  - Writes assets and a JSON summary to `artifacts/screenshots/` (CI variant writes `screenshots-summary.ci.json`).
- CLI flags supported: `--url`, `--out`, `--no-server`, `--ci`.
- Updated `package.json` (`task:screenshots`), CONTRIBUTING, and README to document the workflow.
- CI jobs can publish the screenshot artifact by appending an `upload-artifact` step referencing `artifacts/screenshots/`.
- Wired the GitHub Actions `ci-e2e-azure-vale` workflow to run the screenshot capture after the e2e orchestration and upload the resulting PNGs automatically.
- CLI now also captures `tutorial-summary.png` and `wave-scorecard.png` via new debug hooks, so docs and regression reviews include the tutorial wrap-up modal and wave-end scorecard states.
- CI now reads `screenshots-summary.ci.json` and appends a markdown table to the workflow summary so nightly reviewers can inspect the captured shots (with condensed/diagnostics context) without downloading artifacts.

## Next Steps
1. Introduce automated diff tooling (e.g., Playwright `toHaveScreenshot`) once baselines stabilize.
