> Note: This document targets the retired web version (`apps/keyboard-defense`). The current Godot project lives at `apps/keyboard-defense-godot`; see `docs/GODOT_PROJECT.md` and `apps/keyboard-defense-godot/README.md` for active workflows.

## Passive Unlock Timeline Export - 2025-11-07

**Summary**
- Added `scripts/passiveTimeline.mjs` plus `npm run analytics:passives` to flatten `analytics.castlePassiveUnlocks` arrays into JSON or CSV for dashboards.
- Script accepts one or more analytics snapshots/dirs, filters out empty runs, and caps output to ready-to-plot entries (file, mode, level, total, delta, time stamp).
- New Vitest coverage (`tests/passiveTimeline.test.js`) executes the CLI, verifies CSV/JSON paths, and exercises the argument parser.
- README + analytics schema now point to the CLI so automation can capture unlock cadence artifacts alongside diagnostics gold deltas.
- `--merge-gold` + `--gold-window` flags correlate unlocks with the nearest gold events, exporting `goldDelta`, `gold`, `goldEventTime`, and `goldLag` columns for downstream economy tooling.

**Next**
1. Feed the CSV output into CI artifacts (tutorial smoke + castle breach) to visualize passive unlock cadence nightly.
2. Consider piping the merged gold/unlock rows directly into dashboards for combined economy timelines or enable `analytics:passives --ci` to drop artifacts automatically.

## Follow-up
- `docs/codex_pack/tasks/32-passive-gold-dashboard.md`

