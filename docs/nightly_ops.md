# Nightly Operations Cheat Sheet

> Note: These workflows were for the retired web version (`apps/keyboard-defense`). The current Godot project lives at `apps/keyboard-defense-godot` and does not use these nightly jobs.

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

Alternatively, from `apps/keyboard-defense/` use the helper script with a run id:

```bash
npm run ci:download-artifacts -- --run-id <RUN_ID> --name ci-matrix-summary --name codex-dashboard-nightly
npm run ci:download-artifacts -- --workflow ci-matrix-nightly.yml --name ci-matrix-summary
```

## Retrieve artifacts

After a run completes:

```bash
# replace RUN_ID with the Actions run id
gh run download RUN_ID --name ci-matrix-summary --dir artifacts/ci-matrix-nightly
gh run download RUN_ID --name codex-dashboard-nightly --dir artifacts/codex-dashboard-nightly
```

Artifacts you should see:

- `ci-matrix-summary`: `ci-matrix-summary.json`, `ui-snapshot-gallery-nightly.(md|json)`, `asset-integrity.nightly.(json|md)`, `asset-integrity-report.nightly.(json|md)`, `asset-integrity.log`
- `codex-dashboard-nightly`: `docs/codex_dashboard.md`, `docs/CODEX_PORTAL.md`, `gold-analytics-board.ci.(json|md)`, `gold-baseline-guard.json`

If you need the run id, list recent workflow runs:

```bash
gh run list --workflow ci-matrix-nightly.yml --limit 5
gh run list --workflow codex-dashboard-nightly.yml --limit 5
```

## Quick triage

- HUD gallery missing shots: rerun `npm run docs:gallery` locally, ensure `artifacts/screenshots/*.meta.json` exist, then re-dispatch.
- Asset integrity failure: run `npm run assets:integrity -- --check --mode strict --telemetry artifacts/summaries/asset-integrity.json --telemetry-md artifacts/summaries/asset-integrity.md --history artifacts/history/asset-integrity.log`.
- Baseline guard missing: `node scripts/ci/goldBaselineGuard.mjs --timeline artifacts/summaries/gold-timeline.ci.json --baseline docs/codex_pack/fixtures/gold/gold-percentiles.baseline.json --out-json artifacts/summaries/gold-baseline-guard.json --mode warn` then `npm run codex:dashboard`.

## When to rerun locally

- HUD screenshots changed: `cd apps/keyboard-defense && npm run docs:gallery && npm run codex:dashboard`
- Gallery verification only: `cd apps/keyboard-defense && npm run docs:verify-hud-snapshots`
- Dashboard refresh from fixtures: `cd apps/keyboard-defense && npm run codex:dashboard`

## Common checks

- HUD metadata missing in nightly: rerun `npm run docs:verify-hud-snapshots` locally and regenerate gallery before dispatching.
- Asset integrity failure: inspect `apps/keyboard-defense/artifacts/summaries/asset-integrity*.json|md` and `artifacts/history/asset-integrity.log`; rerun `npm run assets:integrity -- --check --mode strict`.
- Baseline guard missing: run `node scripts/ci/goldBaselineGuard.mjs --timeline artifacts/summaries/gold-timeline.ci.json --baseline docs/codex_pack/fixtures/gold/gold-percentiles.baseline.json --out-json artifacts/summaries/gold-baseline-guard.json --mode warn` before `npm run codex:dashboard`.
