---
id: gold-timeline-dashboard
title: "Publish gold timeline analytics + derived metrics"
priority: P2
effort: M
depends_on: [gold-summary-dashboard-integration, passive-gold-dashboard]
produces:
  - scripts/ci/goldTimelineDashboard.mjs
  - artifacts/summaries/gold-timeline.ci.json
status_note: docs/status/2025-11-08_gold_timeline_cli.md
backlog_refs:
  - "#45"
  - "#79"
---
> Note: This document targets the retired web version (`apps/keyboard-defense`). The current Godot project lives at `apps/keyboard-defense-godot`; see `docs/GODOT_PROJECT.md` and `apps/keyboard-defense-godot/README.md` for active workflows.

**Context**  
`scripts/goldTimeline.mjs` already emits CSV/JSON economy timelines and can merge
passive unlock metadata, but CI still uploads the raw artifact with no automated
dashboards or alerts. Reviewers must download the files to see spikes, and we lack
derived metrics (rolling sums, averages) that would make alerts meaningful.

## Steps

1. **Derived metrics + fixtures**
   - Extend `goldTimeline.mjs` (or a sibling helper) to compute rolling sums,
     rolling averages, and per-scenario aggregates (median delta, max spend streak).
   - Capture fixtures in `docs/codex_pack/fixtures/gold-timeline/` for tutorial
     smoke, castle breach, and sandbox runs to drive local dry-runs.
2. **Dashboard script**
   - Add `scripts/ci/goldTimelineDashboard.mjs` that:
     - Consumes the existing CLI output (or invokes it directly).
     - Produces `artifacts/summaries/gold-timeline.ci.json` plus Markdown showing
       the last N events, derived metrics, and merged passive info.
     - Supports thresholds (e.g., `MAX_NEG_STREAK`) which warn/fail CI when breached.
3. **CI + docs integration**
   - Wire the script into tutorial smoke + breach workflows, uploading the summary
     artifact and appending Markdown to `$GITHUB_STEP_SUMMARY`.
   - Update `docs/codex_dashboard.md` and `CODEX_PLAYBOOKS.md` with instructions for
     regenerating the timeline dashboard locally.
   - Add troubleshooting guidance so Codex knows how to refresh baselines when
     thresholds change.

## Implementation Notes

- **CLI contract**
  - `scripts/ci/goldTimelineDashboard.mjs` should accept:
    - `--timeline <file>` (or multiple), `--passives <file>`, `--percentiles <file>`, `--out-json <file>`, `--out-md <file>`, and `--mode info|warn|fail`.
  - Provide a fixtures shortcut (`--fixtures docs/codex_pack/fixtures/gold-timeline`) to simplify local dry-runs.
  - Output JSON must follow `{scenario, metrics, derived, events, alerts}` so downstream tools (`goldAnalyticsBoard`) can ingest it directly.
- **Derived metrics implementation**
  - Rolling windows: compute for last 3/5/10 events using sliding window helpers.
  - Streak detection: track gain/spend streak lengths while iterating events.
  - Baseline deltas: when `--percentiles` provided, emit `varianceVsMedian`, `varianceVsP90`.
  - Passive merge: annotate events with `passiveId` + `delta` whenever the passive timeline indicates an unlock at the same timestamp.
- **Alerting**
  - Accept threshold flags (`--warn-max-negative-streak-ms`, `--fail-max-delta`, `--warn-min-average`) and include them in the JSON/Markdown so reviewers know which limits triggered.
  - Markdown should show alert badges (✅/⚠️/❌) with quick remediation hints (“Check passive unlock timings”).
- **CI wiring**
  - After `npm run analytics:gold`, run the dashboard CLI for each scenario, upload `artifacts/summaries/gold-timeline*.json|md`, and append Markdown to `$GITHUB_STEP_SUMMARY`.
  - Ensure the Codex dashboard tile links to both Markdown + JSON.
