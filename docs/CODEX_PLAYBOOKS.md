# Codex Playbooks

Use these playbooks when tackling new work. Each section maps a type of work to
the relevant docs, Codex tasks, verification commands, and documentation
expectations.

## Automation & CI Playbook

- **Read first**: `docs/codex_pack/README.md`, `docs/codex_pack/CODEX_RUNBOOK.md`.
- **Typical flow**
  1. Pick the highest-priority task from `docs/codex_pack/manifest.yml`.
  2. Claim it in `docs/codex_pack/task_status.yml` (`state: in-progress` and your
     owner id).
  3. Follow the task instructions (snippets + fixtures live under
     `docs/codex_pack/snippets` and `docs/codex_pack/fixtures`).
  4. Run verification:
     ```bash
     npm run lint
     npm run test
     npm run codex:validate-pack
     npm run codex:validate-links
     npm run codex:status
     ```
     plus any task-specific commands listed under `## Verification`.
  5. Update documentation (status note follow-up, backlog reference, manifest,
     task file, tracker).
  6. Commit with the task id/backlog number in the message.
- **CI**: ensure `.github/workflows/ci-e2e-azure-vale.yml` contains the Codex
  validation block (see `docs/codex_pack/snippets/status-ci-step.md`).

## Gameplay & UI Playbook

- **Docs to read**
  - `docs/status/2025-11-17_hud_condensed_lists.md`
  - `docs/status/2025-11-17_responsive_layout.md`
  - `apps/keyboard-defense/docs/season1_backlog.md` (UI/backlog numbers)
