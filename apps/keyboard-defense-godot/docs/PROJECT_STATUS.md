# Project Status

**Last updated:** 2026-01-11

## Overview
Keyboard Defense is a Godot 4 typing-first kingdom defense roguelite. The sim layer is deterministic and data-first, while the game layer renders a tile grid, HUD, and typing-driven day/night loop.

The game features "The Siege of Keystonia" narrative with a 20-day campaign across 5 acts, boss encounters, and a mentor system. Multiple game modes support different play styles from command-line sim to RTS-style defense.

Reference research summary: `docs/RESEARCH_SFK_SUMMARY.md` (inspiration only).
Plan library: `docs/plans/README.md` (reference material only).

## Game Modes

### Main Menu / Mode Selection
- `scenes/MainMenu.tscn` provides mode selection
- `scripts/GameController.gd` manages scene transitions

### Original Sim Mode (Main)
- `game/main.gd` + `scenes/Main.tscn`
- Command-line typing interface with day/night loop
- Full feature set described below

### Kingdom Defense Mode
- `game/kingdom_defense.gd` + `scenes/KingdomDefense.tscn`
- RTS-style top-down typing game inspired by Super Fantasy Kingdom
- Planning phase with cursor-based building
- Defense phase with real-time enemy movement and typing combat
- Story integration with act progression and dialogue
- Practice mode for key-by-key learning

### Open World Mode
- `game/open_world.gd` + `scenes/OpenWorld.tscn`
- Exploration-focused gameplay with tile discovery
- Resource gathering (wood, stone, food)
- Roaming enemies and encounter system
- Structure building (towers, walls, farms)

### Typing Defense Mode
- `game/typing_defense.gd` + `scenes/TypingDefense.tscn`
- Pure typing battle focus

## Story and Narrative System

### Campaign Structure (`data/story.json`)
- 5 acts spanning 20 days:
  - Act 1 "The Awakening" (days 1-4): Home row mastery
  - Act 2 "Reaching Beyond" (days 5-8): Reach keys
  - Act 3 "The Depths" (days 9-12): Bottom row
  - Act 4 "Full Power" (days 13-16): Full alphabet speed
  - Act 5 "The Final Stand" (days 17-20): Numbers and symbols
- Boss encounters at end of each act
- Elder Lyra mentor with contextual dialogue

### Story Manager (`game/story_manager.gd`)
- Act progression tracking
- Dialogue system with substitutions
- Lesson introductions with finger guides
- Typing tips by category (posture, technique, practice, rhythm, etc.)
- Performance feedback (accuracy, speed, combo)
- Achievement definitions
- Lore access (kingdom, horde, characters)

### Dialogue System
- `game/dialogue_box.gd` + `scenes/DialogueBox.tscn`
- Typewriter text display
- Speaker identification
- Signal-based flow control

## Current Feature Set
- Day phase
  - Gather, explore, build, upgrade, demolish, cursor movement, inspect, map.
  - Action points, resource costs, adjacency bonuses, and wall/tower path blocking.
  - Midgame economy guardrails (stone catch-up explores, low-food bonus, storage caps) with a one-time UI note.
  - Save/load and new run commands.
- Night phase
  - Turn-based typing defense with enemy variety (raider/scout/armored) and per-enemy words.
  - Enemies spawn on borders, move via pathfinding, and are targeted by typing.
  - Towers attack with upgrade scaling; wave panel shows enemies and progress bars.
- Typing tutor features
  - Live prefix feedback, safe Enter gating, typing stats, reports, history, trends, and coaching.
  - Practice goals with thresholds and colored goal badge.
  - Lesson selection and per-lesson progress with recent trends and sparklines.
- UI and controls
  - Typing-first command bar, panels (settings, lessons, trend, history, report), and hotkeys.
  - Rebindable actions (settings, lessons, trend, compact, history, report, goal) with in-game bind flow and controls list.
  - UI scale setting (settings scale/font) and compact panels mode for readability on smaller screens.
  - Accessibility checklist: `docs/ACCESSIBILITY_VERIFICATION.md` (manual 1280x720 readability + keyboard-only checks, plus `settings verify` output and keybind conflict warnings).
  - Onboarding tutorial flow with step engine, copy-based panel, and replay/skip controls.

## Visual Effects and Polish
- Projectile effects with tower attacks
- Castle morphing animations (damage states)
- Combo counter with visual feedback (particles, screen effects)
- Defeat animations for enemies
- Hit effects (`game/hit_effects.gd`)
- Status effect icons display
- Boss progress indicators
- Sprite animations (`game/sprite_animator.gd`)

