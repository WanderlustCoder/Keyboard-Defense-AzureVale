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
> Note: This document targets the retired web version (`apps/keyboard-defense`). The current Godot project lives at `apps/keyboard-defense-godot`; see `docs/GODOT_PROJECT.md` and `apps/keyboard-defense-godot/README.md` for active workflows.

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

## Implementation Notes

- **CLI behavior**
  - `scripts/analytics/goldDeltaAggregator.mjs` should accept:
    - `--input <file>` (repeatable), `--out-json <file>`, `--out-md <file>`, `--mode info|warn|fail`, `--fixtures`.
  - Output JSON shape:
    ```json
    {
      "scenario": "tutorial-smoke",
      "waves": [{ "wave": 3, "gain": 150, "spend": 40, "net": 110 }],
      "stats": {
        "largestGain": { "delta": 200, "wave": 5, "timestamp": 123456 },
        "largestLoss": { "delta": -90, "wave": 7 },
        "medianGain": 85,
        "medianLoss": -30,
        "netLine": [0, 110, 80, ...]
      },
      "alerts": [...]
    }
    ```
  - Markdown should include tables for per-wave totals + badges for largest gain/loss and anomalies.
- **Derived metrics**
  - Calculate per-wave gain/spend, rolling net total, histogram buckets (time-of-day or event order), and streaks of negative deltas.
  - Provide threshold flags (`--warn-max-loss`, `--fail-net-drop`) so CI can react to regressions.
- **Schema/docs**
  - Extend `docs/analytics_schema.md` with new sections describing:
    - `goldDelta.waves[]`
    - `goldDelta.stats`
    - `goldDelta.alerts`
  - Document how to regenerate the aggregates in `CODEX_GUIDE.md` + `docs/docs_index.md`.
- **Fixtures/tests**
  - Store baseline outputs under `docs/codex_pack/fixtures/gold-delta-aggregates/` (normal, spike, regression) and use them for Vitest snapshot tests.
  - Add unit tests covering aggregation math, multi-file inputs, and threshold handling.
- **Dashboard & CI**
  - Wire the CLI into Build/Test + analytics workflows, uploading JSON/Markdown and appending key stats to `$GITHUB_STEP_SUMMARY`.
  - Update `docs/codex_dashboard.md` with a “Gold Delta Watch” tile linking to the new artifact; display largest gain/loss and net change.
  - Ensure `npm run codex:dashboard` reads the JSON so docs stay in sync.

## Deliverables & Artifacts

- `scripts/analytics/goldDeltaAggregator.mjs` + tests/fixtures.
- Updated analytics schema, docs, and guide references.
- New dashboard tile + CI summary snippet referencing aggregate stats.
- Sample outputs under `docs/codex_pack/fixtures/gold-delta-aggregates/` (analytics input + JSON/Markdown summary) for regression tests and documentation.

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