- **Implementation steps**
  1. Identify the backlog item (e.g., #53 responsive layout). If no Codex task
     exists, create one via `docs/codex_pack/templates/task.md`.
  2. Update `docs/status/<date>_*.md` with both the change summary and a
     Follow-up reference to the Codex task.
  3. Modify code/tests under `apps/keyboard-defense/src/ui`, `public/styles.css`,
     etc.
  4. Run:
     ```bash
     npm run lint
     npm run test
     npm run codex:validate-pack
     npm run codex:validate-links
     ```
     plus any Playwright/HUD screenshot commands relevant to the change.
  5. Capture before/after context in the task file if needed (link screenshots or
     artifacts).
- **Artifacts**: for visual work, use `node scripts/hudScreenshots.mjs --ci` or
  the Playwright visual tests once `visual-diffs` lands. When new screenshots are
  captured, refresh `docs/hud_gallery.md` via
  `node scripts/docs/renderHudGallery.mjs --input artifacts/screenshots --meta artifacts/screenshots`.

### Canvas DPR Monitor & Transitions (task `canvas-dpr-monitor`)

1. **Files to touch**
   - `apps/keyboard-defense/src/ui/canvasResolution.ts` (helpers)
   - `apps/keyboard-defense/src/ui/diagnostics.ts` (HUD overlays)
   - `apps/keyboard-defense/src/controller/gameController.ts` (player settings)
   - `apps/keyboard-defense/src/config/ui.ts` (tuning knobs)
2. **Implementation outline**
   - Register `matchMedia("(resolution: Xdppx)")` listeners that call
     `calculateCanvasResolution` whenever `devicePixelRatio` changes. Debounce
     events so pinch/zoom doesn’t thrash renders.
   - Introduce a `ResolutionTransitionController` that captures the previous
     frame, fades it out (≈150 ms), and applies a hold period so overlays never
     “pop” mid-wave.
   - Persist the latest DPR multiplier in `playerSettings.hud.dpr` and emit a
     telemetry event (`ui.canvasResolutionChanged`) via `analyticsAggregate`.
3. **Testing**
   - Add Vitest coverage for the DPR listener (mock `matchMedia` + timers).
   - Extend analytics tests to assert the telemetry payload.
   - Optionally add a DOM/Vitest test to confirm fade classes toggle as expected.
4. **Verification commands**
   ```bash
   npm run lint
   npm run test -- canvasResolution
   npm run test -- analyticsAggregate
   npm run codex:validate-pack
   npm run codex:validate-links
   npm run codex:status
   ```
   Then manually tweak zoom/devicePixelRatio in the browser to confirm smoother
   transitions.

## Analytics & Telemetry Playbook

- **Docs to read**
  - `docs/analytics_schema.md`
  - Gold/telemetry status notes (`docs/status/2025-11-08_gold_summary_cli.md`,
    `docs/status/2025-11-14_gold_summary_ci_guard.md`, etc.)
- **Execution**
  1. Locate the backlog item (#76 schema contracts, #101+ for gold metrics).
  2. Ensure a Codex task exists (e.g., `schema-contracts`, `ci-guards`).
  3. Update status notes with Follow-up links when creating new automation work.
  4. Run data validators/dry-runs (Ajv scripts, goldSummary CLI) plus the core
     command checklist.
    - Use `node scripts/ci/goldPercentileGuard.mjs artifacts/smoke` to verify
      gold summary artifacts before dashboards ingest them; the guard writes
      `artifacts/summaries/gold-percentile-guard*.json` + Markdown so CI
      summaries stay in sync.
    - Run `node scripts/ci/passiveGoldDashboard.mjs artifacts/smoke --summary artifacts/summaries/passive-gold.local.json --mode warn`
      to reproduce the passive unlock + gold dashboard output locally; CI uploads
      the resulting `artifacts/summaries/passive-gold*.json` files alongside the
      tutorial smoke and e2e bundles.
    - Use `node scripts/ci/goldTimelineDashboard.mjs artifacts/smoke --summary artifacts/summaries/gold-timeline.local.json --mode warn`
      to regenerate the derived gold timeline dashboard (net delta, spend streaks, recent events).
    - Run `node scripts/ci/goldSummaryReport.mjs artifacts/smoke/gold-summary.ci.json --summary artifacts/summaries/gold-summary-report.local.json --mode warn`
      to mirror the CI gold summary dashboard (median/p90 gains & spends, thresholds). Update baselines via `docs/codex_pack/fixtures/gold/gold-percentiles.baseline.json`
      and thresholds via `scripts/ci/gold-percentile-thresholds.json` when economy expectations shift.
    - Use `node scripts/ci/diagnosticsDashboard.mjs docs/codex_pack/fixtures/diagnostics-dashboard/sample.analytics.json --summary temp/diagnostics-dashboard.fixture.json --markdown temp/diagnostics-dashboard.fixture.md --mode warn`
      to preview the diagnostics dashboard (gold delta trend + passive timeline) before committing changes.
    - Run `node scripts/analytics/goldDeltaAggregator.mjs docs/codex_pack/fixtures/gold-delta-aggregates/sample.analytics.json --output temp/gold-delta-aggregates.fixture.json --markdown temp/gold-delta-aggregates.fixture.md --mode warn`
      to regenerate the per-wave gold delta report used by docs/dashboards (task `gold-delta-aggregates`).
    - Capture HUD screenshots (`node scripts/hudScreenshots.mjs --ci --out artifacts/screenshots`) after taunt/UI changes and confirm each `.meta.json` contains the `taunt` block so docs/hud_gallery.md and the Codex dashboard can surface the active callout without inspecting raw JSON.
 5. Keep fixtures/sample artifacts under `docs/codex_pack/fixtures` for future
     runs.

### Gold Analytics Board (task `gold-analytics-board`)

1. **Scope review** – read the Nov-20 gold status notes plus
   `docs/codex_pack/tasks/38-gold-analytics-board.md` to understand how the
   summary, timeline, passive, and percentile feeds should merge.
2. **Local dry-run** – stitch fixtures together before touching the CI pipeline:
   ```bash
   node scripts/ci/goldAnalyticsBoard.mjs \
     --summary docs/codex_pack/fixtures/gold-summary.json \
     --timeline docs/codex_pack/fixtures/gold-timeline/smoke.json \
     --passive docs/codex_pack/fixtures/passives/sample.json \
     --percentile-guard docs/codex_pack/fixtures/gold/percentile-guard.json \
     --percentile-alerts docs/codex_pack/fixtures/gold/gold-percentiles.baseline.json \
     --out temp/gold-analytics-board.fixture.json \
     --mode warn
   ```
   The CLI must emit both Markdown and JSON (`artifacts/summaries/gold-analytics-board*.json`).
3. **Dashboard wiring** – update `docs/codex_dashboard.md` plus CI workflows to
   publish the aggregated Markdown in `$GITHUB_STEP_SUMMARY`.
4. **Documentation** – list the new command and artifacts inside the Guide,
   Playbooks, and affected status notes. Keep `docs/codex_pack/task_status.yml`
   synced while implementing.

### Gold Percentile Baseline Refresh (task `gold-percentile-baseline-refresh`)

1. **Inputs** – gather the latest gold analytics outputs (smoke/e2e summary,
   timeline, passive) or use fixtures under `docs/codex_pack/fixtures/gold/`.
2. **Generator CLI** – run:
   ```bash
   node scripts/ci/goldPercentileBaseline.mjs \
     docs/codex_pack/fixtures/gold/*.json \
     --baseline-out docs/codex_pack/fixtures/gold/gold-percentiles.baseline.json \
     --thresholds-out apps/keyboard-defense/scripts/ci/gold-percentile-thresholds.json \
     --check
   ```
   The script should refresh baselines, optionally recompute thresholds, and
   exit non-zero if committed files are stale.
3. **Helper npm script** – wire `npm run gold:percentiles:refresh` (documented
   in `package.json`) so Codex automation can re-run the baseline workflow in a
   single command.
4. **Docs + status** – update `docs/status/2025-11-20_gold_percentile_alerts.md`,
   `CODEX_GUIDE.md`, and `docs/codex_dashboard.md` with the refresh procedure
   and the timestamp of the latest baseline.

### Castle Breach Analytics (task `castle-breach-analytics`)

1. **Prereqs**
   - Read `docs/status/2025-11-06_castle_breach_replay.md` and
     `docs/codex_pack/tasks/29-castle-breach-analytics.md`.
   - Ensure fixtures exist under `docs/codex_pack/fixtures/castle-breach/`.
2. **CLI instrumentation**
   - Extend `scripts/castleBreachReplay.mjs` with `--turret slot:type`,
     repeatable `--enemy` flags, and derived metrics (`timeToBreachMs`,
     `castleHpDelta`, `damageSource`, etc.).
   - Persist CLI options + metrics inside `artifacts/castle-breach*.json`.
3. **Summary generator**
   - Implement `scripts/ci/castleBreachSummary.mjs` that accepts one or more
     breach artifacts/fixtures, emits normalized JSON
     (`artifacts/summaries/castle-breach.ci.json`), and prints Markdown suitable
     for `$GITHUB_STEP_SUMMARY`. Support `--mode warn|fail` and thresholds like
     `--max-time-to-breach-ms`.
4. **CI/docs wiring**
   - Update `.github/workflows/ci-e2e-azure-vale.yml` to run the summary script
     after `npm run task:breach`, upload the JSON, and append Markdown.
   - Add a “Castle Breach Watch” tile to `docs/codex_dashboard.md`, plus
     guidance in `docs/CODEX_GUIDE.md`/`README.md`.
5. **Verification commands**
   ```bash
   node scripts/castleBreachReplay.mjs --seed 2025 --lane 1 --artifact temp/castle-breach.fixture.json --no-artifact
   node scripts/castleBreachReplay.mjs --seed 1337 --turret slot-2:arcane@2 --enemy brute:2 --enemy witch:1 --artifact temp/castle-breach-turrets.fixture.json --no-artifact
   node scripts/ci/castleBreachSummary.mjs docs/codex_pack/fixtures/castle-breach --summary temp/castle-breach-summary.fixture.json --mode warn
   npx vitest run tests/castleBreachReplay.test.js tests/castleBreachSummary.test.js
   npm run codex:validate-pack
   npm run codex:validate-links
   npm run codex:status
   ```

## Documentation & Status Playbook

- Every status note must end with a **Follow-up** block that lists the canonical
  Codex tasks using the `docs/codex_pack/tasks/<id>.md` path.
- When a Follow-up has no task yet, note that explicitly (“Future work will add
  a Codex task once scoped”) so the validator passes.
- Backlog entries should reference Codex task ids using the format
  `*(Codex: \`task-id\`)*`.
- Before committing documentation changes:
  ```bash
  npm run codex:validate-pack
  npm run codex:validate-links
  npm run codex:status
  ```
- Use `docs/CODEX_GUIDE.md` for the global workflow, while
  `docs/codex_pack/README.md` + task files cover the automation-specific
  details.

## Submission Checklist (all work)

1. `npm run lint`
2. `npm run test`
3. `npm run codex:validate-pack`
4. `npm run codex:validate-links`
5. `npm run codex:status` (ensure only one task is `in-progress` per owner)
6. Task-specific verification commands (Playwright, CLI fixtures, etc.)
7. Status note Follow-up links updated
8. Backlog references updated
9. `docs/codex_pack/task_status.yml` updated (if automation task)

Keep this file updated whenever new domains or workflows are added. The goal is
for Codex to follow these playbooks without human intervention.