## Accessibility Options
- High contrast mode toggle
- Reduced motion setting (disables particles, animations)
- Game speed multiplier (0.5x - 2.0x)
- Keyboard navigation hints toggle
- Practice mode for individual key learning
- All settings persist to `user://profile.json`

## Balance Diagnostics Infrastructure
- `balance export` command with metric groups:
  - wave: night wave totals by day
  - enemies: HP bonus, armor, speed by enemy type and day
  - towers: damage, cost, upgrade scaling
  - buildings: resource production, costs
  - midgame: caps, catch-up bonuses
- `balance verify` command with guardrails and invariant checks
- `balance diff` command for comparing to saved baselines
- `balance summary` for compact pacing signals
- Extensive tuning history (Milestones 72-102)

## Export Pipeline
- Windows Desktop export preset with deterministic paths
- `VERSION.txt` as single source of truth
- Bump version scripts (`scripts/bump_version.ps1`, `scripts/bump_version.sh`)
  - patch/minor/major increment modes
  - dry-run and apply modes
- Export scripts with validation
- Manifest generation with metadata
- PCK validation and packaging
- Product/file version consistency enforcement

## Art Assets
New SVG assets in `assets/art/src-svg/`:

### Buildings (`buildings/`)
- Tower variants: arcane, holy, multi, siege (each with t1, t2, t3 tiers)

### Enemies (`enemies/`)
- New enemy types: champion, dragon, elemental_fire, elemental_ice, hydra, specter, titan, warlord, wraith
- Affixes: armored, burning, enraged, frozen, shielded, swift, toxic, vampiric

### Effects (`effects/`)
- Combat effects: arrow_hit, burn, critical, damage_boost, magic_hit, poison, shield, slow, speed_boost, stun
- Typing effects: combo, word_complete, word_error

## Persistence Model
- Run savegame: `user://savegame.json` stores the current deterministic run state (map, resources, phase, enemies, lesson id, RNG state).
- Profile: `user://profile.json` stores typing history, lifetime stats, practice goal, preferred lesson, lesson progress, keybinds, and UI preferences.

## Architecture Snapshot
- `sim/**`: deterministic rules and data helpers (no Node/Scene dependencies).
- `game/**` and `ui/**`: rendering, input routing, panels, and profile persistence.
- Tests: headless via `godot --headless --path . --script res://tests/run_tests.gd` (wrappers in `scripts/`).
- Scenario harness (Phase 2): `res://tools/run_scenarios.gd` runs `data/scenarios.json` headless with tag/priority filtering and expanded balance coverage.
- Scenario reports and summaries are written under `Logs/ScenarioReports/` for CI-friendly collection (via `--out-dir`).

## Test Coverage (as of 2026-01-12)
**Total: ~7,150+ assertions**

