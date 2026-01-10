# System Dependency Graph

Visual map of how Keyboard Defense systems interconnect. Use this to understand impact of changes.

## Architecture Layers

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           UI LAYER (ui/)                                │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐ ┌──────────────┐   │
│  │ command_bar  │ │ typing_display│ │ threat_bar   │ │ event_panel  │   │
│  └──────┬───────┘ └──────┬───────┘ └──────┬───────┘ └──────┬───────┘   │
│         │                │                │                │            │
│  ┌──────┴────────────────┴────────────────┴────────────────┴───────┐   │
│  │                    Signals & UI Events                          │   │
│  └─────────────────────────────────┬───────────────────────────────┘   │
└────────────────────────────────────┼───────────────────────────────────┘
                                     │
┌────────────────────────────────────┼───────────────────────────────────┐
│                           GAME LAYER (game/)                           │
│  ┌──────────────┐ ┌──────────────┐ │ ┌──────────────┐ ┌──────────────┐ │
│  │ main.gd      │ │grid_renderer │ │ │ hit_effects  │ │audio_manager │ │
│  │ (Controller) │ │              │ │ │              │ │              │ │
│  └──────┬───────┘ └──────────────┘ │ └──────────────┘ └──────────────┘ │
│         │                          │                                    │
│  ┌──────┴──────────────────────────┴───────────────────────────────┐   │
│  │              Intent Creation & State Rendering                   │   │
│  └─────────────────────────────────┬───────────────────────────────┘   │
└────────────────────────────────────┼───────────────────────────────────┘
                                     │
                                     ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                           SIM LAYER (sim/)                              │
│                                                                         │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                     COMMAND PIPELINE                             │   │
│  │  parse_command.gd → intents.gd → apply_intent.gd                │   │
│  └─────────────────────────────────┬───────────────────────────────┘   │
│                                    │                                    │
│  ┌─────────────┬─────────────┬─────┴─────┬─────────────┬────────────┐  │
│  ▼             ▼             ▼           ▼             ▼            │  │
│ ┌───────┐ ┌─────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐       │  │
│ │types.gd│ │enemies.gd│ │buildings │ │ lessons  │ │ words.gd │       │  │
│ │(State)│ │         │ │   .gd    │ │   .gd    │ │          │       │  │
│ └───┬───┘ └────┬────┘ └────┬─────┘ └────┬─────┘ └────┬─────┘       │  │
│     │          │           │            │            │              │  │
│     └──────────┴───────────┴────────────┴────────────┘              │  │
│                            │                                         │  │
│  ┌─────────────────────────┴─────────────────────────────────────┐  │  │
│  │                    SUPPORT SYSTEMS                             │  │  │
│  │  balance.gd | tick.gd | events.gd | upgrades.gd | world_tick  │  │  │
│  └───────────────────────────────────────────────────────────────┘  │  │
└─────────────────────────────────────────────────────────────────────────┘
                                     │
                                     ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                           DATA LAYER (data/)                            │
│  lessons.json | enemies.json | buildings.json | upgrades.json | ...    │
└─────────────────────────────────────────────────────────────────────────┘
```

## Core Systems

### Command Pipeline
```
User Input
    │
    ▼
┌──────────────────┐     ┌──────────────────┐     ┌──────────────────┐
│ parse_command.gd │────▶│   intents.gd     │────▶│ apply_intent.gd  │
│                  │     │                  │     │                  │
│ • Tokenize input │     │ • Create intent  │     │ • Validate phase │
│ • Match keywords │     │ • Add parameters │     │ • Check costs    │
│ • Validate syntax│     │ • Return dict    │     │ • Mutate state   │
└──────────────────┘     └──────────────────┘     │ • Generate events│
                                                   └────────┬─────────┘
                                                            │
                              ┌──────────────────────────────┘
                              ▼
                    ┌──────────────────┐
                    │   GameState      │
                    │   (types.gd)     │
                    └──────────────────┘
```

### Typing Combat Flow
```
┌──────────────────┐
│  Enemy Spawned   │
│  (with word)     │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐     ┌──────────────────┐
│  Player Types    │────▶│ typing_feedback  │
│                  │     │      .gd         │
└──────────────────┘     │                  │
                         │ • Match prefix   │
                         │ • Calculate edit │
                         │ • Rank candidates│
                         └────────┬─────────┘
                                  │
         ┌────────────────────────┴────────────────────────┐
         ▼                                                 ▼
┌──────────────────┐                             ┌──────────────────┐
│  Word Complete   │                             │  Partial Match   │
│                  │                             │                  │
│ • Deal damage    │                             │ • Update display │
│ • Award gold     │                             │ • Play sound     │
│ • Update stats   │                             │ • Show feedback  │
└────────┬─────────┘                             └──────────────────┘
         │
         ▼
┌──────────────────┐     ┌──────────────────┐
│   Enemy Dies?    │────▶│  typing_stats.gd │
│                  │     │                  │
│ • Remove enemy   │     │ • Track WPM      │
│ • Spawn loot     │     │ • Track accuracy │
│ • Check wave end │     │ • Update streaks │
└──────────────────┘     └──────────────────┘
```

### Day/Night Cycle
```
┌──────────────────┐
│    DAY PHASE     │
│                  │
│ • Build/upgrade  │
│ • Manage workers │
│ • Explore POIs   │
│ • Trade resources│
└────────┬─────────┘
         │
         ▼ (player types "night" or "ready")
