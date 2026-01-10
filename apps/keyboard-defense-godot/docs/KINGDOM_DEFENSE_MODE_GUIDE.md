# Kingdom Defense Mode Guide

This document explains the Kingdom Defense gameplay mode - a top-down RTS typing game inspired by Super Fantasy Kingdom with typing-based combat and commands.

## Overview

Kingdom Defense combines RTS base-building with typing combat:

```
Planning Phase → Defense Phase → Wave Complete → Repeat
      ↓              ↓               ↓
  Build/Manage    Type to Attack    Rewards/Progression
```

## Scene Structure

```gdscript
# game/kingdom_defense.gd
extends Control

# UI Node references
@onready var grid_renderer: Node2D = $GridRenderer
@onready var day_label: Label = $HUD/TopBar/HBox/DayLabel
@onready var wave_label: Label = $HUD/TopBar/HBox/WaveLabel
@onready var hp_value: Label = $HUD/TopBar/HBox/HPBar/HPValue
@onready var gold_value: Label = $HUD/TopBar/HBox/GoldBar/GoldValue
@onready var resources_label: Label = $HUD/TopBar/HBox/ResourceBar/ResourcesLabel
@onready var word_display: RichTextLabel = $HUD/TypingPanel/VBox/WordDisplay
@onready var input_field: LineEdit = $HUD/TypingPanel/VBox/InputField
@onready var keyboard_display: Control = $HUD/TypingPanel/VBox/KeyboardPanel
@onready var dialogue_box: Control = $DialogueBox
@onready var kingdom_dashboard: KingdomDashboard
```

## Game State Variables

### Core State

```gdscript
var state: GameState                    # Sim state reference
var current_phase: String = "planning"  # "planning", "defense", "practice", "gameover"
var day: int = 1
var wave: int = 1
var waves_per_day: int = 3
var castle_hp: int = 10
var castle_max_hp: int = 10
var gold: int = 50
```

### Enemy Management

```gdscript
var active_enemies: Array = []      # Enemies on the field
var enemy_queue: Array = []         # Enemies waiting to spawn
var spawn_timer: float = 0.0
var spawn_interval: float = 2.0
var target_enemy_id: int = -1       # Currently targeted enemy
```

### Typing State

```gdscript
var current_word: String = ""
var typed_text: String = ""
var combo: int = 0
var max_combo: int = 0
var correct_chars: int = 0
var total_chars: int = 0
var words_typed: int = 0
var wave_start_time: float = 0.0
```

### Lesson Progression

```gdscript
var lesson_order: Array[String] = [
    "home_row_1", "home_row_2",
    "reach_row_1", "reach_row_2",
    "bottom_row_1", "bottom_row_2",
    "upper_row_1", "upper_row_2",
    "mixed_rows", "speed_alpha",
    "nexus_blend", "apex_mastery"
]
var current_lesson_index: int = 0
var lesson_accuracy_threshold: float = 0.8  # 80% to unlock next
```

## Build Commands

```gdscript
const BUILD_COMMANDS := {
    "build tower": "tower",
    "build wall": "wall",
    "build farm": "farm",
    "build lumber": "lumber",
    "build quarry": "quarry",
    "build market": "market",
    "build barracks": "barracks",
    "build temple": "temple",
    "build workshop": "workshop",
    # Short forms
    "tower": "tower",
    "wall": "wall",
    "farm": "farm",
    "lumber": "lumber",
    "quarry": "quarry",
    "market": "market",
    "barracks": "barracks",
    "temple": "temple",
    "workshop": "workshop"
}
```

## Initialization

```gdscript
# game/kingdom_defense.gd:140
func _ready() -> void:
    _init_game_state()
    _init_kingdom_systems()
    _connect_signals()
    _show_game_start_dialogue()

func _init_game_state() -> void:
    state = DefaultState.create()
    state.base_pos = Vector2i(1, state.map_h / 2)
    state.cursor_pos = cursor_grid_pos
    state.lesson_id = lesson_order[current_lesson_index]

    # Discover entire map for RTS view
    for y in range(state.map_h):
        for x in range(state.map_w):
            var index: int = y * state.map_w + x
            state.discovered[index] = true

    # Generate terrain
    SimMap.generate_terrain(state)

    # Starting resources
    state.resources["wood"] = 10
    state.resources["stone"] = 5
    state.resources["food"] = 10
```

