# Plan Library

**Last updated:** 2026-01-09

This folder contains design specifications and implementation blueprints for Keyboard Defense.

## Development Model

**All development is done by Claude Code.** These documents serve as:

1. **Implementation Blueprints** - JSON schemas can be extracted directly into `data/` files
2. **Reference Specifications** - Check relevant docs before implementing features
3. **Consistency Guide** - Use documented IDs, values, and structures

When implementing from these plans:
- Extract JSON directly from docs into game data files
- Follow naming conventions exactly as specified
- Use documented balance values (damage, costs, timing)
- Reference plan doc paths in code comments when helpful

Art assets are created by Claude Code via SVG generation, Godot draw primitives, or procedural generation - see `SPRITE_USAGE_GUIDE.md`.

## Current Status

- **P0 items are nearly complete** - see `p0/P0_IMPLEMENTATION_BACKLOG.md` for task status
- **Multiple shipped milestones** - story system, game modes, VFX, accessibility, balance tools, export pipeline
- **Gaps identified** - see `docs/PRIORITIES.md` for next steps

Planpacks:
- planpack_2025-12-27_tempPlans/  (generated plans, status docs, checklists, UI status plans)

Action Plans (P0):
- `p0/ONBOARDING_PLAN.md`
- `p0/ONBOARDING_COPY.md`
- `p0/BALANCE_PLAN.md`
- `p0/BALANCE_TARGETS.md`
- `p0/ACCESSIBILITY_READABILITY_PLAN.md`
- `p0/EXPORT_PIPELINE_PLAN.md`
- `p0/P0_IMPLEMENTATION_BACKLOG.md`

Action Plans (P1):
- `p1/CONTENT_EXPANSION_PLAN.md`
- `p1/VISUAL_STYLE_GUIDE_PLAN.md`
- `p1/MAP_EXPLORATION_PLAN.md`
- `p1/WORLD_EXPANSION_PLAN.md` - Vision for expanding Keystonia to 3 lands, 14 regions, 161+ POIs
- `p1/REGION_SPECIFICATIONS.md` - Detailed specs for all 14 regions, zones, POIs, NPCs
- `p1/NPC_CHARACTER_ROSTER.md` - Complete character roster with dialogue examples
- `p1/WORLD_LORE_HISTORY.md` - Creation myth, ages, Letter Spirits mythology
- `p1/POI_EVENT_SYSTEM.md` - Event tables, challenge types, rewards by POI
- `p1/ENVIRONMENTAL_MECHANICS.md` - Weather, terrain, day/night, hazards
- `p1/QUEST_SIDE_CONTENT.md` - Main quests, side chains, dailies, achievements
- `p1/ENEMY_COMBAT_DESIGN.md` - Enemy tiers, affixes, bosses, wave composition
- `p1/TOWER_BUILDING_SYSTEM.md` - Tower types, upgrades, synergies, placement
- `p1/ITEM_EQUIPMENT_SYSTEM.md` - Equipment, consumables, crafting, inventory
- `p1/PLAYER_PROGRESSION_SKILLS.md` - Levels, skill trees, prestige, mastery
- `p1/UI_UX_SPECIFICATIONS.md` - Color palette, typography, components, layouts
- `p1/SAVE_SYSTEM_ARCHITECTURE.md` - Save data structure, versioning, cloud sync
- `p1/AUDIO_MUSIC_SYSTEM.md` - Typing sounds, music, ambient, dynamic audio
- `p1/KEYBOARD_LAYOUT_SUPPORT.md` - QWERTY, AZERTY, Dvorak, custom layouts
- `p1/ANALYTICS_TELEMETRY.md` - Session, typing, combat, economy analytics
- `p1/QA_AUTOMATION_PLAN.md`

