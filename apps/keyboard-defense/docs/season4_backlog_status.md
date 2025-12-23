# Season 4 Backlog Status (Rolling)

Quick status snapshot for items in `season4_backlog.md`. All items start as Not Started; update rows as work lands.

| ID | Title | Status | Notes |
| --- | --- | --- | --- |
| 1 | Diagnostic placement test | Done | Added a Placement Test mode in Typing Drills: left/right segments + mixed strings, hand-specific accuracy scores, tutorial pacing suggestion, and local persistence (`keyboard-defense:placement-test`). |
| 2 | Per-finger mastery tree | Done | Typing drills now track per-finger accuracy/tempo, render a mastery tree, and unlock advanced drills (reaction/rhythm/combo/symbols/precision) once fingers hit target stats; stored in `keyboard-defense:finger-mastery`. |
| 3 | Adaptive session goals | Done | Adds local-only adaptive session goals (accuracy/WPM/consistency) with a HUD panel that tracks live progress and tunes targets after each defeat/victory run. |
| 4 | Spaced-repetition scheduler | Done | Adds a local spaced-repetition scheduler for weak keys/digraphs, updated from wave + drill typing stats and blended into Focus/Warm-up targets + drill recommendations. |
| 5 | Error-cluster detection | Done | Tracks recent typing-error clusters (top expected keys) in local storage (`keyboard-defense:error-clusters`) and adds a Focus Drill mode that micro-drills trouble keys; drill recommendations can now surface Focus Drill when clusters are strong. |
| 6 | Keystroke timing profile | Done | Builds a local keystroke timing profile (tempo WPM band + jitter) and applies a spawn speed gate so enemy speed ramps wait for steadier typing; surfaced in Diagnostics. |
| 7 | Fatigue detector | Done | Detects sustained accuracy drops plus slowing keystroke timing across recent waves and surfaces a "Fatigue check" break suggestion in the wave scorecard; respects cooldown and break-reminder snooze/reset. |
| 8 | Personalized warm-up generator | Done | Added a 5-Min Warm-up drill mode that builds timed segments from recent error-cluster keys (plus cadence/accuracy segments) and can be started from the main menu. |
| 9 | Post-run coach summary | Done | Wave scorecard now includes a Coach Summary (biggest win + biggest gap) plus a suggested drill CTA that opens Typing Drills and auto-starts the recommended mode. |
| 10 | Shortcut practice drills | Done | Added a Shortcut Practice drill mode (Ctrl/Cmd combos for select-all/copy/cut/paste/undo/redo) with step-by-step prompts and Enter-to-skip. |
| 11 | Shift timing tutor | Done | Added a Shift Timing drill mode that practices capital letters (Shift + letter) with hold vs tap feedback and a slow-mo toggle for extra time + clearer cues. |
| 12 | Number/symbol modules | Done | Added a Numbers & Symbols drill mode plus progressive advanced symbol unlocks (Silver medal in Symbols) and persistence via existing lesson medal tracking. |
| 13 | Sentence construction drills | Done | Added a Sentence Builder typing drill (45s) with punctuation-focused sentences and medal/WPM ladder tracking. |
| 14 | Reading-comprehension passages | Done | Added a Reading Quiz typing drill (practice): read short passages, then answer A/B/C questions with score progress + summary. |
| 15 | Alternating-hand rhythm drills | Done | Added a Rhythm Drill mode (30s) with alternating-hand targets and an in-drill metronome toggle (visual + optional audio/haptics). |
| 16 | Daily quest board | Done | Added a Daily Quest Board panel (Mission Control) with three rotating quests (drills, Gold medal, campaign waves/accuracy) persisted locally under `keyboard-defense:daily-quests`. |
| 17 | Weekly mastery quest | Done | Adds a weekly quest panel (Mission Control) with local persistence, progress from drills/campaign runs, and a Weekly Trial button that launches a bespoke single-wave challenge. |
| 18 | Time-attack sprint mode | Done | Added a Time Attack typing drill (60s sprint) with tiered medals and WPM ladder/medal integrations. |
| 19 | Calm focus lane mode | Done | Adds a Practice Mode lane focus selector (All / A / B / C) that constrains spawns, hazards, bonus events, and wave previews to a single lane. |
| 20 | Ghost race vs self | Done | Time Attack sprint now loads/saves a local ghost run (per-second words timeline) under `keyboard-defense:typing-drill-ghosts` and shows an in-run Ghost pace delta in the progress label. |
| 21 | Challenge modifiers | Done | Adds opt-in challenge modifiers (fog of war, fast spawns, limited mistakes) with local persistence, score multipliers, and practice/trial-only enforcement. |
| 22 | Checkpointed runs with upgrades | Not Started | - |
| 23 | Boss practice lab | Not Started | - |
| 24 | Reaction challenge mini-game | Done | Added a Reaction Challenge typing drill mode (30s) with random cue delays, hit/miss tracking, and reaction time stats in-drill + summary tip. |
| 25 | Combo preservation challenge | Done | Added a Combo Preservation typing drill mode (45s) with 3 timed segments and a per-segment mistake budget that protects combo until depleted. |
| 26 | Typo recovery drills mid-wave | Done | After a mid-wave typing error (combo >= 3), prompts Undo → Redo (Ctrl/Cmd+Z then Ctrl/Cmd+Y / Ctrl/Cmd+Shift+Z); restores combo once per wave with cooldown. |
| 27 | Lane support selection drills | Done | Adds a Lane Support typing drill (45s): type A/B/C to route support to the highlighted lane, with timing stats (avg/best/last). |
| 28 | Hand isolation practice mode | Done | Adds a Hand Isolation typing drill (45s) with a left/right hand toggle and curated single-hand word pools. |
| 29 | Endurance marathon with breaks | Done | Endurance drill now runs a multi-segment marathon with break segments and an auto-pause toggle. |
| 30 | Seasonal event playlists | Not Started | - |
| 31 | Modular castle rooms | Not Started | - |
| 32 | Typed barricade building | Not Started | - |
| 33 | Code-locked resource drops | Not Started | - |
| 34 | Rescue events | Not Started | - |
| 35 | Weather effects on projectiles | Not Started | - |
| 36 | Burrowing enemies | Not Started | - |
| 37 | Mimic enemies | Not Started | - |
| 38 | Shield generators | Not Started | - |
| 39 | Siege engine miniboss | Not Started | - |
| 40 | Sneak enemies with reveal | Not Started | - |
| 41 | Hazard tiles | Not Started | - |
| 42 | Lane-priority macros | Not Started | - |
| 43 | Spawnable training dummy | Done | Added a HUD "Practice Dummy" panel to spawn or clear dummies mid-run for turret DPS checks. |
| 44 | Power phrase overdrive | Done | Added a Power Phrase HUD card to type a short phrase and trigger a lane fire-rate overdrive with cooldown feedback. |
| 45 | Defensive rune sockets | Not Started | - |
| 46 | HUD zoom control | Done | Options overlay adds a HUD zoom selector (90-120%) that scales the entire HUD and persists per profile. |
| 47 | Left-handed layout | Done | Options toggle flips HUD to the left side; persists per profile with body data attribute for layout. |
| 48 | Onboarding dyslexia preset suggestion | Done | Accessibility onboarding now spotlights a dyslexia-friendly preset button that enables the font + spacing defaults and marks onboarding complete. |
| 49 | Reduced cognitive-load mode | Done | Options toggle hides non-essential HUD panels (metrics, wave preview, battle log) and softens hints/debug panels; persists per profile and disables panel toggles while active. |
| 50 | Focus outline presets | Done | Options overlay adds a Focus Outline selector (system/high-contrast/glow) that updates global focus rings and persists per profile. |
| 51 | Audio narration toggle | Done | Options overlay adds an Audio Narration toggle that persists per profile and applies a global data attribute for spoken menu cues. |
| 52 | Posture checklist | Done | Options adds a Posture Checklist overlay with a 5-minute micro-reminder and inline posture toast, plus a quick summary in options. |
| 53 | Layout preview overlay | Done | Options overlay adds a Layout Preview dialog with left/right mockups and quick apply buttons so players can compare layouts before switching. |
| 54 | Large-text subtitles | Done | Options overlay adds a Large-Text Subtitles toggle plus a preview dialog; enables global large subtitles with higher contrast across overlays and voice-line captions. |
| 55 | Tutorial pacing slider | Done | Options overlay adds a Tutorial Pacing slider (75-125%) that rescales scripted tutorial timings and persists per profile. |
| 56 | Input latency sparkline | Done | Latency indicator now renders a live sparkline of recent samples alongside the value. |
| 57 | Profile-bound accessibility toggle | Done | One-tap accessibility preset per profile that bundles reduced motion, readable/dyslexia fonts and spacing, narration, large subtitles, and a simplified HUD. |
| 58 | Screen-shake preview | Done | Options adds a screen shake toggle with intensity slider, preview button, and reduced-motion guard so players can test before enabling. |
| 59 | Accessibility self-test mode | Done | Options overlay adds an accessibility self-test card that plays sound/flash/motion cues with per-channel confirmations and persisted last-run state; motion check respects Reduced Motion. |
| 60 | Contrast audit overlay | Done | Options overlay adds a Contrast Audit overlay that scans UI regions for low-contrast text and highlights warnings/fails with an overlay list and markers. |
| 61 | Sticker book achievements | Done | Options overlay now links to a Sticker Book overlay with pixel stickers and live progress/unlock states driven by session stats. |
| 62 | Castle skin themes | Done | Options overlay adds a castle skin selector (Classic/Dusk/Aurora/Ember) with live HUD theming and per-profile persistence. |
| 63 | Companion pet sprites | Done | HUD adds a companion pet sprite panel that reacts to performance (calm/happy/cheer/sad) with live mood text. |
| 64 | Collectible lore scrolls | Done | Lore scroll overlay unlocks scrolls when lessons/drills are completed, with HUD progress, persistence, and reading-friendly snippets. |
| 65 | Weekly parent summary | Done | Options/HUD button opens a parent-friendly weekly summary overlay with session time, accuracy/WPM, combo, breaches, drills, repairs, notes, and a print/download action. |
| 66 | Free seasonal reward track | Done | Free, predictable 10-tier reward track unlocks via lesson milestones with HUD/overlay views. |
| 67 | Medal tiers per lesson | Done | Bronze/Silver/Gold/Platinum medals per drill with HUD panel/overlay and replay CTA. |
| 68 | Mastery certificates | Done | Printable mastery certificate with learner name, session stats, and HUD panel/overlay + options shortcut. |
| 69 | Milestone celebration VFX | Done | Reduced-motion-safe celebration banner with fireworks/spotlights for lesson milestones and Gold/Platinum medals. |
| 70 | Adaptive mentor dialogue | Done | Mentor card surfaces focus-specific tips (accuracy vs speed) based on live stats with cooldowns and reduced-motion-safe styling. |
| 71 | Castle museum room | Done | Castle Museum panel/overlay shows unlocked skins, reward artifacts, companion moods, lore scrolls, medals, certificates, and drills. |
| 72 | Side-mission quest log | Done | HUD panel and overlay list narrative side quests with progress (lessons, medals, scrolls, drills) plus options and HUD entry points. |
| 73 | Personal WPM ladder | Done | HUD card + options overlay surface per-mode best WPM ladders from typing drills (local storage). |
| 74 | Streak-freeze tokens | Done | Daily streak tokens granted after 5-day streaks; HUD card shows tokens/streak and options shortcut. |
| 75 | Training calendar heatmap | Done | HUD card + overlay show recent lessons/drills per day with a 4+ week heatmap (local storage). |
| 76 | Pixel art biome expansion | Done | HUD biome gallery adds themed palettes, active biome selection, and per-biome run tracking (local storage). |
| 77 | Day/night palette swaps | Done | HUD adds a day/night palette selector with global theming for panels/overlays; persists locally. |
| 78 | Parallax backgrounds | Done | Layered parallax sky/hills with day/night/storm scenes, gentle motion that pauses with Reduced Motion/Low Graphics, and an options toggle. |
| 79 | Enemy readability guide refresh | Done | Overlay guide refreshed with silhouettes, tier color tags, and quick readability tips for each enemy tier. |
| 80 | SFX library refresh | Done | Options adds an SFX library picker with palette previews and a selectable active mix. |
| 81 | Dynamic music stems | Done | Dynamic music suites layer stems that react to wave danger/health with an options picker and local persistence. |
| 82 | UI sound scheme selector | Done | UI sound scheme picker with overlay previews and inline apply/preview controls; persists chosen scheme per profile. |
| 83 | Voice pack stubs | Done | Voice pack selector with text-based stubs for narration styles; persists choice per profile. |
| 84 | Reduced-motion VFX variants | Done | Reduced-motion mode now swaps to softened VFX: particle systems render low-motion fades and a global `data-vfx-mode` toggle gates motion-heavy effects. |
| 85 | Sprite batching/atlas plan | Not Started | - |
| 86 | Session timeline export | Done | Options → Diagnostics adds a Session Timeline (CSV) export that downloads per-wave stats from the current run. |
| 87 | Keystroke timing histograms | Done | Records inter-key timings during battle and adds a Diagnostics export that downloads a histogram CSV for cadence analysis. |
| 88 | Stuck-key anomaly detection | Done | Detects repeated identical typing errors (likely stuck key) and surfaces a friendly troubleshooting prompt in the HUD/battle log with per-key throttling. |
| 89 | Parental session reminders | Done | Options → Accessibility adds a Break Reminders interval selector (off/10/20/30/45 min) that tunes the existing in-session stretch reminder and persists locally. |
| 90 | Progress export/import | Done | Options menu adds Export/Import Progress buttons that package local-only progress/settings into JSON and restore them safely (key whitelist) with a reload prompt. |
| 91 | Safety/content audit checklist | Done | Added a vitest content safety audit that scans user-facing HTML + content catalogs against `data/wordlists/denylist.txt`. |
| 92 | Offline-first telemetry queue | Done | Implemented localStorage-backed telemetry queue client with endpoint-gated flush + new Diagnostics panel buttons to download/clear the queue. |
| 93 | Drop-off reason prompt | Done | Pause/options menu adds End Session + a local-only reason prompt stored under `keyboard-defense:dropoff-reasons` for coaching. |
| 94 | Privacy explainer update | Done | Updated the in-game parental privacy overlay to reflect progress export/import, drop-off reasons, diagnostics exports, and the local-only telemetry queue/flush controls. |
| 95 | Screen-time goals/lockout | Done | Added a daily screen-time badge + options controls (goal + lockout), local-only persistence, lockout enforcement (blocks resume/start), and vitest coverage. |
| 96 | Wordlist readability grader | Done | Added a readability/typing-complexity grader (script + vitest audit) that scores wordlists + the default word bank and gates extreme punctuation/phrase complexity in CI. |
| 97 | Automated ARIA audit | Done | Added a unit test that enforces unique IDs + valid `aria-labelledby`/`aria-describedby`/`aria-controls` references for `public/index.html`. |
| 98 | Throttled-device perf smoke | Done | Added a Playwright-based perf smoke (`scripts/ci/perfSmoke.mjs`) that applies CPU throttling and records FPS/frame-time + heap metrics, plus CI guard thresholds + workflow wiring. |
| 99 | Offline/PWA cache verification | Done | Added a service worker + cache manifest with a vitest audit to ensure core assets are precached for offline reloads. |
| 100 | Asset licensing manifest checker | Done | Added `docs/asset_licensing_manifest.json` + `scripts/assetLicensing.mjs` checker, enforced via `lint:assets:licensing` and a vitest audit. |
