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
