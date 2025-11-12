# CI & Tutorial Smoke Automation - 2025-11-06

## Context
- Backlog items **#71** and **#95** targeted nightly tutorial automation and CI coverage for the dev-server monitor.
- Scripts (`scripts/build.mjs`, `scripts/smoke.mjs`, `scripts/e2e.mjs`) were in place, but no GitHub workflow executed them yet.

## Summary
- Added `.github/workflows/ci-e2e-azure-vale.yml` with three jobs:
  - **Build & Tests**: runs orchestrators for build, unit, and integration suites with cached installs.
  - **Tutorial Smoke**: installs Playwright Chromium, launches `node scripts/smoke.mjs --ci`, and uploads monitor/smoke artifacts.
  - **Full E2E**: drives `node scripts/e2e.mjs --ci` to exercise tutorial (full) and campaign flows, archiving results.
- Workflow caches both root and app dependency lockfiles to keep installs fast.
- `PLAYWRIGHT_BROWSERS_PATH` is pinned so runners reuse browser downloads.
- Artifacts include `monitor-artifacts/` output, ensuring the dev monitor JSON is captured per run.

## Next Steps
1. Gate merges on the workflow once flake rate is confirmed.
2. Layer mutation testing into the pipeline when Stryker harness matures.
3. Add traceability report upload (coverage + backlog links) so CI exports the spec-to-test map automatically. *(Codex: `docs/codex_pack/tasks/14-ci-traceability-report.md`)*
