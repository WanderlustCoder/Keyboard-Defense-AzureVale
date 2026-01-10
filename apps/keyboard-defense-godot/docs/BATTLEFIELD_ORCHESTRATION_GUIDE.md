# Battlefield Orchestration Guide

This document explains the Battlefield controller that orchestrates typing combat, managing drills, buffs, threat mechanics, visual feedback, and battle completion flow.

## Overview

The Battlefield is the main battle scene controller:

```
Initialize Battle → Build Drill Plan → Execute Drills → Handle Typing → Victory/Defeat
       ↓                  ↓                 ↓                ↓              ↓
   Load node,         Plan from         Lesson mode,     Combat flow,    Record stats,
   get modifiers      template          targets,         apply relief,   award gold
                                        intermission     spawn projectile
```

## Core Constants

```gdscript
# scripts/Battlefield.gd
const BUFF_DEFS := {
    "focus": {
        "label": "Focus Surge",
        "duration": 8.0,
        "typing_power_multiplier": 1.25
    },
    "ward": {
        "label": "Ward of Calm",
        "duration": 8.0,
        "threat_rate_multiplier": 0.75
    }
}
const BUFF_WORD_STREAK := 4      # Words needed for Focus buff
const BUFF_INPUT_STREAK := 24    # Correct inputs needed for Ward buff

const FEEDBACK_DURATION := 0.75
const FEEDBACK_ERROR_DURATION := 0.6
const FEEDBACK_WAVE_DURATION := 1.1
const FEEDBACK_BUFF_DURATION := 0.9

const THREAT_WARNING_THRESHOLD := 70.0
const ERROR_SHAKE_INTENSITY := 4.0
const ERROR_SHAKE_DURATION := 0.15
const COMBO_PULSE_DURATION := 0.15
```

## Battle State

### Combat Values

```gdscript
# Base values (from progression modifiers)
var base_typing_power: float = 1.0
var base_threat_rate_multiplier: float = 1.0
var base_mistake_forgiveness: float = 0.0
var base_castle_health: int = 3
var base_threat_rate: float = 8.0
var base_threat_relief: float = 12.0
var base_mistake_penalty: float = 18.0

# Current computed values (with buffs applied)
var threat: float = 0.0
var threat_rate: float = 8.0
var threat_relief: float = 12.0
var mistake_penalty: float = 18.0
var castle_health: int = 3
var typing_power: float = 1.0
var mistake_forgiveness: float = 0.0
```

### Buff System

```gdscript
var active_buffs: Array = []           # [{id, remaining}]
var buff_modifiers := {
    "typing_power_multiplier": 1.0,
    "threat_rate_multiplier": 1.0,
    "mistake_forgiveness_bonus": 0.0
}
var input_streak: int = 0
var word_streak: int = 0
```

### Drill State

```gdscript
var drill_plan: Array = []             # Array of drill dictionaries
var drill_index: int = -1              # Current drill index
var drill_mode: String = ""            # "lesson", "targets", "intermission"
var drill_label: String = ""           # Display name
var drill_timer: float = 0.0           # Intermission countdown
var drill_word_goal: int = 0           # Target count for current drill
var drill_input_enabled: bool = true
var current_drill: Dictionary = {}
```

### Battle Statistics

```gdscript
var battle_start_time_ms: int = 0
var battle_total_inputs: int = 0
var battle_correct_inputs: int = 0
var battle_errors: int = 0
var battle_words_completed: int = 0
```

## Battle Initialization

```gdscript
# scripts/Battlefield.gd:195
func _initialize_battle() -> void:
    node_id = game_controller.next_battle_node_id
    if node_id == "":
        game_controller.go_to_map()
        return

    var node: Dictionary = progression.map_nodes.get(node_id, {})
    node_label = str(node.get("label", "Battle"))
    lesson_id = str(node.get("lesson_id", ""))
    var lesson: Dictionary = progression.get_lesson(lesson_id)
    lesson_words = lesson.get("words", [])
    if lesson_words.is_empty():
        lesson_words = _generate_words_from_lesson(lesson, node_id)

    # Load combat modifiers from progression
    var modifiers: Dictionary = progression.get_combat_modifiers()
    base_modifiers = modifiers.duplicate(true)
    base_typing_power = float(modifiers.get("typing_power", 1.0))
    base_threat_rate_multiplier = float(modifiers.get("threat_rate_multiplier", 1.0))
    base_mistake_forgiveness = float(modifiers.get("mistake_forgiveness", 0.0))
    base_castle_health = 3 + int(modifiers.get("castle_health_bonus", 0))

    # Reset battle state
    castle_health = base_castle_health
    _set_threat(0.0)
    active_buffs.clear()
    _reset_streaks()
    _clear_feedback()
    _recompute_buff_modifiers()
    _recompute_combat_values()

    if battle_stage != null:
        battle_stage.reset()

    tutorial_mode = progression.completed_nodes.size() == 0

    # Reset stats
    battle_start_time_ms = Time.get_ticks_msec()
    battle_total_inputs = 0
    battle_correct_inputs = 0
    battle_errors = 0
    battle_words_completed = 0

    # Build and start drill plan
    drill_plan = _build_drill_plan(node, lesson)
    drill_index = -1
    _start_next_drill()

    # Start battle music
    if audio_manager != null:
        audio_manager.switch_to_battle_music(false)
```

