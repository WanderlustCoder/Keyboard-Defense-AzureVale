# Game Loop Orchestration Guide

This document explains the main game controller that orchestrates the core game loop, command processing, UI management, and system integration.

## Overview

The main controller is the central orchestrator for the open-world typing game:

```
Input → Command Parse → Intent Apply → State Update → HUD Refresh → Visual/Audio Feedback
   ↓          ↓              ↓              ↓              ↓                  ↓
Hotkeys   CommandParser   IntentApplier   GameState   _refresh_hud()    _trigger_*()
Typing                                                 GridRenderer      AudioManager
```

## Core Dependencies

```gdscript
# game/main.gd - Key preloads
const DefaultState = preload("res://sim/default_state.gd")
const CommandParser = preload("res://sim/parse_command.gd")
const IntentApplier = preload("res://sim/apply_intent.gd")
const GameState = preload("res://sim/types.gd")
const SimTypingStats = preload("res://sim/typing_stats.gd")
const SimTypingFeedback = preload("res://sim/typing_feedback.gd")
const WorldTick = preload("res://sim/world_tick.gd")
const OnboardingFlow = preload("res://game/onboarding_flow.gd")
const AchievementChecker = preload("res://game/achievement_checker.gd")
const KeybindConflicts = preload("res://game/keybind_conflicts.gd")
```

## State Variables

### Game State

```gdscript
var state: GameState              # Main simulation state
var preview_type: String = ""     # Building preview type
var overlay_path_enabled: bool    # Path overlay toggle
```

### Typing State

```gdscript
var typing_candidates: Dictionary = {}   # Candidate enemy matches
var typing_candidate_ids: Array = []     # Ordered candidate IDs
var typing_focus_id: int = -1            # Currently focused enemy
var typing_stats: SimTypingStats         # Combat typing statistics
var last_input_text: String = ""         # Last typed text
```

### UI State

```gdscript
var report_visible: bool = false
var history_visible: bool = false
var trend_visible: bool = false
var settings_visible: bool = false
var lesson_visible: bool = false
var tutorial_visible: bool = false
var event_visible: bool = false
var awaiting_bind_action: String = ""   # Action awaiting rebind
```

### Profile State

```gdscript
var profile: Dictionary = {}            # Player profile data
var onboarding: Dictionary = {}         # Tutorial progress
var typing_history: Array = []          # Night reports
var current_goal: String = "balanced"   # Active practice goal
var preferred_lesson: String = ""       # Selected lesson
var lesson_progress: Dictionary = {}    # Per-lesson stats
```

### Accessibility Settings

```gdscript
var ui_scale_percent: int = 100
var compact_panels: bool = false
var reduced_motion: bool = false
var high_contrast: bool = false
var nav_hints: bool = true
var practice_mode: bool = false
```

## Initialization

```gdscript
# game/main.gd:114
func _ready() -> void:
    state = DefaultState.create()
    typing_stats = SimTypingStats.new()

    # Connect command bar signals
    if command_bar.has_signal("command_submitted"):
        command_bar.command_submitted.connect(_on_command_submitted)
    if command_bar.has_signal("input_changed"):
        command_bar.input_changed.connect(_on_input_changed)

    # Enable BBCode for rich text
    _enable_rich_text_labels()

    # Load player profile
    _load_profile()
    _reset_onboarding_flags()

    # Initialize systems
    _append_log(["Type 'help' to see commands."])
    _refresh_hud()
    _init_achievement_system()
    command_bar.grab_focus()
```

## Main Loop

### Process Tick

```gdscript
# game/main.gd:174
func _process(delta: float) -> void:
    # World tick for open-world exploration (real-time threats)
    if state.phase != "game_over":
        var result: Dictionary = WorldTick.tick(state, delta)
        if result.get("changed", false):
            var events: Array = result.get("events", [])
            if not events.is_empty():
                _append_log(events)
            _refresh_hud()
```

### Input Handling

```gdscript
# game/main.gd:184
func _input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        # Rebind mode
        if awaiting_bind_action != "":
            _handle_bind_action(event)
            return

        # Hotkey dispatch
        if KeybindConflicts.event_matches_action_exact(event, "toggle_settings"):
            _toggle_settings_hotkey()
            return
        if KeybindConflicts.event_matches_action_exact(event, "toggle_lessons"):
            _toggle_lessons_hotkey()
            return
        # ... more hotkeys

        # Arrow key cursor navigation (when command bar empty)
        if command_bar.text.is_empty():
            match event.keycode:
                KEY_UP: _move_cursor_direction(Vector2i(0, -1))
                KEY_DOWN: _move_cursor_direction(Vector2i(0, 1))
                KEY_LEFT: _move_cursor_direction(Vector2i(-1, 0))
                KEY_RIGHT: _move_cursor_direction(Vector2i(1, 0))
```

