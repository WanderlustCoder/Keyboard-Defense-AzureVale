---
id: gold-percentile-baseline-refresh
title: "Automate gold percentile baseline + thresholds refresh"
priority: P2
effort: M
depends_on:
  - gold-percentile-dashboard-alerts
  - gold-percentile-ingestion-guard
produces:
  - scripts/ci/goldPercentileBaseline.mjs
  - updated docs/codex_pack/fixtures/gold/gold-percentiles.baseline.json
  - docs/codex_pack/fixtures/gold/gold-percentile-thresholds.json
status_note: docs/status/2025-11-20_gold_percentile_alerts.md
backlog_refs:
  - "#101"
  - "#79"
---
> Note: This document targets the retired web version (`apps/keyboard-defense`). The current Godot project lives at `apps/keyboard-defense-godot`; see `docs/GODOT_PROJECT.md` and `apps/keyboard-defense-godot/README.md` for active workflows.

**Context**\
Percentile alerts now run inside GitHub Actions and rely on manually curated
baseline + threshold files. The Nov-20 gold percentile alerts status calls out
two gaps: Codex needs a one-command refresh flow whenever economy tuning ships,
and we should pipe the alert JSON into dashboards once the static board (#7/#38)
is live. Without automated refresh tooling, contributors risk committing stale
percentiles or missing documentation steps.

## Steps

1. **Baseline generator CLI**
   - Create `scripts/ci/goldPercentileBaseline.mjs` that:
     - Accepts one or more analytics outputs (`goldSummary`, `goldTimeline`,
       smoke/e2e artifacts) and computes canonical percentile medians/p90s per
       scenario.
     - Writes the result back to
       `docs/codex_pack/fixtures/gold/gold-percentiles.baseline.json`.
     - Supports `--check` mode to verify the committed baseline is current,
       enabling CI guardrails.
   - Allow configurable percentile sets so the script can adapt when new metrics
     are added (e.g., p75, spend streak percentiles).
2. **Threshold assistant**
   - Add optional flags (`--thresholds-out`, `--delta <pct|abs>`) that compute
     recommendation thresholds and update
     `apps/keyboard-defense/scripts/ci/gold-percentile-thresholds.json`.
   - Emit a short Markdown snippet summarizing the recommended deltas so Codex
     can drop it into status notes/backlog updates.
3. **Workflow + dashboard wiring**
   - Document a guided flow in `CODEX_GUIDE.md` / `CODEX_PLAYBOOKS.md`:
     `npm run analytics:gold:summary -- --baseline-run` followed by the new CLI.
   - Add a helper `npm run gold:percentiles:refresh` script that chains the
     analytics command + baseline generator for Codex automation.
   - Feed the guard/alert JSON into the forthcoming gold analytics board (task
     #38) so the refreshed baselines immediately show up on dashboards.
4. **Status + bookkeeping**
   - Update `docs/status/2025-11-20_gold_percentile_alerts.md` and any related
     backlog entries with instructions for using the refresh script.
   - Mention the new workflow inside `docs/codex_dashboard.md` so reviewers know
     when the baselines were last regenerated.

## Acceptance criteria

- Running `npm run gold:percentiles:refresh` regenerates the baseline +
  thresholds from the latest analytics outputs and fails CI if files are stale.
- Codex docs clearly describe how to refresh baselines, check them into git, and
  verify guard outputs before merging.
- Percentile guard/alert dashboards reference the refreshed baseline timestamp so
  reviewers can trust the metrics.

## Verification

- npm run analytics:gold:summary -- --fixtures docs/codex_pack/fixtures/gold
- node scripts/ci/goldPercentileBaseline.mjs docs/codex_pack/fixtures/gold/*.json \
  --baseline-out docs/codex_pack/fixtures/gold/gold-percentiles.baseline.json \
  --thresholds-out apps/keyboard-defense/scripts/ci/gold-percentile-thresholds.json \
  --check
- npm run codex:validate-pack
- npm run codex:validate-links
- npm run codex:status






