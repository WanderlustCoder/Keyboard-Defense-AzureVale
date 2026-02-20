# Polish and Juice Implementation Guide

## Overview

This guide provides complete, copy-paste-ready GDScript code for all polish systems. Each section includes the full file contents and integration instructions.

---

## Part 1: Screen Shake System

### 1.1 Complete Implementation

**File**: `game/screen_shake.gd`

```gdscript
class_name ScreenShake
extends Node
## Screen shake system using noise-based trauma for natural feeling camera shake.
## Attach to the main camera or use as an autoload singleton.

## Emitted when shake intensity changes significantly
signal shake_intensity_changed(intensity: float)

## Current trauma level (0-1, affects shake intensity quadratically)
var trauma: float = 0.0

## How quickly trauma decays per second
var trauma_decay_rate: float = 0.8

## Maximum pixel offset for X and Y axes
var max_offset: Vector2 = Vector2(16.0, 12.0)

## Maximum rotation in radians
var max_rotation: float = 0.03

## Noise generator for organic movement
var _noise: FastNoiseLite

## Original camera offset (to return to)
var _original_offset: Vector2 = Vector2.ZERO

## The camera to shake (auto-detected or set manually)
var camera: Camera2D = null

## Whether shake is enabled (for accessibility)
var shake_enabled: bool = true

## Noise sample position (increments over time)
var _noise_y: float = 0.0


func _ready() -> void:
	# Setup noise generator
	_noise = FastNoiseLite.new()
	_noise.seed = randi()
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	_noise.frequency = 2.0

	# Try to find camera
	_find_camera()


func _find_camera() -> void:
	# Look for camera in common locations
	var viewport = get_viewport()
	if viewport:
		camera = viewport.get_camera_2d()

	if camera:
		_original_offset = camera.offset


## Set the camera to shake
func set_camera(cam: Camera2D) -> void:
	camera = cam
	if camera:
		_original_offset = camera.offset


## Add trauma to the shake system
## amount: 0.0 to 1.0 (will be clamped)
func add_trauma(amount: float) -> void:
	if not shake_enabled:
		return

	var old_trauma = trauma
	trauma = clampf(trauma + amount, 0.0, 1.0)

	if absf(trauma - old_trauma) > 0.1:
		shake_intensity_changed.emit(trauma)


## Immediately set trauma level
func set_trauma(amount: float) -> void:
	if not shake_enabled:
		return
	trauma = clampf(amount, 0.0, 1.0)


## Stop all shake immediately
func stop_shake() -> void:
	trauma = 0.0
	if camera:
		camera.offset = _original_offset
		camera.rotation = 0.0


func _process(delta: float) -> void:
	if not shake_enabled or trauma <= 0.0 or camera == null:
		return

	# Decay trauma over time
	trauma = maxf(trauma - trauma_decay_rate * delta, 0.0)

	# Calculate shake amount (quadratic for better feel)
	var shake_amount = trauma * trauma

	# Sample noise for organic movement
	_noise_y += delta * 50.0
	var noise_x = _noise.get_noise_2d(_noise_y, 0.0)
	var noise_y = _noise.get_noise_2d(0.0, _noise_y)
	var noise_rot = _noise.get_noise_2d(_noise_y, _noise_y)

	# Apply offset and rotation
	camera.offset = _original_offset + Vector2(
		noise_x * max_offset.x * shake_amount,
		noise_y * max_offset.y * shake_amount
	)
	camera.rotation = noise_rot * max_rotation * shake_amount

	# Reset when shake is done
	if trauma <= 0.0:
		camera.offset = _original_offset
		camera.rotation = 0.0


# =============================================================================
# PRESET SHAKE AMOUNTS
# =============================================================================

## Tiny shake - subtle feedback for minor events
func shake_tiny() -> void:
	add_trauma(0.05)


## Small shake - word completion, minor hits
func shake_small() -> void:
	add_trauma(0.1)


## Medium shake - enemy deaths, important events
func shake_medium() -> void:
	add_trauma(0.2)


## Large shake - castle damage, boss attacks
func shake_large() -> void:
	add_trauma(0.35)


## Huge shake - boss spawns, wave complete
func shake_huge() -> void:
	add_trauma(0.5)


## Maximum shake - game over, massive events
func shake_max() -> void:
	add_trauma(0.8)


# =============================================================================
# EVENT-SPECIFIC SHAKES
# =============================================================================

## Call when player types a word correctly
func on_word_complete() -> void:
	add_trauma(0.03)


## Call when player gets a critical hit
func on_critical_hit() -> void:
	add_trauma(0.12)


## Call when an enemy dies
func on_enemy_death() -> void:
	add_trauma(0.06)


## Call when castle takes damage
func on_castle_damage(damage_percent: float) -> void:
	# Scale shake with damage severity
	var shake_amount = clampf(damage_percent * 0.5, 0.15, 0.4)
	add_trauma(shake_amount)


## Call when boss spawns
func on_boss_spawn() -> void:
	add_trauma(0.4)


## Call when boss changes phase
func on_boss_phase() -> void:
	add_trauma(0.3)


## Call when wave is completed
func on_wave_complete() -> void:
	add_trauma(0.2)


## Call on game over
func on_game_over() -> void:
	add_trauma(0.6)
```

