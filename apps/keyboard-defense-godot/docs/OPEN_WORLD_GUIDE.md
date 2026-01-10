# Open World Guide

This document explains the open-world exploration system where players navigate a map, encounter enemies, and build defenses.

## Overview

The open-world mode combines exploration with real-time threat management:

```
Exploration → Discover Tiles → Build Structures → Encounter Enemies → Combat
     ↓              ↓                ↓                   ↓              ↓
  arrow keys    discover()      build wall/tower     roaming spawn   type words
```

## Scene Structure

```gdscript
# game/open_world.gd
extends Node2D

@onready var grid_renderer: Node2D = $GridRenderer
@onready var command_bar: LineEdit = $CanvasLayer/HUD/CommandBar
@onready var hp_label: Label = $CanvasLayer/HUD/TopBar/HPLabel
@onready var gold_label: Label = $CanvasLayer/HUD/TopBar/GoldLabel
@onready var day_label: Label = $CanvasLayer/HUD/TopBar/DayLabel
@onready var resources_label: Label = $CanvasLayer/HUD/TopBar/ResourcesLabel
@onready var mode_label: Label = $CanvasLayer/HUD/ModeLabel
@onready var tile_info_label: Label = $CanvasLayer/HUD/TileInfoLabel
@onready var actions_label: Label = $CanvasLayer/HUD/ActionsLabel
@onready var log_label: RichTextLabel = $CanvasLayer/HUD/LogPanel/LogLabel
@onready var objective_label: RichTextLabel = $CanvasLayer/HUD/ObjectivePanel/ObjectiveLabel
@onready var enemy_panel: Panel = $CanvasLayer/HUD/EnemyPanel
@onready var enemy_list: RichTextLabel = $CanvasLayer/HUD/EnemyPanel/EnemyList
```

## Game State

### Core Variables

```gdscript
var state: GameState
var log_lines: Array[String] = []
const MAX_LOG_LINES := 10
var typing_buffer: String = ""
```

### Activity Modes

| Mode | Description | Actions Available |
|------|-------------|-------------------|
| `exploration` | Normal gameplay | explore, build, gather, end |
| `encounter` | Fighting roaming enemies | Type enemy words |
| `wave_assault` | Wave attack on castle | Type enemy words |

## Initialization

### Ready Setup

```gdscript
# game/open_world.gd:34
func _ready() -> void:
    state = DefaultState.create("open_world")
    state.activity_mode = "exploration"
    state.resources = {"wood": 10, "stone": 5, "food": 10}

    _discover_starting_area()

    command_bar.text_submitted.connect(_on_command_submitted)
    command_bar.text_changed.connect(_on_command_changed)
    command_bar.grab_focus()

    _refresh_all()
    _append_log("[color=yellow]Welcome to Keyboard Defense![/color]")
```

### Starting Area Discovery

```gdscript
# game/open_world.gd:55
func _discover_starting_area() -> void:
    # Discover 5x5 area around castle
    for dy in range(-2, 3):
        for dx in range(-2, 3):
            var pos: Vector2i = state.base_pos + Vector2i(dx, dy)
            if SimMap.in_bounds(pos.x, pos.y, state.map_w, state.map_h):
                var idx: int = pos.y * state.map_w + pos.x
                state.discovered[idx] = true
                SimMap.ensure_tile_generated(state, pos)
```

## Game Loop

### Process Tick

```gdscript
# game/open_world.gd:65
func _process(delta: float) -> void:
    if state.phase == "game_over":
        return

    var result: Dictionary = WorldTick.tick(state, delta)
    if result.get("changed", false):
        var events: Array = result.get("events", [])
        for event in events:
            _append_log(str(event))
        _refresh_all()
```

The `WorldTick.tick()` function handles:
- Threat level updates
- Roaming enemy movement
- Encounter triggers
- Wave spawning

## Input Handling

### Keyboard Navigation

```gdscript
# game/open_world.gd:76
func _input(event: InputEvent) -> void:
    if not event is InputEventKey or not event.pressed:
        return

    # Arrow key navigation when command bar is empty
    if command_bar.text.is_empty() or not command_bar.has_focus():
        match event.keycode:
            KEY_UP:
                _move_cursor(Vector2i(0, -1))
            KEY_DOWN:
                _move_cursor(Vector2i(0, 1))
            KEY_LEFT:
                _move_cursor(Vector2i(-1, 0))
            KEY_RIGHT:
                _move_cursor(Vector2i(1, 0))

    # Focus command bar on any letter key
    if event.keycode >= KEY_A and event.keycode <= KEY_Z:
        if not command_bar.has_focus():
            command_bar.grab_focus()
```

