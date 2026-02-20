class_name PanelTransitions
extends RefCounted
## Utility class for animated panel show/hide transitions.
## Supports slide, fade, scale, and combo transitions.

enum TransitionType {
	FADE,
	SLIDE_LEFT,
	SLIDE_RIGHT,
	SLIDE_UP,
	SLIDE_DOWN,
	SCALE,
	SCALE_FADE,
	SLIDE_FADE_LEFT,
	SLIDE_FADE_RIGHT
}

const DEFAULT_DURATION := 0.25
const DEFAULT_EASE := Tween.EASE_OUT
const DEFAULT_TRANS := Tween.TRANS_QUAD
const OVERSHOOT_TRANS := Tween.TRANS_BACK

static var _panel_tweens: Dictionary = {}  # Control -> Tween
static var _panel_positions: Dictionary = {}  # Control -> original position
static var _settings_manager = null


## Show a panel with animation
static func show_panel(
	panel: Control,
	transition: TransitionType = TransitionType.SCALE_FADE,
	duration: float = DEFAULT_DURATION,
	callback: Callable = Callable()
) -> void:
	if panel == null or not panel.is_inside_tree():
		return

	if _is_reduced_motion():
		panel.visible = true
		panel.modulate.a = 1.0
		panel.scale = Vector2.ONE
		if callback.is_valid():
			callback.call()
		return

	_kill_tween(panel)
	_store_position(panel)

	# Reset to hidden state first
	match transition:
		TransitionType.FADE:
			panel.modulate.a = 0.0
		TransitionType.SLIDE_LEFT:
			panel.position.x = _panel_positions[panel].x - 50.0
		TransitionType.SLIDE_RIGHT:
			panel.position.x = _panel_positions[panel].x + 50.0
		TransitionType.SLIDE_UP:
			panel.position.y = _panel_positions[panel].y - 30.0
		TransitionType.SLIDE_DOWN:
			panel.position.y = _panel_positions[panel].y + 30.0
		TransitionType.SCALE:
			panel.scale = Vector2(0.8, 0.8)
			panel.pivot_offset = panel.size * 0.5
		TransitionType.SCALE_FADE:
			panel.modulate.a = 0.0
			panel.scale = Vector2(0.9, 0.9)
			panel.pivot_offset = panel.size * 0.5
		TransitionType.SLIDE_FADE_LEFT:
			panel.modulate.a = 0.0
			panel.position.x = _panel_positions[panel].x - 30.0
		TransitionType.SLIDE_FADE_RIGHT:
			panel.modulate.a = 0.0
			panel.position.x = _panel_positions[panel].x + 30.0

	panel.visible = true

	var tween := panel.create_tween()
	if tween == null:
		return

	tween.set_parallel(true)
	tween.set_ease(DEFAULT_EASE)

	match transition:
		TransitionType.FADE:
			tween.set_trans(DEFAULT_TRANS)
			tween.tween_property(panel, "modulate:a", 1.0, duration)
		TransitionType.SLIDE_LEFT, TransitionType.SLIDE_RIGHT:
			tween.set_trans(OVERSHOOT_TRANS)
			tween.tween_property(panel, "position:x", _panel_positions[panel].x, duration)
		TransitionType.SLIDE_UP, TransitionType.SLIDE_DOWN:
			tween.set_trans(OVERSHOOT_TRANS)
			tween.tween_property(panel, "position:y", _panel_positions[panel].y, duration)
		TransitionType.SCALE:
			tween.set_trans(OVERSHOOT_TRANS)
			tween.tween_property(panel, "scale", Vector2.ONE, duration)
		TransitionType.SCALE_FADE:
			tween.set_trans(OVERSHOOT_TRANS)
			tween.tween_property(panel, "modulate:a", 1.0, duration * 0.6)
			tween.tween_property(panel, "scale", Vector2.ONE, duration)
		TransitionType.SLIDE_FADE_LEFT, TransitionType.SLIDE_FADE_RIGHT:
			tween.set_trans(DEFAULT_TRANS)
			tween.tween_property(panel, "modulate:a", 1.0, duration)
			tween.tween_property(panel, "position:x", _panel_positions[panel].x, duration)

	if callback.is_valid():
		tween.chain().tween_callback(callback)

	_panel_tweens[panel] = tween


## Hide a panel with animation
static func hide_panel(
	panel: Control,
	transition: TransitionType = TransitionType.SCALE_FADE,
	duration: float = DEFAULT_DURATION,
	callback: Callable = Callable()
) -> void:
	if panel == null or not panel.is_inside_tree():
		return

	if _is_reduced_motion():
		panel.visible = false
		if callback.is_valid():
			callback.call()
		return

	_kill_tween(panel)
	_store_position(panel)

	var tween := panel.create_tween()
	if tween == null:
		return

	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(DEFAULT_TRANS)

	match transition:
		TransitionType.FADE:
			tween.tween_property(panel, "modulate:a", 0.0, duration)
		TransitionType.SLIDE_LEFT:
			tween.tween_property(panel, "position:x", panel.position.x - 50.0, duration)
		TransitionType.SLIDE_RIGHT:
			tween.tween_property(panel, "position:x", panel.position.x + 50.0, duration)
		TransitionType.SLIDE_UP:
			tween.tween_property(panel, "position:y", panel.position.y - 30.0, duration)
		TransitionType.SLIDE_DOWN:
			tween.tween_property(panel, "position:y", panel.position.y + 30.0, duration)
		TransitionType.SCALE:
			tween.tween_property(panel, "scale", Vector2(0.8, 0.8), duration)
		TransitionType.SCALE_FADE:
			tween.tween_property(panel, "modulate:a", 0.0, duration)
			tween.tween_property(panel, "scale", Vector2(0.9, 0.9), duration)
		TransitionType.SLIDE_FADE_LEFT:
			tween.tween_property(panel, "modulate:a", 0.0, duration)
			tween.tween_property(panel, "position:x", panel.position.x - 30.0, duration)
		TransitionType.SLIDE_FADE_RIGHT:
			tween.tween_property(panel, "modulate:a", 0.0, duration)
			tween.tween_property(panel, "position:x", panel.position.x + 30.0, duration)

	tween.chain().tween_callback(func():
		panel.visible = false
		_restore_position(panel)
		if callback.is_valid():
			callback.call()
	)

	_panel_tweens[panel] = tween


## Toggle panel visibility with animation
static func toggle_panel(
	panel: Control,
	transition: TransitionType = TransitionType.SCALE_FADE,
	duration: float = DEFAULT_DURATION
) -> void:
	if panel == null:
		return
	if panel.visible:
		hide_panel(panel, transition, duration)
	else:
		show_panel(panel, transition, duration)


static func _store_position(panel: Control) -> void:
	if not _panel_positions.has(panel):
		_panel_positions[panel] = panel.position


static func _restore_position(panel: Control) -> void:
	if _panel_positions.has(panel):
		panel.position = _panel_positions[panel]


static func _kill_tween(panel: Control) -> void:
	if _panel_tweens.has(panel):
		var tween: Tween = _panel_tweens[panel]
		if tween != null and tween.is_valid():
			tween.kill()
		_panel_tweens.erase(panel)


static func _is_reduced_motion() -> bool:
	if _settings_manager == null:
		var tree = Engine.get_main_loop()
		if tree != null and tree.root != null:
			_settings_manager = tree.root.get_node_or_null("/root/SettingsManager")
	if _settings_manager != null and _settings_manager.get("reduced_motion") != null:
		return _settings_manager.reduced_motion
	return false
