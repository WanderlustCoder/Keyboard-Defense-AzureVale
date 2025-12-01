# Runtime Log Summary - 2025-12-04

## Summary
- Added `scripts/ci/runtimeLogSummary.mjs` to scan monitor/dev-server logs (JSON arrays, JSON lines, and plain text) and extract breach totals/max, last accuracy, warning/error counts, and event volumes.
- New npm script `npm run logs:summary` emits JSON + Markdown summaries (default: `artifacts/summaries/runtime-log-summary.(json|md)`) and errors when no log files are found.
- Vitest coverage exercises arg parsing plus aggregation across JSON/text sources.
- Backlog #79 marked done; Codex task/manifest/portal updated to reference the new automation.

## Next Steps
1. Feed the Markdown into the Codex dashboard if we want runtime log insights alongside smoke/monitor tiles.
2. Add optional regex flag for custom metrics (e.g., latency) if additional log fields appear.
3. Wire the summarizer into CI smoke steps once live logs are available from dev-monitor/start-monitored workflows.

## Related Work
- `apps/keyboard-defense/scripts/ci/runtimeLogSummary.mjs`
- `apps/keyboard-defense/tests/runtimeLogSummary.test.js`
- `apps/keyboard-defense/package.json` (`logs:summary`)
- `docs/codex_pack/tasks/44-runtime-log-summary.md`