### Kingdom Systems Setup

```gdscript
# game/kingdom_defense.gd:146
func _init_kingdom_systems() -> void:
    research_instance = SimResearch.instance()

    kingdom_dashboard = KingdomDashboard.new()
    add_child(kingdom_dashboard)
    kingdom_dashboard.update_state(state)
    kingdom_dashboard.closed.connect(_on_dashboard_closed)
    kingdom_dashboard.upgrade_requested.connect(_on_upgrade_requested)
    kingdom_dashboard.research_started.connect(_on_research_started)
    kingdom_dashboard.trade_executed.connect(_on_trade_executed)
```

## Phase Management

### Planning Phase

```gdscript
# game/kingdom_defense.gd:360
func _start_planning_phase() -> void:
    current_phase = "planning"
    planning_timer = 30.0
    tip_timer = 0.0
    cursor_grid_pos = state.base_pos + Vector2i(2, 0)
    state.cursor_pos = cursor_grid_pos

    _update_objective("Build defenses! [color=cyan]Ctrl+Arrows[/color] to move cursor.\n[color=cyan]Tab[/color] for Kingdom Dashboard | Type [color=cyan]ready[/color] to start.")
    _update_hint("PLANNING: build <type> | upgrade | research | trade | status | ready | Tab=dashboard")

    # Update dashboard state
    if kingdom_dashboard:
        kingdom_dashboard.update_state(state)

    # Show typing tip and act intro
    _show_random_tip()
    _show_act_intro()

func _process_planning(delta: float) -> void:
    planning_timer -= delta
    if planning_timer <= 0:
        _start_defense_phase()

    # Rotate typing tips
    tip_timer += delta
    if tip_timer >= tip_interval:
        tip_timer = 0.0
        _show_random_tip()
```

### Defense Phase

```gdscript
# game/kingdom_defense.gd:381
func _start_defense_phase() -> void:
    current_phase = "defense"
    wave_start_time = Time.get_unix_time_from_system()

    # Show boss intro on boss days
    if wave == waves_per_day and StoryManager.is_boss_day(day):
        _show_boss_intro()

    # Generate enemies for this wave
    _generate_wave_enemies()
    spawn_timer = 0.0

    _update_objective("Defeat the enemies! Type their words to attack.")
    _update_hint("Type the highlighted word to damage enemies. Combos increase power!")

func _process_defense(delta: float) -> void:
    # Spawn enemies from queue
    spawn_timer -= delta
    if spawn_timer <= 0 and not enemy_queue.is_empty():
        _spawn_next_enemy()
        spawn_timer = spawn_interval

    # Move all active enemies toward castle
    var dist_field: PackedInt32Array = SimMap.compute_dist_to_base(state)
    for i in range(active_enemies.size() - 1, -1, -1):
        var enemy: Dictionary = active_enemies[i]
        _move_enemy(enemy, dist_field, delta)

        # Check if reached castle
        var pos: Vector2i = enemy.get("pos", Vector2i.ZERO)
        if pos == state.base_pos:
            _enemy_reached_castle(i)

    # Update state for renderer
    state.enemies = active_enemies.duplicate(true)
    _update_grid_renderer()

    # Check wave completion
    if active_enemies.is_empty() and enemy_queue.is_empty():
        _wave_complete()
```

## Enemy System

### Wave Generation

```gdscript
# game/kingdom_defense.gd:399
func _generate_wave_enemies() -> void:
    enemy_queue.clear()
    active_enemies.clear()
    target_enemy_id = -1

    var wave_size: int = 3 + wave + int(day / 2)
    var used_words: Dictionary = {}

    for i in range(wave_size):
        var kind: String = SimEnemies.choose_spawn_kind(state)
        var enemy: Dictionary = {
            "id": state.enemy_next_id,
            "kind": kind,
            "hp": _get_enemy_hp(kind),
            "speed": SimEnemies.speed_for_day(kind, day),
            "armor": SimEnemies.armor_for_day(kind, day),
            "pos": Vector2i.ZERO,
            "word": "",
            "move_progress": 0.0
        }

        # Assign word from current lesson
        var word: String = SimWords.word_for_enemy(
            state.rng_seed, day, kind,
            state.enemy_next_id, used_words, state.lesson_id
        )
        enemy["word"] = word.to_lower()
        used_words[enemy["word"]] = true

        state.enemy_next_id += 1
        enemy_queue.append(enemy)
```

