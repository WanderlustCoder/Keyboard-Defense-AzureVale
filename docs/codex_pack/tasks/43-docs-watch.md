---
id: docs-watch
title: "Docs watcher and summary refresh"
priority: P2
effort: S
depends_on: []
produces:
  - apps/keyboard-defense/scripts/docs/watchDocs.mjs
  - apps/keyboard-defense/package.json
  - docs/CODEX_PORTAL.md
  - docs/codex_dashboard.md
status_note: docs/status/2025-12-04_docs_watch.md
backlog_refs:
  - "#77"
---

**Context**  
Manual dashboard refreshes slow down doc edits. We need a lightweight watcher that reruns our Codex dashboard/portal generation whenever docs change so the summaries stay current during authoring sessions.

## Steps

1. Add a docs watcher CLI (defaults to `apps/.../docs` and `../../docs`) with a debounce guard and an initial rebuild. On change, rerun `npm run codex:dashboard` to regenerate `docs/codex_dashboard.md` + `docs/CODEX_PORTAL.md`.
2. Provide a package.json script (`npm run docs:watch`) and help text; ensure shutdown cleans watchers.
3. Cover the watcher helpers with unit tests (defaults, arg parsing, debounce/queue behavior).
4. Update docs/status/backlog/index to record the automation and rerun `npm run codex:dashboard` so the portal reflects the new workflow.

## Acceptance criteria

- Running `npm run docs:watch` watches both doc roots, performs an initial rebuild, and logs change reasons as it refreshes the dashboard/portal.
- Non-recursive platforms fall back to per-directory watchers without crashing, and Ctrl+C cleans up listeners.
- Tests exercise arg parsing defaults and the debounce/queue trigger logic.
- Status note/backlog mark item #77 complete and codex dashboard references the new command.

## Verification

- `npm run docs:watch -- --help`
- `npm test`
- `npm run codex:dashboard`
