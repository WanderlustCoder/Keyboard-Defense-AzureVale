# Docs Watch Automation - 2025-12-04

## Summary
- Added `npm run docs:watch` (scripts/docs/watchDocs.mjs) to monitor `apps/keyboard-defense/docs` and the root `docs/` tree, debounced by default and with an initial run that regenerates `docs/codex_dashboard.md` + `docs/CODEX_PORTAL.md`.
- Watcher falls back to per-directory listeners when recursive file watching is unsupported, logs change reasons, and cleans up gracefully on Ctrl+C/SIGTERM.
- Unit tests cover watch defaults, arg parsing, and the debounce/queue trigger to keep rebuilds serialized.
- Codex task/backlog/status/index updated to mark backlog item **#77** complete and expose the new command in the portal/dashboard generation workflow.

## Next Steps
1. Consider extending the watcher to rerun HUD gallery/condensed audits when screenshot artifacts change.
2. Wire `npm run docs:watch` into local docs authoring scripts (e.g., npm-run-all) if we start batching multiple doc generators.
3. Add an optional `--command` flag if we need to chain additional doc summary rebuilders later.

## Related Work
- `apps/keyboard-defense/scripts/docs/watchDocs.mjs`
- `docs/codex_pack/tasks/43-docs-watch.md`
- `apps/keyboard-defense/package.json` (`docs:watch`)
- `docs/codex_dashboard.md`, `docs/CODEX_PORTAL.md`
