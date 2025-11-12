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
  the Playwright visual tests once `visual-diffs` lands.

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
  5. Keep fixtures/sample artifacts under `docs/codex_pack/fixtures` for future
     runs.

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
