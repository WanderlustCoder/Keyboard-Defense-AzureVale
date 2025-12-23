---
id: passive-gold-dashboard
title: "Publish passive timeline + gold history dashboards"
priority: P2
effort: M
depends_on: [diagnostics-dashboard]
produces:
  - scripts/ci/passiveGoldDashboard.mjs
  - docs/codex_dashboard.md (passive/gold tiles)
status_note: docs/status/2025-11-07_passive_timeline.md
backlog_refs:
  - "#41"
  - "#79"
---
> Note: This document targets the retired web version (`apps/keyboard-defense`). The current Godot project lives at `apps/keyboard-defense-godot`; see `docs/GODOT_PROJECT.md` and `apps/keyboard-defense-godot/README.md` for active workflows.

**Context**  
`scripts/passiveTimeline.mjs` and the new `recentGoldEvents` overlay already emit
rich unlock/economy data, but CI still uploads raw CSV/JSON artifacts that nobody
sees unless they download them. We need Codex automation that merges those feeds,
publishes Markdown dashboards, and highlights spikes so reviewers spot passive
regressions without spelunking artifacts. This also addresses the gold event
history follow-up from `docs/status/2025-11-08_gold_event_history.md`.

## Steps

1. **Codex fixture + aggregator**
   - Capture representative `analytics:passives` and tutorial smoke artifacts in `docs/codex_pack/fixtures/passives/`.
   - Create `scripts/ci/passiveGoldDashboard.mjs` that:
     - Calls `scripts/passiveTimeline.mjs --ci` (or imports it) to produce normalized rows.
     - Reads the `recentGoldEvents` entries emitted by smoke runs.
     - Emits `artifacts/summaries/passive-gold.ci.json` plus Markdown with sparkline-ready tables (passive unlock cadence, latest gold deltas).
2. **CI wiring**
   - Update tutorial smoke + breach workflows to run the aggregator after analytics export.
   - Upload the summary JSON with a stable artifact name and append the Markdown to `$GITHUB_STEP_SUMMARY`.
   - Add failure thresholds (e.g., `MAX_PASSIVE_LAG_MS`) that warn/fail when unlock cadence drifts.
3. **Dashboard + docs**
   - Extend `docs/codex_dashboard.md` with a Passive Unlocks tile showing the newest Markdown snippet (link to JSON for deep dives).
   - Note the workflow in `CODEX_PLAYBOOKS.md` and `CODEX_GUIDE.md` so Codex knows how to regenerate the dashboard locally.
4. **Status + backlog bookkeeping**
   - Update both relevant status notes to reference this task once the automation lands.

## Implementation Notes

- **Input contract**
  - Treat `passiveTimeline` rows and `recentGoldEvents` entries as append-only logs.
  - Normalize timestamps to ISO strings plus elapsed milliseconds so CI diffs remain stable.
  - Tag each record with `{scenario, buildId, waveIndex}` so dashboards can be filtered when multiple smoke scenarios run in parallel.
- **Aggregator structure**
  - Split `passiveGoldDashboard.mjs` into data loaders (`loadTimeline`, `loadGoldEvents`), calculators (`deriveUnlockLag`, `calculateGoldVelocity`), and renderers (JSON + Markdown) so tests can target each layer.
  - Emit both Markdown tables (human readable) and machine-friendly JSON arrays, e.g.
    ```json
    {
      "scenario": "tutorial-smoke",
      "passives": [{ "id": "castle_regen", "wave": 3, "delta": 0.5, "goldDelta": 120 }],
      "goldVelocity": { "last3": 180, "rollingAvg": 95 }
    }
    ```
  - Add `--threshold-max-unlock-gap-ms`, `--threshold-gold-velocity-drop` flags so CI can warn when passives unlock too late or gold income collapses.
- **CI glue**
  - After analytics export, run `node scripts/ci/passiveGoldDashboard.mjs --timeline artifacts/analytics/passiveTimeline.json --gold artifacts/analytics/recentGoldEvents.json --out artifacts/summaries/passive-gold.ci.json --mode warn`.
  - Upload both JSON + Markdown, and append the Markdown snippet to `$GITHUB_STEP_SUMMARY` with collapsible sections per scenario.
- **Docs + playbooks**
  - Document the workflow under a new “Passive cadence dashboard” subsection in `CODEX_PLAYBOOKS.md` and list the CLI invocation inside `CODEX_GUIDE.md` + `docs/docs_index.md`.
  - Capture a screenshot or snippet of the dashboard tile inside `docs/status/2025-11-07_passive_timeline.md` when closing the follow-up.
- **Automation support**
  - Provide fixtures:
    - `docs/codex_pack/fixtures/passives/sample.timeline.json`
    - `docs/codex_pack/fixtures/passives/sample.gold-events.json`
    - Combined `sample.dashboard.json` for regression tests.
  - Write Vitest tests that load those fixtures, run the aggregator, and snapshot both Markdown + JSON outputs to catch schema drift.

## Deliverables & Artifacts

- `scripts/ci/passiveGoldDashboard.mjs` with unit tests living next to other CI scripts.
- Updated npm script (e.g., `npm run analytics:passives:dashboard`) that shells into the aggregator with fixtures for local devs.
- `artifacts/summaries/passive-gold*.json|md` produced by CI/smoke runs.
- Dashboard tile + doc references pointing to the summary.
- Status note updates pointing back to this task once delivered.

## Acceptance criteria

- CI dashboards list at least the last three passive unlock events alongside their corresponding gold deltas with no manual artifact download.
- Aggregator script accepts fixtures for local dry runs and exposes thresholds for alerting.
- `docs/codex_dashboard.md` links to the summary JSON/Markdown so Codex has a single pane of glass for economy cadence reviews.

## Verification

- npm run analytics:passives -- --merge-gold --out temp/passives.ci.json docs/codex_pack/fixtures/passives
- node scripts/ci/passiveGoldDashboard.mjs docs/codex_pack/fixtures/passives/sample.json --summary artifacts/summaries/passive-gold.fixture.json --mode warn
- npm run test -- passiveTimeline
- npm run codex:validate-pack
- npm run codex:validate-links
- npm run codex:status






