> Note: This document targets the retired web version (`apps/keyboard-defense`). The current Godot project lives at `apps/keyboard-defense-godot`; see `docs/GODOT_PROJECT.md` and `apps/keyboard-defense-godot/README.md` for active workflows.

## Diagnostics & Passive Unlock Telemetry - 2025-11-07

**What landed**
- Runtime metrics now record capped gold events and expose active castle passives + latest unlock, letting the diagnostics overlay show current gold, recent delta/timestamp, and passive summaries in-game.
- Diagnostics overlay now lists the three most recent gold events (delta, resulting total, timestamp, and time since) so smoke logs and HUD screenshots capture economy swings without opening analytics exports.
- Analytics snapshots export `goldEvents` alongside enriched `castlePassiveUnlocks`; the CLI CSV adds columns (`passiveUnlockCount`, `lastPassiveUnlock`, `castlePassiveUnlocks`, `goldEventsTracked`, `lastGoldDelta`, `lastGoldEventTime`) for dashboards to consume directly.
- Tutorial smoke and castle breach artifacts now embed passive unlock counts, summaries, and active passive lists, so automation timelines capture economy progression milestones without extra parsing.
- Documentation updates cover the schema changes and changelog notes the diagnostic refresh plus artifact enrichment.
- New `scripts/ci/diagnosticsDashboard.mjs` CLI ingests analytics snapshots, emits Markdown/JSON summaries (gold delta sparkline + passive unlock timeline), and the Codex dashboard now links to the generated artifacts so reviewers no longer download raw JSON.

**Follow-up**
- `docs/codex_pack/tasks/11-diagnostics-dashboard.md` (DONE)

