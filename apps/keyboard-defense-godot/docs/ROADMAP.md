# Roadmap

## How to read this roadmap
This roadmap lists the next priorities for the Godot project. Items are grouped into P0 (now), P1 (next), and P2 (later). Each item has a stable ID, status, planning references, and lightweight acceptance criteria.

**Last updated:** 2026-01-11

## Recent Milestones (Shipped)

### M-STORY-001 Story and Narrative System
Status: Done

Implemented "The Siege of Keystonia" narrative framework with 5 acts, boss encounters, mentor dialogue, and lore.

Key deliverables:
- `data/story.json` with full 20-day campaign structure across 5 acts
- `game/story_manager.gd` providing act progression, dialogue, tips, and achievement data
- Boss encounters on days 4, 8, 12, 16, 20 with unique dialogue
- Elder Lyra mentor system with contextual advice
- Typing tips, finger assignments, and performance feedback
- Achievement definitions for milestones

### M-MODE-001 Game Mode Expansion
Status: Done

Added multiple game modes beyond the original command-line sim.

Key deliverables:
- `game/kingdom_defense.gd` + `scenes/KingdomDefense.tscn` - RTS-style typing defense
- `game/open_world.gd` + `scenes/OpenWorld.tscn` - Exploration mode with roaming enemies
- `game/typing_defense.gd` + `scenes/TypingDefense.tscn` - Pure typing battle mode
- `game/dialogue_box.gd` + `scenes/DialogueBox.tscn` - Narrative dialogue system
- `game/keyboard_display.gd` - Visual keyboard with finger hints
- Practice mode for individual key training

### M-VFX-001 Visual Effects and Polish
Status: Done

Added visual feedback systems for combat and typing.

Key deliverables:
- Projectile effects and castle morphing animations
- Combo counter with visual feedback
- Defeat animations and hit effects
- Status effect icons display
- Boss progress indicators

### M-ACC-002 Accessibility Options Suite
Status: Done

Implemented comprehensive accessibility settings beyond basic readability.

Key deliverables:
- High contrast mode toggle
- Reduced motion setting
- Game speed multiplier (0.5x - 2.0x)
- Keyboard navigation hints toggle
- Practice mode for learning

### M-BAL-002 Balance Diagnostics Infrastructure
Status: Done

Built tooling for deterministic balance tuning and validation.

Key deliverables:
- `balance export` command with metric groups (wave, enemies, towers, buildings, midgame)
- `balance verify` command with guardrails and invariant checks
- `balance diff` command for comparing to baselines
- `balance summary` for compact pacing signals
- Day 1-7 tuning with extensive milestone iterations (70+ balance commits)

### M-EXP-002 Windows Export Infrastructure
Status: Done

Built versioned Windows export pipeline with validation.

Key deliverables:
- Windows Desktop export preset with deterministic paths
- `VERSION.txt` as single source of truth
- Bump version scripts (patch/minor/major modes)
- Export manifest generation with metadata
- PCK validation and packaging scripts
- Product/file version consistency enforcement

## P0 - Now (stabilize and ship)

### P0-ONB-001 Onboarding and first-run guidance
Status: Done

Deliver a guided tutorial that teaches core commands and the day/night loop without mouse input.

Planning refs:
- `docs/ONBOARDING_TUTORIAL.md`
- `docs/plans/p0/ONBOARDING_PLAN.md`
- `docs/plans/p0/ONBOARDING_COPY.md`
- `docs/plans/p0/ONBOARDING_IMPLEMENTATION_SPEC.md`
- `docs/plans/p0/P0_IMPLEMENTATION_BACKLOG.md`
- `docs/PLAYTEST_PROTOCOL.md`
- `docs/plans/planpack_2025-12-27_tempPlans/generated/PROJECT_MASTER_PLAN.md`
- `docs/plans/planpack_2025-12-27_tempPlans/keyboard-defense-plans/UX_CONTROLS.md`

Acceptance criteria:
- Tutorial auto-shows on first run and can be replayed on demand.
- Players complete a full day -> night -> dawn loop using typed commands.
- Completion is persisted in `user://profile.json`.
- Tutorial copy is finalized and matches the step plan in `docs/plans/p0/ONBOARDING_COPY.md`.

