# Season 3 Backlog Status (Rolling)

Quick status snapshot for items in `season3_backlog.md`. Audience ages 8-16, Edge/Chrome, free single-player, cartoonish pixel art.

| ID | Title | Status | Notes |
| --- | --- | --- | --- |
| 3 | Rotating posture and wrist micro-tips between waves | Done | Wave recap card shows a rotating comfort tip (posture, breathing, light taps) after each wave. |
| 61 | Dyslexia-friendly spacing toggle | Done | New option increases letter spacing/line-height for typing UI; persists in player settings. |
| 68 | Background brightness/contrast comfort slider | Done | Options slider adjusts global background brightness (90-110%) and persists per player. |
| 71 | Persistent caps/num lock indicators near input | Done | HUD pills show Caps/Num lock states beside the typing input; Caps warning remains for errors. |
| 64 | Input latency indicator with warning thresholds | Done | HUD pill samples event-loop delay and shows green/amber/red states with live ms readout. |
| 65 | Expanded key hints showing finger assignment per character | Done | Finger hint pill beside the input surfaces the recommended finger and key for the next character (or the expected key after an error), hiding automatically when idle. |
| 62 | Colorblind-safe palette set (multiple modes) | Done | Options menu now lets players choose deuteran/protan/tritan/high-contrast palettes; applies across HUD and wave previews. |
| 70 | Remappable pause and shortcut overlay keys | Done | Pause key (P/Esc/Space/O) and shortcuts overlay key (?,?,/,F1) are configurable in Options and persist locally. |
| 63 | HUD customization toggles | Done | Pause menu can hide typing metrics, wave preview, and battle log for a cleaner view; persists locally. |
| 73 | Contextual tooltips for new systems | Done | Once-per-user comfort hints now surface for drills, wave preview, and battle log until dismissed. |
| 67 | Screen-reader labels for controls/overlays | Done | Added ARIA labels for core controls (fullscreen, pause, roadmap, typing input, break reminders) and ensured options dialog landmarks remain announced. |
| 72 | Accessibility preference check during onboarding | Done | First-run comfort overlay asks for reduced motion, dyslexia spacing, colorblind palette, and brightness; applies and persists choices before play. |
| 87 | Automated difficulty tuning script (bot-driven) | Done | New script `npm run analytics:difficulty-tuning` ingests playtest-bot artifacts and outputs JSON/Markdown recommendations; see `docs/difficulty_tuning.md`. |
| 93 | Performance budget doc for effects/sprites/audio | Done | `docs/performance_budget.md` defines Edge/Chrome budgets for draw calls, particles, memory, audio, and payload sizes. |
| 69 | Reduced-motion variant for enemy deaths/UI transitions | Done | Reduced motion toggle now explicitly disables enemy death splashes and UI transitions while keeping essential cues. |
| 95 | Memory watchdog in diagnostics overlay | Done | Diagnostics overlay now samples heap usage (Chrome/Edge) with a warning above 82% of the heap cap. |
| 94 | Asset preloading strategy to avoid hitches during waves | Done | Documented in `docs/asset_preloading_strategy.md`; idle atlas frame prewarm added after manifest load. |
| 90 | QA checklist for new enemy behaviors and traps | Done | `docs/qa_enemy_behaviors.md` covers shielded/splitting/stealth/frost enemies, traps, status effects, and reduced-motion expectations. |
| 100 | Release readiness checklist for Season 3 drop | Done | `docs/release_readiness.md` details functional, perf, accessibility, analytics, and packaging gates. |
| 74 | First-encounter overlays for new enemy types | Done | One-time intro overlay surfaces name/role/tips when an unseen enemy tier spawns; stored in localStorage and auto-pauses until dismissed. |
| 99 | Input stress test harness (key bursts/holds) | Done | `npm run input:stress` simulates rapid key bursts with wrong keys, holds, and backspaces, asserting buffer bounds and reporting ops/sec. |
