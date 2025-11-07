## Gold Summary Percentiles - 2025-11-09

**Summary**
- `scripts/goldSummary.mjs` now records the full set of positive (gain) and negative (spend) deltas per file and reports the median and 90th percentile for each side alongside the existing totals/max values.
- The CLI's CSV/JSON schema adds `medianGain`, `p90Gain`, `medianSpend`, and `p90Spend`, giving dashboards a quick sense of typical economy pacing versus single-event spikes.
- Global summaries now reprocess the raw timeline entries (instead of merging pre-aggregated rows) so cross-file percentiles remain accurate even when files contain wildly different run lengths.
- Vitest coverage asserts the percentile math (including empty timelines) and the CSV header contract; README/changelog/backlog entries call out the new metrics so other contributors know they're available.

**Details**
- Percentiles use an interpolated nearest-rank calculation so very small samples still produce useful values without step-wise jumps.
- Spend percentiles stay negative like `maxSpend`, which keeps them comparable with raw deltas in diagnostics/logs.
- The CLI remains backwards-compatible for callers that ignore the new columns—the additional fields simply appear at the tail of each row.

**Next Steps**
1. Pipe the new percentile signals into CI dashboards/alerts so we can spot economy drift before it hits players.
2. Consider exposing a `--percentiles` flag so advanced workflows can request alternate cutlines (p95, p99) without editing the script.