### Wave Size Formula

| Day | Wave | Base Size | Result |
|-----|------|-----------|--------|
| 1 | 1 | 3 + 1 + 0 | 4 |
| 1 | 3 | 3 + 3 + 0 | 6 |
| 5 | 2 | 3 + 2 + 2 | 7 |
| 10 | 3 | 3 + 3 + 5 | 11 |

### Enemy Movement

```gdscript
# game/kingdom_defense.gd:268
func _move_enemy(enemy: Dictionary, dist_field: PackedInt32Array, delta: float) -> void:
    var pos: Vector2i = enemy.get("pos", Vector2i.ZERO)
    var speed: float = float(enemy.get("speed", 1)) * 0.5  # Tiles per second

    # Accumulate movement progress
    var progress: float = enemy.get("move_progress", 0.0) + speed * delta
    enemy["move_progress"] = progress

    if progress >= 1.0:
        enemy["move_progress"] = 0.0
        # Find next tile toward castle using distance field
        var next_pos: Vector2i = _get_next_tile(pos, dist_field)
        if next_pos != pos:
            enemy["pos"] = next_pos

func _get_next_tile(from: Vector2i, dist_field: PackedInt32Array) -> Vector2i:
    var neighbors: Array[Vector2i] = SimMap.neighbors4(from, state.map_w, state.map_h)
    var best_pos: Vector2i = from
    var best_dist: int = _dist_at(from, dist_field)

    for neighbor in neighbors:
        var d: int = _dist_at(neighbor, dist_field)
        if d >= 0 and d < best_dist:
            best_dist = d
            best_pos = neighbor

    return best_pos
```

### Spawning

```gdscript
# game/kingdom_defense.gd:303
func _spawn_next_enemy() -> void:
    if enemy_queue.is_empty():
        return

    var enemy: Dictionary = enemy_queue.pop_front()
    var spawn_edge: int = randi() % 3  # 0=top, 1=right, 2=bottom
    var spawn_pos: Vector2i

    match spawn_edge:
        0:  # Top edge
            spawn_pos = Vector2i(randi() % state.map_w, 0)
        1:  # Right edge
            spawn_pos = Vector2i(state.map_w - 1, randi() % state.map_h)
        2:  # Bottom edge
            spawn_pos = Vector2i(randi() % state.map_w, state.map_h - 1)

    enemy["pos"] = spawn_pos
    enemy["move_progress"] = 0.0
    active_enemies.append(enemy)

    # Auto-target first enemy
    if target_enemy_id < 0:
        _target_closest_enemy()
```

## Typing Combat

### Input Processing

```gdscript
# game/kingdom_defense.gd:526
func _on_input_changed(new_text: String) -> void:
    var old_len: int = typed_text.length()
    typed_text = new_text.to_lower()

    # Handle practice mode specially
    if current_phase == "practice" and typed_text.length() > old_len:
        var last_char: String = typed_text[typed_text.length() - 1]
        _handle_practice_input(last_char)
        input_field.call_deferred("clear")
        return

    # Flash keyboard key on new character
    if keyboard_display and typed_text.length() > old_len:
        var last_char: String = typed_text[typed_text.length() - 1]
        var expected: String = ""
        if current_phase == "defense" and current_word.length() >= typed_text.length():
            expected = current_word[typed_text.length() - 1]
        var is_correct: bool = (last_char == expected)
        keyboard_display.flash_key(last_char, is_correct)

    if current_phase == "defense":
        _process_combat_typing()
    elif current_phase == "planning":
        _process_command_typing()

func _process_combat_typing() -> void:
    if current_word.is_empty():
        return

    # Check if typed text matches start of word
    if not current_word.begins_with(typed_text) and typed_text.length() > 0:
        # Mistake - break combo
        combo = 0
        total_chars += 1

    # Auto-complete on exact match
    if typed_text == current_word:
        _attack_target_enemy()
```

### Attack Execution

