# Castle Breach Replay CLI - 2025-11-06

## Context
- Backlog **#99** requested a deterministic castle-breach drill to guard the tutorial sequence.
- Prior automation suites covered wave simulations, smoke runs, and screenshot capture but lacked a direct regression harness for the scripted breach.

## Summary
- Added `node scripts/castleBreachReplay.mjs` which:
  - Builds a minimal GameEngine configuration with an empty wave and shortened prep countdown.
  - Spawns a configurable enemy (default brute) and advances the simulation headlessly until the castle takes damage or a timeout occurs.
  - Records timeline samples, breach metadata, and relevant events, emitting a JSON artifact (default `artifacts/castle-breach.json`).
  - Supports CLI flags: `--seed`, `--step`, `--max-time`, `--sample`, `--tier`, `--lane`, `--prep`, `--speed-mult`, `--health-mult`, plus `--no-artifact`.
- Exposed `task:breach` in `package.json`, documented the workflow in README/CONTRIBUTING, and marked backlog item #99 as Done.
- GitHub Actions `ci-e2e-azure-vale` now runs the breach drill after e2e smoke steps and uploads `artifacts/castle-breach.ci.json`; the job fails automatically if no breach occurs.
- Vitest now includes coverage for the CLI (see `tests/castleBreachReplay.test.js`).

## Next Steps
1. Feed the CI breach artifact into nightly analytics dashboards to monitor time-to-breach deltas.
2. Extend the CLI with optional turret placements to simulate countermeasure regressions.
3. Allow multi-enemy scenarios to validate shield and armor variations across future tutorials.