- **Docs & playbooks**
  - Add `npm run analytics:gold:timeline` (wrapper) to `package.json` for local devs.
  - Document the wrapper + fixture workflow in `CODEX_GUIDE.md`, `docs/docs_index.md`, and a new “Gold timeline dashboard” subsection inside `CODEX_PLAYBOOKS.md`.
  - Update status notes (`docs/status/2025-11-08_gold_timeline_cli.md`, Nov-20 gold dashboard series) once the tile lands.
- **Testing & fixtures**
  - Store baseline fixtures under `docs/codex_pack/fixtures/gold-timeline/` (normal, spike, regression).
  - Write Vitest tests covering derived metrics, passive merge, baseline variance, threshold handling, and Markdown snapshot stability. Include negative tests (missing inputs).

## Deliverables & Artifacts

- `scripts/ci/goldTimelineDashboard.mjs` + tests/fixtures.
- CI workflow updates uploading timeline summaries + dashboards referencing them.
- Documentation updates (guide, playbook, docs_index, status) describing regen commands + troubleshooting.

## Implementation Detail

- **Derived metric catalog**
  - Rolling windows: last 3/5/10 events (gain, spend, net) plus cumulative totals per scenario.
  - Streak detection: longest spend streak, longest gain streak, most recent net-negative stretch length.
  - Passive merge: include `passiveId`, `delta`, and `unlockWave` on rows where passive events occur so dashboards can correlate spikes.
  - Baseline comparison: load optional `goldPercentiles` baseline to show variance vs median/p90 deltas.
- **Script structure**
  - `goldTimelineDashboard.mjs` should accept multiple inputs via flags (`--timeline`, `--passives`, `--percentiles`), defaulting to the latest artifacts when run in CI.
  - Output schema: `{ scenario, metrics: {...}, events: [...], alerts: [...] }` so other tooling (e.g., `goldAnalyticsBoard`) can ingest the same JSON.
  - Markdown renderer should highlight:
    - Table of most recent events with emoji/badge for gain/spend.
    - Derived metrics summary (rolling averages, streaks, variance vs baseline).
    - Alert section listing any threshold breaches with actionable text.
- **Thresholds & modes**
  - Support `--warn-max-negative-streak`, `--fail-max-delta`, `--warn-min-average` to tune per workflow.
  - Honor `--mode info|warn|fail` similar to other CI scripts so nightly jobs can warn while blocking release branches.
- **Docs + tooling**
  - Add `npm run analytics:gold:timeline` (or extend the existing script) to invoke the dashboard with fixtures.
  - Document fixture regeneration + CLI usage in `CODEX_GUIDE.md`, `CODEX_PLAYBOOKS.md`, and `docs/docs_index.md`.
  - Update relevant status notes (`docs/status/2025-11-08_gold_timeline_cli.md`, Nov-20 gold dashboard entries) when the tile lands.
- **Testing**
  - Provide fixtures under `docs/codex_pack/fixtures/gold-timeline/` representing normal, spike, and regression scenarios.
  - Add Vitest tests that assert derived metric calculations, threshold handling, and Markdown snapshot stability.
  - Include negative tests (missing inputs, malformed data) to ensure the CLI fails clearly with actionable messages.

## Deliverables & Artifacts

- `scripts/ci/goldTimelineDashboard.mjs` + unit tests and fixtures.
- Updated CI workflow steps (tutorial smoke, breach, nightly) uploading `artifacts/summaries/gold-timeline*.json|md`.
- Dashboard tile + documentation pointers linking to latest outputs.
- Status note updates referencing this task once dashboards are published.

## Acceptance criteria

- CI dashboards present the latest gold timeline (events + derived metrics) without
  manual artifact downloads.
- Thresholds ensure regressions in economy pacing fail or warn automatically.
- Codex guide/playbooks describe how to regenerate the dashboard + fixtures.

## Verification

- npm run analytics:gold -- --merge-passives --out temp/gold-timeline.json docs/codex_pack/fixtures/gold-timeline
- node scripts/ci/goldTimelineDashboard.mjs docs/codex_pack/fixtures/gold-timeline/smoke.json --summary temp/gold-timeline.fixture.json --mode warn
- npm run test -- goldTimeline
- npm run codex:validate-pack
- npm run codex:validate-links
- npm run codex:status