### P0-BAL-001 Balance curve and pacing
Status: Nearly complete (validation pass remaining)

Balance enemy stats, tower upgrades, and word length ranges for days 1-7 with deterministic seeds.

**Progress:** Extensive tuning completed (Milestones 72-102). Balance diagnostics infrastructure shipped. Day 1-7 parameters documented. Remaining work is final playtest validation and scenario harness integration.

Planning refs:
- `docs/plans/p0/BALANCE_PLAN.md`
- `docs/plans/p0/BALANCE_TARGETS.md`
- `docs/plans/p0/P0_IMPLEMENTATION_BACKLOG.md`
- `docs/plans/p1/SCENARIO_CATALOG.md`
- `docs/plans/p1/SCENARIO_HARNESS_IMPLEMENTATION_SPEC.md`
- `docs/PLAYTEST_PROTOCOL.md`
- `docs/plans/planpack_2025-12-27_tempPlans/keyboard-defense-plans/BALANCING_MODEL.md`
- `docs/plans/planpack_2025-12-27_tempPlans/generated/CORE_SIM_GAMEPLAY_PLAN.md`
- `docs/plans/planpack_2025-12-27_tempPlans/keyboard-defense-plans/preprod/PLAYTEST_PLAN.md`

Acceptance criteria:
- Day 1-3 nights are survivable without high WPM.
- Tower upgrades provide meaningful pacing relief without trivializing waves.
- Determinism tests remain stable for the same seed/actions.
- Day 1-7 numeric targets are documented and tied to scenario tolerances.

### P0-ACC-001 Accessibility and readability polish
Status: Nearly complete (final audit remaining)

Improve panel readability, keyboard navigation, and accessibility toggles while keeping typing-first flow.

**Progress:** Core accessibility options shipped (high contrast, reduced motion, game speed, keyboard hints, practice mode). Settings persist to profile. Remaining work is final 1280x720 audit and documentation.

Planning refs:
- `docs/plans/p0/ACCESSIBILITY_READABILITY_PLAN.md`
- `docs/plans/p0/P0_IMPLEMENTATION_BACKLOG.md`
- `docs/ACCESSIBILITY_VERIFICATION.md`
- `docs/plans/planpack_2025-12-27_tempPlans/generated/UI_UX_ACCESSIBILITY_PLAN.md`
- `docs/plans/planpack_2025-12-27_tempPlans/keyboard-defense-plans/UX_CONTROLS.md`
- `docs/plans/planpack_2025-12-27_tempPlans/keyboard-defense-plans/preprod/ACCESSIBILITY_SPEC.md`

Acceptance criteria:
- Panels remain readable at 1280x720 and do not truncate critical info.
- Keyboard-only navigation works across settings, lessons, trend, and report panels.
- Accessibility preferences persist in `user://profile.json`.

### P0-EXP-001 Export pipeline (Windows)
Status: Nearly complete (smoke test remaining)

Document and validate a Windows export pipeline with a release checklist.

**Progress:** Windows export preset created. Version management scripts shipped (bump_version with patch/minor/major). Export scripts with dry-run/apply modes. Manifest generation and PCK validation. Remaining work is final smoke test execution and release checklist completion.

Planning refs:
- `docs/plans/p0/EXPORT_PIPELINE_PLAN.md`
- `docs/plans/p0/P0_IMPLEMENTATION_BACKLOG.md`
- `docs/plans/planpack_2025-12-27_tempPlans/keyboard-defense-plans/preprod/CI_CD_AND_RELEASE.md`
- `docs/plans/planpack_2025-12-27_tempPlans/keyboard-defense-plans/business/QUALITY_GATES.md`

Acceptance criteria:
- Windows export preset is documented and reproducible.
- Release smoke checklist is documented and completed once.
- Build output includes versioned folder and minimal run notes.

## P1 - Next (expand depth)

### P1-CNT-001 Content expansion (lessons and drills)
Status: Complete

Expand lesson packs and word curricula with data validation and clear pedagogy stages.

