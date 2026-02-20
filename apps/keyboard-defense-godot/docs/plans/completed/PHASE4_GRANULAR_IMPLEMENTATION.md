# Phase 4: Scene Transitions - Granular Implementation Guide

## Overview

This document covers smooth scene transitions with fade, wipe, and custom effects. Scene transitions make the game feel more polished and hide loading.

---

## Task 4.1: Create Scene Transition Manager

**Time**: 30 minutes
**File to create**: `game/scene_transition.gd`

### Step 4.1.1: Create the transition manager autoload

**Action**: Create new file `game/scene_transition.gd`

**Complete file contents**:

```gdscript
extends CanvasLayer
class_name SceneTransition
## Scene transition manager with fade, wipe, and custom effects.
## Add as autoload named "SceneTransition" for global access.

signal transition_started
signal transition_midpoint  # When old scene should be replaced
signal transition_finished

enum TransitionType {
	FADE,           # Simple fade to black
	FADE_WHITE,     # Fade to white
	WIPE_LEFT,      # Wipe from right to left
	WIPE_RIGHT,     # Wipe from left to right
	WIPE_UP,        # Wipe from bottom to top
	WIPE_DOWN,      # Wipe from top to bottom
	CIRCLE_IN,      # Circle closes to center
	CIRCLE_OUT,     # Circle opens from center
	PIXELATE,       # Pixelate effect
	DISSOLVE        # Random dissolve
}

const DEFAULT_DURATION := 0.4
const DEFAULT_COLOR := Color(0.05, 0.05, 0.08, 1.0)  # Near-black
const WHITE_COLOR := Color(1.0, 1.0, 1.0, 1.0)

var _overlay: ColorRect
var _is_transitioning: bool = false
var _pending_scene: String = ""
var _pending_callback: Callable = Callable()
var _current_type: TransitionType = TransitionType.FADE
var _transition_color: Color = DEFAULT_COLOR

# For custom transition effects
var _circle_shader: ShaderMaterial = null
var _pixelate_shader: ShaderMaterial = null


func _ready() -> void:
	layer = 100  # Render above everything
	_setup_overlay()


func _setup_overlay() -> void:
	_overlay = ColorRect.new()
	_overlay.color = Color(0, 0, 0, 0)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_overlay)


## Transition to a new scene with animation
func transition_to_scene(
	scene_path: String,
	type: TransitionType = TransitionType.FADE,
	duration: float = DEFAULT_DURATION,
	callback: Callable = Callable()
) -> void:
	if _is_transitioning:
		return

	_is_transitioning = true
	_pending_scene = scene_path
	_pending_callback = callback
	_current_type = type

	# Set transition color based on type
	_transition_color = WHITE_COLOR if type == TransitionType.FADE_WHITE else DEFAULT_COLOR

	transition_started.emit()

	# Play transition out (cover screen)
	_play_transition_out(type, duration * 0.5)

	# Wait for out transition, change scene, then play in transition
	await get_tree().create_timer(duration * 0.5).timeout

	transition_midpoint.emit()

	# Change scene
	if not _pending_scene.is_empty():
		get_tree().change_scene_to_file(_pending_scene)

	# Wait a frame for scene to load
	await get_tree().process_frame

	# Play transition in (reveal screen)
	_play_transition_in(type, duration * 0.5)

	await get_tree().create_timer(duration * 0.5).timeout

	_is_transitioning = false
	transition_finished.emit()

	if _pending_callback.is_valid():
		_pending_callback.call()


## Play just the fade out (for manual scene control)
func fade_out(
	type: TransitionType = TransitionType.FADE,
	duration: float = DEFAULT_DURATION * 0.5
) -> void:
	if _is_transitioning:
		return

	_is_transitioning = true
	_transition_color = WHITE_COLOR if type == TransitionType.FADE_WHITE else DEFAULT_COLOR
	_play_transition_out(type, duration)

	await get_tree().create_timer(duration).timeout
	_is_transitioning = false


## Play just the fade in (for manual scene control)
func fade_in(
	type: TransitionType = TransitionType.FADE,
	duration: float = DEFAULT_DURATION * 0.5
) -> void:
	if _is_transitioning:
		return

	_is_transitioning = true
	_play_transition_in(type, duration)

	await get_tree().create_timer(duration).timeout
	_is_transitioning = false


func _play_transition_out(type: TransitionType, duration: float) -> void:
	var tween := create_tween()

	match type:
		TransitionType.FADE, TransitionType.FADE_WHITE:
			_overlay.color = Color(_transition_color.r, _transition_color.g, _transition_color.b, 0.0)
			tween.tween_property(_overlay, "color:a", 1.0, duration)

		TransitionType.WIPE_LEFT:
			_overlay.color = _transition_color
			_overlay.anchor_right = 0.0
			_overlay.offset_right = 0.0
			tween.tween_property(_overlay, "anchor_right", 1.0, duration)

		TransitionType.WIPE_RIGHT:
			_overlay.color = _transition_color
			_overlay.anchor_left = 1.0
			_overlay.offset_left = 0.0
			tween.tween_property(_overlay, "anchor_left", 0.0, duration)

		TransitionType.WIPE_UP:
			_overlay.color = _transition_color
			_overlay.anchor_top = 1.0
			_overlay.offset_top = 0.0
			tween.tween_property(_overlay, "anchor_top", 0.0, duration)

		TransitionType.WIPE_DOWN:
			_overlay.color = _transition_color
			_overlay.anchor_bottom = 0.0
			_overlay.offset_bottom = 0.0
			tween.tween_property(_overlay, "anchor_bottom", 1.0, duration)

		_:
			# Default to fade for unsupported types
			_overlay.color = Color(_transition_color.r, _transition_color.g, _transition_color.b, 0.0)
			tween.tween_property(_overlay, "color:a", 1.0, duration)


func _play_transition_in(type: TransitionType, duration: float) -> void:
	var tween := create_tween()

	match type:
		TransitionType.FADE, TransitionType.FADE_WHITE:
			tween.tween_property(_overlay, "color:a", 0.0, duration)

		TransitionType.WIPE_LEFT:
			_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
			tween.tween_property(_overlay, "anchor_left", 1.0, duration)

		TransitionType.WIPE_RIGHT:
			_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
			tween.tween_property(_overlay, "anchor_right", 0.0, duration)

		TransitionType.WIPE_UP:
			_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
			tween.tween_property(_overlay, "anchor_bottom", 0.0, duration)

		TransitionType.WIPE_DOWN:
			_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
			tween.tween_property(_overlay, "anchor_top", 1.0, duration)

		_:
			tween.tween_property(_overlay, "color:a", 0.0, duration)

	tween.tween_callback(_reset_overlay)


func _reset_overlay() -> void:
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.offset_left = 0
	_overlay.offset_right = 0
	_overlay.offset_top = 0
	_overlay.offset_bottom = 0
	_overlay.color.a = 0.0


func is_transitioning() -> bool:
	return _is_transitioning


## Quick fade for battle start
func battle_transition(scene_path: String) -> void:
	transition_to_scene(scene_path, TransitionType.WIPE_RIGHT, 0.5)


## Quick fade for returning to menu
func menu_transition(scene_path: String) -> void:
	transition_to_scene(scene_path, TransitionType.FADE, 0.3)
```

