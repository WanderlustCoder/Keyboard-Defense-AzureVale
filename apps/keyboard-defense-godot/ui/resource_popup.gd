class_name ResourcePopup
extends RefCounted
## Floating +/- indicators for resource changes.

const POPUP_DURATION := 1.2
const POPUP_RISE_SPEED := 40.0
const POPUP_FADE_START := 0.6  # When to start fading
const FONT_SIZE := 16
const FONT_SIZE_LARGE := 20

# Resource colors
const RESOURCE_COLORS := {
	"gold": Color(1.0, 0.84, 0.0),
	"wood": Color(0.6, 0.4, 0.2),
	"stone": Color(0.6, 0.6, 0.7),
	"food": Color(0.4, 0.8, 0.4),
	"mana": Color(0.5, 0.4, 1.0),
	"xp": Color(0.4, 0.9, 1.0),
	"hp": Color(0.9, 0.3, 0.3),
	"default": Color(0.9, 0.9, 0.9)
}

var _active_popups: Array = []
var _parent: Node = null


func set_parent(parent: Node) -> void:
	_parent = parent


func spawn_popup(
	position: Vector2,
	amount: int,
	resource_type: String = "default",
	is_large: bool = false
) -> void:
	if _parent == null:
		return

	var label := Label.new()

	# Format text
	var prefix := "+" if amount > 0 else ""
	label.text = "%s%d" % [prefix, amount]

	# Style
	var color: Color = RESOURCE_COLORS.get(resource_type, RESOURCE_COLORS["default"])
	if amount < 0:
		color = color.darkened(0.2)

	label.add_theme_font_size_override("font_size", FONT_SIZE_LARGE if is_large else FONT_SIZE)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)

	# Position centered above spawn point
	label.position = position - Vector2(20, 0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.custom_minimum_size = Vector2(40, 0)

	_parent.add_child(label)

	_active_popups.append({
		"node": label,
		"lifetime": POPUP_DURATION,
		"velocity": Vector2(randf_range(-10, 10), -POPUP_RISE_SPEED)
	})


func spawn_resource_change(
	position: Vector2,
	resource_type: String,
	old_value: int,
	new_value: int
) -> void:
	var delta: int = new_value - old_value
	if delta == 0:
		return

	var is_large: bool = absi(delta) >= 50
	spawn_popup(position, delta, resource_type, is_large)


func spawn_text(
	position: Vector2,
	text: String,
	color: Color = Color.WHITE,
	is_large: bool = false
) -> void:
	if _parent == null:
		return

	var label := Label.new()
	label.text = text

	label.add_theme_font_size_override("font_size", FONT_SIZE_LARGE if is_large else FONT_SIZE)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)

	label.position = position - Vector2(30, 0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.custom_minimum_size = Vector2(60, 0)

	_parent.add_child(label)

	_active_popups.append({
		"node": label,
		"lifetime": POPUP_DURATION,
		"velocity": Vector2(randf_range(-10, 10), -POPUP_RISE_SPEED)
	})


func update(delta: float) -> void:
	for i in range(_active_popups.size() - 1, -1, -1):
		var popup = _active_popups[i]
		if not popup is Dictionary:
			_active_popups.remove_at(i)
			continue

		var node = popup.get("node")
		if node == null or not is_instance_valid(node):
			_active_popups.remove_at(i)
			continue

		var lifetime: float = popup.get("lifetime", 0.0)
		var velocity: Vector2 = popup.get("velocity", Vector2.ZERO)

		lifetime -= delta
		popup["lifetime"] = lifetime

		if lifetime <= 0.0:
			node.queue_free()
			_active_popups.remove_at(i)
			continue

		# Move
		node.position += velocity * delta

		# Fade
		if lifetime < POPUP_FADE_START:
			node.modulate.a = lifetime / POPUP_FADE_START


func clear() -> void:
	for popup in _active_popups:
		if popup is Dictionary:
			var node = popup.get("node")
			if node != null and is_instance_valid(node):
				node.queue_free()
	_active_popups.clear()


func get_active_count() -> int:
	return _active_popups.size()
