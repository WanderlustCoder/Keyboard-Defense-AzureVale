# Automation Blueprint Pack (for Codex CLI)
> Note: This pack targets the retired web version (`apps/keyboard-defense`). The current Godot project lives at `apps/keyboard-defense-godot`; see `docs/GODOT_PROJECT.md` and `apps/keyboard-defense-godot/README.md` for active workflows.

This pack turns the agreed automation plan into **actionable, bite-sized tasks** with code snippets.
Point your Codex CLI (or any docs/task runner) at this folder. Each task has YAML front-matter that
exposes `id`, `priority`, and outputs, and the pack includes ready-to-copy **snippets**.

> **Scope:** derived from your `/docs` bundle - CI & smoke orchestration, gold/economy artifacts,
> dev-server monitoring, screenshot capture, asset integrity, and the DX/tooling baseline.

## Structure

```
codex_pack/
  README.md
  CODEX_RUNBOOK.md
  manifest.yml
  task_status.yml
  tasks/
    01-ci-step-summary.md
    02-ci-guards.md
    03-playwright-visual-diffs.md
    04-scenario-matrix.md
    05-ci-matrix-and-concurrency.md
    06-semantic-release.md
    07-static-dashboard.md
    08-hermetic-ci.md
    09-type-lint-test-gates.md
    10-schema-contracts.md
  snippets/
    emit-summary.mjs
    validate.mjs
    run-matrix.mjs
    guards.example.yml
    playwright.config.additions.ts
    workflow.patch.yaml
  fixtures/
    smoke-summary.json
    gold-summary.json
    traceability-tests.json
    traceability-report.json
    audio-intensity/
      summary.json
      summary.csv
    responsive/
      condensed-audit.json
```
Use the fixture JSON files when running CLI dry-runs (see `tasks/01-ci-step-summary.md`). For example,
`responsive/condensed-audit.json` feeds the condensed HUD audit rows that now appear in CI summaries.

## How to use

1. Read `manifest.yml` to see the task list and priorities.
2. For each task in `tasks/`, follow the **Steps** and copy the code from `snippets/`.
3. Prefer small PRs that land tasks **in order** (P1 first).
4. Run `npm run codex:validate-pack` (from `apps/keyboard-defense`) before every commit to ensure metadata stays consistent.
5. Run `npm run codex:validate-links` to confirm status notes and tasks cross-reference correctly.
6. Codex operators must follow `CODEX_RUNBOOK.md` (automation-specific loop) and the global `docs/CODEX_GUIDE.md`.
7. GitHub Actions `codex-dashboard-nightly` regenerates `docs/codex_dashboard.md` + `docs/CODEX_PORTAL.md` daily (05:30 UTC) using gold fixtures; dispatch inputs (`summary`, `timeline`, `passive`, `guard`, `alerts`) let you point at real artifacts without editing the workflow.

## Source-of-truth mapping

| Concern | Status note / historical context | Active task | Backlog reference |
| --- | --- | --- | --- |
| CI step summaries fed by artifacts | `docs/status/2025-11-18_devserver_smoke_ci.md` documented the smoke harness and called for richer CI output. | `tasks/01-ci-step-summary.md` | Backlog #79 |
| Declarative CI guards for smoke/gold/breach/screenshots | `docs/status/2025-11-14_gold_summary_ci_guard.md` launched percentile enforcement. | `tasks/02-ci-guards.md` | Backlog #82 |
| Visual regression on HUD states | `docs/status/2025-11-06_hud_screenshots.md` shipped deterministic captures + "introduce diff tooling." | `tasks/03-playwright-visual-diffs.md` | Backlog #94 |
| CI coverage/concurrency hygiene | `docs/status/2025-11-18_devserver_bin_resolution.md` recorded the Windows bin fix and pipeline gaps. | `tasks/05-ci-matrix-and-concurrency.md` | Backlog #82 |
| Schema + analytics contracts | `docs/status/2025-11-08_gold_summary_cli.md` captured schema drift risks. | `tasks/10-schema-contracts.md` | Backlog #76 |

Workflow guidance:
1. **Status notes** capture what shipped plus any learnings, then reference the single follow-up task in this pack.
2. **Codex tasks** own the actionable next step (files to touch, acceptance criteria, snippets). Update only the task when implementation details change.
3. **Backlog items** retain the high-level objective and point back to the relevant status note/task combo if more context is needed.

Authoring tips:
- When you add "Follow-up" text to `docs/status/*`, link directly to the task ID here instead of duplicating instructions.
- If a new automation idea appears in a backlog/status entry, immediately add a Codex task so every plan funnels through this pack.
- Use `templates/task.md` when drafting a new entry so the required front-matter (status note, backlog refs, etc.) stays consistent and include a `## Verification` section (see `snippets/verify-task.md` for a boilerplate checklist).

## Tracking & metadata

- `manifest.yml` records `status_note`, `backlog_refs`, and the current `status` for each task so scripts can cross-check dependencies.
- `task_status.yml` is the lightweight progress tracker (owner + state). Update it whenever a task moves or gets picked up.
- `CODEX_RUNBOOK.md` documents the end-to-end workflow Codex follows when acting as the sole developer.
- `npm run codex:validate-pack` (from `apps/keyboard-defense`) runs automated checks that ensure the manifest, tasks, and tracker stay in sync and that only one owner holds an `in-progress` task at a time.
- `npm run codex:validate-links` ensures every status note “Follow-up” entry references a real Codex task (and vice versa).
- `npm run codex:status` prints the current task table for quick reviews.

## CI integration

Add these steps to the Build/Test job so automation fails fast when metadata drifts:

```yaml
- name: Validate Codex Pack
  working-directory: apps/keyboard-defense
  run: npm run codex:validate-pack

- name: Validate Status Links
  working-directory: apps/keyboard-defense
  run: npm run codex:validate-links

- name: Codex Task Tracker
  working-directory: apps/keyboard-defense
  run: npm run codex:status
```

See `snippets/status-ci-step.md` for a ready-to-copy block. Optionally follow it with a
`git diff --exit-code docs/codex_pack/task_status.yml` check to ensure the tracker wasn't
modified unexpectedly.

## Assumptions

- Artifact paths follow the docs: `artifacts/monitor/dev-monitor.json` (legacy: `monitor-artifacts/run.json`), `artifacts/smoke/devserver-smoke-summary*.json`,
  `artifacts/screenshots/screenshots-summary.ci.json`, `artifacts/*/gold-summary.ci.json`,
  `artifacts/castle-breach.ci.json`. Adjust in snippets if your repo differs.
- Node >= 18, Playwright installed in CI with a pinned `PLAYWRIGHT_BROWSERS_PATH`.