### Step 4.1.2: Register as autoload

**File**: `project.godot`
**Action**: Add to autoload section

**Find the `[autoload]` section and add**:
```ini
SceneTransition="*res://game/scene_transition.gd"
```

### Verification:
1. Restart Godot to load autoload
2. Call `SceneTransition.transition_to_scene("res://scenes/MainMenu.tscn")`
3. Screen fades to black, scene changes, fades back in
4. Transition is smooth and approximately 0.4 seconds total

---

## Task 4.2: Update GameController to Use Transitions

**Time**: 15 minutes
**File to modify**: `scripts/GameController.gd`

### Step 4.2.1: Add transition manager reference

**File**: `scripts/GameController.gd`
**Action**: Add at top of file

```gdscript
@onready var scene_transition = get_node_or_null("/root/SceneTransition")
```

### Step 4.2.2: Update all go_to methods

**File**: `scripts/GameController.gd`
**Action**: Replace all scene change calls

**Before**:
```gdscript
func go_to_menu() -> void:
	get_tree().change_scene_to_file(SCENE_MENU)

func go_to_map() -> void:
	get_tree().change_scene_to_file(SCENE_MAP)

func go_to_battle(node_id: String) -> void:
	next_battle_node_id = node_id
	last_battle_summary = {}
	get_tree().change_scene_to_file(SCENE_BATTLE)

func go_to_kingdom() -> void:
	get_tree().change_scene_to_file(SCENE_KINGDOM)

func go_to_settings() -> void:
	get_tree().change_scene_to_file(SCENE_SETTINGS)
```

