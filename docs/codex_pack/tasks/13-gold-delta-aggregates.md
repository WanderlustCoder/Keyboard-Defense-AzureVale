---
id: gold-delta-aggregates
title: "Aggregate gold delta streams for automation & docs"
priority: P2
effort: M
depends_on: [ci-step-summary]
produces:
  - scripts/analytics/goldDeltaAggregator.mjs
  - docs/codex_pack/fixtures/gold-delta-aggregates.json
  - updates to docs/analytics_schema.md and docs/codex_dashboard.md references
status_note: docs/status/2025-11-06_gold_event_delta.md
backlog_refs:
  - "#79"
---

**Context**  
Gold events already include `{ delta, timestamp }`, but we lack a summarized view
for automation and documentation. This task adds a CLI + docs to roll up per-wave
gold delta aggregates and surface them in automation artifacts.

## Steps

1. **Aggregator CLI**
   - Create `scripts/analytics/goldDeltaAggregator.mjs` that ingests gold event
     arrays (from smoke/e2e artifacts) and emits:
     - Per-wave totals (gain/spend)
     - Largest delta, median delta, time-of-day histogram
     - Running cumulative gold line (for graphing)
   - Support JSON input via `--input artifacts/smoke/gold-summary.ci.json`.
2. **Schema/docs**
   - Update `docs/analytics_schema.md` describing the new aggregate fields.
   - Add documentation/snippets so other tasks know how to consume the output.
3. **Fixtures**
   - Capture a sample output under `docs/codex_pack/fixtures/gold-delta-aggregates.json`.
   - Reference this fixture from the Codex task so future contributors can dry-run.
4. **Dashboard integration**
   - Extend the static dashboard (or Codex dashboard) to link to the aggregate
     output, e.g., show “Largest tutorial gold delta” and “Wave with biggest loss”.
   - Ensure `npm run codex:dashboard` references the new artifact path.

## Acceptance criteria

- CLI produces deterministic aggregates for both smoke and e2e artifacts.
- Schema/docs updated; fixture available.
- Dashboard (or CI summary) calls out key gold delta stats per run.

## Verification

- npm run lint
- npm run test
- npm run codex:validate-pack
- npm run codex:validate-links
- npm run codex:status
- node scripts/analytics/goldDeltaAggregator.mjs --input docs/codex_pack/fixtures/gold-delta-aggregates.json --output /tmp/gold-delta.json (adjust path)
