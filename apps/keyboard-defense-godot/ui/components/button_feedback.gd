class_name ButtonFeedback
extends RefCounted
## Utility class to add satisfying press/release animations to buttons

const PRESS_SCALE := 0.92
const RELEASE_SCALE := 1.0
const OVERSHOOT_SCALE := 1.06
const PRESS_DURATION := 0.08
const RELEASE_DURATION := 0.12
const OVERSHOOT_DURATION := 0.06

const HOVER_BRIGHTEN := 0.1
const HOVER_DURATION := 0.1

static var _button_tweens: Dictionary = {}  # Button -> Tween
static var _button_base_modulate: Dictionary = {}  # Button -> base modulate
static var _settings_manager = null

## Apply press/release feedback to a button
static func apply_to_button(button: BaseButton) -> void:
	if button == null:
		return

	# Store base modulate for hover effects
	_button_base_modulate[button] = button.modulate

	# Set pivot to center for scaling
	if button is Control:
		button.pivot_offset = button.size * 0.5

	# Connect signals
	if not button.button_down.is_connected(_on_button_down.bind(button)):
		button.button_down.connect(_on_button_down.bind(button))
	if not button.button_up.is_connected(_on_button_up.bind(button)):
		button.button_up.connect(_on_button_up.bind(button))
	if not button.mouse_entered.is_connected(_on_mouse_entered.bind(button)):
		button.mouse_entered.connect(_on_mouse_entered.bind(button))
	if not button.mouse_exited.is_connected(_on_mouse_exited.bind(button)):
		button.mouse_exited.connect(_on_mouse_exited.bind(button))

	# Listen for tree exit to clean up
	if not button.tree_exiting.is_connected(_on_button_tree_exiting.bind(button)):
		button.tree_exiting.connect(_on_button_tree_exiting.bind(button))

## Apply to all buttons in a container recursively
static func apply_to_container(container: Node) -> void:
	for child in container.get_children():
		if child is BaseButton:
			apply_to_button(child)
		if child.get_child_count() > 0:
			apply_to_container(child)

static func _on_button_down(button: BaseButton) -> void:
	if _is_reduced_motion():
		return

	_kill_tween(button)

	var tween := button.create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.tween_property(button, "scale", Vector2(PRESS_SCALE, PRESS_SCALE), PRESS_DURATION)
	_button_tweens[button] = tween

static func _on_button_up(button: BaseButton) -> void:
	if _is_reduced_motion():
		return

	_kill_tween(button)

	var tween := button.create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)

	# Scale up with overshoot, then settle
	tween.tween_property(button, "scale", Vector2(OVERSHOOT_SCALE, OVERSHOOT_SCALE), RELEASE_DURATION)
	tween.tween_property(button, "scale", Vector2(RELEASE_SCALE, RELEASE_SCALE), OVERSHOOT_DURATION)
	_button_tweens[button] = tween

static func _on_mouse_entered(button: BaseButton) -> void:
	if _is_reduced_motion():
		return

	var base_mod: Color = _button_base_modulate.get(button, Color.WHITE)
	var bright_mod := base_mod.lightened(HOVER_BRIGHTEN)

	var tween := button.create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "modulate", bright_mod, HOVER_DURATION)

static func _on_mouse_exited(button: BaseButton) -> void:
	if _is_reduced_motion():
		return

	var base_mod: Color = _button_base_modulate.get(button, Color.WHITE)

	var tween := button.create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "modulate", base_mod, HOVER_DURATION)

static func _on_button_tree_exiting(button: BaseButton) -> void:
	_kill_tween(button)
	_button_tweens.erase(button)
	_button_base_modulate.erase(button)

static func _kill_tween(button: BaseButton) -> void:
	if _button_tweens.has(button):
		var tween: Tween = _button_tweens[button]
		if tween != null and tween.is_valid():
			tween.kill()

static func _is_reduced_motion() -> bool:
	if _settings_manager == null:
		_settings_manager = Engine.get_main_loop().root.get_node_or_null("/root/SettingsManager")
	if _settings_manager != null and _settings_manager.get("reduced_motion") != null:
		return _settings_manager.reduced_motion
	return false