- **Parser tests**: Command parsing, intent validation
- **Reducer tests**: State mutation, intent application
- **Determinism tests**: RNG reproducibility
- **Lessons tests**: Lesson data validation, word generation
- **Balance report tests**: Export, verify, diff commands
- **Typing tests**: Feedback, stats, trends, profiles
- **Story manager tests**: Acts, bosses, dialogue, lore
- **Boss encounters tests**: Phases, mechanics, dialogue
- **Difficulty tests**: Modes, modifiers, multipliers
- **Lesson consistency tests**: Lesson-story intro alignment
- **Dialogue flow tests**: Key dialogues, substitutions, milestones
- **Exploration challenges tests**: Generation, evaluation, rewards
- **Daily challenges tests**: Structure, shop, streaks
- **Buffs tests**: Multipliers, bonuses, active buff tracking
- **Combo tests**: Tiers, damage/gold bonuses, milestones
- **Affixes tests**: Application, glyphs, serialization
- **Bestiary tests**: Tier/category names, encounter tracking
- **Damage types tests**: Calculations, resistances, type info
- **Enemy types tests**: Enums, definitions, tier validation
- **Items tests**: Equipment slots, rarities, data structure
- **Crafting tests**: Materials, recipes, ingredients
- **Endless mode tests**: Milestones, modifiers, unlock conditions
- **Expeditions tests**: State constants, worker tracking
- **Status effects tests**: Constants, categories, DoT properties
- **Tower types tests**: Enums, IDs, category arrays, footprints
- **Skills tests**: Skill trees, data structure, prerequisites
- **Quests tests**: Type/status constants, daily quest structure
- **Hero types tests**: Hero IDs, data, passives, abilities
- **Wave composer tests**: Tier weights, themes, modifiers
- **Upgrades tests**: Kingdom/unit upgrades, effects, purchase validation
- **Loot tests**: Quality tiers, multipliers, loot queue management
- **Milestones tests**: Milestone categories, messages, detection, formatting
- **Auto tower types tests**: Tiers, targeting modes, damage types, DPS calculations, upgrade paths
- **Player stats tests**: Statistics tracking, records, derived stats, formatting
- **Login rewards tests**: Reward tiers, bonuses, streak progress, buff management
- **Synergy detector tests**: Synergy definitions, detection, effect queries
- **Auto targeting tests**: Target selection modes (nearest, HP, fastest, cluster, chain, zone, smart)
- **Enemy abilities tests**: Ability types, passive queries, untargetable states, data integrity
- **Practice goals tests**: Goal validation, normalization, labels, descriptions, thresholds
- **Resource nodes tests**: Challenge types, node spawning, harvesting, respawn mechanics
- **Typing metrics tests**: WPM window, accuracy calculation, combo multipliers, battle summary
- **Typing tower bonuses tests**: Tower damage constants, chain bonuses, letter shrine modes
- **Summoned units tests**: Summon creation/removal, Legion synergy, taunt detection, serialization
- **Trade tests**: Base rates, market requirements, command parsing, trade calculation/execution
- **Workers tests**: Production bonuses, upkeep calculation, assignment/unassignment, capacity
- **Special commands tests**: Command structure, unlock levels, cooldowns, effects, formatting
- **Research tests**: Prerequisites, start/cancel research, progress tracking, research tree
- **Targeting tests**: Priority enums, single/multi/AoE/chain targeting, boss prioritization
- **Tower combat tests**: Attack dispatch, tower types, summoner/trap processing, damage application
- **RNG tests**: Seed conversion, roll_range determinism, choose function, state mutation
- **Balance tests**: Midgame constants, resource caps, stone catchup, food bonus mechanics
- **Intents tests**: Intent creation, help_lines content, COMMANDS array structure
- **Tick tests**: Wave base values, night prompts, advance_day, wave total calculation
- **Auto tower combat tests**: Targeting modes, damage events, fire checks, state init, enemy conversion, damage application
- **World tick tests**: Constants, terrain biomes, threat contribution, enemy kind selection, threat breakdown
- **Controls aliases tests**: Modifier aliases, key aliases, token normalization, modifier detection, keycode lookup
- **Scenario report tests**: Report building, path normalization, directory normalization, path joining
- **Button feedback tests**: Scale constants, duration constants, hover constants, animation timing
- **Theme colors tests**: Background colors, border colors, text colors, accent colors, status colors, gameplay colors, alpha helper functions
- **Persistence tests**: Save path constant validation
- **Data integrity tests**: Data file existence, JSON parsing, structure validation for lessons, story, buildings, scenarios, assets
- **Audio manager tests**: Bus constants, path constants, rate limits, timing, SFX/Music enums, ducking, threat thresholds
- **Damage numbers tests**: Animation constants, font sizes, damage type colors
- **Keyboard display tests**: Layout constants, finger zones, finger colors, animation timing, ripple effects
- **Combo announcement tests**: Milestones, animation constants, tier colors, celebration titles
- **Threat bar tests**: Visual constants, threat thresholds, health display constants
- **Typing display tests**: Font sizes, animation timing, progress bar, accuracy ring colors, letter burst effects
- **Modal panel tests**: Title font, button dimensions, fade animation timing
- **Command bar tests**: Background colors, error shake animation, autocomplete popup constants
- **Event panel tests**: Font sizes, fade duration
- **Dialogue box tests**: Fade in/out durations
- **Grid renderer tests**: Particle constants, damage number constants, animation FPS
- **Action tooltip tests**: Timing constants, size constants
- **Battle stage tests**: Core constants, damage number settings, trail particle settings
- **Battlefield tests**: Buff streaks, feedback durations, font sizes, threat/trend tracking, streak glow, combo milestones, accuracy badges, animation timing, grade system

## Planning
- `docs/ROADMAP.md` is the authoritative milestone list.
- `docs/plans/p0/` contains P0 action plans tied to roadmap IDs.
- `docs/plans/README.md` is the plan library index for imported references.
- `docs/plans/PLANPACK_TRIAGE.md` tracks planpack adoption decisions.

## P0-ACC Signoff (manual)
- [ ] Run `docs/ACCESSIBILITY_VERIFICATION.md` at 1280x720.
- [ ] Capture `settings verify` output and panel screenshots for the milestone report.

## Definition of Done (Playable Vertical Slice)
- [ ] New player can start a run and see the HUD/grid.
- [ ] Commands and hotkeys are discoverable (help/settings) and usable without mouse.
- [ ] Player can survive at least one night and see a typing report.
- [ ] Save/load restores the run state reliably.
- [ ] Lessons, goals, and trend panels provide feedback without affecting sim outcomes.
