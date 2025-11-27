---
id: gold-percentile-dashboard-alerts
title: "Alert on gold percentile drift in CI dashboards"
priority: P2
effort: M
depends_on: [gold-summary-dashboard-integration]
produces:
  - dashboards/gold-percentiles.md
  - ci/gold-percentile-thresholds.json
status_note: docs/status/2025-11-09_gold_percentiles.md
backlog_refs:
  - "#101"
  - "#79"
---

**Context**  
Gold summary CLI now emits `median`/`p90` gain and spend metrics, but CI simply writes
artifacts. Reviewers still eyeball CSVs to detect economy drift, delaying reactions
when gain/spend pacing changes. We need automated dashboards plus thresholds that
fail or warn CI when percentiles escape a configured band.

## Steps

1. **Baseline capture**
   - Add `fixtures/gold/gold-percentiles.baseline.json` storing reference medians/p90s per scenario (smoke, tutorial, e2e).
   - Document how to update the baseline (e.g., `npm run gold:summary -- --baseline`).
2. **Threshold config**
   - Create `ci/gold-percentile-thresholds.json` describing allowed delta bands (absolute + percentage) for each percentile metric.
   - Allow overrides via env vars/CLI flags in CI.
3. **CI enforcement**
   - Extend `scripts/ci/goldSummaryReport.mjs` (or a sibling) to:
     - Parse the artifact.
     - Compare medians/p90s against thresholds.
     - Emit structured JSON for dashboards plus a Markdown alert table (pass/fail per metric).
   - Fail or soft-warn the job based on severity + `FAIL_ON_PERCENTILE_DRIFT`.
4. **Dashboard wiring**
   - Update `docs/codex_dashboard.md` (and `docs/codex_pack/tasks/27-*` if needed) to include the percentile drift summary.
   - Add troubleshooting guidance to `CODEX_PLAYBOOKS.md` for responding to percentile alerts.

## Implementation Notes

- **Baseline workflow**
  - Provide `npm run gold:percentiles:baseline` that shells into
    `scripts/ci/goldPercentileBaseline.mjs` to regenerate
    `docs/codex_pack/fixtures/gold/gold-percentiles.baseline.json` plus a Markdown
    changelog summarizing drift (commit alongside the fixture).
  - Require the command to fail if working tree diffs are detected after running,
    ensuring contributors update baselines before merging.
- **Threshold schema**
  - Define per-scenario objects:
    ```json
    {
      "tutorial-smoke": {
        "gain": { "median": { "abs": 15, "pct": 0.08 }, "p90": { "abs": 20, "pct": 0.1 } },
        "spend": { ... }
      }
    }
    ```
  - Allow optional `trendWindow` so CI can compare against rolling history (stored in
    `artifacts/history/gold-percentiles.json`) for more resilient alerts.
  - Support env overrides (`PERCENTILE_THRESHOLDS_PATH`) and CLI flags for ad-hoc runs.
- **CI/CLI behavior**
  - Emit JSON: `{scenario, metric, percentile, actual, baseline, delta, status}` to power
    other dashboards (e.g., `goldAnalyticsBoard`).
  - Markdown summary should include emoji badges (✅/⚠️/❌), baseline vs actual, and links
    to underlying artifacts.
  - Introduce `--mode info|warn|fail` + `--output-md` options for reuse in nightly vs release workflows.
  - When drift exceeds thresholds, attach remediation hints (e.g., “rerun tutorial smoke”
    or “refresh baseline via npm run gold:percentiles:baseline”).
- **Documentation**
  - Add a “Gold percentile alert playbook” section to `CODEX_PLAYBOOKS.md` describing
    how to react (check logs, refresh baselines, verify inputs).
  - Mention the new CLI + baseline workflow in `CODEX_GUIDE.md` and `docs/docs_index.md`.
  - Update Nov-09/Nov-20 gold status notes once alerts ship.
- **Testing**
  - Add Vitest coverage for the alert script:
    - Happy path matching baseline.
    - Warning/failure when exceeding abs/pct thresholds.
    - Baseline regeneration smoke test to guarantee fixture schema stability.
  - Store representative fixtures under `docs/codex_pack/fixtures/gold/` for consistent snapshots.

## Deliverables & Artifacts

- `ci/gold-percentile-thresholds.json` + regeneration instructions.
- `scripts/ci/goldPercentileAlert.mjs` (or enhanced `goldSummaryReport`) with unit tests.
- Baseline fixtures + history logs kept under version control.
- Dashboard tile + status/doc updates referencing the alert output.

## Acceptance criteria

- CI job summaries highlight percentile drift with clear pass/fail badges.
- Threshold config lives in repo and is easy to tune per scenario.
- Codex dashboard exposes the latest percentile metrics + drift decision without artifact downloads.

## Verification

- node scripts/goldSummary.mjs --input docs/codex_pack/fixtures/gold/smoke.json --out temp/gold-smoke.json
- node scripts/ci/goldSummaryReport.mjs --fixture docs/codex_pack/fixtures/gold/smoke.json --thresholds ci/gold-percentile-thresholds.json
- npm run test -- goldSummary
- npm run codex:validate-pack
- npm run codex:validate-links
- npm run codex:status