```gdscript
# game/kingdom_defense.gd:608
func _attack_target_enemy() -> void:
    if target_enemy_id < 0:
        return

    var enemy_index: int = _find_enemy_index(target_enemy_id)
    if enemy_index < 0:
        _target_closest_enemy()
        return

    var enemy: Dictionary = active_enemies[enemy_index]

    # Calculate damage with power multiplier
    var power: float = _calculate_power()
    var damage: int = max(1, int(ceil(power)))

    # Apply damage
    enemy["hp"] = int(enemy.get("hp", 1)) - damage

    # Track stats
    correct_chars += current_word.length()
    total_chars += current_word.length()
    words_typed += 1
    combo += 1
    max_combo = max(max_combo, combo)

    # Fire projectile visual
    if grid_renderer.has_method("fire_projectile"):
        var enemy_pos: Vector2i = enemy.get("pos", Vector2i.ZERO)
        grid_renderer.fire_projectile(state.base_pos, enemy_pos, Color(1, 0.8, 0.3))

    if int(enemy.get("hp", 0)) <= 0:
        # Enemy defeated
        var gold_reward: int = SimEnemies.gold_reward(str(enemy.get("kind", "raider")))
        if combo >= 10:
            gold_reward = int(gold_reward * 1.5)
        elif combo >= 5:
            gold_reward = int(gold_reward * 1.2)
        gold += gold_reward

        # Spawn hit particles
        if grid_renderer.has_method("spawn_hit_particles"):
            grid_renderer.spawn_hit_particles(enemy.pos, 12, Color(1, 0.5, 0.2))

        active_enemies.remove_at(enemy_index)
        _target_closest_enemy()
    else:
        # Enemy damaged but alive - assign new word
        # ... regenerate word from lesson pool
```

### Power Calculation

```gdscript
# game/kingdom_defense.gd:839
func _calculate_power() -> float:
    var accuracy: float = _get_accuracy()
    var combo_bonus: float = min(combo * 0.1, 1.0)  # Max +100% from combo
    var accuracy_bonus: float = accuracy * 0.5      # Max +50% from accuracy

    # Building effects (barracks, etc.)
    var typing_power_bonus: float = 0.0
    var building_effects: Dictionary = SimBuildings.get_total_effects(state)
    typing_power_bonus += float(building_effects.get("typing_power", 0.0))

    # Research effects
    if research_instance:
        var research_effects: Dictionary = research_instance.get_total_effects(state)
        typing_power_bonus += float(research_effects.get("typing_power", 0.0))

        # Apply combo multiplier from research
        var combo_mult: float = float(research_effects.get("combo_multiplier", 0.0))
        if combo_mult > 0:
            combo_bonus = combo_bonus * (1.0 + combo_mult)

    return 1.0 + combo_bonus + accuracy_bonus + typing_power_bonus
```

### Power Bonuses

| Source | Bonus | Max |
|--------|-------|-----|
| Base | +1.0x | - |
| Combo (per kill) | +0.1x | +1.0x (10 combo) |
| Accuracy | +accuracy * 0.5x | +0.5x |
| Barracks | varies | - |
| Research | varies | - |

## Building System

### Build Command

```gdscript
# game/kingdom_defense.gd:676
func _try_build(building_type: String) -> void:
    # Validate building type
    if not SimBuildings.is_valid(building_type):
        _update_objective("[color=red]Unknown building type![/color]")
        return

    # Get cost from SimBuildings
    var cost: Dictionary = SimBuildings.cost_for(building_type)

    # Check resources
    var can_afford: bool = true
    for res in cost.keys():
        var have: int = int(state.resources.get(res, 0))
        if res == "gold":
            have = state.gold
        if have < int(cost.get(res, 0)):
            can_afford = false
            break

    if not can_afford:
        _update_objective("[color=red]Not enough resources![/color]")
        return

    # Check if buildable at cursor
    if not SimMap.is_buildable(state, cursor_grid_pos):
        _update_objective("[color=red]Cannot build there![/color]")
        return

    # Check path still open after build (blocking buildings only)
    var test_index: int = cursor_grid_pos.y * state.map_w + cursor_grid_pos.x
    if SimBuildings.is_blocking(building_type):
        state.structures[test_index] = building_type
        if not SimMap.path_open_to_base(state):
            state.structures.erase(test_index)
            _update_objective("[color=red]Would block enemy path![/color]")
            return
    else:
        state.structures[test_index] = building_type

    # Deduct resources
    for res in cost.keys():
        if res == "gold":
            state.gold -= int(cost[res])
        else:
            state.resources[res] -= int(cost.get(res, 0))

    state.buildings[building_type] = int(state.buildings.get(building_type, 0)) + 1
    _update_objective("[color=green]Built %s![/color]" % building_type)
```

