# Season 3 Backlog Status (Rolling)

Quick status snapshot for items in `season3_backlog.md`. Audience ages 8-16, Edge/Chrome, free single-player, cartoonish pixel art.

| ID | Title | Status | Notes |
| --- | --- | --- | --- |
| 61 | Dyslexia-friendly spacing toggle | Done | New option increases letter spacing/line-height for typing UI; persists in player settings. |
| 68 | Background brightness/contrast comfort slider | Done | Options slider adjusts global background brightness (90-110%) and persists per player. |
| 71 | Persistent caps/num lock indicators near input | Done | HUD pills show Caps/Num lock states beside the typing input; Caps warning remains for errors. |
| 87 | Automated difficulty tuning script (bot-driven) | Done | New script `npm run analytics:difficulty-tuning` ingests playtest-bot artifacts and outputs JSON/Markdown recommendations; see `docs/difficulty_tuning.md`. |
| 93 | Performance budget doc for effects/sprites/audio | Done | `docs/performance_budget.md` defines Edge/Chrome budgets for draw calls, particles, memory, audio, and payload sizes. |
| 95 | Memory watchdog in diagnostics overlay | Done | Diagnostics overlay now samples heap usage (Chrome/Edge) with a warning above 82% of the heap cap. |
| 94 | Asset preloading strategy to avoid hitches during waves | Done | Documented in `docs/asset_preloading_strategy.md`; idle atlas frame prewarm added after manifest load. |