### 1.2 Integration

**In your main game controller or camera setup:**

```gdscript
# Option 1: As child of camera
var screen_shake = ScreenShake.new()
camera.add_child(screen_shake)
screen_shake.set_camera(camera)

# Option 2: As autoload (add to Project Settings > Autoload)
# Name: ScreenShake, Path: res://game/screen_shake.gd

# Usage anywhere:
ScreenShake.on_word_complete()
ScreenShake.on_enemy_death()
ScreenShake.on_castle_damage(0.1)  # 10% of max HP
```

---

## Part 2: Hit Pause System

### 2.1 Complete Implementation

**File**: `game/hit_pause.gd`

```gdscript
class_name HitPause
extends Node
## Hit pause/freeze frame system for impactful moments.
## Briefly pauses the game tree while allowing input to continue.

## Whether hit pause is enabled (for accessibility)
var pause_enabled: bool = true

## Current pause timer
var _pause_timer: float = 0.0

## Whether we're currently in a hit pause
var _is_paused: bool = false

## Store the original time scale
var _original_time_scale: float = 1.0

## Minimum time between pauses (prevents stacking)
var _cooldown: float = 0.0
const MIN_PAUSE_INTERVAL: float = 0.05


func _ready() -> void:
	# Ensure this node processes even when tree is paused
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(delta: float) -> void:
	# Handle cooldown
	if _cooldown > 0:
		_cooldown -= delta

	# Handle active pause
	if _is_paused and _pause_timer > 0:
		_pause_timer -= delta

		if _pause_timer <= 0:
			_end_pause()


## Pause the game for a duration (in seconds)
func pause(duration_seconds: float) -> void:
	if not pause_enabled:
		return

	if _cooldown > 0:
		return

	if duration_seconds <= 0:
		return

	_pause_timer = duration_seconds
	_is_paused = true
	_original_time_scale = Engine.time_scale

	# Slow time to near-zero (not full stop to allow processing)
	Engine.time_scale = 0.0001

	_cooldown = MIN_PAUSE_INTERVAL


## Pause for a duration in milliseconds (more intuitive)
func pause_ms(duration_ms: float) -> void:
	pause(duration_ms / 1000.0)


func _end_pause() -> void:
	_is_paused = false
	Engine.time_scale = _original_time_scale


## Cancel any active pause
func cancel_pause() -> void:
	if _is_paused:
		_end_pause()


## Check if currently paused
func is_paused() -> bool:
	return _is_paused


# =============================================================================
# PRESET PAUSE DURATIONS
# =============================================================================

## Micro pause - barely perceptible, satisfying snap
func pause_micro() -> void:
	pause_ms(20)


## Tiny pause - subtle feedback
func pause_tiny() -> void:
	pause_ms(35)


## Small pause - word completion
func pause_small() -> void:
	pause_ms(50)


## Medium pause - critical hit, enemy kill
func pause_medium() -> void:
	pause_ms(80)


## Large pause - boss hit, important moment
func pause_large() -> void:
	pause_ms(120)


## Huge pause - boss death, dramatic moment
func pause_huge() -> void:
	pause_ms(200)


# =============================================================================
# EVENT-SPECIFIC PAUSES
# =============================================================================

## Call when player completes a word
func on_word_complete() -> void:
	pause_ms(30)


## Call when player completes a word perfectly (no mistakes)
func on_word_perfect() -> void:
	pause_ms(50)


## Call when dealing a critical hit
func on_critical_hit() -> void:
	pause_ms(45)


## Call when killing an enemy
func on_enemy_death() -> void:
	pause_ms(25)


## Call when killing an elite enemy
func on_elite_death() -> void:
	pause_ms(60)


## Call when hitting a boss
func on_boss_hit() -> void:
	pause_ms(70)


## Call when killing a boss
func on_boss_death() -> void:
	pause_ms(180)


## Call when reaching a combo milestone
func on_combo_milestone() -> void:
	pause_ms(40)


## Call when castle takes significant damage
func on_castle_damage() -> void:
	pause_ms(100)
```