### Upgrade Command

```gdscript
# game/kingdom_defense.gd:747
func _try_upgrade_at_cursor() -> void:
    var index: int = cursor_grid_pos.y * state.map_w + cursor_grid_pos.x
    if not state.structures.has(index):
        _update_objective("[color=red]No building at cursor![/color]")
        return

    var check: Dictionary = SimBuildings.can_upgrade(state, index)
    if not check.ok:
        _update_objective("[color=red]Cannot upgrade: %s[/color]" % check.reason)
        return

    if SimBuildings.apply_upgrade(state, index):
        var building_type: String = str(state.structures[index])
        _update_objective("[color=green]Upgraded %s to level %d![/color]" % [building_type, check.next_level])
```

## Kingdom Management Commands

```gdscript
# game/kingdom_defense.gd:556
func _on_input_submitted(text: String) -> void:
    var lower_text: String = text.to_lower().strip_edges()

    if current_phase == "planning":
        match lower_text:
            "ready":
                _start_defense_phase()
            "status", "kingdom":
                _toggle_dashboard()
            "workers":
                _show_dashboard_tab(1)
            "research":
                _show_dashboard_tab(3)
            "trade":
                _show_dashboard_tab(4)
            "info":
                _show_tile_info()

        if BUILD_COMMANDS.has(lower_text):
            _try_build(BUILD_COMMANDS[lower_text])
        elif lower_text == "upgrade":
            _try_upgrade_at_cursor()
        elif lower_text.begins_with("upgrade "):
            _try_upgrade_building_type(lower_text.substr(8).strip_edges())
        elif lower_text.begins_with("research "):
            _try_start_research(lower_text.substr(9).strip_edges())
        elif lower_text.begins_with("trade "):
            _try_execute_trade(lower_text)
```

### Dashboard Integration

```gdscript
# game/kingdom_defense.gd:732
func _toggle_dashboard() -> void:
    if kingdom_dashboard:
        if kingdom_dashboard.visible:
            kingdom_dashboard.hide_dashboard()
        else:
            kingdom_dashboard.update_state(state)
            kingdom_dashboard.show_dashboard()

func _show_dashboard_tab(tab_index: int) -> void:
    if kingdom_dashboard:
        kingdom_dashboard.update_state(state)
        kingdom_dashboard.show_dashboard()
        if kingdom_dashboard._tabs:
            kingdom_dashboard._tabs.current_tab = tab_index
```

## Wave Completion

```gdscript
# game/kingdom_defense.gd:433
func _wave_complete() -> void:
    var was_boss_day: bool = wave == waves_per_day and StoryManager.is_boss_day(day)
    var old_lesson_id: String = state.lesson_id

    wave += 1

    # Gold reward
    var wave_bonus: int = 10 + wave * 5
    if castle_hp == castle_max_hp:
        wave_bonus = int(wave_bonus * 1.5)  # Perfect defense bonus
    gold += wave_bonus

    # Advance research
    if research_instance and not state.active_research.is_empty():
        var research_result: Dictionary = research_instance.advance_research(state)
        if research_result.completed:
            _update_objective("[color=lime]Research complete: %s![/color]" % research_result.research_id)

    # Apply building effects (wave healing from temples)
    var building_effects: Dictionary = SimBuildings.get_total_effects(state)
    var total_wave_heal: int = 2 + int(building_effects.get("wave_heal", 0))

    # Research wave heal bonus
    if research_instance:
        var research_effects: Dictionary = research_instance.get_total_effects(state)
        total_wave_heal += int(research_effects.get("wave_heal", 0))

    # Check lesson progression
    var accuracy: float = _get_accuracy()
    if accuracy >= lesson_accuracy_threshold and current_lesson_index < lesson_order.size() - 1:
        current_lesson_index += 1
        state.lesson_id = lesson_order[current_lesson_index]

    # Heal between waves
    castle_hp = min(castle_hp + total_wave_heal, castle_max_hp)

    # Day advancement
    if wave > waves_per_day:
        wave = 1
        day += 1
        state.day = day
        _apply_daily_production()
        SimWorkers.gain_worker(state)

    # Story dialogues
    if was_boss_day:
        _show_boss_defeat()
    elif state.lesson_id != old_lesson_id:
        _show_lesson_intro(state.lesson_id)
    else:
        _show_wave_feedback()
```