## Drill Plan System

### Building Drill Plans

```gdscript
# scripts/Battlefield.gd:615
func _build_drill_plan(node: Dictionary, lesson: Dictionary) -> Array:
    var base_plan: Array = []

    # 1. Check for inline drill plan
    var inline_plan = node.get("drill_plan", [])
    if inline_plan is Array and inline_plan.size() > 0:
        base_plan = inline_plan

    # 2. Check for template reference
    var template_id := str(node.get("drill_template", ""))
    if base_plan.is_empty() and template_id != "":
        var template: Dictionary = progression.get_drill_template(template_id)
        var template_plan = template.get("plan", [])
        if template_plan is Array and template_plan.size() > 0:
            base_plan = template_plan

    # 3. Fall back to default plan
    if base_plan.is_empty():
        base_plan = _build_default_drill_plan(node, lesson)

    # 4. Apply overrides
    var resolved: Array = base_plan.duplicate(true)
    var overrides = node.get("drill_overrides", {})
    if overrides is Dictionary:
        resolved = _apply_drill_overrides(resolved, overrides)

    return resolved
```

### Default Drill Plan

```gdscript
# scripts/Battlefield.gd:686
func _build_default_drill_plan(node: Dictionary, lesson: Dictionary) -> Array:
    var warmup_count: int = min(4, lesson_words.size())
    var main_count: int = min(6, lesson_words.size())
    var lesson_label_text := str(lesson.get("label", "Defense Drill"))
    var rune_targets: Array = node.get("rune_targets", DEFAULT_RUNE_TARGETS)

    return [
        {
            "mode": "lesson",
            "label": "Warmup Runes",
            "word_count": warmup_count,
            "shuffle": true
        },
        {
            "mode": "intermission",
            "label": "Scouts Regroup",
            "duration": 2.5,
            "message": "Scouts regroup and the ward recharges."
        },
        {
            "mode": "targets",
            "label": "Rune Marks",
            "targets": rune_targets
        },
        {
            "mode": "lesson",
            "label": lesson_label_text,
            "word_count": main_count,
            "shuffle": true
        }
    ]
```

### Drill Overrides

```gdscript
# scripts/Battlefield.gd:634
func _apply_drill_overrides(base_plan: Array, overrides: Dictionary) -> Array:
    var plan: Array = base_plan.duplicate(true)

    # Replace specific indices
    var replace_list: Array = overrides.get("replace", [])
    for entry in replace_list:
        var index: int = int(entry.get("index", -1))
        if index >= 0 and index < plan.size():
            plan[index] = entry.get("step", {})

    # Merge data into existing steps
    var step_overrides: Array = overrides.get("steps", [])
    for entry in step_overrides:
        var index: int = int(entry.get("index", -1))
        if index >= 0 and index < plan.size():
            var merged: Dictionary = plan[index].duplicate(true)
            for key in entry.get("data", {}).keys():
                merged[key] = entry.data[key]
            plan[index] = merged

    # Remove indices (sorted descending)
    var remove_list: Array = overrides.get("remove", [])
    remove_list.sort()
    for i in range(remove_list.size() - 1, -1, -1):
        var index: int = int(remove_list[i])
        if index >= 0 and index < plan.size():
            plan.remove_at(index)

    # Prepend steps
    var prepend_steps: Array = overrides.get("prepend", [])
    if prepend_steps.size() > 0:
        var new_plan: Array = prepend_steps + plan
        plan = new_plan

    # Append steps
    var append_steps: Array = overrides.get("append", [])
    for step in append_steps:
        plan.append(step)

    return plan
```

### Drill Modes

| Mode | Description |
|------|-------------|
| `lesson` | Type words from the lesson word pool |
| `targets` | Type specific target strings |
| `intermission` | Countdown break between drills |

