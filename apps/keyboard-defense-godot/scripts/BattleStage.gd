extends Control

const DEFAULT_STAGE_SIZE := Vector2(800, 360)
const BREACH_RESET := 0.25
const PROJECTILE_SPEED := 520.0
const HIT_FLASH_DURATION := 0.18

@onready var castle: ColorRect = $Castle
@onready var enemy: ColorRect = $Enemy
@onready var projectile_layer: Control = $ProjectileLayer

var progress: float = 0.0
var breach_pending: bool = false
var lane_left_x: float = 0.0
var lane_right_x: float = 0.0
var lane_y: float = 0.0
var projectiles: Array = []
var hit_flash_timer: float = 0.0
var enemy_base_color: Color = Color(0.63, 0.22, 0.26, 1)

func _ready() -> void:
	if not resized.is_connected(_on_resized):
		resized.connect(_on_resized)
	if enemy != null:
		enemy_base_color = enemy.color
	_layout()

func _on_resized() -> void:
	_layout()

func reset() -> void:
	progress = 0.0
	breach_pending = false
	hit_flash_timer = 0.0
	_clear_projectiles()
	_layout()
	_update_enemy_position()
	_apply_enemy_flash(0.0)

func set_progress_percent(value: float) -> void:
	progress = clamp(value / 100.0, 0.0, 1.0)
	breach_pending = progress >= 1.0
	_update_enemy_position()

func get_progress_percent() -> float:
	return progress * 100.0

func advance(delta: float, threat_rate: float) -> void:
	if threat_rate != 0.0:
		progress = clamp(progress + (threat_rate / 100.0) * delta, 0.0, 1.0)
		breach_pending = progress >= 1.0
	_update_enemy_position()
	_update_projectiles(delta)
	_update_enemy_flash(delta)

func apply_relief(amount_percent: float) -> void:
	if amount_percent <= 0.0:
		return
	progress = clamp(progress - amount_percent / 100.0, 0.0, 1.0)
	if progress < 1.0:
		breach_pending = false
	_update_enemy_position()

func apply_penalty(amount_percent: float) -> void:
	if amount_percent <= 0.0:
		return
	progress = clamp(progress + amount_percent / 100.0, 0.0, 1.0)
	breach_pending = progress >= 1.0
	_update_enemy_position()

func consume_breach() -> bool:
	if breach_pending:
		breach_pending = false
		return true
	return false

func reset_after_breach() -> void:
	progress = clamp(BREACH_RESET, 0.0, 1.0)
	_update_enemy_position()

func spawn_projectile(power_shot: bool = false) -> void:
	if projectile_layer == null or castle == null:
		return
	var shot = ColorRect.new()
	shot.color = Color(0.96, 0.82, 0.48, 1) if power_shot else Color(0.9, 0.72, 0.32, 1)
	shot.size = Vector2(12, 4) if power_shot else Vector2(8, 3)
	shot.position = Vector2(castle.position.x + castle.size.x - 4.0, lane_y)
	projectile_layer.add_child(shot)
	projectiles.append({
		"node": shot,
		"velocity": Vector2(PROJECTILE_SPEED, 0.0)
	})

func _layout() -> void:
	var stage_size = size
	if stage_size.x <= 0.0 or stage_size.y <= 0.0:
		stage_size = DEFAULT_STAGE_SIZE
	if castle != null:
		var castle_size = Vector2(min(stage_size.x * 0.16, 120.0), min(stage_size.x * 0.16, 120.0))
		castle_size.y = max(48.0, castle_size.y * 0.85)
		castle.size = castle_size
		castle.position = Vector2(stage_size.x * 0.06, stage_size.y * 0.65 - castle_size.y * 0.5)
	if enemy != null:
		var enemy_size = Vector2(max(40.0, castle.size.x * 0.7), max(28.0, castle.size.y * 0.6))
		enemy.size = enemy_size
	lane_left_x = 0.0
	lane_right_x = 0.0
	lane_y = stage_size.y * 0.65
	if castle != null:
		lane_left_x = castle.position.x + castle.size.x + 24.0
	if enemy != null:
		lane_right_x = stage_size.x - enemy.size.x - 24.0
	_update_enemy_position()

func _update_enemy_position() -> void:
	if enemy == null:
		return
	if lane_right_x == 0.0 and lane_left_x == 0.0:
		_layout()
	var x = lerp(lane_right_x, lane_left_x, progress)
	enemy.position = Vector2(x, lane_y - enemy.size.y * 0.5)

func _update_projectiles(delta: float) -> void:
	if projectiles.is_empty():
		return
	for i in range(projectiles.size() - 1, -1, -1):
		var entry = projectiles[i]
		if not entry is Dictionary:
			projectiles.remove_at(i)
			continue
		var node = entry.get("node", null)
		if node == null or not is_instance_valid(node):
			projectiles.remove_at(i)
			continue
		var velocity: Vector2 = entry.get("velocity", Vector2.ZERO)
		node.position += velocity * delta
		if enemy != null and node.position.x >= enemy.position.x:
			node.queue_free()
			projectiles.remove_at(i)
			_flash_enemy()

func _clear_projectiles() -> void:
	for entry in projectiles:
		if entry is Dictionary:
			var node = entry.get("node", null)
			if node != null and is_instance_valid(node):
				node.queue_free()
	projectiles.clear()

func _flash_enemy() -> void:
	hit_flash_timer = HIT_FLASH_DURATION
	_apply_enemy_flash(1.0)

func _update_enemy_flash(delta: float) -> void:
	if hit_flash_timer <= 0.0:
		return
	hit_flash_timer = max(0.0, hit_flash_timer - delta)
	if hit_flash_timer <= 0.0:
		_apply_enemy_flash(0.0)

func _apply_enemy_flash(intensity: float) -> void:
	if enemy == null:
		return
	var flash_color = Color(1.0, 0.76, 0.68, 1)
	enemy.color = enemy_base_color.lerp(flash_color, intensity)