### 2.2 Integration

```gdscript
# As autoload or child node
# In combat code:
HitPause.on_word_complete()
HitPause.on_enemy_death()
HitPause.on_boss_death()
```

---

## Part 3: Damage Numbers System

### 3.1 Complete Implementation

**File**: `game/damage_numbers.gd`

```gdscript
class_name DamageNumbers
extends Node2D
## Floating damage number system with pooling for performance.

const ObjectPool = preload("res://game/object_pool.gd")

## Number types with their styling
enum NumberType {
	NORMAL,      # White, standard size
	CRITICAL,    # Gold, large, shake
	COMBO,       # Cyan, medium
	HEAL,        # Green
	SHIELD,      # Blue
	BLOCK,       # Gray, small
	OVERKILL,    # Red, extra large
	GOLD,        # Gold coins
	XP           # Purple, experience
}

## Style definitions
const STYLES: Dictionary = {
	NumberType.NORMAL: {
		"color": Color(1.0, 1.0, 1.0),
		"size": 16,
		"scale_pop": 1.2,
		"duration": 0.8,
		"rise_speed": 60,
		"shake": false
	},
	NumberType.CRITICAL: {
		"color": Color(1.0, 0.85, 0.2),  # Gold
		"size": 24,
		"scale_pop": 1.5,
		"duration": 1.0,
		"rise_speed": 80,
		"shake": true
	},
	NumberType.COMBO: {
		"color": Color(0.4, 0.9, 1.0),  # Cyan
		"size": 20,
		"scale_pop": 1.3,
		"duration": 0.9,
		"rise_speed": 70,
		"shake": false
	},
	NumberType.HEAL: {
		"color": Color(0.2, 0.9, 0.3),  # Green
		"size": 16,
		"scale_pop": 1.2,
		"duration": 0.8,
		"rise_speed": 50,
		"shake": false
	},
	NumberType.SHIELD: {
		"color": Color(0.3, 0.6, 1.0),  # Blue
		"size": 16,
		"scale_pop": 1.3,
		"duration": 0.7,
		"rise_speed": 40,
		"shake": false
	},
	NumberType.BLOCK: {
		"color": Color(0.6, 0.6, 0.6),  # Gray
		"size": 14,
		"scale_pop": 1.0,
		"duration": 0.6,
		"rise_speed": 30,
		"shake": false
	},
	NumberType.OVERKILL: {
		"color": Color(1.0, 0.2, 0.2),  # Red
		"size": 28,
		"scale_pop": 1.8,
		"duration": 1.2,
		"rise_speed": 100,
		"shake": true
	},
	NumberType.GOLD: {
		"color": Color(1.0, 0.85, 0.2),  # Gold
		"size": 16,
		"scale_pop": 1.2,
		"duration": 0.9,
		"rise_speed": 45,
		"shake": false
	},
	NumberType.XP: {
		"color": Color(0.7, 0.4, 1.0),  # Purple
		"size": 14,
		"scale_pop": 1.1,
		"duration": 0.8,
		"rise_speed": 55,
		"shake": false
	}
}

## Active number data
var _active_numbers: Array = []

## Pool for label nodes
var _label_pool: ObjectPool = null

## Font to use
var _font: Font = null

## Maximum active numbers (performance limit)
const MAX_ACTIVE: int = 50


func _ready() -> void:
	# Get default font
	_font = ThemeDB.fallback_font

	# Setup object pool
	_label_pool = ObjectPool.new(_create_label, _reset_label, MAX_ACTIVE * 2)
	_label_pool.set_parent(self)
	_label_pool.prewarm(20)


func _create_label() -> Label:
	var label = Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.visible = false
	return label


func _reset_label(label: Label) -> void:
	label.modulate = Color.WHITE
	label.scale = Vector2.ONE
	label.rotation = 0.0
	label.text = ""


## Spawn a damage number at a position
func spawn(pos: Vector2, value, type: NumberType = NumberType.NORMAL) -> void:
	if _active_numbers.size() >= MAX_ACTIVE:
		# Remove oldest
		_remove_number(0)

	var label: Label = _label_pool.acquire()
	if label == null:
		return

	var style: Dictionary = STYLES.get(type, STYLES[NumberType.NORMAL])

	# Format text
	var text: String
	if value is int or value is float:
		if type == NumberType.GOLD:
			text = "+%d" % int(value)
		elif type == NumberType.HEAL:
			text = "+%d" % int(value)
		else:
			text = str(int(value))
	else:
		text = str(value)

	label.text = text
	label.add_theme_font_size_override("font_size", style.size)
	label.add_theme_color_override("font_color", style.color)

	# Add outline for readability
	label.add_theme_constant_override("outline_size", 2)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))

	# Position with slight random offset
	var offset = Vector2(randf_range(-10, 10), randf_range(-5, 5))
	label.position = pos + offset
	label.pivot_offset = label.size / 2.0
	label.visible = true

	# Start scale animation
	label.scale = Vector2.ZERO

	# Store data for animation
	_active_numbers.append({
		"label": label,
		"lifetime": style.duration,
		"max_lifetime": style.duration,
		"rise_speed": style.rise_speed,
		"scale_pop": style.scale_pop,
		"shake": style.shake,
		"phase": "pop_in"  # pop_in, rising, fade_out
	})


func _process(delta: float) -> void:
	for i in range(_active_numbers.size() - 1, -1, -1):
		var data: Dictionary = _active_numbers[i]
		var label: Label = data.label

		if not is_instance_valid(label):
			_active_numbers.remove_at(i)
			continue

		data.lifetime -= delta

		if data.lifetime <= 0:
			_remove_number(i)
			continue

		var progress: float = 1.0 - (data.lifetime / data.max_lifetime)

		# Phase: Pop in (first 10%)
		if progress < 0.1:
			var pop_progress = progress / 0.1
			label.scale = Vector2.ONE * data.scale_pop * pop_progress
		# Phase: Pop settle (10-20%)
		elif progress < 0.2:
			var settle_progress = (progress - 0.1) / 0.1
			var scale_val = lerpf(data.scale_pop, 1.0, settle_progress)
			label.scale = Vector2.ONE * scale_val
		# Phase: Rising
		else:
			label.scale = Vector2.ONE

		# Rise upward
		label.position.y -= data.rise_speed * delta

		# Shake for critical/overkill
		if data.shake and progress < 0.5:
			label.position.x += randf_range(-2, 2)

		# Fade out in last 30%
		if progress > 0.7:
			var fade_progress = (progress - 0.7) / 0.3
			label.modulate.a = 1.0 - fade_progress


func _remove_number(index: int) -> void:
	if index < 0 or index >= _active_numbers.size():
		return

	var data: Dictionary = _active_numbers[index]
	var label: Label = data.label

	if is_instance_valid(label):
		label.visible = false
		_label_pool.release(label)

	_active_numbers.remove_at(index)


## Clear all active numbers
func clear() -> void:
	for i in range(_active_numbers.size() - 1, -1, -1):
		_remove_number(i)


# =============================================================================
# CONVENIENCE METHODS
# =============================================================================

func spawn_damage(pos: Vector2, amount: int) -> void:
	spawn(pos, amount, NumberType.NORMAL)


func spawn_critical(pos: Vector2, amount: int) -> void:
	spawn(pos, amount, NumberType.CRITICAL)


func spawn_combo(pos: Vector2, multiplier: int) -> void:
	spawn(pos, "%dx" % multiplier, NumberType.COMBO)


func spawn_heal(pos: Vector2, amount: int) -> void:
	spawn(pos, amount, NumberType.HEAL)


func spawn_shield(pos: Vector2, amount: int) -> void:
	spawn(pos, amount, NumberType.SHIELD)


func spawn_block(pos: Vector2) -> void:
	spawn(pos, "BLOCK", NumberType.BLOCK)


func spawn_overkill(pos: Vector2, amount: int) -> void:
	spawn(pos, amount, NumberType.OVERKILL)


func spawn_gold(pos: Vector2, amount: int) -> void:
	spawn(pos, amount, NumberType.GOLD)


func spawn_xp(pos: Vector2, amount: int) -> void:
	spawn(pos, "+%d XP" % amount, NumberType.XP)
```