### Cursor Movement

```gdscript
# game/open_world.gd:106
func _move_cursor(direction: Vector2i) -> void:
    var new_pos: Vector2i = state.cursor_pos + direction
    if SimMap.in_bounds(new_pos.x, new_pos.y, state.map_w, state.map_h):
        state.cursor_pos = new_pos
        _refresh_all()
```

## Command Processing

### Command Submission

```gdscript
# game/open_world.gd:117
func _on_command_submitted(text: String) -> void:
    command_bar.clear()

    if text.strip_edges().is_empty():
        return

    var input: String = text.strip_edges().to_lower()

    # During combat, check if typing an enemy word
    if state.activity_mode in ["encounter", "wave_assault"] and not state.enemies.is_empty():
        var hit_enemy: Dictionary = {}
        var hit_idx: int = -1
        for i in range(state.enemies.size()):
            var enemy: Dictionary = state.enemies[i]
            var word: String = str(enemy.get("word", "")).to_lower()
            if word == input:
                hit_enemy = enemy
                hit_idx = i
                break

        if hit_idx >= 0:
            # Process hit...
```

### Combat Word Matching

```gdscript
if hit_idx >= 0:
    var damage: int = 1
    hit_enemy["hp"] = int(hit_enemy.get("hp", 1)) - damage
    var kind: String = str(hit_enemy.get("kind", "enemy"))

    if int(hit_enemy.get("hp", 0)) <= 0:
        state.enemies.remove_at(hit_idx)
        var gold_reward: int = 5 + state.day
        state.gold += gold_reward
        _append_log("[color=lime]DEFEATED %s![/color] +%d gold" % [kind.to_upper(), gold_reward])

        # Check if combat over
        if state.enemies.is_empty():
            state.activity_mode = "exploration"
            state.phase = "day"
            _append_log("[color=cyan]Combat ended! Back to exploration.[/color]")
    else:
        hit_enemy["word"] = _get_random_word()
```

### Command Intent Processing

```gdscript
# Parse and apply command (if not a combat word)
var parse_result: Dictionary = CommandParser.parse(text, state)
if not parse_result.get("ok", false):
    _append_log("[color=gray]Unknown: %s[/color]" % text)
    return

var intent: Dictionary = parse_result.get("intent", {})
var apply_result: Dictionary = IntentApplier.apply(state, intent)

state = apply_result.get("state", state)
var events: Array = apply_result.get("events", [])

for event in events:
    _append_log(str(event))
```

## UI Refresh

### Main Refresh

```gdscript
# game/open_world.gd:188
func _refresh_all() -> void:
    _refresh_hud()
    _refresh_tile_info()
    _refresh_objective()
    _refresh_enemies()
    grid_renderer.update_state(state)
```

### HUD Update

```gdscript
# game/open_world.gd:195
func _refresh_hud() -> void:
    hp_label.text = "HP: %d/10" % state.hp
    gold_label.text = "Gold: %d" % state.gold
    day_label.text = "Day %d" % state.day

    # Resources
    var wood: int = int(state.resources.get("wood", 0))
    var stone: int = int(state.resources.get("stone", 0))
    var food: int = int(state.resources.get("food", 0))
    resources_label.text = "Wood: %d | Stone: %d | Food: %d" % [wood, stone, food]

    # Mode with color
    var mode_text: String = state.activity_mode.to_upper()
    match state.activity_mode:
        "wave_assault":
            mode_text = "WAVE!"
            mode_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
        "encounter":
            mode_text = "COMBAT"
            mode_label.add_theme_color_override("font_color", Color(1, 0.6, 0.3))
        _:
            mode_label.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
    mode_label.text = mode_text
```

### Enemy List with Highlighting

```gdscript
# game/open_world.gd:242
func _refresh_enemies() -> void:
    if state.enemies.is_empty():
        enemy_panel.visible = false
        return

    enemy_panel.visible = true
    var text: String = "[b]Type the word to attack:[/b]\n\n"
    for enemy in state.enemies:
        var word: String = str(enemy.get("word", "???"))
        var hp: int = int(enemy.get("hp", 0))
        var kind: String = str(enemy.get("kind", "enemy"))

        # Highlight matching portion
        var typed: String = command_bar.text.to_lower()
        if word.begins_with(typed) and typed.length() > 0:
            var matched: String = word.substr(0, typed.length())
            var remaining: String = word.substr(typed.length())
            text += "[color=lime]%s[/color][color=yellow]%s[/color] (%s) HP:%d\n" % [matched, remaining, kind, hp]
        else:
            text += "[color=yellow]%s[/color] (%s) HP:%d\n" % [word, kind, hp]
    enemy_list.text = text
```

