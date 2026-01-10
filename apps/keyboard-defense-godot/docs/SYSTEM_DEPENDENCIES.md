# System Dependencies Map

This document maps how Keyboard Defense systems interconnect, helping Claude Code understand the architecture when implementing new features.

## Architecture Layers

```
┌─────────────────────────────────────────────────────────────┐
│                     PRESENTATION LAYER                       │
│  scenes/*.tscn    ui/*.gd    game/main.gd    game/*.gd      │
└─────────────────────────┬───────────────────────────────────┘
                          │ renders state, handles input
                          ▼
┌─────────────────────────────────────────────────────────────┐
│                      INTENT LAYER                            │
│  sim/intents.gd    sim/parse_command.gd    sim/apply_intent │
└─────────────────────────┬───────────────────────────────────┘
                          │ modifies state via intents
                          ▼
┌─────────────────────────────────────────────────────────────┐
│                    SIMULATION LAYER                          │
│  sim/types.gd (GameState)    sim/*.gd (pure logic)          │
└─────────────────────────┬───────────────────────────────────┘
                          │ loads/saves
                          ▼
┌─────────────────────────────────────────────────────────────┐
│                       DATA LAYER                             │
│  data/*.json    game/persistence.gd    game/typing_profile  │
└─────────────────────────────────────────────────────────────┘
```

## Core Flow: Input → State → Render

```
User Input (keyboard)
       │
       ▼
game/main.gd::_input() or CommandBar::_on_text_submitted()
       │
       ▼
sim/parse_command.gd::parse() → Dictionary (intent)
       │
       ▼
sim/apply_intent.gd::apply(state, intent) → Array[String] (events)
       │
       ▼
GameState modified + events returned
       │
       ▼
game/main.gd::_render_state() → UI updated
```

## System Dependency Graph

### Core Systems (Always Required)

