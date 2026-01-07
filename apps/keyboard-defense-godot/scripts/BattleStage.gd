extends Control

const AssetLoader = preload("res://game/asset_loader.gd")
const HitEffectsScript = preload("res://game/hit_effects.gd")

const DEFAULT_STAGE_SIZE := Vector2(800, 360)
const BREACH_RESET := 0.25
const PROJECTILE_SPEED := 520.0
const HIT_FLASH_DURATION := 0.18
const SPRITE_SCALE := 3.0  # Scale 16px sprites to ~48px

signal castle_damaged

@onready var castle: Sprite2D = $Castle
@onready var enemy: Sprite2D = $Enemy
@onready var projectile_layer: Control = $ProjectileLayer
@onready var audio_manager = get_node_or_null("/root/AudioManager")

var asset_loader: AssetLoader
var hit_effects: HitEffects
var progress: float = 0.0
var breach_pending: bool = false
var lane_left_x: float = 0.0
var lane_right_x: float = 0.0
var lane_y: float = 0.0
var projectiles: Array = []
var hit_flash_timer: float = 0.0
var current_enemy_kind: String = "runner"
var _last_projectile_power: bool = false

# Texture references
var projectile_texture: Texture2D
var magic_bolt_texture: Texture2D

func _ready() -> void:
	asset_loader = AssetLoader.new()
	asset_loader._load_manifest()
	hit_effects = HitEffects.new()
	_load_textures()
	if not resized.is_connected(_on_resized):
		resized.connect(_on_resized)
	_layout()

func _load_textures() -> void:
	# Load castle texture
	if castle != null:
		var castle_tex := asset_loader.get_sprite_texture("bld_castle")
		if castle_tex != null:
			castle.texture = castle_tex
			castle.scale = Vector2(SPRITE_SCALE, SPRITE_SCALE)

	# Load default enemy texture
	if enemy != null:
		var enemy_tex := asset_loader.get_sprite_texture("enemy_runner")
		if enemy_tex != null:
			enemy.texture = enemy_tex
			enemy.scale = Vector2(SPRITE_SCALE, SPRITE_SCALE)

	# Cache projectile textures
	projectile_texture = asset_loader.get_sprite_texture("fx_projectile")
	magic_bolt_texture = asset_loader.get_sprite_texture("fx_magic_bolt")

func set_enemy_kind(kind: String) -> void:
	current_enemy_kind = kind
	if enemy == null or asset_loader == null:
		return
	var sprite_id := asset_loader.get_enemy_sprite_id(kind)
	var enemy_tex := asset_loader.get_sprite_texture(sprite_id)
	if enemy_tex != null:
		enemy.texture = enemy_tex
		# Boss sprites are 32x32, regular are 16x16
		if kind.begins_with("boss"):
			enemy.scale = Vector2(SPRITE_SCALE * 0.75, SPRITE_SCALE * 0.75)
		else:
			enemy.scale = Vector2(SPRITE_SCALE, SPRITE_SCALE)

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
	if hit_effects != null:
		hit_effects.update(delta)

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

	_last_projectile_power = power_shot
	var shot: CanvasItem
	var use_sprite: bool = projectile_texture != null

	if use_sprite:
		var sprite := Sprite2D.new()
		sprite.texture = magic_bolt_texture if power_shot else projectile_texture
		sprite.scale = Vector2(2.0, 2.0) if power_shot else Vector2(1.5, 1.5)
		shot = sprite
	else:
		var rect := ColorRect.new()
		rect.color = Color(0.96, 0.82, 0.48, 1) if power_shot else Color(0.9, 0.72, 0.32, 1)
		rect.size = Vector2(12, 4) if power_shot else Vector2(8, 3)
		shot = rect

	var castle_size := _get_sprite_size(castle)
	shot.position = Vector2(castle.position.x + castle_size.x * 0.5, lane_y)
	projectile_layer.add_child(shot)
	projectiles.append({
		"node": shot,
		"velocity": Vector2(PROJECTILE_SPEED, 0.0),
		"power": power_shot
	})

func _get_sprite_size(sprite: Sprite2D) -> Vector2:
	if sprite == null or sprite.texture == null:
		return Vector2(48, 48)
	return sprite.texture.get_size() * sprite.scale

func _layout() -> void:
	var stage_size = size
	if stage_size.x <= 0.0 or stage_size.y <= 0.0:
		stage_size = DEFAULT_STAGE_SIZE

	if castle != null:
		var castle_size := _get_sprite_size(castle)
		castle.position = Vector2(
			stage_size.x * 0.08 + castle_size.x * 0.5,
			stage_size.y * 0.65
		)

	lane_left_x = 0.0
	lane_right_x = 0.0
	lane_y = stage_size.y * 0.65

	if castle != null:
		var castle_size := _get_sprite_size(castle)
		lane_left_x = castle.position.x + castle_size.x * 0.5 + 24.0
	if enemy != null:
		var enemy_size := _get_sprite_size(enemy)
		lane_right_x = stage_size.x - enemy_size.x * 0.5 - 24.0

	_update_enemy_position()

func _update_enemy_position() -> void:
	if enemy == null:
		return
	if lane_right_x == 0.0 and lane_left_x == 0.0:
		_layout()
	var x = lerp(lane_right_x, lane_left_x, progress)
	enemy.position = Vector2(x, lane_y)

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
			var is_power: bool = entry.get("power", false)
			var hit_pos := node.position
			node.queue_free()
			projectiles.remove_at(i)
			_flash_enemy()
			_spawn_hit_effect(hit_pos, is_power)

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
	if audio_manager != null:
		audio_manager.play_hit_enemy()

func _update_enemy_flash(delta: float) -> void:
	if hit_flash_timer <= 0.0:
		return
	hit_flash_timer = max(0.0, hit_flash_timer - delta)
	if hit_flash_timer <= 0.0:
		_apply_enemy_flash(0.0)

func _apply_enemy_flash(intensity: float) -> void:
	if enemy == null:
		return
	# Use modulate for sprite flash effect
	var base_color := Color.WHITE
	var flash_color := Color(1.5, 1.2, 1.0, 1.0)  # Bright flash
	enemy.modulate = base_color.lerp(flash_color, intensity)

func _spawn_hit_effect(hit_position: Vector2, is_power_shot: bool) -> void:
	if hit_effects == null or projectile_layer == null:
		return
	if is_power_shot:
		hit_effects.spawn_power_burst(projectile_layer, hit_position)
	else:
		hit_effects.spawn_hit_sparks(projectile_layer, hit_position)

func spawn_castle_damage_effect() -> void:
	if hit_effects == null or projectile_layer == null or castle == null:
		return
	var castle_size := _get_sprite_size(castle)
	var pos := castle.position + Vector2(castle_size.x * 0.3, -castle_size.y * 0.2)
	hit_effects.spawn_damage_flash(projectile_layer, pos)
	castle_damaged.emit()
