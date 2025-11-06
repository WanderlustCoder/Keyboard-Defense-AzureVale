## Diagnostics & Passive Unlock Telemetry - 2025-11-07

**What landed**
- Runtime metrics now record capped gold events and expose active castle passives + latest unlock, letting the diagnostics overlay show current gold, recent delta/timestamp, and passive summaries in-game.
- Analytics snapshots export `goldEvents` alongside enriched `castlePassiveUnlocks`; the CLI CSV adds columns (`passiveUnlockCount`, `lastPassiveUnlock`, `castlePassiveUnlocks`, `goldEventsTracked`, `lastGoldDelta`, `lastGoldEventTime`) for dashboards to consume directly.
- Tutorial smoke and castle breach artifacts now embed passive unlock counts, summaries, and active passive lists, so automation timelines capture economy progression milestones without extra parsing.
- Documentation updates cover the schema changes and changelog notes the diagnostic refresh plus artifact enrichment.

**Follow-ups**
1. Project the gold event stream into diagnostics overlay history (e.g., last 3 entries) once HUD layout budget is confirmed.
2. Thread passive unlock summaries into analytics dashboards / CI reports to visualize economy pacing over time.
3. Extend tutorial smoke metrics with castle passive milestones for step-level assertions when new passives arrive mid-onboarding.