### Reward Calculation

| Condition | Gold Bonus |
|-----------|------------|
| Wave completion | 10 + wave * 5 |
| Perfect defense | +50% |
| Combo 5+ | +20% per enemy |
| Combo 10+ | +50% per enemy |

## Daily Production

```gdscript
# game/kingdom_defense.gd:500
func _apply_daily_production() -> void:
    var production: Dictionary = SimWorkers.daily_production_with_workers(state)

    # Apply worker upkeep first
    var upkeep_result: Dictionary = SimWorkers.apply_upkeep(state)
    if not upkeep_result.ok and upkeep_result.workers_lost > 0:
        _update_objective("[color=red]Lost %d workers due to food shortage![/color]" % upkeep_result.workers_lost)

    # Add production
    for res_key in production.keys():
        if res_key == "gold":
            state.gold += int(production[res_key])
        else:
            state.resources[res_key] = int(state.resources.get(res_key, 0)) + int(production[res_key])

    gold = state.gold
```

## Key Practice Mode

```gdscript
# game/kingdom_defense.gd:1276
func _start_key_practice(lesson_id: String) -> void:
    var intro: Dictionary = StoryManager.get_lesson_intro(lesson_id)
    var keys: Array = intro.get("keys", [])

    if keys.is_empty():
        _start_planning_phase()
        return

    practice_keys.clear()
    for k in keys:
        practice_keys.append(str(k).to_lower())

    practice_lesson_id = lesson_id
    practice_index = 0
    practice_correct_count = 0
    practice_attempts = 0
    practice_mode = true
    current_phase = "practice"

    _update_practice_ui()

func _handle_practice_input(key_pressed: String) -> void:
    if not practice_mode or practice_index >= practice_keys.size():
        return

    var expected_key: String = practice_keys[practice_index]
    practice_attempts += 1

    if key_pressed.to_lower() == expected_key:
        practice_correct_count += 1
        practice_index += 1
        keyboard_display.flash_key(key_pressed, true)

        if practice_index >= practice_keys.size():
            _complete_key_practice()
        else:
            await get_tree().create_timer(0.3).timeout
            if practice_mode:
                _update_practice_ui()
    else:
        keyboard_display.flash_key(key_pressed, false)
```

## Input Handling

```gdscript
# game/kingdom_defense.gd:1028
func _input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed:
        # Tab toggles kingdom dashboard during planning
        if event.keycode == KEY_TAB and current_phase == "planning":
            _toggle_dashboard()
            get_viewport().set_input_as_handled()
            return

        # Ctrl+Arrow keys for grid cursor movement
        if current_phase == "planning" and event.ctrl_pressed:
            var moved: bool = false
            match event.keycode:
                KEY_UP:
                    cursor_grid_pos.y = max(0, cursor_grid_pos.y - 1)
                    moved = true
                KEY_DOWN:
                    cursor_grid_pos.y = min(state.map_h - 1, cursor_grid_pos.y + 1)
                    moved = true
                KEY_LEFT:
                    cursor_grid_pos.x = max(0, cursor_grid_pos.x - 1)
                    moved = true
                KEY_RIGHT:
                    cursor_grid_pos.x = min(state.map_w - 1, cursor_grid_pos.x + 1)
                    moved = true

            if moved:
                state.cursor_pos = cursor_grid_pos
                _update_grid_renderer()
                get_viewport().set_input_as_handled()
```

## Story Integration

