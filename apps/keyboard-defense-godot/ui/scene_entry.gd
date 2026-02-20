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
		var control: Control = controls[i]
		if control == null:
			continue

		# Set initial hidden state
		control.modulate.a = 0.0
		var original_pos: Vector2 = control.position

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


## Animate a single control appearing with scale
static func animate_scale_in(control: Control, delay: float = 0.0) -> void:
	if control == null:
		return

	var settings_manager = Engine.get_main_loop().root.get_node_or_null("/root/SettingsManager")
	if settings_manager != null and settings_manager.get("reduced_motion"):
		control.visible = true
		control.modulate.a = 1.0
		return

	control.visible = true
	control.modulate.a = 0.0
	control.scale = Vector2(0.8, 0.8)
	control.pivot_offset = control.size * 0.5

	var tween := control.create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)

	if delay > 0:
		tween.tween_interval(delay)

	tween.tween_property(control, "modulate:a", 1.0, FADE_DURATION)
	tween.parallel().tween_property(control, "scale", Vector2.ONE, FADE_DURATION * 1.5)


## Animate a title or header appearing
static func animate_title(control: Control) -> void:
	if control == null:
		return

	var settings_manager = Engine.get_main_loop().root.get_node_or_null("/root/SettingsManager")
	if settings_manager != null and settings_manager.get("reduced_motion"):
		control.visible = true
		control.modulate.a = 1.0
		return

	control.visible = true
	control.modulate.a = 0.0
	control.scale = Vector2(1.2, 1.2)
	control.pivot_offset = control.size * 0.5

	var tween := control.create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_EXPO)
	tween.tween_property(control, "modulate:a", 1.0, FADE_DURATION * 0.8)
	tween.parallel().tween_property(control, "scale", Vector2.ONE, FADE_DURATION * 1.2)
