# Typing Defense Guide

This document explains the on-rails typing tutor scene with wave-based combat and progressive lesson unlocks.

## Overview

Typing Defense is a focused typing combat mode where better typing = more power:

```
Wave Start → Spawn Enemies → Type Words → Deal Damage → Earn Gold
     ↓            ↓              ↓             ↓            ↓
 generate      queue[]       match word    power calc    rewards
```

## Scene Structure

```gdscript
# game/typing_defense.gd
extends Control

@onready var wave_label: Label = $TopBar/WaveLabel
@onready var hp_label: Label = $TopBar/HPLabel
@onready var gold_label: Label = $TopBar/GoldLabel
@onready var lesson_label: Label = $TopBar/LessonLabel
@onready var wpm_label: Label = $StatsBar/WPMLabel
@onready var accuracy_label: Label = $StatsBar/AccuracyLabel
@onready var combo_label: Label = $StatsBar/ComboLabel
@onready var power_label: Label = $StatsBar/PowerLabel
@onready var word_display: RichTextLabel = $TypingPanel/VBox/WordDisplay
@onready var typed_display: Label = $TypingPanel/VBox/TypedDisplay
@onready var input_field: LineEdit = $TypingPanel/VBox/InputField
@onready var feedback_label: Label = $TypingPanel/VBox/FeedbackLabel
@onready var queue_list: RichTextLabel = $EnemyQueue/QueueList
@onready var wave_progress: ProgressBar = $WaveProgress
@onready var enemy_lane: Control = $BattleArea/EnemyLane
```

## Game State

### Core Variables

```gdscript
# Castle
var castle_hp: int = 10
var castle_max_hp: int = 10
var gold: int = 0
var wave: int = 1
var enemies_defeated: int = 0
var wave_enemies_total: int = 5

# Current enemy
var current_enemy: Dictionary = {}
var enemy_queue: Array[Dictionary] = []

# Typing stats
var combo: int = 0
var max_combo: int = 0
var correct_chars: int = 0
var total_chars: int = 0
var words_typed: int = 0
var typing_start_time: float = 0.0
var wave_start_time: float = 0.0
```

### Lesson System

```gdscript
var lesson_words: Dictionary = {
    "home_row": ["asdf", "jkl", "sad", "dad", "lad", "ask", "all", "fall", "salad", "flask"],
    "top_row": ["we", "you", "type", "query", "write", "power", "tower", "poetry", "equity"],
    "bottom_row": ["mix", "box", "zen", "vim", "zap", "zoom", "comic", "maximum"],
    "numbers": ["123", "456", "789", "2024", "1000", "42", "365", "100"],
    "full": ["castle", "defend", "knight", "dragon", "shield", "sword", "attack", "victory", "kingdom", "throne", "battle", "archer", "wizard", "fortress", "treasure"]
}
var current_lesson: String = "home_row"
```

### Enemy Types

```gdscript
var enemy_types: Array[Dictionary] = [
    {"kind": "scout", "hp": 1, "speed": 2.0, "gold": 3},
    {"kind": "raider", "hp": 2, "speed": 1.5, "gold": 5},
    {"kind": "brute", "hp": 4, "speed": 1.0, "gold": 10},
    {"kind": "knight", "hp": 3, "speed": 1.2, "gold": 8},
]
```

## Wave System

### Starting a Wave

```gdscript
# game/typing_defense.gd:80
func _start_wave() -> void:
    enemy_queue.clear()
    enemies_defeated = 0
    wave_enemies_total = 3 + wave * 2
    wave_start_time = Time.get_unix_time_from_system()

    # Generate enemies for this wave
    for i in range(wave_enemies_total):
        var template: Dictionary = enemy_types[randi() % enemy_types.size()]
        var word: String = _get_lesson_word()
        enemy_queue.append({
            "kind": template.kind,
            "hp": template.hp,
            "max_hp": template.hp,
            "speed": template.speed,
            "gold": template.gold,
            "word": word,
            "position": 1.0  # 1.0 = far right, 0.0 = at castle
        })

    _next_enemy()
    _refresh_ui()
```

### Wave Size Formula

| Wave | Enemies |
|------|---------|
| 1 | 5 |
| 2 | 7 |
| 3 | 9 |
| n | 3 + n*2 |

### Next Enemy

