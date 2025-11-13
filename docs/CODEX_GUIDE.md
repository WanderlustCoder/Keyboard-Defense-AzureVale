# Codex Development Guide

This project is built primarily by Codex. Use this guide as the single entry
point for finding work, running commands, and updating documentation. For
domain-specific checklists (automation, gameplay/UI, analytics), see
`docs/CODEX_PLAYBOOKS.md`.

## 1. Where to find work

1. **Automation tasks** – `docs/codex_pack/manifest.yml` + `task_status.yml`.
   - Follow `docs/codex_pack/CODEX_RUNBOOK.md` to claim and deliver these.
2. **Feature/backlog items** – `apps/keyboard-defense/docs/season1_backlog.md`.
   - Each entry notes the Codex task (when applicable). If a backlog item has no
     task yet, author one via `docs/codex_pack/templates/task.md`.
3. **Historical context** – `docs/status/*.md`. Every status note should end with
   a “Follow-up” (or “Notes”) section linking to the relevant Codex task. When
   you finish work, update the status note accordingly.

## 2. Execution loop

1. Pick the next task/backlog item (see above).
2. Update `docs/codex_pack/task_status.yml` if you’re claiming an automation task.
3. Implement code/tests/scripts exactly as described in the backlog/task/status
   chain.
4. Update documentation:
   - Status notes: add/adjust the Follow-up section with the canonical task link.
   - Backlog: mark the item as done or note the active Codex task.
   - Codex Pack: ensure `manifest.yml`, task file, and `task_status.yml` stay
     in sync (new tasks must include `status_note` + `backlog_refs`).
5. Run the verification checklist (below) before committing.
6. Summarize your changes referencing task IDs/backlog numbers.

## 3. Command checklist

From `apps/keyboard-defense/`:

```bash
npm install
npm run lint
npm run test
npm run codex:validate-pack
npm run codex:validate-links
npm run codex:status
```

Run additional commands listed under each Codex task’s `## Verification`
section (e.g., Playwright snapshots, CLI dry-runs with fixtures). For scripts
that require sample data, use the JSON files in `docs/codex_pack/fixtures/`.

## 4. Documentation rules

- **Status notes** must reference the authoritative Codex task path
  (`docs/codex_pack/tasks/<id>.md`) inside their Follow-up section. If no task
  exists yet, say so explicitly (“Future work will add a Codex task once scoped”).
- **Codex tasks** must include:
  - `status_note`
  - `backlog_refs`
  - `## Steps`, `## Acceptance criteria`, and `## Verification`
  - Links to snippets/fixtures when applicable.
- **Backlog items** should call out the Codex task IDs that deliver them.
- Use `docs/codex_pack/templates/task.md` when drafting new tasks and
  `docs/codex_pack/snippets/verify-task.md` as a starter verification block.

## 5. Tooling & scripts

| Command | Purpose |
| --- | --- |
| `npm run codex:status` | Prints the task → state table. |
| `npm run codex:validate-pack` | Ensures manifest/tasks/tracker are consistent and that only one owner has an in-progress task. |
| `npm run codex:validate-links` | Confirms every status note follow-up points to a real task and every task references an existing status note. |
| `node scripts/ci/emit-summary.mjs --smoke docs/codex_pack/fixtures/smoke-summary.json --gold docs/codex_pack/fixtures/gold-summary.json` | Local dry-run for the CI summary task. |
| `node scripts/ci/goldPercentileGuard.mjs docs/codex_pack/fixtures/gold-summary.json` | Validates percentile metadata before dashboards ingest gold summary artifacts and writes the guard summary JSON/Markdown. |
| `node scripts/ci/passiveGoldDashboard.mjs docs/codex_pack/fixtures/passives/sample.json --summary temp/passive-gold.fixture.json --mode warn` | Generates the passive unlock + gold dashboard summary locally (mirrors the CI passive/gold step). |
| `node scripts/ci/goldTimelineDashboard.mjs docs/codex_pack/fixtures/gold-timeline/smoke.json --summary temp/gold-timeline.fixture.json --mode warn` | Produces the gold timeline dashboard summary (derived metrics + Markdown) matching the CI step. |
| `node scripts/ci/goldSummaryReport.mjs docs/codex_pack/fixtures/gold-summary.json --summary temp/gold-summary-report.fixture.json --mode warn` | Surfaces gold summary metrics (median/p90 gains/spends, net delta) and thresholds exactly like the CI gold summary dashboard step. |
| `node scripts/ci/castleBreachSummary.mjs docs/codex_pack/fixtures/castle-breach/base.json --summary temp/castle-breach-summary.fixture.json --mode warn` | Aggregates castle breach artifacts (time-to-breach, turret loadouts, warnings) and mirrors the CI Castle Breach Watch tile. |
| `node scripts/ci/goldAnalyticsBoard.mjs --summary <file> --timeline <file> --passive <file> --percentile-guard <file> --percentile-alerts <file> --out temp/gold-analytics-board.fixture.json` | Aggregates the gold summary, timeline, passive, and percentile guard feeds into one Markdown/JSON bundle for dashboards and CI summaries (task `gold-analytics-board`). |
| `node scripts/ci/goldPercentileBaseline.mjs docs/codex_pack/fixtures/gold/*.json --baseline-out docs/codex_pack/fixtures/gold/gold-percentiles.baseline.json --thresholds-out apps/keyboard-defense/scripts/ci/gold-percentile-thresholds.json --check` | Regenerates percentile baselines/thresholds or validates that the committed files match the latest analytics outputs (task `gold-percentile-baseline-refresh`). |
| `node scripts/ci/diagnosticsDashboard.mjs docs/codex_pack/fixtures/diagnostics-dashboard/sample.analytics.json --summary temp/diagnostics-dashboard.fixture.json --markdown temp/diagnostics-dashboard.fixture.md --mode warn` | Builds the gold delta + passive unlock diagnostics dashboard summary (JSON + Markdown) exactly like the CI step (task `diagnostics-dashboard`). |
| `node scripts/analytics/goldDeltaAggregator.mjs docs/codex_pack/fixtures/gold-delta-aggregates/sample.analytics.json --output temp/gold-delta-aggregates.fixture.json --markdown temp/gold-delta-aggregates.fixture.md --mode warn` | Rolls gold event streams into per-wave aggregates (task `gold-delta-aggregates`). |
| `node scripts/hudScreenshots.mjs --ci --out artifacts/screenshots` | Captures deterministic HUD/Tutorial screenshots and writes `*.meta.json` sidecars (including condensed-state + taunt metadata) for docs/hud_gallery.md and CI summaries. |
| `node scripts/docs/renderHudGallery.mjs --input artifacts/screenshots --output docs/hud_gallery.md` | Rebuilds the HUD screenshot gallery with the latest `*.meta.json` badges emitted by `scripts/hudScreenshots.mjs`. |
| `npx playwright test --config playwright.config.ts --project=visual --grep \"hud-main|options-overlay|tutorial-summary|wave-scorecard\"` | Visual verification for HUD screenshots. |

## 6. CI expectations

- Mirror the local checklist inside GitHub Actions (see
  `docs/codex_pack/snippets/status-ci-step.md`). Codex commits should never
  bypass these checks.
- When adding new workflows, include a `Validate Codex Pack/Links/Status`
  block so automation fails fast if documentation drifts.

Keep this guide updated whenever the process changes. If Codex needs new
fixtures, commands, or templates, add them here and in the relevant scripts so
future automation can rely on the documented contract.