**Progress:** 98 lessons implemented covering core curriculum, numbers, symbols, coding, bosses, realms, and more. As of 2026-01-10, all 98 lessons have introductions in `data/story.json` (version 5) including finger guides and practice tips. Full 1:1 consistency between `lessons.json` and `story.json` lesson introductions verified.

**Lesson Tracks Identified:**
- Core Curriculum (training → home row → reach → upper → bottom → mixed → speed → mastery)
- Skill Development (finger training, pattern practice)
- Challenge Modes (gauntlets, precision, time trials, legendary)
- Themed Content (twilight, realms, bosses, biomes)
- Professional Skills (coding, business typing)

Planning refs:
- `docs/plans/p1/LESSON_GUIDE_PLAN.md` - Lesson inventory, tracks, and gap analysis
- `docs/plans/p1/PEDAGOGY_GUIDE_FRAMEWORK.md` - Educational framework and templates
- `docs/plans/p1/LESSON_INTRODUCTIONS_DRAFT.md` - Draft content for priority lessons
- `docs/FINGER_GUIDE_REFERENCE.md` - Canonical finger-to-key assignments
- `docs/plans/p1/CONTENT_EXPANSION_PLAN.md`
- `docs/plans/p1/VISUAL_STYLE_GUIDE_PLAN.md`
- `docs/plans/planpack_2025-12-27_tempPlans/keyboard-defense-plans/TYPING_PEDAGOGY.md`

Acceptance criteria:
- New lessons load and validate in headless tests.
- Word ranges stay aligned to lesson intent (short/medium/long).
- No RNG consumption added to lesson word selection.

### P1-MAP-001 Map and exploration depth
Status: Partially complete

Add deeper exploration events and map structure while staying deterministic.

**Progress:** Open world exploration mode implemented (`game/open_world.gd`). Tile discovery, resource gathering, roaming enemies, and structure building functional. Kingdom defense mode adds RTS-style map interaction. Remaining work is POI events, map variety, and deeper exploration outcomes.

Planning refs:
- `docs/plans/p1/MAP_EXPLORATION_PLAN.md`
- `docs/plans/planpack_2025-12-27_tempPlans/keyboard-defense-plans/COMPARATIVE_MECHANICS_MAPPING.md`
- `docs/plans/planpack_2025-12-27_tempPlans/keyboard-defense-plans/RESEARCH_SUPER_FANTASY_KINGDOM.md`
- `docs/plans/planpack_2025-12-27_tempPlans/keyboard-defense-plans/extended/EVENT_POI_SYSTEM_SPEC.md`

Acceptance criteria:
- New exploration events appear in log without breaking determinism.
- Map data remains data-driven and tested.
- UI can surface event outcomes clearly in the log.

### P1-QA-001 Testing and QA hardening
Status: In progress (significant test additions 2026-01-11)

Increase automated coverage and formalize manual QA gates for releases.

**Progress (2026-01-11):** Test suite expanded to 3,801 assertions covering:
- Boss encounters (phases, mechanics, dialogue)
- Difficulty modes (modifiers, multipliers)
- Lesson consistency (lesson-story alignment)
- Dialogue flow (speakers, substitutions, milestones)
- Exploration challenges (generation, evaluation, rewards)
- Daily challenges (structure, shop, streaks)
- Story manager (acts, bosses, tips, lore)
- Buffs system (multipliers, bonuses, active buff tracking)
- Combo system (tiers, damage/gold bonuses, milestones)
- Affixes system (application, glyphs, serialization)
- Bestiary system (tier/category names, encounter tracking)
- Damage types (calculations, resistances, type info)
- Enemy types (enums, definitions, tier validation)
- Items system (equipment slots, rarities, data structure)
- Crafting system (materials, recipes, ingredients)
- Endless mode (milestones, modifiers, unlock conditions)
- Expeditions (state constants, worker tracking)
- Status effects (constants, categories, DoT properties)
- Tower types (enums, IDs, category arrays, footprints)
- Skills (skill trees, data structure, prerequisites)
- Quests (type/status constants, daily quest structure)
- Hero types (hero IDs, data, passives, abilities)
- Wave composer (tier weights, themes, modifiers)