## Command Processing

### Command Submission Flow

```gdscript
# game/main.gd:278
func _on_command_submitted(command: String) -> void:
    var is_night: bool = state.phase == "night"
    var trimmed: String = command.strip_edges()

    if trimmed.is_empty():
        if is_night and typing_stats != null:
            typing_stats.record_incomplete_enter("empty")
        _refresh_typing_feedback(command)
        return

    # Parse command
    var parsed: Dictionary = CommandParser.parse(trimmed)

    if parsed.get("ok", false):
        var intent_kind: String = str(parsed.intent.get("kind", ""))

        # Track night typing stats
        if is_night and typing_stats != null:
            if intent_kind == "defend_input":
                _handle_defend_stats(command)
            else:
                typing_stats.record_command_enter(intent_kind, intent_kind == "wait")

        # Route UI intents locally
        if intent_kind.begins_with("ui_"):
            _handle_ui_intent(intent_kind, parsed.intent, trimmed)
            return

        # Apply sim intent
        command_bar.accept_submission(trimmed)
        var result: Dictionary = IntentApplier.apply(state, parsed.intent)
        _apply_result(result, intent_kind)
        return

    # Night phase fallback - treat unparsed as defend input
    if state.phase == "night":
        var route: Dictionary = SimTypingFeedback.route_night_input(false, "", command, state.enemies)
        _handle_night_routing(route, command, trimmed)
        return

    _append_log(["Error: %s" % parsed.get("error", "Unknown error")])
```

### Result Application

```gdscript
# game/main.gd:492
func _apply_result(result: Dictionary, intent_kind: String = "") -> void:
    var prev_phase: String = state.phase
    var prev_lesson: String = state.lesson_id

    # Update state
    state = result.state
    _append_log(result.events)

    # Trigger feedback
    _trigger_event_audio(result.events)
    _trigger_event_visuals(result.events)
    _trigger_achievement_events(result.events)

    # Play intent-specific audio
    if audio_manager != null and intent_kind != "":
        match intent_kind:
            "gather": audio_manager.play_sfx(audio_manager.SFX.RESOURCE_PICKUP)
            "build": audio_manager.play_sfx(audio_manager.SFX.BUILD_PLACE)
            "upgrade": audio_manager.play_upgrade_purchase()
            "end": audio_manager.play_wave_start()
            "explore":
                audio_manager.play_ui_confirm()
                if _event_has_prefix(result.events, "Found:"):
                    audio_manager.play_poi_appear()

    # Handle special results
    if result.has("request"):
        var request_result: Dictionary = _handle_request(result.request)
        if request_result.has("state"):
            state = request_result.state

    # Progress onboarding
    _advance_onboarding(intent_kind, result.events, prev_phase, state.phase)

    # Refresh display
    _refresh_hud()
    _handle_phase_change(prev_phase, state.phase)
    command_bar.grab_focus()
```

## HUD Refresh

```gdscript
# game/main.gd:535
func _refresh_hud() -> void:
    stats_label.text = IntentApplier._format_status(state)
    _update_prompt()
    _update_command_hint()

    # Update grid renderer
    if grid_renderer.has_method("update_state"):
        grid_renderer.update_state(state)
    if grid_renderer.has_method("set_preview_type"):
        grid_renderer.set_preview_type(preview_type)
    if grid_renderer.has_method("set_path_overlay"):
        grid_renderer.set_path_overlay(overlay_path_enabled)

    # Refresh all panels
    _refresh_inspector()
    _refresh_legend()
    _refresh_typing_feedback(command_bar.text)
    _refresh_goal_badge()
    _refresh_goal_legend()
    _refresh_tutorial_panel()
    _refresh_lesson_health()
    _refresh_settings_panel()
    _refresh_lesson_panel()
    _refresh_report_panel()
    _refresh_history_panel()
    _refresh_trend_panel()
    _maybe_log_economy_guardrails()
    _check_pending_event()
```

## Event-Driven Feedback