## Typing Combat Flow

### Input Handling

```gdscript
# scripts/Battlefield.gd:381
func _unhandled_input(event: InputEvent) -> void:
    if not active:
        return
    if paused:
        return
    if battle_tutorial != null and battle_tutorial.is_dialogue_open():
        return
    if not drill_input_enabled:
        return

    if _is_key_pressed(event):
        if event.keycode == KEY_BACKSPACE:
            typing_system.backspace()
            _update_word_display()
            _trigger_backspace_feedback()
            return
        if event.unicode == 0:
            return
        var char_text: String = char(event.unicode)
        var result: Dictionary = typing_system.input_char(char_text)
        _handle_typing_result(result)
```

### Typing Result Handler

```gdscript
# scripts/Battlefield.gd:393
func _handle_typing_result(result: Dictionary) -> void:
    var status: String = str(result.get("status", ""))
    if status == "ignored":
        return

    if status == "error":
        _reset_streaks()
        if audio_manager != null:
            audio_manager.play_type_mistake()
            audio_manager.play_combo_break()
        _trigger_error_shake()
    else:
        _advance_streaks(status)
        if audio_manager != null:
            audio_manager.play_type_correct()

    _check_buff_triggers()
    _update_feedback_for_status(status)
    _apply_typing_combat(status)

    if status == "lesson_complete":
        _complete_drill()
        return

    _update_word_display()
    _update_stats()
    _update_threat()
    _update_drill_status()
```

### Combat Application

```gdscript
# scripts/Battlefield.gd:517
func _apply_typing_combat(status: String) -> void:
    if battle_stage == null:
        _apply_typing_threat_fallback(status)
        return

    match status:
        "error":
            battle_stage.apply_penalty(mistake_penalty)
            battle_stage.apply_relief(threat_relief * 0.2)
        "progress":
            battle_stage.apply_relief(threat_relief * 0.2)
        "word_complete":
            battle_stage.apply_relief(threat_relief)
            battle_stage.spawn_projectile(false)
        "lesson_complete":
            battle_stage.apply_relief(threat_relief)
            battle_stage.spawn_projectile(true)

    _sync_threat_from_stage()
```

| Status | Penalty | Relief | Visual |
|--------|---------|--------|--------|
| error | +mistake_penalty | +20% relief | Error shake |
| progress | - | +20% relief | - |
| word_complete | - | +100% relief | Spawn projectile |
| lesson_complete | - | +100% relief | Big projectile |

## Buff System

### Streak Tracking

```gdscript
# scripts/Battlefield.gd:1138
func _reset_streaks() -> void:
    input_streak = 0
    word_streak = 0

func _advance_streaks(status: String) -> void:
    if status == "progress" or status == "word_complete" or status == "lesson_complete":
        input_streak += 1
        _pulse_combo_indicator()
    if status == "word_complete" or status == "lesson_complete":
        word_streak += 1
        _pulse_combo_indicator()

func _check_buff_triggers() -> void:
    if word_streak >= BUFF_WORD_STREAK:
        _activate_buff("focus")
        word_streak = 0
    if input_streak >= BUFF_INPUT_STREAK:
        _activate_buff("ward")
        input_streak = 0
```

### Buff Activation

```gdscript
# scripts/Battlefield.gd:1158
func _activate_buff(buff_id: String) -> void:
    if not BUFF_DEFS.has(buff_id):
        return

    var definition: Dictionary = BUFF_DEFS[buff_id]
    var duration: float = float(definition.get("duration", 0.0))

    # Refresh existing buff or add new
    var refreshed := false
    for buff in active_buffs:
        if buff is Dictionary and str(buff.get("id", "")) == buff_id:
            buff["remaining"] = duration
            refreshed = true
            break
    if not refreshed:
        active_buffs.append({"id": buff_id, "remaining": duration})

    _apply_buff_changes()
    _show_feedback("%s!" % _get_buff_label(buff_id), buff_color, FEEDBACK_BUFF_DURATION)
```

### Buff Modifiers