**After**:
```gdscript
func go_to_menu() -> void:
	if scene_transition != null:
		scene_transition.menu_transition(SCENE_MENU)
	else:
		get_tree().change_scene_to_file(SCENE_MENU)


func go_to_map() -> void:
	if scene_transition != null:
		scene_transition.transition_to_scene(
			SCENE_MAP,
			scene_transition.TransitionType.FADE,
			0.4
		)
	else:
		get_tree().change_scene_to_file(SCENE_MAP)


func go_to_battle(node_id: String) -> void:
	next_battle_node_id = node_id
	last_battle_summary = {}
	if scene_transition != null:
		scene_transition.battle_transition(SCENE_BATTLE)
	else:
		get_tree().change_scene_to_file(SCENE_BATTLE)


func go_to_kingdom() -> void:
	if scene_transition != null:
		scene_transition.transition_to_scene(
			SCENE_KINGDOM,
			scene_transition.TransitionType.FADE,
			0.35
		)
	else:
		get_tree().change_scene_to_file(SCENE_KINGDOM)


func go_to_settings() -> void:
	if scene_transition != null:
		scene_transition.transition_to_scene(
			SCENE_SETTINGS,
			scene_transition.TransitionType.FADE,
			0.25
		)
	else:
		get_tree().change_scene_to_file(SCENE_SETTINGS)
```

### Verification:
1. Navigate between scenes using UI buttons
2. All scene changes now have smooth fade transitions
3. Battle entry uses wipe-right effect
4. Menu return uses faster fade

---

## Task 4.3: Add Battle Start Dramatic Effect

**Time**: 20 minutes
**File to modify**: `scripts/Battlefield.gd`

### Step 4.3.1: Add intro animation state

**File**: `scripts/Battlefield.gd`
**Action**: Add variables after existing state vars

```gdscript
# Battle intro animation
var _intro_playing: bool = false
var _intro_timer: float = 0.0
const INTRO_DURATION := 1.0
const INTRO_TEXT_DELAY := 0.3
```

### Step 4.3.2: Add intro animation method

**File**: `scripts/Battlefield.gd`
**Action**: Add new method