### Audio Triggers

```gdscript
# game/main.gd:642
func _trigger_event_audio(events: Array) -> void:
    if audio_manager == null:
        return
    for event in events:
        var text: String = str(event)
        # Boss events
        if text.begins_with("BOSS ENCOUNTER:"):
            audio_manager.play_sfx(audio_manager.SFX.BOSS_APPEAR)
        elif text.begins_with("BOSS DEFEATED:"):
            audio_manager.play_sfx(audio_manager.SFX.BOSS_DEFEATED)
        # Combat events
        elif text.contains("defeated") and text.contains("gold"):
            audio_manager.play_hit_enemy()
        elif text.begins_with("Enemy") and text.contains("hits the base"):
            audio_manager.play_hit_player()
        # Wave events
        elif text.begins_with("Dawn breaks"):
            audio_manager.play_wave_end()
        elif text.begins_with("Night falls"):
            audio_manager.play_sfx(audio_manager.SFX.WAVE_START)
        # Victory/defeat
        elif text.begins_with("VICTORY"):
            audio_manager.play_victory()
        elif text.begins_with("Game over"):
            audio_manager.play_defeat()
```

### Visual Triggers

```gdscript
# game/main.gd:698
func _trigger_event_visuals(events: Array) -> void:
    if grid_renderer == null or reduced_motion:
        return
    for event in events:
        var text: String = str(event)
        # Enemy defeated - spawn projectile
        if text.contains("defeated") and text.contains("gold"):
            var defeat_pos: Vector2i = _get_last_target_pos()
            if defeat_pos != Vector2i(-1, -1):
                grid_renderer.spawn_projectile(defeat_pos, text.contains("BOSS"))
        # Tower attack - fire animation
        elif text.begins_with("Tower hits"):
            _parse_tower_hit_and_trigger(text)
        # Exploration reveal
        elif text.begins_with("Discovered tile"):
            _parse_tile_coords_and_reveal(text)
        # Building construction
        elif text.begins_with("Built "):
            grid_renderer.spawn_build_effect(state.cursor_pos)
        # Castle damage
        elif text.contains("hits the base"):
            grid_renderer.spawn_damage_flash()
```

## UI Intent Routing

| Intent Kind | Handler |
|-------------|---------|
| `ui_preview` | `_apply_preview()` |
| `ui_overlay` | `_apply_overlay()` |
| `ui_report` | `_apply_report()` |
| `ui_goal_*` | `_apply_goal_*()` |
| `ui_lessons_*` | `_apply_lessons_*()` |
| `ui_settings_*` | `_apply_settings_*()` |
| `ui_tutorial_*` | `_apply_tutorial_*()` |
| `ui_bind_action*` | `_apply_bind_action*()` |
| `ui_history` | `_apply_history()` |
| `ui_trend` | `_apply_trend()` |
| `ui_balance_*` | `_apply_balance_*()` |
| `help` | `_apply_help()` |

## Onboarding System

### Flag Tracking

```gdscript
# game/main.gd:856
func _default_onboarding_flags() -> Dictionary:
    return {
        "used_help_or_status": false,
        "did_gather": false,
        "did_build": false,
        "did_explore": false,
        "entered_night": false,
        "hit_enemy": false,
        "reached_dawn": false,
        "opened_lessons": false,
        "opened_settings": false,
        "toggled_tutorial": false
    }
```

### Advancement

```gdscript
# game/main.gd:615
func _advance_onboarding(intent_kind: String, events: Array, prev_phase: String, new_phase: String) -> void:
    _ensure_onboarding_state()
    if bool(onboarding.get("completed", false)):
        return
    if not bool(onboarding.get("enabled", true)):
        return

    _update_onboarding_flags(intent_kind, events, prev_phase, new_phase)
    var snapshot: Dictionary = _build_onboarding_snapshot(prev_phase, new_phase)
    var step_index: int = OnboardingFlow.clamp_step(int(onboarding.get("step", 0)))
    var next_step: int = OnboardingFlow.advance(step_index, snapshot)

    if next_step == step_index:
        return

    onboarding["step"] = next_step
    if next_step >= OnboardingFlow.step_count():
        onboarding["completed"] = true
        onboarding["enabled"] = false
        _append_log(["Tutorial completed. Use 'tutorial restart' to replay."])

    _persist_onboarding_state()
    _refresh_tutorial_panel()
```

