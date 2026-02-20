extends CanvasLayer
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

# Loading indicator
var _loading_indicator: Control = null
var _loading_rotation: float = 0.0


func _ready() -> void:
	layer = 100  # Render above everything
	_setup_overlay()
	_setup_loading_indicator()


func _process(delta: float) -> void:
	if _loading_indicator != null and _loading_indicator.visible:
		_loading_rotation += delta * 5.0
		_loading_indicator.queue_redraw()


func _setup_overlay() -> void:
	_overlay = ColorRect.new()
	_overlay.color = Color(0, 0, 0, 0)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_overlay)


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

	var center: Vector2 = Vector2(16, 16)
	var radius: float = 12.0
	var width: float = 3.0
	var color: Color = Color(1.0, 1.0, 1.0, 0.8)

	# Draw arc (not full circle for spinner effect)
	var start_angle: float = _loading_rotation
	var end_angle: float = _loading_rotation + TAU * 0.7

	var points: PackedVector2Array = []
	var segments: int = 16
	for i in range(segments + 1):
		var t: float = float(i) / float(segments)
		var angle: float = lerpf(start_angle, end_angle, t)
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)

	if points.size() >= 2:
		_loading_indicator.draw_polyline(points, color, width, true)


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

	# Show loading indicator
	_loading_indicator.visible = true

	# Change scene
	if not _pending_scene.is_empty():
		get_tree().change_scene_to_file(_pending_scene)

	# Wait a frame for scene to load
	await get_tree().process_frame

	# Hide loading indicator
	_loading_indicator.visible = false

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
	var tween: Tween = create_tween()

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
	var tween: Tween = create_tween()

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