┌──────────────────┐
│   NIGHT PHASE    │
│                  │
│ • Waves spawn    │
│ • Type to attack │
│ • Towers auto-fire│
│ • Manage threats │
└────────┬─────────┘
         │
         ▼ (all waves cleared)
┌──────────────────┐
│   DAWN PHASE     │
│                  │
│ • Collect loot   │
│ • Apply bonuses  │
│ • Advance day    │
│ • Show summary   │
└────────┬─────────┘
         │
         └─────────▶ Back to DAY PHASE
```

## Data Dependencies

### Lesson System
```
┌──────────────────┐
│  lessons.json    │
│                  │
│ • Lesson defs    │
│ • Graduation paths│
│ • Mode configs   │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐     ┌──────────────────┐
│   lessons.gd     │────▶│    words.gd      │
│                  │     │                  │
│ • Load lessons   │     │ • Generate words │
│ • Track progress │     │ • Apply lengths  │
│ • Check mastery  │     │ • Filter chars   │
└──────────────────┘     └──────────────────┘
         │
         ▼
┌──────────────────┐
│  Enemy word      │
│  assignment      │
└──────────────────┘
```

### Upgrade System
```
┌────────────────────────────────────────────────────────────┐
│                    UPGRADE SOURCES                          │
│                                                            │
│  ┌──────────────────┐  ┌──────────────────┐               │
│  │kingdom_upgrades  │  │ unit_upgrades    │               │
│  │    .json         │  │    .json         │               │
│  └────────┬─────────┘  └────────┬─────────┘               │
│           │                     │                          │
│           └──────────┬──────────┘                          │
│                      ▼                                     │
│           ┌──────────────────┐                             │
│           │   upgrades.gd    │                             │
│           │                  │                             │
│           │ • Check requires │                             │
│           │ • Apply effects  │                             │
│           │ • Track purchased│                             │
│           └────────┬─────────┘                             │
│                    │                                       │
│    ┌───────────────┼───────────────┐                       │
│    ▼               ▼               ▼                       │
│ ┌───────┐    ┌──────────┐   ┌──────────┐                  │
│ │ Stats │    │ Buildings │   │ Combat   │                  │
│ │ boost │    │ unlocks  │   │ bonuses  │                  │
│ └───────┘    └──────────┘   └──────────┘                  │
└────────────────────────────────────────────────────────────┘
```

### Event System
```
┌──────────────────┐
│  event_tables.gd │
│                  │
│ • Event weights  │
│ • Conditions     │
│ • Cooldowns      │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐     ┌──────────────────┐
│    events.gd     │────▶│ event_effects.gd │
│                  │     │                  │
│ • Roll events    │     │ • Apply buffs    │
│ • Check triggers │     │ • Modify state   │
│ • Queue display  │     │ • Spawn enemies  │
└──────────────────┘     └──────────────────┘
         │
         ▼
┌──────────────────┐
│  event_panel.gd  │
│  (UI)            │
│                  │
│ • Show choices   │
│ • Handle input   │
└──────────────────┘
```

## File Impact Matrix

When modifying a system, these files may also need changes:

| If you change... | Also check... |
|------------------|---------------|
| `types.gd` (GameState) | `apply_intent.gd`, `save.gd`, all sim files that read state |
| `enemies.gd` | `apply_intent.gd`, `world_tick.gd`, `grid_renderer.gd` |
| `buildings.gd` | `apply_intent.gd`, `upgrades.gd`, `balance.gd` |
| `lessons.gd` | `words.gd`, `main.gd`, `lessons.json` |
| `apply_intent.gd` | Tests, `parse_command.gd`, `intents.gd` |
| `parse_command.gd` | `command_keywords.gd`, `intents.gd` |
| `balance.gd` | `apply_intent.gd`, `world_tick.gd`, tests |
| `upgrades.gd` | `kingdom_upgrades.json`, `unit_upgrades.json` |
| Any JSON schema | `data/schemas/*.schema.json`, validation scripts |

## Signal Flow (UI ↔ Game)

```
UI Components                    Game Layer
─────────────────────────────────────────────────────
command_bar.gd ──command_submitted──▶ main.gd
                                         │
typing_display ◀──state_changed─────────┘
                                         │
threat_bar.gd ◀──threat_updated─────────┘
                                         │
event_panel.gd ◀──event_triggered───────┘
        │
        └──choice_selected──▶ main.gd
                                │
stat_bar.gd ◀──resources_changed┘
```

## Adding New Systems

### Checklist for New Sim Feature
1. Create `sim/new_feature.gd` (extends RefCounted, static functions)
2. Add import to `apply_intent.gd` if needed
3. Add commands to `parse_command.gd`
4. Add to `intents.gd` help text
5. Create/update JSON data in `data/`
6. Update schema in `data/schemas/`
7. Add tests to `tests/run_tests.gd`

### Checklist for New UI Component
1. Create `ui/components/new_component.gd`
2. Create `scenes/NewComponent.tscn` if needed
3. Add signals for game layer communication
4. Connect to parent scene
5. Update main.gd to handle signals

### Checklist for New Game Mode
1. Create `scripts/NewMode.gd` (scene controller)
2. Create `scenes/NewMode.tscn`
3. Add to `GameController.gd` scene list
4. Create sim support files if needed
5. Add navigation from existing scenes
