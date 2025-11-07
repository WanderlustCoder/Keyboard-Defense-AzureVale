## Gold Timeline Summary CLI - 2025-11-08

**Summary**
- Added `scripts/goldSummary.mjs` (`npm run analytics:gold:summary`), a companion CLI that ingests either gold timeline files or raw snapshots/smoke artifacts and emits per-file economy stats (event counts, net delta, max gain/spend, total positive/negative, passive linkage counts/lag). Pass `--global` to append an aggregate row for the entire data set.
- The CLI mirrors the existing timeline tooling (JSON output by default, `--csv` flag, `--out` support) so dashboards can ingest concise metrics without post-processing large timelines.
- Tutorials smoke already produces a passive-aware timeline; the orchestrator now runs the summary CLI immediately afterwards, uploading both `gold-timeline*.json` and `gold-summary*.json/.
- CI smoke job now runs the summary CLI automatically, publishing `gold-summary.ci.csv` next to the timeline artifact for immediate ingestion.
- Vitest coverage validates argument parsing, per-file aggregation, and CSV output.

**Next Steps**
1. Explore enriching the stats with percentile data (e.g., median gain/spend) and cross-file aggregates.
2. Feed the CI-generated summary into dashboards/alerts to track economy regression deltas automatically.
