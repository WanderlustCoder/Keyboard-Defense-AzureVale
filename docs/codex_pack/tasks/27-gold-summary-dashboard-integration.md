---
id: gold-summary-dashboard-integration
title: "Feed gold summary output into dashboards/alerts"
priority: P2
effort: M
depends_on: [ci-traceability-report]
produces:
  - automation that uploads/parses gold summary in CI summary
  - optional dashboard generator / JSON feed
status_note: docs/status/2025-11-08_gold_summary_cli.md
backlog_refs:
  - "#101"
  - "#79"
---

**Context**  
Gold summary CLI now exists and runs in CI, but the artifact is not surfaced
directly to dashboards/alerts. We need automation to parse the summary and
publish metrics (percentiles, anomalies) automatically.

## Steps

1. **Parser**
   - Add `scripts/ci/goldSummaryReport.mjs` that:
     - Reads `artifacts/smoke/gold-summary.ci.json` (and e2e variants)
     - Extracts key metrics (median/p90 gain/spend, net delta)
     - Emits JSON + Markdown summaries for CI dashboards
2. **CI integration**
   - Call the script at the end of the Build/Test job.
   - Append the Markdown to `$GITHUB_STEP_SUMMARY` and upload the JSON.
3. **Alerts**
   - Optionally add thresholds (e.g., if p90 spend > baseline) to fail or warn CI.
4. **Docs**
   - Update status/backlog references once the integration is live.

## Acceptance criteria

- CI job summary shows gold summary metrics without downloading artifacts.
- JSON feed (or JSON file) is available for dashboards/alerts.
- Thresholds/config documented for future tuning.

## Verification

- npm run lint
- npm run test
- npm run codex:validate-pack
- npm run codex:validate-links
- npm run codex:status
- Run the script locally with fixtures to confirm summary output.