```gdscript
# scripts/Battlefield.gd:1203
func _recompute_buff_modifiers() -> void:
    buff_modifiers = {
        "typing_power_multiplier": 1.0,
        "threat_rate_multiplier": 1.0,
        "mistake_forgiveness_bonus": 0.0
    }
    for buff in active_buffs:
        var buff_id := str(buff.get("id", ""))
        var definition: Dictionary = BUFF_DEFS.get(buff_id, {})
        for key in buff_modifiers.keys():
            if definition.has(key):
                if key == "mistake_forgiveness_bonus":
                    buff_modifiers[key] += float(definition[key])
                else:
                    buff_modifiers[key] *= float(definition[key])

func _recompute_combat_values() -> void:
    var typing_multiplier: float = float(buff_modifiers.get("typing_power_multiplier", 1.0))
    var threat_multiplier: float = float(buff_modifiers.get("threat_rate_multiplier", 1.0))
    var forgiveness_bonus: float = float(buff_modifiers.get("mistake_forgiveness_bonus", 0.0))

    typing_power = base_typing_power * typing_multiplier
    mistake_forgiveness = clamp(base_mistake_forgiveness + forgiveness_bonus, 0.0, 0.8)
    threat_rate = base_threat_rate * base_threat_rate_multiplier * threat_multiplier
    threat_relief = base_threat_relief * typing_power
    mistake_penalty = base_mistake_penalty * (1.0 - mistake_forgiveness)
```

## Visual Feedback

### Screen Shake

```gdscript
# scripts/Battlefield.gd:1394
func _trigger_screen_shake(intensity: float, duration: float) -> void:
    if settings_manager != null and not settings_manager.screen_shake:
        return
    _shake_intensity = intensity
    _shake_duration = duration
    _shake_initial_duration = duration

func _update_screen_shake(delta: float) -> void:
    if _shake_duration <= 0.0:
        if _shake_offset != Vector2.ZERO:
            position -= _shake_offset
            _shake_offset = Vector2.ZERO
        return

    _shake_duration -= delta
    var decay_factor := _shake_duration / _shake_initial_duration
    var current_intensity := _shake_intensity * decay_factor

    position -= _shake_offset
    _shake_offset = Vector2(
        randf_range(-current_intensity, current_intensity),
        randf_range(-current_intensity, current_intensity)
    )
    position += _shake_offset
```

### Error Shake (Typed Label)

```gdscript
# scripts/Battlefield.gd:1354
func _trigger_error_shake() -> void:
    if typed_label == null:
        return
    if settings_manager != null and not settings_manager.screen_shake:
        return

    if _error_shake_tween != null and _error_shake_tween.is_valid():
        _error_shake_tween.kill()
        typed_label.position = _typed_label_base_pos

    _error_shake_tween = create_tween()
    var shake_time := ERROR_SHAKE_DURATION / 4.0

    _error_shake_tween.tween_property(typed_label, "position",
        _typed_label_base_pos + Vector2(-ERROR_SHAKE_INTENSITY, 0), shake_time)
    _error_shake_tween.tween_property(typed_label, "position",
        _typed_label_base_pos + Vector2(ERROR_SHAKE_INTENSITY, 0), shake_time)
    _error_shake_tween.tween_property(typed_label, "position",
        _typed_label_base_pos + Vector2(-ERROR_SHAKE_INTENSITY * 0.5, 0), shake_time)
    _error_shake_tween.tween_property(typed_label, "position",
        _typed_label_base_pos, shake_time)
```

### Combo Indicator

```gdscript
# scripts/Battlefield.gd:1444
func _update_combo_indicator(delta: float) -> void:
    if combo_label == null:
        return

    var total_streak := input_streak + word_streak * 2
    if total_streak < 3:
        combo_label.visible = false
        return

    combo_label.visible = true

    # Determine combo tier and color
    if total_streak >= 30:
        combo_text = "BLAZING x%d" % total_streak
        combo_color = Color(1.0, 0.5, 0.2, 1.0)  # Orange
    elif total_streak >= 20:
        combo_text = "HOT x%d" % total_streak
        combo_color = ThemeColors.ACCENT  # Gold
    elif total_streak >= 10:
        combo_text = "COMBO x%d" % total_streak
        combo_color = ThemeColors.ACCENT_BLUE  # Cyan
    else:
        combo_text = "x%d" % total_streak
        combo_color = ThemeColors.text_alpha(0.65)  # Gray

    combo_label.text = combo_text
```

| Streak | Label | Color |
|--------|-------|-------|
| 3-9 | x{n} | Gray |
| 10-19 | COMBO x{n} | Cyan |
| 20-29 | HOT x{n} | Gold |
| 30+ | BLAZING x{n} | Orange |

## Battle Completion

### Finish Battle