```gdscript
func _play_battle_intro() -> void:
	_intro_playing = true
	_intro_timer = 0.0

	# Disable input during intro
	drill_input_enabled = false

	# Animate elements in sequence
	var tween := create_tween()

	# Castle slides in from left
	if battle_stage != null and battle_stage.castle != null:
		var castle := battle_stage.castle
		var target_pos := castle.position
		castle.position.x -= 100
		castle.modulate.a = 0.0
		tween.tween_property(castle, "position:x", target_pos.x, 0.4).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(castle, "modulate:a", 1.0, 0.3)

	# Enemy slides in from right
	tween.tween_interval(0.2)
	if battle_stage != null and battle_stage.enemy != null:
		var enemy := battle_stage.enemy
		var target_pos := enemy.position
		enemy.position.x += 80
		enemy.modulate.a = 0.0
		tween.tween_property(enemy, "position:x", target_pos.x, 0.4).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(enemy, "modulate:a", 1.0, 0.3)

	# "BATTLE START" text flash
	tween.tween_interval(0.1)
	tween.tween_callback(_show_battle_start_text)

	# Wait then enable input
	tween.tween_interval(0.4)
	tween.tween_callback(func():
		_intro_playing = false
		drill_input_enabled = true
	)


func _show_battle_start_text() -> void:
	if feedback_label == null:
		return

	feedback_label.text = "BATTLE START!"
	feedback_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	feedback_label.modulate.a = 1.0
	feedback_label.scale = Vector2(1.5, 1.5)
	feedback_label.visible = true

	var tween := create_tween()
	tween.tween_property(feedback_label, "scale", Vector2.ONE, 0.3).set_ease(Tween.EASE_OUT)
	tween.tween_interval(0.5)
	tween.tween_property(feedback_label, "modulate:a", 0.0, 0.2)
```

### Step 4.3.3: Call intro in _ready

**File**: `scripts/Battlefield.gd`
**Action**: Add call at end of `_ready()` function

```gdscript
	# Play intro animation
	call_deferred("_play_battle_intro")
```

