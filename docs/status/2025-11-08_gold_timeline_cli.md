## Gold Timeline CLI - 2025-11-08

**Summary**
- Introduced `scripts/goldTimeline.mjs` plus `npm run analytics:gold` to convert analytics snapshots or smoke artifacts into a concise gold-event timeline (JSON or CSV). Each row captures delta, resulting total, timestamp, and time-since data alongside file/mode metadata so dashboards can plot economy swings without manual parsing.
- The CLI walks files/directories, mirrors the passive timeline interface, and feeds automation by default (stdout) while supporting `--out` targets for CI artifacts.
- Added Vitest coverage to exercise argument parsing, entry shaping, and CSV emission so regressions in future analytics schemas surface immediately.

**Next Steps**
1. Wire the gold timeline export into CI nightly jobs (e.g., alongside `analytics:passives`) so dashboards automatically ingest both passive and gold data.
2. Explore augmenting the CSV with passive unlock IDs when the timestamps fall within a configurable window, avoiding the need to run both scripts separately.