```gdscript
# scripts/Battlefield.gd:853
func _finish_battle(success: bool) -> void:
    active = false
    paused = false

    var stats: Dictionary = _collect_battle_stats(true)
    var accuracy: float = float(stats.get("accuracy", 1.0))
    var wpm: float = float(stats.get("wpm", 0.0))
    var errors: int = int(stats.get("errors", 0))
    var words_completed: int = int(stats.get("words_completed", 0))

    var summary: Dictionary = {
        "node_id": node_id,
        "node_label": node_label,
        "lesson_id": lesson_id,
        "accuracy": accuracy,
        "wpm": wpm,
        "errors": errors,
        "words_completed": words_completed,
        "completed": success,
        "drill_step": drill_index + 1,
        "drill_total": drill_plan.size()
    }

    if success:
        var completed_summary: Dictionary = progression.complete_node(node_id, summary)
        var tier := str(completed_summary.get("performance_tier", ""))
        var bonus := int(completed_summary.get("performance_bonus", 0))
        var gold_awarded := int(completed_summary.get("gold_awarded", 0))

        audio_manager.play_victory()

        # Build victory message
        var lines: Array = ["Victory! The castle stands strong."]
        if tier != "":
            lines.append("Rank: %s" % tier)
        lines.append(stats_line)
        if gold_awarded > 0:
            lines.append("Gold: +%dg" % gold_awarded)
        result_label.text = "\n".join(lines)
        result_action = "map"
    else:
        progression.record_attempt(summary)
        audio_manager.play_defeat()
        result_label.text = "Defeat. The walls fell.\n" + stats_line
        result_action = "retry"

    result_panel.visible = true
```

### Statistics Collection

```gdscript
# scripts/Battlefield.gd:590
func _collect_battle_stats(include_current: bool) -> Dictionary:
    var total_inputs = battle_total_inputs
    var correct_inputs = battle_correct_inputs
    var errors = battle_errors
    var words_completed = battle_words_completed

    if include_current:
        total_inputs += typing_system.total_inputs
        correct_inputs += typing_system.correct_inputs
        errors += typing_system.errors
        words_completed += typing_system.get_words_completed()

    var accuracy: float = 1.0
    if total_inputs > 0:
        accuracy = float(correct_inputs) / float(total_inputs)

    var elapsed_ms: int = Time.get_ticks_msec() - battle_start_time_ms
    var elapsed_seconds: float = max(0.001, float(elapsed_ms) / 1000.0)
    var wpm: float = float(words_completed) / (elapsed_seconds / 60.0)

    return {
        "accuracy": accuracy,
        "wpm": wpm,
        "errors": errors,
        "words_completed": words_completed,
        "total_inputs": total_inputs,
        "correct_inputs": correct_inputs
    }
```

## Pause System

```gdscript
# scripts/Battlefield.gd:1123
func _toggle_pause() -> void:
    if not active or result_panel.visible:
        return
    _set_paused(not paused)

func _set_paused(value: bool) -> void:
    paused = value
    if pause_panel != null:
        pause_panel.visible = paused
```

### Pause Panel Settings

```gdscript
# Quick settings available during pause:
- Music volume slider
- SFX volume slider
- Screen shake toggle
```

## Tutorial Integration

```gdscript
# scripts/Battlefield.gd:255
func _setup_battle_tutorial() -> void:
    battle_tutorial = BattleTutorial.new()
    add_child(battle_tutorial)
    battle_tutorial.initialize(self)
    battle_tutorial.tutorial_finished.connect(_on_tutorial_finished)

    if battle_tutorial.is_active():
        progression.mark_battle_started()
        await get_tree().create_timer(0.5).timeout
        battle_tutorial.start()
```

### Tutorial Triggers

| Trigger | When Fired |
|---------|------------|
| `first_word_typed` | On word_complete status |
| `threat_shown` | When threat > 20.0 |
| `castle_damaged` | When castle takes damage |
| `combo_achieved` | When buff is activated |
| `near_victory` | On second-to-last drill |

## Testing

```gdscript
func test_buff_activation():
    var battlefield := preload("res://scripts/Battlefield.gd").new()

    # Simulate word streak
    for i in range(BUFF_WORD_STREAK):
        battlefield._advance_streaks("word_complete")
        battlefield._check_buff_triggers()

    assert(battlefield.active_buffs.size() == 1)
    assert(battlefield.active_buffs[0].id == "focus")

    _pass("test_buff_activation")

func test_combat_value_computation():
    var battlefield := preload("res://scripts/Battlefield.gd").new()
    battlefield.base_typing_power = 1.5
    battlefield.base_threat_rate_multiplier = 0.9

    battlefield._recompute_combat_values()

    assert(battlefield.threat_relief == 12.0 * 1.5)  # base_relief * typing_power
    assert(battlefield.threat_rate == 8.0 * 0.9)     # base_rate * multiplier

    _pass("test_combat_value_computation")
```
