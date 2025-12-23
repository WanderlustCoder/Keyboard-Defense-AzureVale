> Note: This document targets the retired web version (`apps/keyboard-defense`). The current Godot project lives at `apps/keyboard-defense-godot`; see `docs/GODOT_PROJECT.md` and `apps/keyboard-defense-godot/README.md` for active workflows.

## Gold Timeline CLI - 2025-11-08

**Summary**
- Introduced `scripts/goldTimeline.mjs` plus `npm run analytics:gold` to convert analytics snapshots or smoke artifacts into a concise gold-event timeline (JSON or CSV). Each row captures delta, resulting total, timestamp, and time-since data alongside file/mode metadata so dashboards can plot economy swings without manual parsing.
- The CLI walks files/directories, mirrors the passive timeline interface, and feeds automation by default (stdout) while supporting `--out` targets for CI artifacts. New flags (`--merge-passives`, `--passive-window`) attach the nearest passive unlock metadata to each gold event, keeping economy + unlock context in a single artifact.
- Added Vitest coverage to exercise argument parsing, entry shaping, CSV emission, and passive merging so regressions in future analytics schemas surface immediately.
- Tutorial smoke orchestrator now runs the CLI automatically after each Playwright run, emitting `gold-timeline*.json` artifacts that GitHub Actions uploads with the rest of the smoke bundle.

**Next Steps**
1. Feed the generated timelines into nightly dashboards/alerts so economy spikes trigger automated analysis.
2. Consider extending the CLI with derived metrics (rolling sums, average delta) before plugging the data into reporting.

## Follow-up
- `docs/codex_pack/tasks/34-gold-timeline-dashboard.md`

