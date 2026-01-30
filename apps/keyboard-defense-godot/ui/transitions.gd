class_name UITransitions
extends RefCounted
## Transition manager for consistent UI animations.
## Provides preset transitions for panels, scenes, and phase changes.
## Respects reduced motion accessibility setting.

# =============================================================================
# REDUCED MOTION SUPPORT
# =============================================================================

## Check if reduced motion is enabled
static func _should_reduce_motion() -> bool:
	var settings = Engine.get_main_loop().root.get_node_or_null("/root/SettingsManager")
	if settings:
		return bool(settings.reduced_motion)
	return false


## Get duration based on reduced motion setting
static func _get_duration(base_duration: float) -> float:
	if _should_reduce_motion():
		return 0.0
	return base_duration


# =============================================================================
# TRANSITION PRESETS
# =============================================================================

## Panel open/close presets
const PANEL_OPEN := {
	"duration": 0.25,
	"ease": Tween.EASE_OUT,
	"trans": Tween.TRANS_BACK,
	"fade_trans": Tween.TRANS_QUAD,
	"scale_from": Vector2(0.92, 0.92),
	"alpha_from": 0.0
}

const PANEL_CLOSE := {
	"duration": 0.15,
	"ease": Tween.EASE_IN,
	"trans": Tween.TRANS_QUAD,
	"scale_to": Vector2(0.95, 0.95),
	"alpha_to": 0.0
}

## Scene transition presets
const SCENE_FADE := {
	"duration": 0.4,
	"ease": Tween.EASE_IN_OUT,
	"trans": Tween.TRANS_SINE
}

const SCENE_SLIDE := {
	"duration": 0.35,
	"ease": Tween.EASE_OUT,
	"trans": Tween.TRANS_QUAD
}

## Phase transition presets
const PHASE_DAY := {
	"color": Color(0.98, 0.84, 0.44, 0.3),
	"duration": 0.6
}

const PHASE_NIGHT := {
	"color": Color(0.2, 0.3, 0.5, 0.4),
	"duration": 0.8
}

const PHASE_COMBAT := {
	"color": Color(0.96, 0.45, 0.45, 0.3),
	"duration": 0.4,
	"shake": true
}


# =============================================================================
# PANEL TRANSITIONS
# =============================================================================

## Animate panel opening (respects reduced motion)
static func open_panel(panel: Control, callback: Callable = Callable()) -> Tween:
	panel.visible = true

	var duration := _get_duration(PANEL_OPEN.duration)
	if duration <= 0:
		# Instant show for reduced motion
		panel.modulate.a = 1.0
		panel.scale = Vector2.ONE
		if callback.is_valid():
			callback.call()
		return null

	panel.modulate.a = PANEL_OPEN.alpha_from
	panel.scale = PANEL_OPEN.scale_from
	panel.pivot_offset = panel.size / 2

	var tween := panel.create_tween()
	tween.set_parallel(true)
	tween.set_ease(PANEL_OPEN.ease)

	# Fade: faster with TRANS_QUAD so content is visible before scale settles
	tween.tween_property(panel, "modulate:a", 1.0, duration * 0.6).set_trans(PANEL_OPEN.fade_trans)
	# Scale: full duration with TRANS_BACK for spring overshoot
	tween.tween_property(panel, "scale", Vector2.ONE, duration).set_trans(PANEL_OPEN.trans)

	if callback.is_valid():
		tween.chain().tween_callback(callback)

	return tween


## Animate panel closing (respects reduced motion)
static func close_panel(panel: Control, callback: Callable = Callable()) -> Tween:
	var duration := _get_duration(PANEL_CLOSE.duration)
	if duration <= 0:
		# Instant hide for reduced motion
		panel.visible = false
		if callback.is_valid():
			callback.call()
		return null

	panel.pivot_offset = panel.size / 2

	var tween := panel.create_tween()
	tween.set_parallel(true)
	tween.set_ease(PANEL_CLOSE.ease)
	tween.set_trans(PANEL_CLOSE.trans)

	tween.tween_property(panel, "modulate:a", PANEL_CLOSE.alpha_to, duration)
	tween.tween_property(panel, "scale", PANEL_CLOSE.scale_to, duration)

	tween.chain().tween_callback(func():
		panel.visible = false
		if callback.is_valid():
			callback.call()
	)

	return tween