Planning refs:
- `docs/plans/p1/QA_AUTOMATION_PLAN.md`
- `docs/plans/p1/SCENARIO_TEST_HARNESS_PLAN.md`
- `docs/plans/p1/SCENARIO_HARNESS_IMPLEMENTATION_SPEC.md`
- `docs/plans/p1/SCENARIO_CATALOG.md`
- `docs/plans/p1/CI_AUTOMATION_SPEC.md`
- `docs/plans/p1/GDSCRIPT_QUALITY_PLAN.md`
- `docs/QUALITY_GATES.md`
- `docs/plans/planpack_2025-12-27_tempPlans/generated/TESTING_QA_PLAN.md`
- `docs/plans/planpack_2025-12-27_tempPlans/GODOT_TESTING_PLAN.md`
- `docs/plans/planpack_2025-12-27_tempPlans/keyboard-defense-plans/checklists/QA_CHECKLIST.md`
- `docs/plans/ARCHITECTURE_MAPPING.md`
- `docs/plans/SCHEMA_ALIGNMENT_PLAN.md`

Acceptance criteria:
- Headless tests cover core sim, UI, and data contracts.
- A manual QA checklist is maintained and used before releases.
- Test summary output is visible in scripts and logs.
- Phase 1 scenario harness runs selected JSON scenarios headless.

## P2 - Later (strategic expansion)

### P2-META-001 Meta progression and mastery
Status: Complete (2026-01-11)

Add lightweight persistent unlocks tied to lesson mastery without changing core balance.

**Progress:** Core meta progression systems implemented:
- `sim/titles.gd` - Title and badge system with 30+ titles and 8+ badges
- Titles organized by category: Speed, Accuracy, Combat, Dedication, Mastery, Special
- Unlock conditions based on WPM, accuracy, kills, combos, streaks, words typed, and achievements
- `title` and `badges` commands for viewing and equipping
- Profile persistence for unlocked titles/badges and equipped title
- Comprehensive tests (70+ assertions)

Existing related systems:
- `sim/skills.gd` - Skill tree with 3 paths (Speed, Accuracy, Defense)
- `sim/milestones.gd` - WPM/accuracy/combo/kill/word/streak milestones
- `sim/player_stats.gd` - Lifetime stats tracking
- Achievement system in typing_profile.gd

Planning refs:
- `docs/plans/p2/META_PROGRESSION_PLAN.md`
- `docs/plans/planpack_2025-12-27_tempPlans/keyboard-defense-plans/GDD.md`

Acceptance criteria:
- [x] Unlocks are cosmetic or optional, not required for success.
- [x] Progression data remains deterministic and saveable.

### P2-HERO-001 Hero or faction layer
Status: Complete (2026-01-11)

Introduce optional hero or faction choices with small typing-linked bonuses.

**Progress:** Full hero system implemented with 5 heroes. Each hero has passive bonuses and one typed-command ability. Heroes are optional - game works without one selected.

Heroes:
- Scribe (Support): +5% crit, gold for perfect words, INSCRIBE ability
- Warden (Tank): -10% castle damage, +1 HP, SHIELD ability
- Tempest (Assault): fast typing bonus, SURGE ability
- Sage (Control): +20% buff duration, SLOW ability
- Forgemaster (Builder): +15% gold, -10% tower cost, REINFORCE ability

Key deliverables:
- `sim/hero_types.gd` - Hero definitions, passives, abilities
- Hero command (`hero [id|none]`) for selection
- Hero passive integration with upgrade effect system
- Profile persistence for selected hero
- Comprehensive tests

Planning refs:
- `docs/plans/p2/HERO_SYSTEM_PLAN.md`
- `docs/plans/planpack_2025-12-27_tempPlans/keyboard-defense-plans/GDD.md`

Acceptance criteria:
- [x] Choices are readable and reversible without forcing rerolls.
- [x] Balance and determinism remain stable.

### P2-LOC-001 Localization scaffolding
Status: Complete (2026-01-11)

Add a localization pipeline for UI strings and commands.

