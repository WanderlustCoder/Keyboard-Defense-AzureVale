## Gold Timeline CLI - 2025-11-08

**Summary**
- Introduced `scripts/goldTimeline.mjs` plus `npm run analytics:gold` to convert analytics snapshots or smoke artifacts into a concise gold-event timeline (JSON or CSV). Each row captures delta, resulting total, timestamp, and time-since data alongside file/mode metadata so dashboards can plot economy swings without manual parsing.
- The CLI walks files/directories, mirrors the passive timeline interface, and feeds automation by default (stdout) while supporting `--out` targets for CI artifacts.
- Added Vitest coverage to exercise argument parsing, entry shaping, and CSV emission so regressions in future analytics schemas surface immediately.
- Tutorial smoke orchestrator now runs the CLI automatically after each Playwright run, emitting `gold-timeline*.json` artifacts that GitHub Actions uploads with the rest of the smoke bundle.

**Next Steps**
1. Explore augmenting the CSV with passive unlock IDs when the timestamps fall within a configurable window, avoiding the need to run both scripts separately.
2. Feed the generated timelines into nightly dashboards/alerts so economy spikes trigger automated analysis.