### Tile Information

```gdscript
# game/open_world.gd:263
func _refresh_tile_info() -> void:
    var pos: Vector2i = state.cursor_pos
    var idx: int = pos.y * state.map_w + pos.x
    var terrain: String = SimMap.get_terrain(state, pos)

    var info: String = "(%d,%d) %s" % [pos.x, pos.y, terrain.capitalize()]

    # Check for structures
    if state.structures.has(idx):
        info += " [%s]" % str(state.structures[idx])

    # Check for roaming enemies
    for enemy in state.roaming_enemies:
        if enemy.get("pos", Vector2i(-1,-1)) == pos:
            info += " [Enemy: %s]" % enemy.get("kind", "?")

    # Check for combat enemies
    for enemy in state.enemies:
        if enemy.get("pos", Vector2i(-1,-1)) == pos:
            var word: String = str(enemy.get("word", ""))
            info += " [ENEMY: type '%s']" % word

    if pos == state.base_pos:
        info += " [YOUR CASTLE]"

    tile_info_label.text = info
```

### Objective Display

```gdscript
# game/open_world.gd:225
func _refresh_objective() -> void:
    var text: String = ""
    if state.activity_mode in ["encounter", "wave_assault"]:
        text = "[color=red][b]DEFEND YOUR CASTLE![/b][/color]\n"
        text += "Type the enemy words to defeat them!"
    elif state.roaming_enemies.size() > 0:
        text = "[b]OBJECTIVE[/b]\n"
        text += "[color=orange]%d enemies[/color] approaching!\n" % state.roaming_enemies.size()
        text += "Explore, build defenses, or engage!"
    elif state.threat_level > 0.5:
        text = "[b]OBJECTIVE[/b]\n"
        text += "[color=yellow]Threat rising![/color] Prepare defenses."
    else:
        text = "[b]OBJECTIVE[/b]\n"
        text += "Explore the land. Build structures.\nDefend when enemies arrive."
    objective_label.text = text
```

## Log System

```gdscript
# game/open_world.gd:292
func _append_log(text: String) -> void:
    log_lines.append(text)
    while log_lines.size() > MAX_LOG_LINES:
        log_lines.pop_front()
    log_label.text = "\n".join(log_lines)
```

## Available Commands

| Command | Description |
|---------|-------------|
| `explore` | Discover adjacent tiles |
| `build wall` | Build wall at cursor |
| `build tower` | Build tower at cursor |
| `build farm` | Build farm at cursor |
| `gather` | Collect resources from tile |
| `end` | End day, advance time |
| `[enemy word]` | Attack matching enemy |

## Integration with Sim Layer

The open world scene uses these sim modules:

| Module | Purpose |
|--------|---------|
| `DefaultState` | Create initial game state |
| `SimMap` | Terrain, bounds, tile generation |
| `CommandParser` | Parse typed commands |
| `IntentApplier` | Execute commands |
| `WorldTick` | Real-time threat/enemy updates |
| `SimEnemies` | Enemy data and words |

## Testing

```gdscript
func test_cursor_movement():
    var scene := OpenWorld.new()
    scene.state = GameState.new()
    scene.state.cursor_pos = Vector2i(5, 5)
    scene.state.map_w = 10
    scene.state.map_h = 10

    scene._move_cursor(Vector2i(1, 0))
    assert(scene.state.cursor_pos == Vector2i(6, 5))

    scene._move_cursor(Vector2i(0, 1))
    assert(scene.state.cursor_pos == Vector2i(6, 6))

    _pass("test_cursor_movement")

func test_combat_word_matching():
    var scene := OpenWorld.new()
    scene.state = GameState.new()
    scene.state.activity_mode = "encounter"
    scene.state.enemies = [
        {"id": 1, "word": "castle", "hp": 2, "kind": "raider"}
    ]

    # Simulate typing "castle"
    scene._on_command_submitted("castle")

    assert(scene.state.enemies[0].hp == 1)  # Damaged

    _pass("test_combat_word_matching")
```
