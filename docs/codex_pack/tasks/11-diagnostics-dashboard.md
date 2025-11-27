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

## Implementation Notes

- **Analytics exports**
  - Extend `scripts/analyticsAggregate.mjs` (or a helper) to emit:
    - `goldDelta.events` (timestamp, delta, type), `goldDelta.stats` (avg/min/max, largest spike, streak data).
    - `passives.timeline` (passiveId, level, delta, time, waveIndex, gold impact).
  - Update `docs/analytics_schema.md` + CSV ordering; refresh fixtures covering gold/passive fields.
- **CLI helper**
  - Add `scripts/ci/diagnosticsDashboard.mjs` that ingests analytics artifacts and writes:
    - `artifacts/summaries/diagnostics-dashboard.ci.json`
    - Markdown snippet summarizing gold delta streaks + upcoming passives.
  - Flags: `--gold <file>`, `--passives <file>`, `--out-json`, `--out-md`, `--mode info|warn|fail`, `--fixtures`.
- **Dashboard wiring**
  - Update `scripts/generateCodexDashboard.mjs` to embed “Gold Delta Trend” and “Passive Unlock Timeline” tiles linking to the new summary JSON.
  - Include sparkline data (array of deltas) so front-end dashboards can render charts later.
- **CI integration**
  - Run the new CLI after analytics exports in Build/Test + breach workflows, upload JSON/Markdown, append Markdown to `$GITHUB_STEP_SUMMARY`.
  - Expose thresholds (`--warn-max-negative-delta`, `--fail-passive-lag-ms`) so CI warns/fails on anomalies.
- **Docs + fixtures**
  - Add `docs/codex_pack/fixtures/diagnostics-dashboard.json|md`.
  - Document the workflow in `CODEX_GUIDE.md`, `CODEX_PLAYBOOKS.md` (Automation + Analytics), and note commands in `docs/docs_index.md`.
  - Update `docs/status/2025-11-07_diagnostics_passives.md` once the dashboard lands, including screenshot/snippet references.
- **Testing**
  - Vitest coverage for analytics calculations + CLI outputs (JSON + Markdown snapshot tests).
  - Negative tests for missing inputs / invalid data to ensure the CLI fails clearly.

## Deliverables & Artifacts

- Enhanced analytics exports + schema/docs updates.
- `scripts/ci/diagnosticsDashboard.mjs` + fixtures/tests.
- Codex dashboard + CI summary updates referencing gold delta/passive panels.
- Guide/playbook/status documentation describing the workflow.

## Acceptance criteria

- Analytics CLI outputs gold delta + passive unlock fields; schema + fixtures updated.
- Static dashboard shows gold delta trends and passive unlock timeline with links to
  artifacts.
- CI job summary references the new panels (or provides direct links).

## Data definition & events

- **Gold delta envelope**
  - Persist `{ timestampMs, rawDelta, netGold, source }` for every tracked event,
    plus derived streak data (`streakId`, `streakDelta`, `streakLen`).
  - Tag events from scripted waves (tutorial, castle breach) with `scenarioId`
    so CI can group comparisons.
  - Emit rolling aggregates in the summary JSON:
    - `delta.stats`: `{ avg, median, min, max, p90, largestSpend, largestGain }`.
    - `delta.alerts`: threshold breaches with `severity`, `message`, `recommendation`.
- **Passive unlock timeline**
  - Normalize unlocks to `{ passiveId, passiveName, waveIndex, level, goldCost, effect }`.
  - Attach HUD state snapshots when available so we can link to UI screenshots
    from the dashboard.
  - Track lag metrics (`secondsFromAvailable`, `wavesFromAvailable`) to highlight
    passives that players delay too long.

## Dashboard layout targets

- Tile 1: **Gold Delta Sparkline**
  - Primary stat row: latest delta, rolling average, percent change vs. baseline.
  - Secondary section: table of top 5 spikes/dips with context (wave, passive,
    taunt, tower placement).
  - Link to raw JSON + Markdown summary and provide CLI repro command.
- Tile 2: **Passive Unlock Timeline**
  - Timeline visualization (stacked rows per passive) plus quick badges for
    “delayed unlock” and “early unlock”.
  - Inline filters for scenario + wave range (even if manual for now, describe
    the JSON shape so UI can read it later).
  - CTA linking to `passiveTimeline.mjs` instructions inside `CODEX_PLAYBOOKS.md`.
- Tile 3 (stretch): **Gold Delta vs. Passive Overlay**
  - Combined view plotting delta spikes alongside passive unlock timestamps to
    highlight correlation/regressions.

## Observability & testing checklist

- Add `vitest` suites for:
  - Parsing analytics artifacts into the summary model (happy + edge cases).
  - Markdown snapshot verifying sparkline stats + alert copy.
  - CLI flag combinations (`--fixtures`, `--mode warn`, missing inputs).
- Include integration tests that load fixtures into `scripts/generateCodexDashboard.mjs`
  so we catch layout regressions whenever the JSON schema changes.
- Provide a `npm run analytics:diagnostics --fixtures` smoke command for Codex
  to run locally; document sample output in `docs/codex_dashboard.md`.
- Log `generatedBy`, `gitSha`, `analyticsSchemaVersion`, and `fixturesVersion`
  in every JSON artifact to keep dashboards traceable.

## Verification

- npm run lint
- npm run test
- npm run codex:validate-pack
- npm run codex:validate-links
- npm run codex:dashboard
- Run the analytics CLI against sample artifacts to confirm new fields populate
  (e.g., `node scripts/analyticsAggregate.mjs --input artifacts/smoke/*` once data exists).
