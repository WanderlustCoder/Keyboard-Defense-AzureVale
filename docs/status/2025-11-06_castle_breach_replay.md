# Castle Breach Replay CLI - 2025-11-06

## Context
- Backlog **#99** requested a deterministic castle-breach drill to guard the tutorial sequence.
- Prior automation suites covered wave simulations, smoke runs, and screenshot capture but lacked a direct regression harness for the scripted breach.

## Summary
- Breach CLI grew multi-enemy + turret loadout support: `--enemy tier[:lane]` spawns arbitrary drills, while `--turret slot:type[@level]` pre-places defenses. Artifacts now capture the loadout, derived metrics (time-to-breach ms, damage delta), and telemetry-friendly metadata.
- Added `scripts/ci/castleBreachSummary.mjs` + `npm run analytics:breach:summary`, which ingest breach artifacts (or fixtures under `docs/codex_pack/fixtures/castle-breach/`), emit `artifacts/summaries/castle-breach*.json`, and append a Markdown “Castle Breach Watch” tile to CI summaries.
- E2E workflow now runs the summary step immediately after the drill; artifacts include both the raw replay (`artifacts/castle-breach.ci.json`) and the normalized summary (`artifacts/summaries/castle-breach.e2e.json`), both linked from the Codex dashboard.
- Vitest coverage expanded: `castleBreachReplay.test.js` exercises turret/enemy overrides and `tests/castleBreachSummary.test.js` validates summary normalization/warnings so Codex can refactor safely.

## Next Steps
1. Expand smoke coverage so lighter tutorial runs also generate breach summaries (today only the full e2e job does).
2. Feed the breach summary JSON into the upcoming gold analytics board (task #38) so Codex has a single nightly economy surface.
3. Capture defensive presets (targeting priority, levels) inside fixtures to validate turret regression sweeps offline.

## Follow-up
- `docs/codex_pack/tasks/29-castle-breach-analytics.md`