```gdscript
# game/typing_defense.gd:103
func _next_enemy() -> void:
    if enemy_queue.is_empty():
        _wave_complete()
        return

    current_enemy = enemy_queue.pop_front()
    typing_start_time = Time.get_unix_time_from_system()
    input_field.clear()
    _refresh_word_display()
    _refresh_queue_display()
```

## Typing Input

### Input Changed Handler

```gdscript
# game/typing_defense.gd:118
func _on_input_changed(new_text: String) -> void:
    var target: String = current_enemy.get("word", "")
    var typed: String = new_text.to_lower()

    _refresh_word_display()

    # Check for mistakes
    if not target.begins_with(typed) and typed.length() > 0:
        if combo > 0:
            feedback_label.text = "[color=red]Mistake! Combo broken.[/color]"
        combo = 0
        total_chars += 1
        _refresh_ui()

    # Auto-complete on exact match
    if typed == target:
        _attack_enemy()
```

### Word Display with Color Coding

```gdscript
# game/typing_defense.gd:291
func _refresh_word_display() -> void:
    var target: String = current_enemy.get("word", "")
    var typed: String = input_field.text.to_lower()

    var display: String = "[center]"
    for i in range(target.length()):
        var char: String = target[i]
        if i < typed.length():
            if typed[i] == char:
                display += "[color=lime]%s[/color]" % char  # Correct
            else:
                display += "[color=red]%s[/color]" % char   # Wrong
        else:
            display += "[color=yellow]%s[/color]" % char    # Not typed yet
    display += "[/center]"

    word_display.text = display
    typed_display.text = typed
```

## Combat Mechanics

### Attack Enemy

```gdscript
# game/typing_defense.gd:149
func _attack_enemy() -> void:
    # Calculate damage based on typing performance
    var base_damage: int = 1
    var power_multiplier: float = _calculate_power()
    var damage: int = max(1, int(base_damage * power_multiplier))

    current_enemy["hp"] = int(current_enemy.get("hp", 1)) - damage

    # Stats tracking
    correct_chars += current_enemy.get("word", "").length()
    total_chars += current_enemy.get("word", "").length()
    words_typed += 1
    combo += 1
    max_combo = max(max_combo, combo)

    if int(current_enemy.get("hp", 0)) <= 0:
        # Enemy defeated!
        var gold_reward: int = int(current_enemy.get("gold", 5))
        # Bonus gold for high combo
        if combo >= 10:
            gold_reward = int(gold_reward * 1.5)
        elif combo >= 5:
            gold_reward = int(gold_reward * 1.2)

        gold += gold_reward
        enemies_defeated += 1
        _next_enemy()
    else:
        # Enemy damaged but not dead - new word
        current_enemy["word"] = _get_lesson_word()
        input_field.clear()
        _refresh_word_display()
```

### Power Calculation

```gdscript
# game/typing_defense.gd:191
func _calculate_power() -> float:
    var accuracy: float = _get_accuracy()
    var combo_bonus: float = min(combo * 0.1, 1.0)  # Max +100% from combo
    var accuracy_bonus: float = accuracy * 0.5      # Max +50% from accuracy
    return 1.0 + combo_bonus + accuracy_bonus
```

| Source | Max Bonus |
|--------|-----------|
| Base | 1.0x |
| Combo (10+) | +1.0x |
| Accuracy (100%) | +0.5x |
| **Total Max** | **2.5x** |

### Accuracy Calculation

```gdscript
func _get_accuracy() -> float:
    if total_chars == 0:
        return 1.0
    return float(correct_chars) / float(total_chars)
```

## Enemy Movement

### Update Enemies

```gdscript
# game/typing_defense.gd:212
func _update_enemies(delta: float) -> void:
    if current_enemy.is_empty():
        return

    # Move current enemy toward castle
    var speed: float = current_enemy.get("speed", 1.0) * 0.05 * delta
    current_enemy["position"] = max(0.0, float(current_enemy.get("position", 1.0)) - speed)

    _update_enemy_visual()

    # Check if reached castle
    if float(current_enemy.get("position", 0.0)) <= 0.0:
        _enemy_reached_castle()
```

### Enemy Reaches Castle

```gdscript
# game/typing_defense.gd:227
func _enemy_reached_castle() -> void:
    castle_hp -= 1
    combo = 0  # Break combo

    feedback_label.text = "ENEMY BREACHED! Castle damaged!"

    if castle_hp <= 0:
        _game_over()
    else:
        _next_enemy()
```

