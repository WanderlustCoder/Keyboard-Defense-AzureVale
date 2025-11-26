---
id: gold-analytics-board
title: "Unify gold analytics dashboards into a single Codex board"
priority: P2
effort: L
depends_on:
  - gold-summary-dashboard-integration
  - gold-timeline-dashboard
  - passive-gold-dashboard
  - gold-percentile-dashboard-alerts
  - gold-percentile-ingestion-guard
produces:
  - scripts/ci/goldAnalyticsBoard.mjs
  - artifacts/summaries/gold-analytics-board.ci.json
  - docs/codex_dashboard.md (gold analytics tile)
status_note: docs/status/2025-11-20_gold_analytics_board.md
backlog_refs:
  - "#79"
  - "#101"
  - "#45"
---

**Context**\
Gold timeline, passive, summary, and percentile guard steps now emit their own
Markdown/JSON bundles, but reviewers still hop between multiple dashboard tiles
and workflow summaries to judge economy health. The Nov-20 status notes for the
gold summary dashboard, gold timeline dashboard, percentile guard, and passive
gold dashboards all call for a single Codex-first surface that stitches these
feeds together. Codex should be able to open one page (or CLI command) and see
rolling deltas, percentile drift, guard status, and unlock cadence without
downloading artifacts.

## Steps

1. **Data ingestion layer**
   - Create `scripts/ci/goldAnalyticsBoard.mjs` that loads the latest outputs from:
     - `artifacts/summaries/gold-summary-report*.json`
     - `artifacts/summaries/gold-timeline*.json`
     - `artifacts/summaries/passive-gold*.json`
     - `artifacts/summaries/gold-percentile-guard*.json`
     - `artifacts/summaries/gold-percentiles*.json` (alerts task #30)
   - Normalize timestamps, scenario names, and threshold decisions so each feed
     can be merged under a shared schema (e.g., `{scenario, metric, value, status}`).
   - Accept fixture inputs via CLI flags (`--summary`, `--timeline`, etc.) so Codex
     can dry-run the aggregation locally without CI artifacts.
2. **Board generator**
   - Emit `artifacts/summaries/gold-analytics-board.ci.json` plus Markdown that
     highlights:
     - Last N gold events + unlock cadence with inline percentile drift badges.
     - Net delta + percentile comparison vs baseline for each scenario.
     - Guard results (pass/fail) with links to raw artifacts.
     - A sparkline-friendly `delta@t` sequence per scenario that renders in both the board Markdown and Codex portal tiles.
   - Provide an optional `--mode warn|fail|info` so CI can soften failures if any
     upstream feed is missing.
   - Include sparkline-friendly sequences (arrays) so future renderers can draw
     charts from the JSON alone.
   - Surface the starfield severity (averages + per-scenario notes) from the gold summary so castle tint drift is always visible next to economy deltas.
3. **Dashboard integration**
   - Add a dedicated "Gold Analytics Board" tile to `docs/codex_dashboard.md`
     that links to the aggregated Markdown + JSON.
   - Update `CODEX_GUIDE.md`, `CODEX_PLAYBOOKS.md`, and `docs/docs_index.md`
     with a short how-to on regenerating the board locally:
     `node scripts/ci/goldAnalyticsBoard.mjs --fixtures docs/codex_pack/fixtures/gold`.
   - Ensure `npm run codex:dashboard` (or the existing dashboard pipeline) pulls
     in the aggregated Markdown so nightly automation refreshes the tile.
4. **Workflow wiring + status updates**
   - Insert the aggregator step after the existing gold timeline / percentile
     jobs in smoke + e2e workflows, uploading the new JSON and appending the
     Markdown to `$GITHUB_STEP_SUMMARY`.
   - Update the Nov-20 status notes (timeline, summary, passive dashboard,
     percentile guard) to mark the Next Steps complete once the board lands.

## Acceptance criteria

- Running one CLI (`goldAnalyticsBoard.mjs`) produces a consolidated JSON +
  Markdown bundle that covers timeline, passive, summary, and percentile guard
  data for each scenario.
- GitHub Actions smoke/e2e workflows upload the bundle and expose it via
  `$GITHUB_STEP_SUMMARY`, reducing gold review to a single link.
- `docs/codex_dashboard.md` showcases the board with clear pass/fail badges and
  links back to individual artifacts when deeper debugging is required.

## Verification

- node scripts/ci/goldAnalyticsBoard.mjs \
  --summary docs/codex_pack/fixtures/gold/gold-summary-report.json \
  --timeline docs/codex_pack/fixtures/gold-timeline/smoke.json \
  --passive docs/codex_pack/fixtures/passives/sample.json \
  --percentile-guard docs/codex_pack/fixtures/gold/percentile-guard.json \
  --percentile-alerts docs/codex_pack/fixtures/gold/gold-percentiles.baseline.json \
  --out temp/gold-analytics-board.fixture.json
- npm run codex:validate-pack
- npm run codex:validate-links
- npm run codex:status
