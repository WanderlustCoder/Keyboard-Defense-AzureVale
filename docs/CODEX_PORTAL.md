# Codex Portal

This portal consolidates every instruction set, script, and artifact Codex needs
to develop Keyboard Defense end-to-end. Use it as your starting point each time
you work on the project.

## Quick links

| Area | Doc |
| --- | --- |
| Global workflow | `docs/CODEX_GUIDE.md` |
| Domain playbooks (automation, UI, analytics, docs) | `docs/CODEX_PLAYBOOKS.md` |
| Automation tasks & snippets | `docs/codex_pack/` |
| Codex dashboard (live status) | `docs/codex_dashboard.md` |
| Backlog | `apps/keyboard-defense/docs/season1_backlog.md` |
| Status notes | `docs/status/` |

## Command dashboard

```bash
# Install dependencies
npm ci
cd apps/keyboard-defense
npm ci

# Core Codex checks
npm run lint
npm run test
npm run codex:validate-pack
npm run codex:validate-links
npm run codex:status
npm run codex:dashboard
npm run codex:next        # prints the next TODO task
```

Run all commands from `apps/keyboard-defense/` unless noted.

## Task lifecycle

1. `npm run codex:next` → identifies the highest-priority TODO task.
2. Claim it in `docs/codex_pack/task_status.yml`.
3. Follow the task file under `docs/codex_pack/tasks/`.
4. Apply any domain-specific steps from `docs/CODEX_PLAYBOOKS.md`.
5. Run the command dashboard + task-specific verification.
6. Update status note Follow-up links, backlog references, Codex metadata, and regenerate the dashboard (`npm run codex:dashboard`).
7. Commit with task/backlog references.

## Fixtures & snippets

- Automation CLI dry-runs: `docs/codex_pack/fixtures/*.json`
- CI snippet: `docs/codex_pack/snippets/status-ci-step.md`
- Verification boilerplate: `docs/codex_pack/snippets/verify-task.md`
- Task template: `docs/codex_pack/templates/task.md`

Keep this portal updated when new guides, playbooks, or scripts are added so
Codex always has a single navigation surface.