## Animate panel slide in from direction
static func slide_in(panel: Control, from_direction: String = "bottom", callback: Callable = Callable()) -> Tween:
	var duration := _get_duration(SCENE_SLIDE.duration)
	if duration <= 0:
		panel.visible = true
		panel.modulate.a = 1.0
		if callback.is_valid():
			callback.call()
		return null

	panel.visible = true
	panel.modulate.a = 0.0

	var offset: Vector2
	match from_direction:
		"top":
			offset = Vector2(0, -50)
		"bottom":
			offset = Vector2(0, 50)
		"left":
			offset = Vector2(-50, 0)
		"right":
			offset = Vector2(50, 0)
		_:
			offset = Vector2(0, 50)

	var original_pos := panel.position
	panel.position = original_pos + offset

	var tween := panel.create_tween()
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUAD)

	tween.tween_property(panel, "modulate:a", 1.0, duration)
	tween.tween_property(panel, "position", original_pos, duration)

	if callback.is_valid():
		tween.chain().tween_callback(callback)

	return tween


## Animate panel slide out to direction
static func slide_out(panel: Control, to_direction: String = "bottom", callback: Callable = Callable()) -> Tween:
	var duration := _get_duration(SCENE_SLIDE.duration)
	if duration <= 0:
		panel.visible = false
		if callback.is_valid():
			callback.call()
		return null

	var offset: Vector2
	match to_direction:
		"top":
			offset = Vector2(0, -50)
		"bottom":
			offset = Vector2(0, 50)
		"left":
			offset = Vector2(-50, 0)
		"right":
			offset = Vector2(50, 0)
		_:
			offset = Vector2(0, 50)

	var original_pos := panel.position

	var tween := panel.create_tween()
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_QUAD)

	tween.tween_property(panel, "modulate:a", 0.0, duration)
	tween.tween_property(panel, "position", original_pos + offset, duration)

	tween.chain().tween_callback(func():
		panel.visible = false
		panel.position = original_pos
		if callback.is_valid():
			callback.call()
	)

	return tween


# =============================================================================
# SCENE TRANSITIONS
# =============================================================================

## Create a fade overlay for scene transitions
static func create_fade_overlay(parent: Node) -> ColorRect:
	var overlay := ColorRect.new()
	overlay.name = "TransitionOverlay"
	overlay.color = Color.BLACK
	overlay.color.a = 0.0
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 100
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(overlay)
	return overlay


## Fade to black
static func fade_out(overlay: ColorRect, callback: Callable = Callable()) -> Tween:
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.color.a = 0.0

	var tween := overlay.create_tween()
	tween.set_ease(SCENE_FADE.ease)
	tween.set_trans(SCENE_FADE.trans)

	tween.tween_property(overlay, "color:a", 1.0, SCENE_FADE.duration)

	if callback.is_valid():
		tween.chain().tween_callback(callback)

	return tween


## Fade from black
static func fade_in(overlay: ColorRect, callback: Callable = Callable()) -> Tween:
	overlay.color.a = 1.0

	var tween := overlay.create_tween()
	tween.set_ease(SCENE_FADE.ease)
	tween.set_trans(SCENE_FADE.trans)

	tween.tween_property(overlay, "color:a", 0.0, SCENE_FADE.duration)

	tween.chain().tween_callback(func():
		overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if callback.is_valid():
			callback.call()
	)

	return tween


## Full scene transition with callback between
static func transition_scene(overlay: ColorRect, middle_callback: Callable, end_callback: Callable = Callable()) -> void:
	fade_out(overlay, func():
		if middle_callback.is_valid():
			middle_callback.call()
		fade_in(overlay, end_callback)
	)


# =============================================================================
# PHASE TRANSITIONS
# =============================================================================

