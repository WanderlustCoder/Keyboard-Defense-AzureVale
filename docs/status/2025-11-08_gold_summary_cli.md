## Gold Timeline Summary CLI - 2025-11-08

**Summary**
- Added `scripts/goldSummary.mjs` (`npm run analytics:gold:summary`), a companion CLI that ingests either gold timeline files or raw snapshots/smoke artifacts and emits per-file economy stats (event counts, net delta, max gain/spend, total positive/negative, passive linkage counts/lag). Pass `--global` to append an aggregate row for the entire data set.
- The CLI mirrors the existing timeline tooling (JSON output by default, `--csv` flag, `--out` support) so dashboards can ingest concise metrics without post-processing large timelines.
- Tutorials smoke already produces a passive-aware timeline; the orchestrator now runs the summary CLI immediately afterwards, uploading both `gold-timeline*.json` and `gold-summary*.json`.
- CI smoke job now runs the summary CLI automatically, publishing `gold-summary.ci.csv` next to the timeline artifact for immediate ingestion.
- Vitest coverage validates argument parsing, per-file aggregation, and CSV output.
- Added `scripts/goldReport.mjs` (`npm run analytics:gold:report`) so devs can generate both artifacts locally with one command (timeline + summary) using the same flags as the underlying CLIs.
- Introduced a formal analytics JSON Schema (`apps/keyboard-defense/schemas/analytics.schema.json`) plus `node scripts/analytics/validate-schema.mjs` so CI (and devs) can Ajv-validate snapshots/fixtures on every run; bundled fixtures in `docs/codex_pack/fixtures/analytics/` keep the validator honest.

**Next Steps**
1. Feed the CI-generated summary into dashboards/alerts to track economy regression deltas automatically. *(Codex: `docs/codex_pack/tasks/27-gold-summary-dashboard-integration.md`)*
2. Use the new percentile signals to flag economy anomalies (e.g., sustained p90 spends above tolerance) during smoke and breach drills. *(Same task, add thresholds.)*
3. Wire the schema validation CLI into Build/Test workflows so analytics artifacts fail-fast during CI. *(Follow-up complete via `schema-contracts` task.)*

## Follow-up
- `docs/codex_pack/tasks/27-gold-summary-dashboard-integration.md`
- `docs/status/2025-11-20_gold_summary_dashboard.md`