### 3.2 Integration

```gdscript
# Add DamageNumbers as child of your game world
var damage_numbers = DamageNumbers.new()
world_node.add_child(damage_numbers)

# Usage:
damage_numbers.spawn_damage(enemy.position, 25)
damage_numbers.spawn_critical(enemy.position, 50)
damage_numbers.spawn_combo(player.position, 5)
damage_numbers.spawn_heal(player.position, 10)
damage_numbers.spawn_gold(enemy.position, 15)
```

---

## Part 4: Screen Transitions

### 4.1 Complete Implementation

**File**: `game/screen_transition.gd`

```gdscript
class_name ScreenTransition
extends CanvasLayer
## Screen transition effects for scene changes.

signal transition_midpoint  # Emitted at the darkest point
signal transition_complete  # Emitted when transition finishes

enum TransitionType {
	FADE,       # Simple fade to black
	WIPE_LEFT,  # Horizontal wipe from right to left
	WIPE_RIGHT, # Horizontal wipe from left to right
	WIPE_UP,    # Vertical wipe from bottom to top
	WIPE_DOWN,  # Vertical wipe from top to bottom
	CIRCLE_IN,  # Circle closing in
	CIRCLE_OUT, # Circle expanding out
	PIXELATE,   # Pixelate dissolve
}

## The overlay rect
var _overlay: ColorRect = null

## Current transition state
var _transitioning: bool = false

## Transition parameters
var _duration: float = 0.5
var _type: TransitionType = TransitionType.FADE
var _callback: Callable = Callable()


func _ready() -> void:
	layer = 100  # Above everything
	_setup_overlay()


func _setup_overlay() -> void:
	_overlay = ColorRect.new()
	_overlay.color = Color.BLACK
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.modulate.a = 0.0
	add_child(_overlay)


## Start a transition, call the callback at midpoint, then finish
func transition(
	type: TransitionType = TransitionType.FADE,
	duration: float = 0.5,
	callback: Callable = Callable()
) -> void:
	if _transitioning:
		return

	_transitioning = true
	_type = type
	_duration = duration
	_callback = callback

	match type:
		TransitionType.FADE:
			_do_fade_transition()
		TransitionType.WIPE_LEFT, TransitionType.WIPE_RIGHT, \
		TransitionType.WIPE_UP, TransitionType.WIPE_DOWN:
			_do_wipe_transition()
		TransitionType.CIRCLE_IN, TransitionType.CIRCLE_OUT:
			_do_circle_transition()
		TransitionType.PIXELATE:
			_do_pixelate_transition()
		_:
			_do_fade_transition()


func _do_fade_transition() -> void:
	var tween = create_tween()

	# Fade in
	tween.tween_property(_overlay, "modulate:a", 1.0, _duration / 2.0)
	tween.tween_callback(_on_midpoint)

	# Fade out
	tween.tween_property(_overlay, "modulate:a", 0.0, _duration / 2.0)
	tween.tween_callback(_on_complete)


func _do_wipe_transition() -> void:
	var tween = create_tween()

	# Setup wipe direction
	var start_pos: Vector2
	var mid_pos: Vector2
	var end_pos: Vector2
	var viewport_size = get_viewport().get_visible_rect().size

	match _type:
		TransitionType.WIPE_LEFT:
			_overlay.size = Vector2(viewport_size.x + 100, viewport_size.y)
			start_pos = Vector2(viewport_size.x, 0)
			mid_pos = Vector2(0, 0)
			end_pos = Vector2(-viewport_size.x - 100, 0)
		TransitionType.WIPE_RIGHT:
			_overlay.size = Vector2(viewport_size.x + 100, viewport_size.y)
			start_pos = Vector2(-viewport_size.x - 100, 0)
			mid_pos = Vector2(0, 0)
			end_pos = Vector2(viewport_size.x, 0)
		TransitionType.WIPE_UP:
			_overlay.size = Vector2(viewport_size.x, viewport_size.y + 100)
			start_pos = Vector2(0, viewport_size.y)
			mid_pos = Vector2(0, 0)
			end_pos = Vector2(0, -viewport_size.y - 100)
		TransitionType.WIPE_DOWN:
			_overlay.size = Vector2(viewport_size.x, viewport_size.y + 100)
			start_pos = Vector2(0, -viewport_size.y - 100)
			mid_pos = Vector2(0, 0)
			end_pos = Vector2(0, viewport_size.y)

	_overlay.position = start_pos
	_overlay.modulate.a = 1.0

	# Wipe in
	tween.tween_property(_overlay, "position", mid_pos, _duration / 2.0)
	tween.tween_callback(_on_midpoint)

	# Wipe out
	tween.tween_property(_overlay, "position", end_pos, _duration / 2.0)
	tween.tween_callback(_on_complete)


func _do_circle_transition() -> void:
	# This would use a shader for proper circle mask
	# Falling back to fade for simplicity
	_do_fade_transition()


func _do_pixelate_transition() -> void:
	# This would use a pixelate shader
	# Falling back to fade for simplicity
	_do_fade_transition()


func _on_midpoint() -> void:
	transition_midpoint.emit()
	if _callback.is_valid():
		_callback.call()


func _on_complete() -> void:
	_transitioning = false
	_overlay.modulate.a = 0.0
	_overlay.position = Vector2.ZERO
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	transition_complete.emit()


## Quick scene change with fade
func change_scene(scene_path: String, duration: float = 0.5) -> void:
	transition(TransitionType.FADE, duration, func():
		get_tree().change_scene_to_file(scene_path)
	)


## Quick scene change with wipe
func wipe_to_scene(scene_path: String, direction: TransitionType = TransitionType.WIPE_LEFT) -> void:
	transition(direction, 0.4, func():
		get_tree().change_scene_to_file(scene_path)
	)


## Check if currently transitioning
func is_transitioning() -> bool:
	return _transitioning
```

