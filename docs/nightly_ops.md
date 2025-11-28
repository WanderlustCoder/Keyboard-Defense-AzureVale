# Nightly Operations Cheat Sheet

Use this as a fast reference for running or troubleshooting the nightly jobs.

## Workflows

- `ci-matrix-nightly.yml` (06:00 UTC)
  - Runs scenario matrix (`scripts/ci/run-matrix.mjs`), asset integrity (strict), HUD screenshots, HUD metadata verification + condensed audit.
  - Artifacts: `ci-matrix-summary` (matrix JSON), `ui-snapshot-gallery-nightly.(md|json)`, `asset-integrity.nightly.(json|md)`, `asset-integrity-report.nightly.(json|md)`, `asset-integrity.log`.
- `codex-dashboard-nightly.yml` (05:30 UTC)
  - Rebuilds Codex dashboard/portal from live CI artifacts when present, otherwise falls back to fixtures.
  - Artifacts: `codex-dashboard-nightly` (portal + dashboard MD, gold board JSON/MD, baseline guard JSON).

## Prereqs

- GitHub CLI installed and authenticated (`gh auth status`).
- `gh` must have repo/workflow scopes to dispatch Actions runs.

## Manual dispatch

From repo root (GitHub CLI):

```bash
gh workflow run ci-matrix-nightly.yml --ref master
gh workflow run codex-dashboard-nightly.yml --ref master
```

## When to rerun locally

- HUD screenshots changed: `cd apps/keyboard-defense && npm run docs:gallery && npm run codex:dashboard`
- Gallery verification only: `cd apps/keyboard-defense && npm run docs:verify-hud-snapshots`
- Dashboard refresh from fixtures: `cd apps/keyboard-defense && npm run codex:dashboard`

## Common checks

- HUD metadata missing in nightly: rerun `npm run docs:verify-hud-snapshots` locally and regenerate gallery before dispatching.
- Asset integrity failure: inspect `apps/keyboard-defense/artifacts/summaries/asset-integrity*.json|md` and `artifacts/history/asset-integrity.log`; rerun `npm run assets:integrity -- --check --mode strict`.
- Baseline guard missing: run `node scripts/ci/goldBaselineGuard.mjs --timeline artifacts/summaries/gold-timeline.ci.json --baseline docs/codex_pack/fixtures/gold/gold-percentiles.baseline.json --out-json artifacts/summaries/gold-baseline-guard.json --mode warn` before `npm run codex:dashboard`.
