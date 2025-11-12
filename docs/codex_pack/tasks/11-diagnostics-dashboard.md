---
id: diagnostics-dashboard
title: "Surface gold delta & passive unlock telemetry in dashboards"
priority: P2
effort: M
depends_on: [ci-step-summary, static-dashboard]
produces:
  - analytics CLI updates (gold delta/passive exports)
  - docs/codex_pack/fixtures/diagnostics-dashboard.json (optional sample)
  - static dashboard panels for gold delta + passive unlock timelines
status_note: docs/status/2025-11-07_diagnostics_passives.md
backlog_refs:
  - "#79"
---

**Context**  
Diagnostics overlays now expose gold deltas and passive unlocks, but the CI/static
dashboard does not render those signals yet. We need a deterministic export +
dashboard view so automation reviews trendlines without opening raw JSON.

## Steps

1. **Extend analytics exports**
   - Update the analytics CLI (and fixtures) to include:
     - `goldEventsTracked`, `lastGoldDelta`, `lastGoldEventTime`
     - Passive unlock summary array (`passiveId`, `level`, `time`)
   - Ensure `docs/analytics_schema.md` reflects the new fields.
2. **Augment Codex fixtures**
   - Add `docs/codex_pack/fixtures/diagnostics-dashboard.json` capturing the new
     telemetry (use a tutorial smoke artifact as reference).
3. **Update static dashboard**
   - Render a "Gold Delta" sparkline (last N events) and "Passive Unlock Timeline".
   - Link the widgets to the artifacts produced in CI (`artifacts/smoke`,
     `artifacts/e2e`).
4. **CI wiring**
   - Ensure `npm run codex:dashboard` runs after the new data is generated so the
     Codex dashboard links to the enriched artifacts.

## Acceptance criteria

- Analytics CLI outputs gold delta + passive unlock fields; schema + fixtures updated.
- Static dashboard shows gold delta trends and passive unlock timeline with links to
  artifacts.
- CI job summary references the new panels (or provides direct links).

## Verification

- npm run lint
- npm run test
- npm run codex:validate-pack
- npm run codex:validate-links
- npm run codex:dashboard
- Run the analytics CLI against sample artifacts to confirm new fields populate
  (e.g., `node scripts/analyticsAggregate.mjs --input artifacts/smoke/*` once data exists).