**Progress:** Full localization infrastructure implemented:
- `sim/locale.gd` - Translation system with locale management, string lookup, placeholder substitution, and formatting helpers
- `data/translations/en.json` - English UI strings organized by category (ui, game, resources, combat, messages, help, stats, heroes, tutorial, accessibility, errors)
- `data/translations/es.json` - Spanish translations
- `data/translations/de.json` - German translations
- `data/translations/fr.json` - French translations
- `data/translations/pt.json` - Portuguese translations
- Profile persistence for locale preference via `typing_profile.gd`
- `locale` command (with `lang`/`language` aliases) for runtime language switching
- Comprehensive tests for locale system (40+ assertions)

Remaining work (future iterations):
- Integrate get_text() calls throughout UI components
- Test UI layouts with longer translated strings

Planning refs:
- `docs/plans/p2/LOCALIZATION_PLAN.md`
- `docs/plans/planpack_2025-12-27_tempPlans/keyboard-defense-plans/preprod/LOCALIZATION_AND_LAYOUTS.md`

Acceptance criteria:
- [x] Strings are centralized and can be exported for translation.
- [x] Translation files for 5 locales (en, es, de, fr, pt).

### P2-AUDIO-001 Audio pass
Status: Complete (2026-01-11)

Add procedural or original SFX for typing and combat feedback.

**Progress:** Full audio integration completed. AudioManager autoload with 60+ SFX presets, 6 music tracks, and comprehensive game mode integration. All three main game modes (open_world.gd, typing_defense.gd, kingdom_defense.gd) now have audio calls for music transitions, combat events, typing feedback, and UI interactions.

Planning refs:
- `docs/plans/p2/AUDIO_PLAN.md`
- `docs/plans/planpack_2025-12-27_tempPlans/keyboard-defense-plans/assets/AUDIO_EVENT_MAP.md`

Acceptance criteria:
- [x] Audio events map to key gameplay actions.
- [x] Asset audit rules are respected and documented.

## Future Opportunities (from Story/GDD analysis)

**Note:** As of 2026-01-10, all previously listed items have been implemented. See `docs/PRIORITIES.md` for updated status.

### F-ACH-001 Achievement System Integration - COMPLETED
Full achievement system with UI, notifications, and profile persistence.
- `game/achievement_checker.gd` - Achievement tracking logic
- `ui/components/achievement_panel.gd/.tscn` - Achievement display panel
- `ui/components/achievement_popup.gd/.tscn` - Unlock notifications

### F-NUM-001 Numbers and Symbols Lessons - COMPLETED
All campaign lessons exist in `data/lessons.json` including numbers_1, numbers_2, punctuation_1, symbols_1.

### F-BOSS-001 Boss Battle Mode - COMPLETED
Multi-phase boss system with unique mechanics per boss.
- `sim/boss_encounters.gd` - 4 bosses with distinct abilities
- Phase transitions with HP thresholds
- Boss-specific dialogue (intro, phases, defeat)

### F-PROG-001 Daily Streak and Milestone Tracking - COMPLETED
Full streak tracking in `game/typing_profile.gd` with persistence and notification.

### F-LORE-001 Lore Browser - COMPLETED
`ui/components/lore_panel.gd` with category navigation and formatted display.

### F-TIP-001 Contextual Tip System - COMPLETED
`ui/components/tip_notification.gd` with context-aware tips and cooldown system.

### F-OW-001 Open World Story Integration - COMPLETED (2026-01-10)
Open World mode now includes narrative integration:
- [x] Welcome dialogue from Elder Lyra on game start
- [x] Exploration milestone messages (10, 25, 50 tiles)
- [x] First combat introduction dialogue
- [x] Victory messages with contextual typing tips
- [x] Dialogue box integration with pause during narrative

Future expansion could add:
- Region-specific lore triggers
- Terrain discovery flavor text
- Boss encounter dialogues

## Inspiration / Research
- Summary: `docs/RESEARCH_SFK_SUMMARY.md`

## Testing and Quality Gates
- Headless tests must pass: `res://tests/run_tests.gd`.
- Smoke boot main scene headless without rendering.
- No sim regressions: deterministic outcomes remain identical for same seed/actions.
- README and help text updated for new commands or panels.
