## Gold Timeline Summary CLI - 2025-11-08

**Summary**
- Added `scripts/goldSummary.mjs` (`npm run analytics:gold:summary`), a companion CLI that ingests either gold timeline files or raw snapshots/smoke artifacts and emits per-file economy stats (event counts, net delta, max gain/spend, total positive/negative, passive linkage counts/lag).
- The CLI mirrors the existing timeline tooling (JSON output by default, `--csv` flag, `--out` support) so dashboards can ingest concise metrics without post-processing large timelines.
- Tutorials smoke already produces a passive-aware timeline; teams can now run the summary CLI over the uploaded artifact to track economy regression trends night-over-night.
- Vitest coverage validates argument parsing, per-file aggregation, and CSV output.

**Next Steps**
1. Wire `npm run analytics:gold:summary` into the CI smoke workflow once dashboards are ready to consume the condensed report.
2. Explore enriching the stats with percentile data (e.g., median gain/spend) and cross-file aggregates.