## Cursor Navigation

```gdscript
# game/main.gd:237
func _move_cursor_direction(direction: Vector2i) -> void:
    var new_pos: Vector2i = state.cursor_pos + direction
    if SimMap.in_bounds(new_pos.x, new_pos.y, state.map_w, state.map_h):
        state.cursor_pos = new_pos
        _refresh_hud()
        _update_tile_context()

func _update_tile_context() -> void:
    var pos: Vector2i = state.cursor_pos
    var index: int = pos.y * state.map_w + pos.x
    var lines: Array[String] = []

    # Terrain
    var terrain: String = SimMap.get_terrain(state, pos)
    lines.append("[b]Tile:[/b] %d, %d (%s)" % [pos.x, pos.y, terrain])

    # Structure
    if state.structures.has(index):
        var struct_type: String = str(state.structures[index])
        var level: int = state.structure_levels.get(index, 1)
        lines.append("[b]Structure:[/b] %s (level %d)" % [struct_type, level])

    # POI
    if state.active_pois.has(index):
        var poi: Dictionary = state.active_pois[index]
        lines.append("[b]POI:[/b] %s" % poi.get("id", "unknown"))

    # Roaming enemies
    for entity in state.roaming_enemies:
        if entity.get("pos", Vector2i(-1, -1)) == pos:
            lines.append("[b]Roaming:[/b] %s" % entity.get("kind", "enemy"))

    if inspect_label != null:
        inspect_label.text = "\n".join(lines)
```

## Combo System Integration

```gdscript
# game/main.gd:296
func _handle_defend_stats(command: String) -> void:
    var prev_combo: int = typing_stats.current_combo
    typing_stats.record_defend_attempt(command, state.enemies)

    # Combo threshold audio
    if audio_manager != null and typing_stats.did_reach_threshold(prev_combo):
        audio_manager.play_sfx(audio_manager.SFX.COMBO_UP)

    # Show combo milestone
    _check_combo_milestone(prev_combo, typing_stats.current_combo)

    # Achievement check
    if typing_stats.current_combo >= 5 and achievement_checker != null:
        var result: Dictionary = achievement_checker.check_combo(profile, typing_stats.current_combo)
        profile = result.get("profile", profile)

    # Combo break detection
    if prev_combo >= 3 and typing_stats.current_combo == 0:
        if audio_manager != null:
            audio_manager.play_sfx(audio_manager.SFX.COMBO_BREAK)
        if grid_renderer != null and not reduced_motion:
            grid_renderer.spawn_combo_break()

    # Sync to grid renderer
    if grid_renderer != null:
        grid_renderer.set_combo(typing_stats.current_combo)
```

## Prompt System

```gdscript
# game/main.gd:560
func _update_prompt() -> void:
    prompt_panel.visible = true

    if state.phase == "night":
        prompt_label.text = "DEFEND: type an enemy word"
    elif state.phase == "game_over":
        prompt_label.text = "GAME OVER - type restart"
    else:
        # Open-world exploration prompt
        var pos: Vector2i = state.cursor_pos
        var index: int = pos.y * state.map_w + pos.x
        var context_parts: Array[String] = []

        if state.active_pois.has(index):
            context_parts.append("talk")
        if state.structures.has(index):
            context_parts.append("inspect")
        if _has_roaming_at(pos):
            context_parts.append("attack")
        if SimMap.is_buildable(state, pos):
            context_parts.append("build")

        if context_parts.is_empty():
            prompt_label.text = "EXPLORE: arrow keys move, type commands"
        else:
            prompt_label.text = "Actions: " + ", ".join(context_parts)
```

## Testing

```gdscript
func test_command_routing():
    var main := preload("res://game/main.gd").new()
    main.state = DefaultState.create()

    # Test command parsing routes to correct handler
    var parsed := CommandParser.parse("build farm 3 3")
    assert(parsed.get("ok", false))
    assert(parsed.intent.get("kind", "") == "build")

    _pass("test_command_routing")

func test_onboarding_advancement():
    var main := preload("res://game/main.gd").new()
    main._reset_onboarding_flags()
    main.onboarding_flags["did_gather"] = true
    main.onboarding_flags["did_build"] = true

    var snapshot := main._build_onboarding_snapshot("day", "day")
    assert(snapshot.get("did_gather", false))
    assert(snapshot.get("did_build", false))

    _pass("test_onboarding_advancement")
```