| System | File(s) | Depends On | Used By |
|--------|---------|------------|---------|
| **GameState** | `sim/types.gd` | (none) | Everything |
| **Intent Parser** | `sim/parse_command.gd` | `sim/command_keywords.gd` | `game/main.gd` |
| **Intent Applier** | `sim/apply_intent.gd` | `sim/types.gd`, all sim/*.gd | `game/main.gd` |
| **Balance** | `sim/balance.gd` | (none) | `sim/enemies.gd`, `sim/buildings.gd`, all combat |
| **RNG** | `sim/rng.gd` | (none) | `sim/enemies.gd`, `sim/events.gd`, `sim/words.gd` |

### Combat Systems

| System | File(s) | Depends On | Used By |
|--------|---------|------------|---------|
| **Enemies** | `sim/enemies.gd` | `sim/balance.gd`, `sim/rng.gd`, `sim/words.gd` | `sim/apply_intent.gd`, `game/main.gd` |
| **Words** | `sim/words.gd` | `sim/lessons.gd`, `data/lessons.json` | `sim/enemies.gd` |
| **Lessons** | `sim/lessons.gd` | `data/lessons.json` | `sim/words.gd`, `game/main.gd` |
| **Typing Stats** | `sim/typing_stats.gd` | (none) | `game/main.gd` |
| **Typing Feedback** | `sim/typing_feedback.gd` | (none) | `game/main.gd` |
| **Typing Trends** | `sim/typing_trends.gd` | (none) | `game/main.gd` |
| **Affixes** | `sim/affixes.gd` | `sim/balance.gd` | `sim/enemies.gd` |

### Building Systems

| System | File(s) | Depends On | Used By |
|--------|---------|------------|---------|
| **Buildings** | `sim/buildings.gd` | `sim/balance.gd`, `data/buildings.json` | `sim/apply_intent.gd` |
| **Map** | `sim/map.gd` | `sim/types.gd` | `sim/apply_intent.gd`, `sim/enemies.gd` |
| **Research** | `sim/research.gd` | `data/research.json` | `sim/apply_intent.gd` |

### Progression Systems

| System | File(s) | Depends On | Used By |
|--------|---------|------------|---------|
| **Events** | `sim/events.gd` | `sim/event_tables.gd`, `sim/rng.gd` | `sim/apply_intent.gd` |
| **Event Effects** | `sim/event_effects.gd` | `sim/types.gd` | `sim/events.gd` |
| **POI** | `sim/poi.gd` | `data/pois/`, `sim/events.gd` | `sim/apply_intent.gd` |
| **Upgrades** | `sim/upgrades.gd` | `data/kingdom_upgrades.json`, `data/unit_upgrades.json` | `sim/apply_intent.gd` |
| **Achievement Checker** | `game/achievement_checker.gd` | `data/story.json` | `game/main.gd` |
| **Practice Goals** | `sim/practice_goals.gd` | (none) | `game/main.gd` |

### Open World Systems

| System | File(s) | Depends On | Used By |
|--------|---------|------------|---------|
| **World Tick** | `sim/world_tick.gd` | `sim/types.gd`, `sim/balance.gd` | `game/main.gd` |
| **Story Manager** | `game/story_manager.gd` | `data/story.json` | `game/main.gd` |

### Presentation Systems

| System | File(s) | Depends On | Used By |
|--------|---------|------------|---------|
| **Grid Renderer** | `game/grid_renderer.gd` | `sim/types.gd` | `game/main.gd` |
| **Hit Effects** | `game/hit_effects.gd` | (none) | `game/main.gd` |
| **Audio Manager** | `game/audio_manager.gd` | `data/audio/` | `game/main.gd` |
| **Asset Loader** | `game/asset_loader.gd` | `data/assets_manifest.json` | Various |

### UI Systems

| System | File(s) | Depends On | Used By |
|--------|---------|------------|---------|
| **Theme Colors** | `ui/theme_colors.gd` | (none) | All UI components |
| **Command Bar** | `ui/command_bar.gd` | (none) | `game/main.gd` |
| **Modal Panel** | `ui/components/modal_panel.gd` | (none) | Various panels |
| **Typing Display** | `ui/components/typing_display.gd` | (none) | `game/main.gd` |
| **Stat Bar** | `ui/components/stat_bar.gd` | (none) | Various panels |
| **Threat Bar** | `ui/components/threat_bar.gd` | (none) | `game/main.gd` |

### Persistence Systems

| System | File(s) | Depends On | Used By |
|--------|---------|------------|---------|
| **Persistence** | `game/persistence.gd` | `sim/types.gd` | `game/main.gd` |
| **Save** | `sim/save.gd` | `sim/types.gd` | `game/persistence.gd` |
| **Typing Profile** | `game/typing_profile.gd` | (none) | `game/main.gd` |

### Settings & Controls

| System | File(s) | Depends On | Used By |
|--------|---------|------------|---------|
| **Rebindable Actions** | `game/rebindable_actions.gd` | (none) | `game/main.gd`, `sim/intents.gd` |
| **Controls Formatter** | `game/controls_formatter.gd` | (none) | `game/main.gd` |
| **Keybind Conflicts** | `game/keybind_conflicts.gd` | `game/rebindable_actions.gd` | `game/main.gd` |
| **Onboarding Flow** | `game/onboarding_flow.gd` | (none) | `game/main.gd` |

## Data File Dependencies

### Core Data Files

| File | Loaded By | Used For |
|------|-----------|----------|
| `lessons.json` | `sim/lessons.gd` | Word pools, lesson definitions |
| `buildings.json` | `sim/buildings.gd` | Building stats, costs |
| `story.json` | `game/story_manager.gd`, `game/achievement_checker.gd` | Dialogue, achievements, tips |
| `map.json` | `sim/map.gd` | World map, regions |
| `scenarios.json` | `tools/run_scenarios.gd` | Test scenarios |

### Upgrade Data Files

| File | Loaded By | Used For |
|------|-----------|----------|
| `kingdom_upgrades.json` | `sim/upgrades.gd` | Castle/kingdom upgrades |
| `unit_upgrades.json` | `sim/upgrades.gd` | Unit/combat upgrades |
| `building_upgrades.json` | `sim/buildings.gd` | Building tier upgrades |
| `research.json` | `sim/research.gd` | Research tree |

### Event Data Files

| File | Loaded By | Used For |
|------|-----------|----------|
| `events/*.json` | `sim/event_tables.gd` | Random event pools |
| `pois/*.json` | `sim/poi.gd` | Point of interest definitions |
| `drills.json` | `sim/lessons.gd` | Typing drill definitions |

### Audio/Asset Data

| File | Loaded By | Used For |
|------|-----------|----------|
| `assets_manifest.json` | `game/asset_loader.gd` | Asset registry |
| `audio/sfx_presets.json` | `game/audio_manager.gd` | Sound effect definitions |

## Adding New Systems

### Checklist When Adding a New Sim System

1. **Create sim file**: `sim/new_system.gd`
   - `extends RefCounted` (NOT Node)
   - Static functions only
   - No signals, no scenes

2. **Add data file** (if needed): `data/new_system.json`
   - Include `"version": 1`
   - Follow schema conventions

3. **Extend GameState** (if needed): `sim/types.gd`
   - Add state variables
   - Initialize in `_init()`

4. **Add intents** (if needed):
   - `sim/intents.gd` - Add to help_lines
   - `sim/command_keywords.gd` - Add keywords
   - `sim/parse_command.gd` - Add parsing
   - `sim/apply_intent.gd` - Add handler

5. **Wire to main.gd**:
   - Add preload at top
   - Call from appropriate methods
   - Update render if visual

6. **Update save/load** (if state changes):
   - `sim/save.gd` - Serialize new fields
   - `game/persistence.gd` - Load new fields

### Checklist When Adding a New UI Component

1. **Create scene**: `scenes/NewComponent.tscn`
2. **Create script**: `ui/components/new_component.gd`
3. **Wire signals** to parent
4. **Add to main scene** or create via code
5. **Connect in main.gd** `_ready()`

## Critical Integration Points

### main.gd is the Hub

`game/main.gd` orchestrates everything:
- Holds GameState instance
- Routes all input
- Calls IntentApplier
- Renders state to UI
- Manages panels
- Handles persistence

### Intent Applier is the Gatekeeper

`sim/apply_intent.gd` is the ONLY place state changes:
- Validates intent legality
- Calls appropriate sim functions
- Returns events for feedback
- Maintains state consistency

### GameState is the Single Source of Truth

`sim/types.gd` GameState holds ALL game state:
- Combat state (enemies, threat)
- Economy state (resources, buildings)
- Map state (terrain, structures)
- Progression state (upgrades, research)
- Session state (day, phase, AP)

## Dependency Rules

### Hard Rules (Never Break)

1. **sim/ never imports game/ or ui/**
2. **sim/ never uses Node, Signal, or scene types**
3. **game/ imports sim/ via preload**
4. **ui/ has no direct sim/ dependencies** (receives data via signals/methods)
5. **State changes ONLY through IntentApplier.apply()**

### Soft Rules (Prefer)

1. Pass state explicitly rather than using globals
2. Use signals for loose coupling in UI
3. Keep balance values in `sim/balance.gd`
4. Load JSON once, cache results
5. Prefer composition over inheritance

## Debugging Dependencies

### Finding What Uses a System

```bash
# Find all files that reference enemies.gd
grep -r "enemies" apps/keyboard-defense-godot/sim/ --include="*.gd"
grep -r "SimEnemies" apps/keyboard-defense-godot/ --include="*.gd"
```

### Finding What a System Uses

```bash
# Look at imports/preloads at top of file
head -30 apps/keyboard-defense-godot/sim/enemies.gd
```

### Checking Circular Dependencies

Sim layer should have no cycles. If `A.gd` preloads `B.gd` and `B.gd` preloads `A.gd`, refactor to break the cycle.

## Common Integration Patterns

### Adding a New Command

```
1. sim/command_keywords.gd - Add keyword to array
2. sim/intents.gd - Add to help_lines()
3. sim/parse_command.gd - Add parsing case
4. sim/apply_intent.gd - Add handler function
5. (optional) sim/new_feature.gd - Add logic
6. (optional) game/main.gd - Add rendering
```

### Adding a New Enemy Type

```
1. sim/enemies.gd - Add to ENEMY_TYPES constant or load from JSON
2. sim/balance.gd - Add balance values if unique
3. docs/plans/p1/ENEMY_BESTIARY_CATALOG.md - Document specs
4. (optional) Add affixes in sim/affixes.gd
5. (optional) Add special behaviors in enemy spawn logic
```

### Adding a New Upgrade

```
1. data/kingdom_upgrades.json or data/unit_upgrades.json - Add entry
2. sim/upgrades.gd - Ensure loader handles new fields
3. sim/apply_intent.gd - Ensure buy handler works
4. Relevant sim file - Apply upgrade effect
5. docs/plans - Document the upgrade
```

### Adding a New UI Panel

```
1. scenes/NewPanel.tscn - Create scene
2. ui/components/new_panel.gd - Create script
3. scenes/Main.tscn - Add to UIRoot
4. game/main.gd - Add @onready var
5. game/main.gd - Add toggle logic
6. sim/intents.gd - Add command if togglable via command
```
