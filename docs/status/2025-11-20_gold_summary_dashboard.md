## Gold Summary Dashboard - 2025-11-20

**Summary**
- Implemented `scripts/ci/goldSummaryReport.mjs`, a Codex-friendly parser that reads `gold-summary.ci.json` artifacts, aggregates per-file metrics (net delta, median/p90 gain & spend), and enforces configurable thresholds (`GOLD_SUMMARY_MIN_NET_DELTA`, `GOLD_SUMMARY_MAX_P90_SPEND_MAG`). The script emits Markdown + JSON summaries (`artifacts/summaries/gold-summary-report*.json`) so CI dashboards expose the latest economy stats without downloading artifacts.
- Tutorial smoke and e2e workflows now run the report immediately after the gold timeline dashboard, appending the Markdown table (file, net delta, median/p90 gain/spend, event count) to `$GITHUB_STEP_SUMMARY` and uploading the JSON alongside other summaries.
- Codex docs (Guide, Playbooks, dashboard appendix) document how to dry-run the report locally with fixtures: `node scripts/ci/goldSummaryReport.mjs docs/codex_pack/fixtures/gold-summary.json --summary temp/gold-summary-report.fixture.json --percentile-alerts temp/gold-percentiles.fixture.json --mode warn`, which mirrors the CI invocation.
- Added a `--percentile-alerts <path>` flag so smoke/e2e jobs emit `artifacts/summaries/gold-percentiles.(smoke|e2e).json` before invoking `goldAnalyticsBoard.mjs`, preventing missing-input warnings and giving CI one consolidated gold tile.
- The gold summary report now emits starfield metrics per row (`starfieldDepth|Drift|WaveProgress|CastleRatio|Tint`) plus aggregated averages in the JSON/Markdown header, enabling downstream dashboards (gold board, Codex portal) to show castle tint severity without parsing raw snapshots.

**Next Steps**
1. Monitor the new percentile artifact + board integration and expand it with additional cutlines (p99, rolling variance) if the gold tuning team requests deeper drift analysis.
2. Consider exporting baseline comparison data so the report can flag deviations against historical medians (not just absolute thresholds).
3. Add configurable starfield severity thresholds so the Markdown can badge "calm/warning/breach" directly off the averaged castle ratios.

## Follow-up
- `docs/codex_pack/tasks/27-gold-summary-dashboard-integration.md`
- `docs/codex_pack/tasks/38-gold-analytics-board.md`
