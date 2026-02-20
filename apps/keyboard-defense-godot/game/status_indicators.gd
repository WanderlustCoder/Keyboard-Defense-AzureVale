class_name StatusIndicators
extends RefCounted
## Visual indicators for status effects on enemies/towers.

const INDICATOR_SIZE := Vector2(8, 8)
const INDICATOR_OFFSET := Vector2(0, -24)  # Above sprite
const INDICATOR_SPACING := 10.0
const PULSE_SPEED := 3.0
const ICON_SCALE := 1.5

# Status effect colors
const STATUS_COLORS := {
	"burn": Color(1.0, 0.4, 0.1, 1.0),      # Orange-red
	"slow": Color(0.3, 0.7, 1.0, 1.0),      # Ice blue
	"poison": Color(0.4, 0.9, 0.3, 1.0),    # Green
	"shield": Color(0.9, 0.85, 0.2, 1.0),   # Gold
	"stun": Color(1.0, 1.0, 0.3, 1.0),      # Yellow
	"weaken": Color(0.6, 0.3, 0.6, 1.0),    # Purple
	"haste": Color(0.3, 1.0, 0.6, 1.0),     # Cyan-green
	"armor": Color(0.6, 0.6, 0.7, 1.0),     # Steel gray
}

var _active_indicators: Array = []
var _time: float = 0.0


func update(delta: float) -> void:
	_time += delta

	for i in range(_active_indicators.size() - 1, -1, -1):
		var indicator = _active_indicators[i]
		if not indicator is Dictionary:
			_active_indicators.remove_at(i)
			continue

		var node = indicator.get("node")
		if node == null or not is_instance_valid(node):
			_active_indicators.remove_at(i)
			continue

		var duration: float = indicator.get("duration", 0.0)
		var elapsed: float = indicator.get("elapsed", 0.0)

		elapsed += delta
		indicator["elapsed"] = elapsed

		# Remove expired indicators
		if duration > 0.0 and elapsed >= duration:
			node.queue_free()
			_active_indicators.remove_at(i)
			continue

		# Pulse effect
		var pulse := sin(_time * PULSE_SPEED + indicator.get("phase", 0.0)) * 0.15 + 0.85
		node.modulate.a = pulse

		# Scale pulse for low duration
		if duration > 0.0:
			var remaining := duration - elapsed
			if remaining < 1.0:
				node.scale = Vector2.ONE * ICON_SCALE * (0.5 + remaining * 0.5)

		# Update position to follow target
		var target = indicator.get("target")
		if target != null and is_instance_valid(target):
			var existing_count := _count_indicators_for_target_before(target, i)
			var offset_x := (existing_count - 0.5) * INDICATOR_SPACING
			node.position = target.position + INDICATOR_OFFSET + Vector2(offset_x, 0) - node.size * 0.5 * ICON_SCALE


func add_indicator(parent: Node, target: Node2D, status_type: String, duration: float = -1.0) -> void:
	if parent == null or target == null:
		return

	var color: Color = STATUS_COLORS.get(status_type, Color.WHITE)

	# Create indicator visual
	var indicator := ColorRect.new()
	indicator.size = INDICATOR_SIZE
	indicator.color = color

	# Position above target
	var existing_count := _count_indicators_for_target(target)
	var offset_x := (existing_count - 0.5) * INDICATOR_SPACING
	indicator.position = target.position + INDICATOR_OFFSET + Vector2(offset_x, 0) - indicator.size * 0.5 * ICON_SCALE
	indicator.scale = Vector2.ONE * ICON_SCALE
	indicator.pivot_offset = INDICATOR_SIZE * 0.5

	parent.add_child(indicator)

	_active_indicators.append({
		"node": indicator,
		"target": target,
		"status": status_type,
		"duration": duration,
		"elapsed": 0.0,
		"phase": randf() * TAU  # Random pulse phase
	})


func remove_indicator(target: Node2D, status_type: String) -> void:
	for i in range(_active_indicators.size() - 1, -1, -1):
		var indicator = _active_indicators[i]
		if not indicator is Dictionary:
			continue
		if indicator.get("target") == target and indicator.get("status") == status_type:
			var node = indicator.get("node")
			if node != null and is_instance_valid(node):
				node.queue_free()
			_active_indicators.remove_at(i)
			break


func remove_all_for_target(target: Node2D) -> void:
	for i in range(_active_indicators.size() - 1, -1, -1):
		var indicator = _active_indicators[i]
		if not indicator is Dictionary:
			continue
		if indicator.get("target") == target:
			var node = indicator.get("node")
			if node != null and is_instance_valid(node):
				node.queue_free()
			_active_indicators.remove_at(i)


func has_indicator(target: Node2D, status_type: String) -> bool:
	for indicator in _active_indicators:
		if indicator is Dictionary:
			if indicator.get("target") == target and indicator.get("status") == status_type:
				return true
	return false


func _count_indicators_for_target(target: Node2D) -> int:
	var count := 0
	for indicator in _active_indicators:
		if indicator is Dictionary and indicator.get("target") == target:
			count += 1
	return count


func _count_indicators_for_target_before(target: Node2D, before_index: int) -> int:
	var count := 0
	for i in range(mini(before_index, _active_indicators.size())):
		var indicator = _active_indicators[i]
		if indicator is Dictionary and indicator.get("target") == target:
			count += 1
	return count


func clear() -> void:
	for indicator in _active_indicators:
		if indicator is Dictionary:
			var node = indicator.get("node")
			if node != null and is_instance_valid(node):
				node.queue_free()
	_active_indicators.clear()


func get_active_count() -> int:
	return _active_indicators.size()