### Verification:
1. Start a battle
2. Castle slides in from left
3. Enemy slides in from right
4. "BATTLE START!" text flashes
5. Input is disabled during intro (can't type)
6. After ~1 second, typing is enabled

---

## Task 4.4: Add Victory/Defeat Screen Transition

**Time**: 20 minutes
**File to modify**: `scripts/Battlefield.gd`

### Step 4.4.1: Add victory animation

**File**: `scripts/Battlefield.gd`
**Action**: Add victory sequence method

```gdscript
func _play_victory_sequence() -> void:
	active = false

	# Screen flash
	var screen_shake = get_node_or_null("/root/ScreenShake")
	if screen_shake != null:
		screen_shake.add_trauma(0.3)

	# Play victory sound
	if audio_manager != null:
		audio_manager.play_sfx(audio_manager.SFX.VICTORY_FANFARE)

	# Show result panel with animation
	if result_panel != null:
		result_panel.visible = true
		result_panel.modulate.a = 0.0
		result_panel.scale = Vector2(0.8, 0.8)

		var tween := create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_BACK)
		tween.tween_property(result_panel, "modulate:a", 1.0, 0.3)
		tween.parallel().tween_property(result_panel, "scale", Vector2.ONE, 0.4)

	# Spawn victory particles if we have hit_effects
	if battle_stage != null:
		for i in range(5):
			await get_tree().create_timer(0.1).timeout
			if battle_stage.hit_effects != null and battle_stage.projectile_layer != null:
				var pos := Vector2(
					randf_range(100, 600),
					randf_range(100, 300)
				)
				battle_stage.hit_effects.spawn_word_complete_burst(
					battle_stage.projectile_layer,
					pos
				)
```

### Step 4.4.2: Add defeat animation

**File**: `scripts/Battlefield.gd`
**Action**: Add defeat sequence method

```gdscript
func _play_defeat_sequence() -> void:
	active = false

	# Heavy screen shake
	var screen_shake = get_node_or_null("/root/ScreenShake")
	if screen_shake != null:
		screen_shake.add_trauma(0.6)

	# Play defeat sound
	if audio_manager != null:
		audio_manager.play_sfx(audio_manager.SFX.DEFEAT_STINGER)

	# Dramatic pause
	var hit_pause = get_node_or_null("/root/HitPause")
	if hit_pause != null:
		hit_pause.pause(0.15)

	# Tint screen red briefly
	modulate = Color(1.2, 0.8, 0.8)
	var color_tween := create_tween()
	color_tween.tween_property(self, "modulate", Color.WHITE, 0.5)

	# Show result panel with shake
	if result_panel != null:
		result_panel.visible = true
		result_panel.modulate.a = 0.0

		await get_tree().create_timer(0.2).timeout

		var tween := create_tween()
		tween.tween_property(result_panel, "modulate:a", 1.0, 0.3)
```

### Step 4.4.3: Call sequences from game end logic

**File**: `scripts/Battlefield.gd`
**Action**: Find where victory/defeat is determined and call animations

**When victory**:
```gdscript
# Replace direct result_panel.visible = true with:
_play_victory_sequence()
```

**When defeat**:
```gdscript
# Replace direct result_panel.visible = true with:
_play_defeat_sequence()
```

### Verification:
1. Win a battle - screen flashes, particles spawn, panel scales in
2. Lose a battle - heavy shake, red tint, defeat sound, dramatic pause
3. Result panel appears smoothly in both cases

---

## Task 4.5: Add Loading Indicator for Transitions

**Time**: 15 minutes
**File to modify**: `game/scene_transition.gd`

### Step 4.5.1: Add loading spinner

**File**: `game/scene_transition.gd`
**Action**: Add loading indicator creation

**Add variables after _overlay**:
```gdscript
var _loading_indicator: Control = null
var _loading_rotation: float = 0.0
```

**Add setup method**:
```gdscript
func _setup_loading_indicator() -> void:
	_loading_indicator = Control.new()
	_loading_indicator.set_anchors_preset(Control.PRESET_CENTER)
	_loading_indicator.custom_minimum_size = Vector2(32, 32)
	_loading_indicator.visible = false
	add_child(_loading_indicator)

	# Draw simple spinner
	_loading_indicator.draw.connect(_draw_loading_spinner)


func _draw_loading_spinner() -> void:
	if _loading_indicator == null:
		return

	var center := Vector2(16, 16)
	var radius := 12.0
	var width := 3.0
	var color := Color(1.0, 1.0, 1.0, 0.8)

	# Draw arc (not full circle for spinner effect)
	var start_angle := _loading_rotation
	var end_angle := _loading_rotation + TAU * 0.7

	var points: PackedVector2Array = []
	var segments := 16
	for i in range(segments + 1):
		var t := float(i) / float(segments)
		var angle := lerp(start_angle, end_angle, t)
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)

	if points.size() >= 2:
		_loading_indicator.draw_polyline(points, color, width, true)
```

**Update `_ready()` to call setup**:
```gdscript
func _ready() -> void:
	layer = 100
	_setup_overlay()
	_setup_loading_indicator()
```

**Add rotation update in `_process()`**:
```gdscript
func _process(delta: float) -> void:
	if _loading_indicator != null and _loading_indicator.visible:
		_loading_rotation += delta * 5.0
		_loading_indicator.queue_redraw()
```

**Show/hide during transition**:
```gdscript
# In transition_to_scene, after transition_midpoint.emit():
_loading_indicator.visible = true

# In _play_transition_in, at start:
_loading_indicator.visible = false
```

### Verification:
1. Trigger a scene transition
2. During mid-transition (while loading), spinner appears at center
3. Spinner rotates smoothly
4. Spinner hides when reveal starts

---

## Task 4.6: Add Scene Entry Animations

**Time**: 15 minutes
**File to modify**: Various scene scripts

### Step 4.6.1: Create reusable entry animation

**File**: `ui/scene_entry.gd` (create new)

**Complete file contents**:

```gdscript
class_name SceneEntry
extends RefCounted
## Utility for animating scene elements on entry.

const STAGGER_DELAY := 0.08
const FADE_DURATION := 0.25
const SLIDE_DISTANCE := 30.0

## Animate a list of controls appearing in sequence
static func animate_entry(controls: Array[Control], from_direction: String = "up") -> void:
	var settings_manager = Engine.get_main_loop().root.get_node_or_null("/root/SettingsManager")
	if settings_manager != null and settings_manager.get("reduced_motion"):
		for control in controls:
			if control != null:
				control.visible = true
				control.modulate.a = 1.0
		return

	for i in range(controls.size()):
		var control := controls[i]
		if control == null:
			continue

		# Set initial hidden state
		control.modulate.a = 0.0
		var original_pos := control.position

		match from_direction:
			"up":
				control.position.y -= SLIDE_DISTANCE
			"down":
				control.position.y += SLIDE_DISTANCE
			"left":
				control.position.x -= SLIDE_DISTANCE
			"right":
				control.position.x += SLIDE_DISTANCE

		control.visible = true

		# Create delayed animation
		var tween := control.create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_QUAD)

		# Delay based on index
		if i > 0:
			tween.tween_interval(i * STAGGER_DELAY)

		tween.tween_property(control, "modulate:a", 1.0, FADE_DURATION)
		tween.parallel().tween_property(control, "position", original_pos, FADE_DURATION)
```

### Step 4.6.2: Use in MainMenu

**File**: `scripts/MainMenu.gd`
**Action**: Add entry animation

**Add at top**:
```gdscript
const SceneEntry = preload("res://ui/scene_entry.gd")
```

**Add in `_ready()` after UI setup**:
```gdscript
	# Animate menu items appearing
	var menu_items: Array[Control] = []
	# Add your menu buttons to this array
	if play_button != null:
		menu_items.append(play_button)
	if settings_button != null:
		menu_items.append(settings_button)
	if quit_button != null:
		menu_items.append(quit_button)

	SceneEntry.animate_entry(menu_items, "up")
```

### Verification:
1. Navigate to main menu
2. Menu buttons fade and slide in one after another
3. Stagger creates pleasant cascading effect
4. Works with reduced motion setting

---

## Summary Checklist

After completing all Phase 4 tasks, verify:

- [ ] Scene transitions use fade effect instead of hard cut
- [ ] Battle entry uses wipe-right transition
- [ ] Menu transitions are faster (0.3s)
- [ ] Battle has intro animation (castle/enemy slide in)
- [ ] "BATTLE START!" text flashes
- [ ] Victory shows particles and smooth panel entrance
- [ ] Defeat has heavy shake, red tint, dramatic pause
- [ ] Loading spinner appears during transition
- [ ] Menu items animate in with stagger

---

## Integration Points

### From any script that changes scenes:
```gdscript
# Instead of:
get_tree().change_scene_to_file("res://scenes/SomeScene.tscn")

# Use:
var scene_transition = get_node_or_null("/root/SceneTransition")
if scene_transition != null:
	scene_transition.transition_to_scene(
		"res://scenes/SomeScene.tscn",
		SceneTransition.TransitionType.FADE,
		0.4
	)
else:
	get_tree().change_scene_to_file("res://scenes/SomeScene.tscn")
```

### Custom transitions for specific scenarios:
```gdscript
# For boss battles (dramatic wipe)
scene_transition.transition_to_scene(
	boss_scene,
	SceneTransition.TransitionType.WIPE_RIGHT,
	0.6
)

# For death/defeat (fade to white)
scene_transition.transition_to_scene(
	menu_scene,
	SceneTransition.TransitionType.FADE_WHITE,
	0.5
)
```

---

## Files Modified/Created Summary

| File | Action | Lines Changed |
|------|--------|--------------|
| `game/scene_transition.gd` | Created | ~200 lines |
| `scripts/GameController.gd` | Modified | +30 lines |
| `scripts/Battlefield.gd` | Modified | +80 lines |
| `ui/scene_entry.gd` | Created | ~60 lines |
| `scripts/MainMenu.gd` | Modified | +15 lines |
| `project.godot` | Modified | +1 line (autoload) |

**Total new code**: ~385 lines
