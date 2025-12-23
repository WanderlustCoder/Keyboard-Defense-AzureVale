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
> Note: This document targets the retired web version (`apps/keyboard-defense`). The current Godot project lives at `apps/keyboard-defense-godot`; see `docs/GODOT_PROJECT.md` and `apps/keyboard-defense-godot/README.md` for active workflows.

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

## Implementation Notes

- **CLI contract**
  - `scripts/ci/goldSummaryReport.mjs` should accept multiple inputs
    (`--summary`, `--percentiles`, `--baseline`, `--out-json`, `--out-md`) so it can
    be invoked both in CI (pointing to fresh artifacts) and locally (pointing to
    fixtures under `docs/codex_pack/fixtures/gold/`).
  - Normalize outputs into a shared structure:
    ```json
    {
      "scenario": "tutorial-smoke",
      "metrics": {
        "gain": { "median": 145, "p90": 210 },
        "spend": { "median": 90, "p90": 140 },
        "netDelta": 32
      },
      "alerts": [{ "metric": "spend.p90", "status": "warn", "delta": 15 }]
    }
    ```
  - Markdown renderer should print a table per scenario plus an alert section with emoji badges + remediation tips.
- **Thresholds & config**
  - Read defaults from `ci/gold-summary-thresholds.json` (abs + % deltas) with env override (`GOLD_SUMMARY_THRESHOLDS`).
  - Support `--mode info|warn|fail` so nightly runs can warn while release branches fail on drift.
- **Workflow integration**
  - After `npm run analytics:gold`, run the report CLI, upload JSON to `artifacts/summaries/gold-summary-report.ci.json`, and append Markdown to the job summary.
  - Publish the Markdown snippet to the Codex dashboard tile (via `docs/codex_dashboard.md` or `scripts/generateCodexDashboard.mjs`).
- **Docs & playbooks**
  - Document regeneration steps (`npm run analytics:gold && node scripts/ci/goldSummaryReport.mjs --fixtures ...`) inside `CODEX_GUIDE.md`, `CODEX_PLAYBOOKS.md` (Analytics section), and `docs/docs_index.md`.
  - Update the Nov-08 gold summary status note once dashboards consume the new feed.
- **Testing**
  - Create fixtures covering normal + drift scenarios and snapshot both JSON + Markdown outputs.
  - Add unit tests for threshold evaluation, scenario filtering, and CLI argument parsing.

## Deliverables & Artifacts

- `scripts/ci/goldSummaryReport.mjs` + tests + fixtures.
- Threshold config file + documentation on updating it.
- CI workflow update uploading `artifacts/summaries/gold-summary-report*.json|md`.
- Dashboard + doc updates pointing to the new summary.

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
- node scripts/ci/goldSummaryReport.mjs docs/codex_pack/fixtures/gold-summary.json --summary temp/gold-summary-report.fixture.json --mode warn