### 4.2 Integration

```gdscript
# Add as autoload or scene child
var transition = ScreenTransition.new()
add_child(transition)

# Usage:
transition.change_scene("res://scenes/MainMenu.tscn")
transition.wipe_to_scene("res://scenes/Game.tscn", ScreenTransition.TransitionType.WIPE_LEFT)

# Or with custom callback:
transition.transition(ScreenTransition.TransitionType.FADE, 0.5, func():
	# Do something at midpoint
	load_next_level()
)
```

---

## Part 5: Input Flash Feedback

### 5.1 Implementation in Typing Display

Add these functions to your typing display component:

```gdscript
# Add to ui/components/typing_display.gd or similar

## Flash effect for correct input
func flash_correct(char_index: int) -> void:
	var char_node = _get_character_node(char_index)
	if char_node == null:
		return

	# Create white flash overlay
	var flash = ColorRect.new()
	flash.color = Color(1, 1, 1, 0.6)
	flash.size = char_node.size
	flash.position = char_node.position
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(flash)

	# Animate flash
	var tween = create_tween()
	tween.tween_property(flash, "modulate:a", 0.0, 0.15)
	tween.tween_callback(flash.queue_free)

	# Also color the character green
	char_node.add_theme_color_override("font_color", Color(0.2, 0.9, 0.3))


## Flash effect for incorrect input
func flash_error(char_index: int) -> void:
	var char_node = _get_character_node(char_index)
	if char_node == null:
		return

	# Create red flash overlay
	var flash = ColorRect.new()
	flash.color = Color(1, 0.2, 0.2, 0.6)
	flash.size = char_node.size
	flash.position = char_node.position
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(flash)

	# Store original position for shake
	var original_pos = char_node.position

	# Animate flash and shake
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(flash, "modulate:a", 0.0, 0.2)

	# Shake sequence
	var shake_tween = create_tween()
	shake_tween.tween_property(char_node, "position:x", original_pos.x + 3, 0.03)
	shake_tween.tween_property(char_node, "position:x", original_pos.x - 3, 0.03)
	shake_tween.tween_property(char_node, "position:x", original_pos.x + 2, 0.03)
	shake_tween.tween_property(char_node, "position:x", original_pos.x, 0.03)

	tween.tween_callback(flash.queue_free)


## Celebrate word completion
func celebrate_word_complete() -> void:
	# Flash all characters gold
	for i in range(_character_count):
		var char_node = _get_character_node(i)
		if char_node == null:
			continue

		# Stagger the gold flash
		var delay = i * 0.03
		var tween = create_tween()
		tween.tween_interval(delay)
		tween.tween_property(char_node, "modulate", Color(1.0, 0.85, 0.3), 0.1)
		tween.tween_property(char_node, "modulate", Color.WHITE, 0.2)

	# Scale pulse the whole word
	var container_tween = create_tween()
	container_tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.1)
	container_tween.tween_property(self, "scale", Vector2.ONE, 0.15)
```