## Create a phase transition overlay effect
static func phase_transition(parent: Node, phase: String, callback: Callable = Callable()) -> void:
	var config: Dictionary
	match phase:
		"day":
			config = PHASE_DAY
		"night":
			config = PHASE_NIGHT
		"combat", "wave_assault":
			config = PHASE_COMBAT
		_:
			config = PHASE_DAY

	# Create flash overlay
	var flash := ColorRect.new()
	flash.color = config.color
	flash.color.a = 0.0
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flash.z_index = 99
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(flash)

	var tween := flash.create_tween()

	# Flash in
	tween.tween_property(flash, "color:a", config.color.a, config.duration * 0.3)

	# Hold
	tween.tween_interval(config.duration * 0.2)

	# Flash out
	tween.tween_property(flash, "color:a", 0.0, config.duration * 0.5)

	# Cleanup
	tween.chain().tween_callback(func():
		flash.queue_free()
		if callback.is_valid():
			callback.call()
	)

	# Add camera shake for combat
	if config.get("shake", false):
		_camera_shake(parent, 0.3)


## Simple camera shake effect (skipped if reduced motion enabled)
static func _camera_shake(node: Node, duration: float, intensity: float = 5.0) -> void:
	# Skip camera shake for reduced motion
	if _should_reduce_motion():
		return

	if not node is CanvasItem:
		return

	var canvas_item := node as CanvasItem
	var original_offset := Vector2.ZERO

	var tween := canvas_item.create_tween()
	var shake_count := int(duration / 0.05)

	for i in range(shake_count):
		var offset := Vector2(
			randf_range(-intensity, intensity),
			randf_range(-intensity, intensity)
		)
		# Decrease intensity over time
		offset *= (1.0 - float(i) / float(shake_count))
		tween.tween_callback(func(): canvas_item.position = original_offset + offset)
		tween.tween_interval(0.05)

	tween.tween_callback(func(): canvas_item.position = original_offset)


# =============================================================================
# ELEMENT TRANSITIONS
# =============================================================================

## Pop in effect for new elements (respects reduced motion)
static func pop_in(element: Control, delay: float = 0.0) -> Tween:
	if _should_reduce_motion():
		# Instant show for reduced motion
		element.scale = Vector2.ONE
		element.modulate.a = 1.0
		return null

	element.scale = Vector2.ZERO
	element.pivot_offset = element.size / 2
	element.modulate.a = 0.0

	var tween := element.create_tween()

	if delay > 0:
		tween.tween_interval(delay)

	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)

	tween.tween_property(element, "scale", Vector2.ONE, 0.3)
	tween.tween_property(element, "modulate:a", 1.0, 0.2)

	return tween


## Pop out effect for removing elements
static func pop_out(element: Control, callback: Callable = Callable()) -> Tween:
	element.pivot_offset = element.size / 2

	var tween := element.create_tween()
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_BACK)

	tween.tween_property(element, "scale", Vector2.ZERO, 0.2)
	tween.tween_property(element, "modulate:a", 0.0, 0.15)

	if callback.is_valid():
		tween.chain().tween_callback(callback)

	return tween


## Staggered animation for list items
static func stagger_in(elements: Array[Control], delay_between: float = 0.05) -> void:
	for i in range(elements.size()):
		var element: Control = elements[i]
		pop_in(element, float(i) * delay_between)


## Highlight flash effect
static func flash_highlight(element: Control, color: Color = ThemeColors.ACCENT) -> Tween:
	var original_modulate := element.modulate

	var tween := element.create_tween()
	tween.tween_property(element, "modulate", color * 1.5, 0.1)
	tween.tween_property(element, "modulate", original_modulate, 0.2)

	return tween


## Pulse attention effect (skipped if reduced motion enabled)
static func pulse_attention(element: Control, loops: int = 3) -> Tween:
	# Skip pulsing animations for reduced motion - use static highlight instead
	if _should_reduce_motion():
		return flash_highlight(element)

	element.pivot_offset = element.size / 2

	var tween := element.create_tween()
	tween.set_loops(loops)

	tween.tween_property(element, "scale", Vector2(1.05, 1.05), 0.15)
	tween.tween_property(element, "scale", Vector2.ONE, 0.15)

	return tween
