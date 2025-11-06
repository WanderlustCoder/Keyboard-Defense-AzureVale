## Passive Unlock Timeline Export - 2025-11-07

**Summary**
- Added `scripts/passiveTimeline.mjs` plus `npm run analytics:passives` to flatten `analytics.castlePassiveUnlocks` arrays into JSON or CSV for dashboards.
- Script accepts one or more analytics snapshots/dirs, filters out empty runs, and caps output to ready-to-plot entries (file, mode, level, total, delta, time stamp).
- New Vitest coverage (`tests/passiveTimeline.test.js`) executes the CLI, verifies CSV/JSON paths, and exercises the argument parser.
- README + analytics schema now point to the CLI so automation can capture unlock cadence artifacts alongside diagnostics gold deltas.

**Next**
1. Feed the CSV output into CI artifacts (tutorial smoke + castle breach) to visualize passive unlock cadence nightly.
2. Extend the script to optionally merge gold event deltas for broader economy timelines.