---

## Part 6: Combo Visual System

### 6.1 Complete Implementation

**File**: `ui/components/combo_display.gd`

```gdscript
class_name ComboDisplay
extends Control
## Visual combo counter with scaling, glow, and particle effects.

## Current combo value
var combo: int = 0:
	set(value):
		var old = combo
		combo = value
		_on_combo_changed(old, value)

## The label showing the combo number
var _combo_label: Label = null

## The multiplier label
var _multiplier_label: Label = null

## Container for effects
var _effects_container: Control = null

## Particle timer
var _particle_timer: float = 0.0

## Color thresholds
const COMBO_COLORS: Dictionary = {
	0: Color(1.0, 1.0, 1.0),      # White
	5: Color(0.4, 0.9, 1.0),      # Cyan
	10: Color(0.2, 0.9, 0.3),     # Green
	20: Color(1.0, 0.85, 0.3),    # Gold
	35: Color(1.0, 0.5, 0.2),     # Orange
	50: Color(1.0, 0.2, 0.5)      # Pink/Red
}

## Scale thresholds
const COMBO_SCALES: Dictionary = {
	0: 1.0,
	5: 1.1,
	10: 1.2,
	20: 1.3,
	35: 1.4,
	50: 1.5
}


func _ready() -> void:
	_setup_ui()


func _setup_ui() -> void:
	# Main container
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(vbox)

	# Combo number
	_combo_label = Label.new()
	_combo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_combo_label.add_theme_font_size_override("font_size", 32)
	_combo_label.add_theme_constant_override("outline_size", 3)
	_combo_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	vbox.add_child(_combo_label)

	# Multiplier text
	_multiplier_label = Label.new()
	_multiplier_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_multiplier_label.add_theme_font_size_override("font_size", 16)
	_multiplier_label.text = "COMBO"
	vbox.add_child(_multiplier_label)

	# Effects container
	_effects_container = Control.new()
	add_child(_effects_container)

	# Initial update
	_update_display()


func _on_combo_changed(old_value: int, new_value: int) -> void:
	_update_display()

	if new_value > old_value:
		_play_increase_effect()
	elif new_value == 0 and old_value > 0:
		_play_break_effect()


func _update_display() -> void:
	if _combo_label == null:
		return

	_combo_label.text = str(combo)

	# Get color for current combo
	var color = _get_color_for_combo(combo)
	_combo_label.add_theme_color_override("font_color", color)
	_multiplier_label.add_theme_color_override("font_color", color.darkened(0.2))

	# Get scale for current combo
	var target_scale = _get_scale_for_combo(combo)
	scale = Vector2(target_scale, target_scale)

	# Update multiplier text
	var multiplier = _get_multiplier_for_combo(combo)
	_multiplier_label.text = "%dx COMBO" % multiplier


func _get_color_for_combo(value: int) -> Color:
	var result_color = COMBO_COLORS[0]
	for threshold in COMBO_COLORS.keys():
		if value >= threshold:
			result_color = COMBO_COLORS[threshold]
	return result_color


func _get_scale_for_combo(value: int) -> float:
	var result_scale = COMBO_SCALES[0]
	for threshold in COMBO_SCALES.keys():
		if value >= threshold:
			result_scale = COMBO_SCALES[threshold]
	return result_scale


func _get_multiplier_for_combo(value: int) -> int:
	if value >= 50:
		return 5
	elif value >= 35:
		return 4
	elif value >= 20:
		return 3
	elif value >= 10:
		return 2
	else:
		return 1


func _play_increase_effect() -> void:
	# Scale pop
	var tween = create_tween()
	var current_scale = scale
	tween.tween_property(self, "scale", current_scale * 1.2, 0.08)
	tween.tween_property(self, "scale", current_scale, 0.12)


func _play_break_effect() -> void:
	# Shake and fade
	var original_pos = position
	var tween = create_tween()

	# Shake
	for i in range(3):
		tween.tween_property(self, "position:x", original_pos.x + 5, 0.02)
		tween.tween_property(self, "position:x", original_pos.x - 5, 0.02)
	tween.tween_property(self, "position", original_pos, 0.02)

	# Flash red
	tween.tween_property(_combo_label, "modulate", Color(1, 0.3, 0.3), 0.1)
	tween.tween_property(_combo_label, "modulate", Color.WHITE, 0.2)


func _process(delta: float) -> void:
	# Spawn particles for high combos
	if combo >= 20:
		_particle_timer += delta
		if _particle_timer >= 0.1:
			_particle_timer = 0.0
			_spawn_combo_particle()


func _spawn_combo_particle() -> void:
	var particle = ColorRect.new()
	particle.size = Vector2(4, 4)
	particle.color = _get_color_for_combo(combo)
	particle.position = Vector2(
		randf_range(-20, 20),
		randf_range(-10, 10)
	)
	_effects_container.add_child(particle)

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(particle, "position:y", particle.position.y - 30, 0.5)
	tween.tween_property(particle, "modulate:a", 0.0, 0.5)
	tween.tween_callback(particle.queue_free)
```