```gdscript
# game/kingdom_defense.gd:1066
func _show_game_start_dialogue() -> void:
    if not dialogue_box:
        game_started = true
        _start_key_practice(state.lesson_id)
        return

    var speaker: String = StoryManager.get_dialogue_speaker("game_start")
    var lines: Array[String] = StoryManager.get_dialogue_lines("game_start")

    if lines.is_empty():
        game_started = true
        _show_lesson_intro(state.lesson_id)
        return

    waiting_for_dialogue = true
    dialogue_box.show_dialogue(speaker, lines)

func _show_act_intro() -> void:
    if not StoryManager.should_show_act_intro(day, last_act_intro_day):
        return
    last_act_intro_day = day
    var act: Dictionary = StoryManager.get_act_for_day(day)
    var speaker: String = StoryManager.get_mentor_name(day)
    var intro_text: String = StoryManager.get_act_intro_text(day)

    waiting_for_dialogue = true
    dialogue_box.show_dialogue(speaker, [intro_text])

func _show_boss_intro() -> void:
    var boss: Dictionary = StoryManager.get_boss_for_day(day)
    var boss_name: String = str(boss.get("name", "Boss"))
    var intro_text: String = str(boss.get("intro", ""))
    var taunt: String = str(boss.get("taunt", ""))

    var lines: Array[String] = []
    if not intro_text.is_empty():
        lines.append(intro_text)
    if not taunt.is_empty():
        lines.append("[color=red]%s[/color]: \"%s\"" % [boss_name, taunt])

    waiting_for_dialogue = true
    dialogue_box.show_dialogue("", lines)
```

## UI Updates

```gdscript
# game/kingdom_defense.gd:876
func _update_ui() -> void:
    # Top bar
    day_label.text = "Day %d" % day
    wave_label.text = "Wave %d/%d" % [wave, waves_per_day]
    hp_value.text = "%d/%d" % [castle_hp, castle_max_hp]
    gold_value.text = "%d" % gold
    resources_label.text = "Wood: %d | Stone: %d | Food: %d" % [
        int(state.resources.get("wood", 0)),
        int(state.resources.get("stone", 0)),
        int(state.resources.get("food", 0))
    ]

    # Stats bar
    wpm_label.text = "WPM: %d" % int(_get_wpm())
    accuracy_label.text = "Accuracy: %d%%" % int(_get_accuracy() * 100)
    combo_label.text = "Combo: %d" % combo
    power_label.text = "Power: %.1fx" % _calculate_power()

    # Word display
    if current_phase == "defense" and not current_word.is_empty():
        _update_word_display()
    elif current_phase == "planning":
        word_display.text = "[center][color=white]Planning Phase[/color]\nTime: %d seconds[/center]" % int(planning_timer)

func _update_word_display() -> void:
    var display: String = "[center]"
    for i in range(current_word.length()):
        var ch: String = current_word[i]
        if i < typed_text.length():
            if typed_text[i] == ch:
                display += "[color=lime]%s[/color]" % ch
            else:
                display += "[color=red]%s[/color]" % ch
        else:
            display += "[color=yellow]%s[/color]" % ch
    display += "[/center]"
    word_display.text = display
```

## Testing

```gdscript
func test_wave_generation():
    var kd := KingdomDefense.new()
    kd._init_game_state()
    kd.day = 5
    kd.wave = 2
    kd._generate_wave_enemies()

    # Wave size = 3 + wave + day/2 = 3 + 2 + 2 = 7
    assert(kd.enemy_queue.size() == 7)

    # All enemies have words
    for enemy in kd.enemy_queue:
        assert(enemy.has("word"))
        assert(not str(enemy.get("word", "")).is_empty())

    _pass("test_wave_generation")

func test_power_calculation():
    var kd := KingdomDefense.new()
    kd.combo = 5
    kd.correct_chars = 80
    kd.total_chars = 100

    var power: float = kd._calculate_power()
    # Base 1.0 + combo 0.5 + accuracy 0.4 = 1.9
    assert(power > 1.8 and power < 2.0)

    _pass("test_power_calculation")

func test_building_path_check():
    var kd := KingdomDefense.new()
    kd._init_game_state()

    # Try to build wall that blocks path
    kd.cursor_grid_pos = kd.state.base_pos + Vector2i(1, 0)
    kd._try_build("wall")

    # Should fail if it would block
    var index: int = kd.cursor_grid_pos.y * kd.state.map_w + kd.cursor_grid_pos.x
    var path_blocked: bool = not SimMap.path_open_to_base(kd.state)
    assert(not kd.state.structures.has(index) or not path_blocked)

    _pass("test_building_path_check")
```
