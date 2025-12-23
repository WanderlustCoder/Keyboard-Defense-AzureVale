> Note: This document targets the retired web version (`apps/keyboard-defense`). The current Godot project lives at `apps/keyboard-defense-godot`; see `docs/GODOT_PROJECT.md` and `apps/keyboard-defense-godot/README.md` for active workflows.

## Gold Percentile Alerts - 2025-11-20

**Summary**
- Introduced percentile baselines (`docs/codex_pack/fixtures/gold/gold-percentiles.baseline.json`) plus repo-configured thresholds (`apps/keyboard-defense/scripts/ci/gold-percentile-thresholds.json`) so gold summary medians/p90s now have an explicit reference curve.
- `scripts/ci/goldSummaryReport.mjs` accepts `--baseline`/`--thresholds` flags (env defaults wired for CI), compares each artifact's median/p90 gain & spend against the baseline, and flags drift when absolute or percentage deltas exceed the configured bands. Fail/warn behavior is controlled by `GOLD_SUMMARY_REPORT_MODE`.
- CI smoke/e2e workflows run the percentiles check alongside the gold summary dashboard; the Markdown section now shows pass/fail rows per metric with diffs, and the uploaded JSON includes `percentileAlerts` for dashboards/automation.
- Codex docs/playbooks list the new command plus baseline/threshold file locations so contributors can refresh references whenever the economy tuning changes.
- `goldSummaryReport.mjs` now writes the percentile drift rows to `artifacts/summaries/gold-percentiles.(smoke|e2e).json`, giving `goldAnalyticsBoard.mjs` (and future dashboards) a dedicated feed instead of scraping the report payload.
- Added `scripts/ci/goldPercentileBaseline.mjs` plus `npm run gold:percentiles:refresh`, which aggregate the latest gold summary artifacts, rewrite the baseline/threshold JSON (with `_meta.generatedAt` timestamps), and produce `artifacts/summaries/gold-percentiles.md` so reviewers know when the references were last regenerated.

**Next Steps**
1. Mirror the percentile alert JSON inside the static Codex dashboard once task #7 lands so reviewers get both the standalone tile and the aggregated board entry.
2. Expand the refresh CLI to ingest future percentile metrics (p75, spend streaks) once those columns ship so dashboards don't require code changes.

## Follow-up
- `docs/codex_pack/tasks/30-gold-percentile-dashboard-alerts.md`
- `docs/codex_pack/tasks/39-gold-percentile-baseline-refresh.md`
- `docs/codex_pack/tasks/38-gold-analytics-board.md`