---

## Part 7: Integration Checklist

### 7.1 Files to Create

| File | Purpose |
|------|---------|
| `game/screen_shake.gd` | Screen shake system |
| `game/hit_pause.gd` | Hit pause/freeze frames |
| `game/damage_numbers.gd` | Floating damage numbers |
| `game/screen_transition.gd` | Scene transitions |
| `ui/components/combo_display.gd` | Combo counter visuals |

### 7.2 Autoload Setup

Add to Project Settings > AutoLoad:
- `ScreenShake` - `res://game/screen_shake.gd`
- `HitPause` - `res://game/hit_pause.gd`
- `ScreenTransition` - `res://game/screen_transition.gd`

### 7.3 Event Wiring

**In your combat/typing controller:**

```gdscript
func _on_word_completed(word: String, perfect: bool) -> void:
	# Audio
	if perfect:
		AudioManager.play_sfx("word_perfect")
	else:
		AudioManager.play_sfx("word_complete")

	# Screen shake
	ScreenShake.on_word_complete()

	# Hit pause
	if perfect:
		HitPause.on_word_perfect()
	else:
		HitPause.on_word_complete()

	# Damage numbers (if showing score)
	var score = calculate_word_score(word, perfect)
	damage_numbers.spawn(word_position, score, DamageNumbers.NumberType.COMBO)


func _on_enemy_killed(enemy: Dictionary, damage: int, overkill: int) -> void:
	var pos = Vector2(enemy.x, enemy.y)

	# Audio
	AudioManager.play_sfx("enemy_death")

	# Screen shake
	ScreenShake.on_enemy_death()

	# Hit pause
	HitPause.on_enemy_death()

	# Damage number
	if overkill > 0:
		damage_numbers.spawn_overkill(pos, damage)
	else:
		damage_numbers.spawn_damage(pos, damage)


func _on_castle_damaged(damage: int, current_hp: int, max_hp: int) -> void:
	var damage_percent = float(damage) / float(max_hp)

	# Audio
	AudioManager.play_sfx("hit_player")

	# Screen shake (scaled by damage)
	ScreenShake.on_castle_damage(damage_percent)

	# Hit pause
	HitPause.on_castle_damage()
```

