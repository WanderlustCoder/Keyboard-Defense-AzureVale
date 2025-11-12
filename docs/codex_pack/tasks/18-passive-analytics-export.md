---
id: passive-analytics-export
title: "Export passive deltas for analytics & docs"
priority: P2
effort: M
depends_on: [diagnostics-dashboard]
produces:
  - analytics export fields for passive unlocks/deltas
  - updated docs/analytics_schema.md entries
  - fixtures demonstrating passive analytics output
status_note: docs/status/2025-11-06_castle_passives.md
backlog_refs:
  - "#41"
  - "#79"
---

**Context**  
Castle passive unlocks are visible in HUD/log and diagnostics, but analytics
exports don't expose passive deltas for dashboards. We need a rollup that
includes per-wave passive state plus unlock deltas.

## Steps

1. **Analytics snapshot updates**
   - Extend the analytics state to include `passiveUnlockEvents` (with `id`,
     `level`, `waveIndex`, `time`, `delta`).
   - Add running totals per wave (regen HP/s, armor, gold bonus).
2. **CLI export**
   - Update `scripts/analyticsAggregate.mjs` (and related commands) to emit the
     new fields into JSON/CSV.
   - Provide a summarized CSV (e.g., `passiveUnlockSummary.csv`) for dashboards.
3. **Fixtures & docs**
   - Create a fixture (use an existing artifact) showing the new fields.
   - Update `docs/analytics_schema.md` and `docs/codex_pack/fixtures` notes.
4. **Automation integration**
   - Modify `docs/codex_dashboard.md` (via `codex:dashboard`) to link to the new
     passive summary artifact or highlight “next passive unlock wave”.

## Acceptance criteria

- Analytics exports include passive delta data for every wave.
- Docs and fixtures describe the new structure.
- CI job summary references the passive summary artifact or key metrics.

## Verification

- npm run lint
- npm run test
- npm run codex:validate-pack
- npm run codex:validate-links
- npm run codex:status
- Run analytics CLI against a fixture to ensure passive fields populate.
