# Season 1 Backlog Status

| # | Category | Description | Status | Notes |
|---|---|---|---|---|
| 1 | Tutorial & Onboarding | Introduce tutorial pause/resume hooks and ensure intro overlay gates gameplay. | Done | Tutorial intro gating implemented |
| 2 | Tutorial & Onboarding | Highlight turret slot and enforce guided placement with gold auto-top-up. | Done | Slot highlight + gold auto-top-up |
| 3 | Tutorial & Onboarding | Gate upgrade step with forced slot selection and auto-replenished gold. | Done | Upgrade step enforced with gold replenish |
| 4 | Tutorial & Onboarding | Script deterministic castle breach demonstration with guided messaging. | Done | Deterministic castle breach scripted |
| 5 | Tutorial & Onboarding | Present wrap-up summary modal (accuracy/combo/breaches/gold) with replay/continue. | Done | Wrap-up modal shows stats & actions |
| 6 | Tutorial & Onboarding | Persist tutorial completion in localStorage; expose debug replay/skip. | Done | Completion stored in localStorage; debug replay/skip |
| 7 | Tutorial & Onboarding | Add assist tip when typing errors exceed threshold during tutorial. | Done | Assist hint after error streak |
| 8 | Tutorial & Onboarding | Record tutorial telemetry events (start/step-complete/fail/skip/complete). | Done | Tutorial events/assists captured in analytics |
| 9 | Tutorial & Onboarding | Provide tutorial skip option from main menu once completed. | Done | Main menu overlay offers skip/replay controls |
| 10 | Tutorial & Onboarding | Surface tutorial firmware versioning to invalidate old completions if flow changes. | Done | Completion stored with version; old runs auto-replay |
| 11 | Combat Systems & Typing | Scale word difficulty dynamically using rolling accuracy window. | Done | Rolling accuracy drives dynamic difficulty bias for spawn weights |
| 12 | Combat Systems & Typing | Diversify lane word banks to reduce repetition and teach pacing. | Done | Lane-specific vocab with per-lane history reduces repeats |
| 13 | Combat Systems & Typing | Add per-letter feedback colors for active enemy word progress. | Done | Canvas renderer highlights typed/next characters with accessible palette |
| 14 | Combat Systems & Typing | Implement combo decay timer with HUD warning state. | Done | Combo auto-decays with timer, HUD warns before reset |
| 15 | Combat Systems & Typing | Provide manual buffer purge hotkey with minor combo penalty. | Done | Ctrl/Cmd+Backspace clears buffer and drops combo by one stack |
| 16 | Combat Systems & Typing | Track wave-side bonus objectives (e.g., perfect words) for rewards. | Done | Perfect-word streak bonus grants gold and appears in analytics/scorecard |
| 17 | Combat Systems & Typing | Introduce shielded enemies requiring turret damage before typing is effective. | Done | Shielded variants live in waves with HUD/canvas cues and tutorial coverage |
| 18 | Combat Systems & Typing | Add turret/enemy affinity bonuses to encourage mixed defenses. | Done | Turrets gain tier multipliers with HUD summaries encouraging varied loadouts |
| 19 | Combat Systems & Typing | Offer low-intensity endless practice mode for casual warm-up. | Done | Main menu \"Practice Mode\" loops waves indefinitely without campaign victory |
| 20 | Combat Systems & Typing | Log typing reaction time metrics for balancing. | Done | Reaction averages tracked in analytics, diagnostics overlay, and exports |
| 21 | Castle & Turrets | Display upcoming castle upgrade benefits in upgrade panel tooltip. | Done | Upgrade panel lists HP/regen/armor/slot gains with tooltip |
| 22 | Castle & Turrets | Add castle repair ability with cooldown/resource cost. | Done | Repair action tracks cooldown/gold, analytics + diagnostics/scorecard display usage with tests |
| 23 | Castle & Turrets | Persist turret loadout presets per slot for experimentation. | Done | Presets panel saves/applies loadouts with gold preview and priority restore |
| 24 | Castle & Turrets | Introduce "Crystal Pulse" turret archetype behind feature toggle. | Done | Crystal Pulse turret added with shield-burst bonus and toggle controls in debug/options/main menu |
| 25 | Castle & Turrets | Allow turret targeting priority selection (first/strongest/weakest). | Done | HUD dropdown with persistence + engine targeting logic |
| 26 | Castle & Turrets | Animate turret firing states with sprite overlays. | Done | Turret shots trigger muzzle flashes tied to archetype colors |
| 27 | Castle & Turrets | Log per-wave turret DPS in diagnostics overlay. | Done | Diagnostics overlay lists per-slot damage and DPS |
| 28 | Castle & Turrets | Provide turret range visualization on hover/focus. | Done | Canvas overlay shows lane coverage when HUD slot is hovered |
| 29 | Castle & Turrets | Allow downgrade/refund via debug toggle for testing. | Done | Debug toggle enables per-slot turret downgrade/refund with HUD messaging |
| 30 | Castle & Turrets | Unlock castle passive buffs (regen/armor/gold) at higher levels. | Done | Passive list + HUD messaging surface regen/armor/gold bonuses |
| 31 | Enemy & Wave Design | Create elite enemy affixes (slow aura, shielded, armored) under toggles. | Done | Affix catalog (aura/armored/shielded) with toggle + preview badges and turret slowdown/mitigation |
| 32 | Enemy & Wave Design | Script Episode 1 boss wave with bespoke mechanics and intro message. | Done | Archivist boss gains rotating shields, vulnerability windows, shockwave slow, boss analytics/toggle |
| 33 | Enemy & Wave Design | Display enemy taunt text when special units spawn. | Done | Wave 2/3 specials announce via taunt banner & battle log (#docs/status/2025-11-19_enemy_taunts.md) |
| 34 | Enemy & Wave Design | Render spawn preview icons using sprite thumbnails. | Done | HUD wave preview shows tier icons with colorblind-aware palette |
| 35 | Enemy & Wave Design | Add dynamic spawn scheduler for surprise mini-events. | Done | Deterministic micro-events (skirmish/gold-runner/shield-carrier) gated by toggle |
| 36 | Enemy & Wave Design | Implement evacuation event requiring long-form typing to rescue civilians. | In Progress | Slices 1-2 shipped (transport + banner, gold reward/penalty) |
| 37 | Enemy & Wave Design | Introduce lane hazards (fog/storms) affecting visibility/accuracy. | Done | Seeded fog/storm hazards reduce lane fire-rate with HUD messaging |
| 38 | Enemy & Wave Design | Provide JSON schema/editor for designer-authored wave configs. | Done | Schema + editor + live preview with filters/timelines (`npm run wave:preview`, docs/status/2025-12-09_wave_preview_slice3.md) |
| 39 | Enemy & Wave Design | Calculate difficulty ratings per wave and surface in analytics overlay. | Done | Diagnostics overlay shows computed wave threat rating |
| 40 | Enemy & Wave Design | Spawn practice dummy enemy for turret DPS tuning in debug mode. | Done | Debug/main-menu toggle spawns stationary dummy target; clear button removes |
| 41 | Analytics & Telemetry | Expand analytics export to include tutorial metrics and summary history. | Done | Analytics export now includes tutorial state |
| 42 | Analytics & Telemetry | Persist per-wave analytics snapshot history for in-session review. | Done | Wave summaries persisted for review |
| 43 | Analytics & Telemetry | Build in-game analytics table accessible from debug panel. | Done | Debug viewer renders recent wave summaries with toggle |
| 44 | Analytics & Telemetry | Separate turret vs typing DPS metrics in analytics payload. | Done | Analytics snapshots & HUD now report turret/typing DPS splits |
| 45 | Analytics & Telemetry | Add CLI script to aggregate analytics logs into summary CSV. | Done | `npm run analytics:aggregate` generates CSV snapshots from exported JSON |
| 46 | Analytics & Telemetry | Guard analytics reset mid-wave with dedicated tests. | Done | resetAnalytics mid-wave covered by tests |
| 47 | Analytics & Telemetry | Export leaderboard-ready CSV covering key stats. | Done | `analyticsLeaderboard.mjs` ranks snapshots by combo, accuracy, DPS |
| 48 | Analytics & Telemetry | Capture time-to-first-turret placement and include in analytics. | Done | Snapshots/CSV now include time-to-first-turret metric |
| 49 | Analytics & Telemetry | Emit tutorial replay/skip counts for onboarding analysis. | Done | Analytics track replay/skip counts |
| 50 | Analytics & Telemetry | Wire optional telemetry endpoint for backend ingestion (future-ready). | Done | Telemetry client now posts batches via custom transports/sendBeacon/fetch with queue rollback on errors |
| 101 | Analytics & Telemetry | Add percentile stats to the gold summary CLI output for dashboards. | Done | `goldSummary.mjs` now emits median/p90 gain & spend columns (JSON/CSV) with updated tests |
| 102 | Analytics & Telemetry | Add percentile flag to the gold summary CLI so dashboards can request alternate gain/spend cutlines. | Done | `goldSummary.mjs --percentiles 25,50,90` now yields matching `gainPXX`/`spendPXX` columns plus legacy aliases |
| 103 | Analytics & Telemetry | Ensure CI smoke workflows emit gold summaries with the standardized percentile list. | Done | Smoke automation and `goldReport.mjs` now forward `--percentiles 25,50,90` to `goldSummary.mjs` |
| 104 | Analytics & Telemetry | Include percentile metadata in gold summary artifacts for downstream validation. | Done | JSON output now wraps `{ percentiles, rows }` and CSV adds `summaryPercentiles` |
| 105 | Analytics & Telemetry | Validate gold summary percentile metadata during CI smoke runs. | Done | `smoke.mjs` now parses the JSON summary, surfaces `goldSummaryPercentiles`, and warns/fails if the metadata deviates from `25,50,90` |
| 106 | Analytics & Telemetry | Provide a standalone gold summary validation CLI for dashboards/alerts. | Done | `goldSummaryCheck.mjs` validates JSON/CSV summaries via `npm run analytics:gold:check` |
| 51 | UI/UX & Accessibility | Offer colorblind-friendly palette toggle across sprites/HUD. | Done | Checkered background + high-contrast palette toggle available |
| 52 | UI/UX & Accessibility | Support adjustable HUD font size with persistence. | Done | HUD options menu offers Small/Default/Large/XL font sizes with persisted setting |
| 53 | UI/UX & Accessibility | Reflow layout for narrow screens / touch devices. | Done | HUD/game stack on tablets/phones with scrollable overlays + 44px touch targets |
| 54 | UI/UX & Accessibility | Add audio intensity slider alongside mute toggle. | Done | Options overlay slider controls audio intensity multiplier with persistence |
| 55 | UI/UX & Accessibility | Provide dyslexia-friendly font option for key UI elements. | Done | Options overlay offers dyslexia-friendly toggle covering active words, input, tutorial prompts with persisted setting |
| 56 | UI/UX & Accessibility | Highlight wave preview during tutorial to emphasize planning. | Done | Tutorial step now pulses wave preview with reduce-motion safe styling |
| 57 | UI/UX & Accessibility | Surface keyboard shortcut reference overlay. | Done | Shortcut modal with launch button + '?' hotkey |
| 58 | UI/UX & Accessibility | Add pause/options overlay while maintaining deterministic state. | Done | Pause menu with resume + sound/diagnostics toggles |
| 59 | UI/UX & Accessibility | Present wave-end scorecard summarizing accuracy, breaches, rewards. | Done | Wave scorecard overlay shows accuracy, combo, breaches, DPS, gold with resume gating |
| 60 | UI/UX & Accessibility | Implement reduced-motion mode (disable shake/particle effects). | Done | Reduced-motion toggle pauses transitions & stored in settings |
| 61 | UI/UX & Accessibility | Persist player settings (audio, diagnostics, toggles) across sessions. | Done | Player settings stored in localStorage (sound & diagnostics) |
| 62 | Asset Pipeline & Visuals | Replace inline SVG helpers with hashed asset pipeline utilities. | Done | Inline SVG helpers consolidated into asset loader |
| 63 | Asset Pipeline & Visuals | Generate sprite atlas to minimize draw calls. | Done | Atlas builder + loader drawFrame; manifest skips atlas-backed keys |
| 64 | Asset Pipeline & Visuals | Defer high-res asset loading until post-ready signal. | Done | Tiered manifest loadWithTiers swaps hi-res after ready with graceful fallback |
| 65 | Asset Pipeline & Visuals | Introduce projectile particle systems via offscreen canvas. | Done | Offscreen-capable particle renderer stub with reduced-motion no-op |
| 66 | Asset Pipeline & Visuals | Add enemy defeat animation frames with easing. | Done | Canvas renderer spawns eased defeat bursts with palette-matched rings and spikes |
| 67 | Asset Pipeline & Visuals | Morph castle visuals across upgrade levels. | Done | Castle renders level-specific sprites/keys with diagnostics noting current tier |
| 68 | Asset Pipeline & Visuals | Overlay ambient starfield/parallax background effects. | Done | Starfield layer with twinkling particles now renders behind the battlefield |
| 69 | Asset Pipeline & Visuals | Validate asset integrity via manifest checksum at startup. | Done | AssetLoader hashes sprites via crypto.subtle and rejects mismatches while warning on missing entries |
| 70 | Asset Pipeline & Visuals | Automate asset manifest generation from source sprites. | Done | Manifest generator runs via `npm run build` and `assets:manifest[:verify]`, preserving custom fields |
| 71 | Automation, Monitoring, Tooling | Script tutorial auto-run CLI verifying onboarding path nightly. | Done | Tutorial smoke CLI executed in CI via `ci-e2e-azure-vale` workflow |
| 72 | Automation, Monitoring, Tooling | Capture automated HUD screenshots for docs/regression. | Done | `node scripts/hudScreenshots.mjs` produces deterministic HUD/options PNGs |
| 73 | Automation, Monitoring, Tooling | Integrate ESLint/Prettier into build pipeline. | Done | `npm run lint` + `npm run format:check` wired into build orchestrator; configs live in repo |
| 74 | Automation, Monitoring, Tooling | Add performance benchmark harness for engine throughput. | Done | `scripts/waveBenchmark.mjs` benchmarks auto/all-turret scenarios with artifacts and baseline guards |
| 75 | Automation, Monitoring, Tooling | Create deterministic wave simulation CLI for balance sweeps. | Done | `scripts/waveSim.mjs` runs headless simulations for balance sweeps with auto-typing |
| 76 | Automation, Monitoring, Tooling | Validate config files against schema in pre-commit hook. | Done | `scripts/validateConfig.mjs` + schema enforce GameConfig structure, tests cover failures |
| 77 | Automation, Monitoring, Tooling | Watch docs/ for changes and rebuild summaries automatically. | Done | `npm run docs:watch` rebuilds codex dashboard/portal on doc changes |
| 78 | Automation, Monitoring, Tooling | Scaffold Playwright smoke tests for tutorial/campaign start. | Done | `npm run smoke:tutorial:full` drives tutorial via Playwright CLI |
| 79 | Automation, Monitoring, Tooling | Aggregate runtime logs into breach/accuracy summary post-run. | Done | `npm run logs:summary` emits breach/accuracy + warning/error summaries |
| 80 | Automation, Monitoring, Tooling | Provide git hook automation to run tests/lint locally. | Done | Pre-commit hook installs via `npm run hooks:install` and runs lint/test/Codex validators |
| 81 | Automation, Monitoring, Tooling | Add performance benchmark harness for engine update throughput. | Done | `scripts/waveBenchmark.mjs` runs auto/all-turret scenarios with artifacts + baseline guards |
| 82 | Automation, Monitoring, Tooling | Create deterministic wave simulation CLI for balance sweeps. | Done | `scripts/waveSim.mjs` runs headless GameEngine simulations with artifacts & auto-typing |
| 83 | Narrative & Content | Script Archivist Lyra dialogue blocks for Episode 1 beats. | Done | Dialogue catalog added (Lyra intro/phase shifts/breach/victory) with tests |
| 84 | Narrative & Content | Author lore codex entries unlocked by completing waves. | Done | Lore codex catalog + wave unlocks with persistence and HUD log |
| 85 | Narrative & Content | Enrich turret tooltips with flavor text. | Done | Turret selector/status now show archetype flavor blurbs for Arrow/Arcane/Flame/Crystal |
| 86 | Narrative & Content | Surface interactive season roadmap overlay within HUD. | Done | Roadmap overlay with filters + tracking (docs/status/2025-12-08_season_roadmap_overlay.md) |
| 87 | Narrative & Content | Add enemy biography cards accessible from wave preview panel. | Done | Wave preview bios with selectable dossiers and tips |
| 88 | Narrative & Content | Curate ambient music tracks escalating across waves. | Done | Ambient profiles (calm/rising/siege/dire) with wave/health-driven escalation |
| 89 | Narrative & Content | Expand word banks with themed lists per wave. | Done | Wave-themed vocab (scout/shield/boss) merged into per-lane buckets |
| 90 | Narrative & Content | Compose short victory/defeat stingers. | Done | Synth stingers trigger on victory/defeat with WebAudio fades |
| 91 | QA & Testing | Expand tutorial state tests to cover assist cues and replay/skip flows. | Done | TutorialManager tests cover assist hints, skip, reset, and replay |
| 92 | QA & Testing | Add asset loader fallback tests (network failure/cache reuse). | Done | Node tests cover fetch rejection + cached image reuse |
| 93 | QA & Testing | Write analytics export/reset integration tests for debug panel flows. | Done | HUD/Debug buttons gated when toggle off + CLI usage test |
| 94 | QA & Testing | Implement visual regression harness for HUD layout snapshots. | Done | Playwright visual project captures hud-main/options/tutorial-summary/wave-scorecard with baselines stored in `baselines/visual` |
| 95 | QA & Testing | Include dev-server monitor smoke test in CI. | Done | CI smoke job runs startMonitored + dev monitor artifacts |
| 96 | QA & Testing | Fuzz test typing input buffer for invalid characters/timing. | Done | TypingSystem fuzz tests cover invalid chars, mixed input, purge/reset behaviors |
| 97 | QA & Testing | Automate tutorial summary modal snapshot tests. | Done | Tutorial summary overlay snapshot test locks stat text and CTA wiring |
| 98 | QA & Testing | Add soak test that alternates tutorial replay/skip, verifying persistence. | Done | Replay/skip soak loops tutorial completion/version and validates persistence |
| 99 | QA & Testing | Create CLI to replay deterministic castle breach scenario for regression. | Done | `node scripts/castleBreachReplay.mjs` simulates the breach and emits a timeline artifact |
| 100 | QA & Testing | Track tutorials completed per session in QA dashboard. | Done | Static dashboard now surfaces tutorial completion counts/rate per session with coverage test |