---

## Part 8: Testing

### 8.1 Test Each System

```gdscript
# Create a test scene or add to debug menu

func test_screen_shake() -> void:
	ScreenShake.shake_tiny()
	await get_tree().create_timer(0.5).timeout
	ScreenShake.shake_small()
	await get_tree().create_timer(0.5).timeout
	ScreenShake.shake_medium()
	await get_tree().create_timer(0.5).timeout
	ScreenShake.shake_large()
	await get_tree().create_timer(0.5).timeout
	ScreenShake.shake_huge()

func test_hit_pause() -> void:
	HitPause.pause_micro()
	await get_tree().create_timer(0.3).timeout
	HitPause.pause_small()
	await get_tree().create_timer(0.3).timeout
	HitPause.pause_medium()
	await get_tree().create_timer(0.3).timeout
	HitPause.pause_large()

func test_damage_numbers() -> void:
	var pos = Vector2(200, 200)
	damage_numbers.spawn_damage(pos, 25)
	await get_tree().create_timer(0.2).timeout
	damage_numbers.spawn_critical(pos + Vector2(50, 0), 100)
	await get_tree().create_timer(0.2).timeout
	damage_numbers.spawn_heal(pos + Vector2(100, 0), 15)
	await get_tree().create_timer(0.2).timeout
	damage_numbers.spawn_gold(pos + Vector2(150, 0), 50)
```

### 8.2 Performance Verification

- Screen shake: No impact (just camera offset)
- Hit pause: Minimal (time scale change)
- Damage numbers: Check pool stats, ensure < 50 active
- Transitions: Verify smooth 60 FPS

### 8.3 Accessibility Verification

```gdscript
# Test with reduced motion
ScreenShake.shake_enabled = false
HitPause.pause_enabled = false

# Verify game still provides feedback through:
# - Audio cues
# - Color changes
# - Text feedback
```
