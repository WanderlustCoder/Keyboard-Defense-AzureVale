## Gold Summary Percentile Metadata - 2025-11-12

**Summary**
- `goldSummary.mjs` now emits the percentile list used for each run: JSON output wraps the `rows` array inside `{ percentiles, rows }`, while CSV output gains a trailing `summaryPercentiles` column containing the pipe-delimited list (e.g., `25|50|90`).
- Regression tests cover both CSV and JSON modes (default + custom percentile runs) so the metadata contract stays stable.
- README, changelog, analytics schema, and backlog are updated to call out the metadata for dashboard consumers.
- Smoke automation now reads the JSON summary immediately after generation to ensure the metadata matches the canonical `25,50,90` list, raising a warning when it drifts.

**Next Steps**
1. Surface the metadata validation status in dashboards/alerts so failures are visible even when smoke artifacts succeed.