## Progression

### Wave Completion

```gdscript
# game/typing_defense.gd:242
func _wave_complete() -> void:
    wave += 1

    # Wave completion bonus
    var wave_bonus: int = 20 * wave
    if castle_hp == castle_max_hp:
        wave_bonus = int(wave_bonus * 1.5)  # Perfect defense bonus
    gold += wave_bonus

    # Progress lesson difficulty
    if wave >= 3 and current_lesson == "home_row":
        current_lesson = "top_row"
    elif wave >= 6 and current_lesson == "top_row":
        current_lesson = "bottom_row"
    elif wave >= 9 and current_lesson == "bottom_row":
        current_lesson = "full"

    # Heal castle between waves
    castle_hp = min(castle_hp + 2, castle_max_hp)

    await get_tree().create_timer(2.0).timeout
    _start_wave()
```

### Lesson Unlock Schedule

| Wave | Lesson Unlocked |
|------|-----------------|
| 1-2 | home_row |
| 3-5 | top_row |
| 6-8 | bottom_row |
| 9+ | full keyboard |

### Combo Gold Bonus

| Combo | Gold Multiplier |
|-------|-----------------|
| 0-4 | 1.0x |
| 5-9 | 1.2x |
| 10+ | 1.5x |

## WPM Tracking

```gdscript
# game/typing_defense.gd:203
func _update_wpm() -> void:
    if words_typed == 0:
        return
    var elapsed: float = Time.get_unix_time_from_system() - wave_start_time
    if elapsed < 1.0:
        return
    var wpm: float = (float(words_typed) / elapsed) * 60.0
    wpm_label.text = "WPM: %d" % int(wpm)
```

## UI Refresh

```gdscript
# game/typing_defense.gd:278
func _refresh_ui() -> void:
    wave_label.text = "Wave %d" % wave
    hp_label.text = "Castle HP: %d/%d" % [castle_hp, castle_max_hp]
    gold_label.text = "Gold: %d" % gold
    lesson_label.text = "Lesson: %s" % current_lesson.replace("_", " ").capitalize()

    accuracy_label.text = "Accuracy: %d%%" % int(_get_accuracy() * 100)
    combo_label.text = "Combo: %d" % combo
    power_label.text = "Power: %.1fx" % _calculate_power()

    wave_progress.max_value = wave_enemies_total
    wave_progress.value = enemies_defeated
```

## Game Over

```gdscript
# game/typing_defense.gd:272
func _game_over() -> void:
    word_display.text = "[center][color=red]GAME OVER[/color][/center]"
    input_field.editable = false
    feedback_label.text = "Castle destroyed! Final gold: %d | Max combo: %d" % [gold, max_combo]
```

## Integration Examples

### Saving Progress

```gdscript
func _save_session_stats() -> void:
    var stats := {
        "waves_completed": wave - 1,
        "gold_earned": gold,
        "max_combo": max_combo,
        "accuracy": _get_accuracy(),
        "lesson_reached": current_lesson
    }
    TypingProfile.record_session(profile, "typing_defense", stats)
```

### Connecting to Main Game

```gdscript
func _on_menu_pressed() -> void:
    if game_controller:
        game_controller.go_to_menu()
```

## Testing

```gdscript
func test_power_calculation():
    var scene := TypingDefense.new()
    scene.correct_chars = 100
    scene.total_chars = 100
    scene.combo = 10

    var power: float = scene._calculate_power()
    # 1.0 + (10 * 0.1) + (1.0 * 0.5) = 2.5
    assert(power == 2.5)

    _pass("test_power_calculation")

func test_lesson_progression():
    var scene := TypingDefense.new()
    scene.current_lesson = "home_row"
    scene.wave = 3

    scene._wave_complete()
    assert(scene.current_lesson == "top_row")

    _pass("test_lesson_progression")

func test_combo_gold_bonus():
    var scene := TypingDefense.new()
    scene.combo = 10
    scene.current_enemy = {"gold": 10, "hp": 1, "word": "test"}

    # With combo 10, gold should be 1.5x
    scene._attack_enemy()
    assert(scene.gold == 15)  # 10 * 1.5

    _pass("test_combo_gold_bonus")
```
