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
- Vitest now includes coverage for the CLI (see `tests/castleBreachReplay.test.js`).

## Next Steps
1. Feed the breach artifact into nightly analytics to surface breached-at-time deltas.
2. Extend the CLI with optional turret placements to simulate countermeasures.
3. Hook the breach drill into the CI pipeline once runtime budgets are finalised.