Complete Catalogs (P1 - Implementation Ready):
- `p1/ENEMY_BESTIARY_CATALOG.md` - Full enemy database with JSON specs for all tiers
- `p1/ITEM_CATALOG_COMPLETE.md` - Complete item database (100+ items, all slots/types)
- `p1/SKILL_TREE_COMPLETE.md` - All skill trees with full ability details and synergies
- `p1/NPC_DIALOGUE_SCRIPTS.md` - Complete dialogue trees for all NPCs
- `p1/LORE_ENTRIES_COMPLETE.md` - All 50 lore page contents
- `p1/BOSS_ENCOUNTER_SCRIPTS.md` - Phase-by-phase boss scripts with mechanics
- `p1/TOWER_SPECIFICATIONS_COMPLETE.md` - All tower types, upgrades, synergies, placement rules
- `p1/WAVE_COMPOSITION_SYSTEM.md` - Wave templates, regional modifiers, spawn patterns
- `p1/ACHIEVEMENT_SYSTEM_COMPLETE.md` - 145 achievements across 9 categories
- `p1/STATUS_EFFECTS_CATALOG.md` - All buffs, debuffs, environmental effects
- `p1/CRAFTING_RECIPES_COMPLETE.md` - 75+ recipes across 4 crafting stations
- `p1/ANIMATION_SPECIFICATIONS.md` - Complete animation system specs for all entities
- `p1/AUTO_DEFENSE_TOWER_SYSTEM.md` - Automated tower mechanics, balancing, synergies
- `p1/DIFFICULTY_MODES_SYSTEM.md` - Story/Adventure/Champion/Nightmare modes, modifiers
- `p1/COMBO_SCORING_SYSTEM.md` - Combo tiers, scoring formulas, multipliers, streaks
- `p1/ECONOMY_SHOP_SYSTEM.md` - Gold economy, shops, merchants, pricing
- `p1/TUTORIAL_HINTS_SYSTEM.md` - Tutorial sequences, contextual hints, training grounds
- `p1/CAMERA_VIEW_SYSTEM.md` - Camera modes, zoom, shake, transitions, minimap
- `p1/NOTIFICATION_FEEDBACK_SYSTEM.md` - Toasts, alerts, floating text, audio feedback
- `p1/SETTINGS_OPTIONS_SYSTEM.md` - All game settings, accessibility, controls
- `p1/SPRITE_USAGE_GUIDE.md` - Sprite standards, animation rules, presentation guidelines
- `p1/SCENARIO_TEST_HARNESS_PLAN.md`
- `p1/SCENARIO_CATALOG.md`

Lesson & Curriculum Plans (P1):
- `p1/LESSON_GUIDE_PLAN.md` - Lesson inventory, tracks, and gap analysis
- `p1/PEDAGOGY_GUIDE_FRAMEWORK.md` - Educational framework and content templates
- `p1/LESSON_INTRODUCTIONS_DRAFT.md` - Draft content for 25 lesson intros (training, gauntlets, bosses)
- `p1/LESSON_INTRODUCTIONS_EXTENDED.md` - 32 additional intros (realms, biomes, patterns, precision)
- `p1/WORD_PACK_SPECIFICATION.md` - Themed vocabularies, word generation algorithms
- `p1/LESSON_PROGRESSION_TREE.md` - Unlock criteria, prerequisites, progression paths
- `p1/TYPING_DRILLS_SPECIFICATION.md` - Drill types, sequences, practice modes
- `p1/MASTERY_ASSESSMENT_CRITERIA.md` - Scoring, achievements, certificates
- `p1/ADAPTIVE_DIFFICULTY_SYSTEM.md` - Dynamic difficulty adjustment algorithms

Implementation Specs:
- `p0/ONBOARDING_IMPLEMENTATION_SPEC.md`
- `p1/SCENARIO_HARNESS_IMPLEMENTATION_SPEC.md`
- `p1/CI_AUTOMATION_SPEC.md`
- `p1/GDSCRIPT_QUALITY_PLAN.md`

Action Plans (P2):
- `p2/META_PROGRESSION_PLAN.md`
- `p2/HERO_SYSTEM_PLAN.md`
- `p2/LOCALIZATION_PLAN.md`
- `p2/AUDIO_PLAN.md`

Cross-cutting plans:
- `ARCHITECTURE_MAPPING.md`
- `SCHEMA_ALIGNMENT_PLAN.md`

Reference docs:
- `docs/FINGER_GUIDE_REFERENCE.md` - Canonical finger-to-key assignments

Execution docs:
- `docs/QUALITY_GATES.md`
- `docs/PLAYTEST_PROTOCOL.md`

Triage:
- `PLANPACK_TRIAGE.md` (adoption decisions and gaps)

Guidance:
- Use docs/PROJECT_STATUS.md and docs/ROADMAP.md as the authoritative source of truth.
- Use planpacks as reference material only.

