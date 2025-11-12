# Codex Automation Runbook

Codex acts as the sole developer for automation tasks. Follow this loop every
time you touch the project.

## 1. Choose the next task

1. Read `manifest.yml` and `task_status.yml`.
2. Pick the highest `priority` task whose `state` is `todo`.
3. If multiple tasks share the same priority, pick the one with the oldest
   `status_note` or the fewest dependencies.

## 2. Claim the task

1. Update `task_status.yml` for that task: set `state: in-progress` and record
   the GitHub username under `owner`.
2. Commit this change immediately so collaborators see the claim.

## 3. do the work

1. Open the task file in `tasks/`. It contains the context, steps, and snippet
   references.
2. Read the linked `status_note` and backlog entry to stay aligned with the
   original intent.
3. Implement code/tests/scripts exactly as described. Prefer small commits.
4. Run the acceptance criteria (tests, lint, CI dry-run) locally.

## 4. update metadata

Before committing:

1. Edit the task file with any findings (e.g., add resolved decisions, add new
   dependencies).
2. If the task spawned follow-up work, create a new task using
   `templates/task.md` and update `manifest.yml`.
3. Update `task_status.yml` to `state: done`.

## 5. Communicate status

1. Summarize changes in PR descriptions using task IDs.
2. Mention the linked `status_note` so the historical doc can be updated if
   needed.
3. After merge, bump `task_status.yml`’s `updated` timestamp.

## Rules of engagement

- Only one task may be `in-progress` per owner.
- Always keep `manifest.yml`, task files, and `task_status.yml` in sync.
- Status notes should remain historical—do not rewrite them beyond adding a
  “Follow-up” link to the task.

With this runbook, Codex has a deterministic workflow: select → claim →
implement → update docs → report. Repeat until every task reaches `done`.

