extends Control

const AssetLoader = preload("res://game/asset_loader.gd")
const StatusIndicators = preload("res://game/status_indicators.gd")

const DEFAULT_STAGE_SIZE := Vector2(800, 360)
const BREACH_RESET := 0.25
const PROJECTILE_SPEED := 520.0
const HIT_FLASH_DURATION := 0.18
const SPRITE_SCALE := 3.0  # Scale 16px sprites to ~48px

# Damage number settings
const DAMAGE_NUMBER_SPEED := 60.0
const DAMAGE_NUMBER_LIFETIME := 0.8
const DAMAGE_NUMBER_FONT_SIZE := 18
const DAMAGE_NUMBER_POWER_FONT_SIZE := 24

# Trail particle settings
const TRAIL_SPAWN_INTERVAL := 0.02
const TRAIL_PARTICLE_LIFETIME := 0.25
const TRAIL_PARTICLE_SIZE := 4.0
const TRAIL_POWER_SIZE := 6.0

signal castle_damaged

@onready var castle: Sprite2D = $Castle
@onready var enemy: Sprite2D = $Enemy
@onready var projectile_layer: Control = $ProjectileLayer
@onready var audio_manager = get_node_or_null("/root/AudioManager")

var asset_loader: AssetLoader
var hit_effects: HitEffects
var status_indicators: StatusIndicators
var progress: float = 0.0
var breach_pending: bool = false
var lane_left_x: float = 0.0
var lane_right_x: float = 0.0
var lane_y: float = 0.0
var projectiles: Array = []
var damage_numbers: Array = []
var trail_particles: Array = []
var hit_flash_timer: float = 0.0
var current_enemy_kind: String = "runner"
var _last_projectile_power: bool = false

# Tower animation state
var _castle_base_position: Vector2 = Vector2.ZERO
var _castle_recoil: float = 0.0
const CASTLE_RECOIL_AMOUNT := 8.0
const CASTLE_RECOIL_RECOVERY := 12.0

# Enemy stagger state
var _enemy_stagger: float = 0.0
var _enemy_stagger_direction: float = 1.0
const ENEMY_STAGGER_AMOUNT := 6.0
const ENEMY_STAGGER_RECOVERY := 8.0

# Texture references
var projectile_texture: Texture2D
var magic_bolt_texture: Texture2D

func _ready() -> void:
	asset_loader = AssetLoader.new()
	asset_loader._load_manifest()
	hit_effects = HitEffects.new()
	status_indicators = StatusIndicators.new()
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
	_clear_damage_numbers()
	_clear_trail_particles()
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
	_update_damage_numbers(delta)
	_update_castle_recoil(delta)
	# Decay enemy stagger
	if _enemy_stagger > 0.0:
		_enemy_stagger = maxf(0.0, _enemy_stagger - ENEMY_STAGGER_RECOVERY * delta)
	if hit_effects != null:
		hit_effects.update(delta)
	if status_indicators != null:
		status_indicators.update(delta)

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

func spawn_projectile(power_shot: bool = false, critical_shot: bool = false) -> void:
	if projectile_layer == null or castle == null:
		return

	_last_projectile_power = power_shot
	var shot: CanvasItem
	var use_sprite: bool = projectile_texture != null

	if use_sprite:
		var sprite := Sprite2D.new()
		sprite.texture = magic_bolt_texture if power_shot else projectile_texture
		var base_scale := Vector2(2.0, 2.0) if power_shot else Vector2(1.5, 1.5)
		if critical_shot:
			base_scale *= 1.3  # Larger for criticals
		sprite.scale = base_scale
		shot = sprite
	else:
		var rect := ColorRect.new()
		rect.color = Color(1.0, 0.4, 0.2, 1) if critical_shot else (Color(0.96, 0.82, 0.48, 1) if power_shot else Color(0.9, 0.72, 0.32, 1))
		rect.size = Vector2(14, 5) if critical_shot else (Vector2(12, 4) if power_shot else Vector2(8, 3))
		shot = rect

	var castle_size := _get_sprite_size(castle)
	shot.position = Vector2(castle.position.x + castle_size.x * 0.5, lane_y)
	projectile_layer.add_child(shot)

	# Critical shots are faster
	var speed_multiplier := 1.2 if critical_shot else 1.0
	projectiles.append({
		"node": shot,
		"velocity": Vector2(PROJECTILE_SPEED * speed_multiplier, 0.0),
		"power": power_shot,
		"critical": critical_shot,
		"trail_timer": 0.0,
		"rotation": 0.0
	})

	# Trigger castle recoil
	_castle_recoil = 1.0
	# Play tower recoil sound
	if audio_manager != null:
		audio_manager.play_tower_recoil()

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
		# Store base position for recoil animation
		_castle_base_position = castle.position
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

	# Apply stagger offset
	var stagger_offset := 0.0
	if _enemy_stagger > 0.0:
		var stagger_curve := _enemy_stagger * _enemy_stagger
		stagger_offset = ENEMY_STAGGER_AMOUNT * stagger_curve * _enemy_stagger_direction

	enemy.position = Vector2(x + stagger_offset, lane_y)

func _update_projectiles(delta: float) -> void:
	# Update trail particles
	_update_trail_particles(delta)

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
		var is_power: bool = entry.get("power", false)
		node.position += velocity * delta

		# Rotate projectile for visual flair
		var rotation: float = entry.get("rotation", 0.0)
		rotation += delta * (15.0 if is_power else 10.0)
		entry["rotation"] = rotation
		if node is Sprite2D:
			node.rotation = rotation

		# Spawn trail particles
		var trail_timer: float = entry.get("trail_timer", 0.0)
		trail_timer -= delta
		if trail_timer <= 0.0:
			_spawn_trail_particle(node.position, is_power)
			trail_timer = TRAIL_SPAWN_INTERVAL
		entry["trail_timer"] = trail_timer

		if enemy != null and node.position.x >= enemy.position.x:
			var hit_pos: Vector2 = node.position
			var is_critical: bool = entry.get("critical", false)
			node.queue_free()
			projectiles.remove_at(i)
			_flash_enemy()
			_spawn_hit_effect(hit_pos, is_power, is_critical)

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
	# Trigger stagger
	_enemy_stagger = 1.0
	_enemy_stagger_direction = -_enemy_stagger_direction  # Alternate direction
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

func _spawn_hit_effect(hit_position: Vector2, is_power_shot: bool, is_critical: bool = false) -> void:
	if hit_effects == null or projectile_layer == null:
		return
	if is_critical:
		hit_effects.spawn_critical_hit(projectile_layer, hit_position)
		_spawn_damage_number(hit_position, "CRITICAL!", true)
		# Trigger screen shake and hit pause for critical hits
		var screen_shake = get_node_or_null("/root/ScreenShake")
		if screen_shake != null:
			screen_shake.add_trauma(0.4)
		var hit_pause = get_node_or_null("/root/HitPause")
		if hit_pause != null:
			hit_pause.pause_medium()
		# Play critical hit sound
		if audio_manager != null:
			audio_manager.play_critical_hit()
	elif is_power_shot:
		hit_effects.spawn_power_burst(projectile_layer, hit_position)
		_spawn_damage_number(hit_position, "POWER!", true)
	else:
		hit_effects.spawn_hit_sparks(projectile_layer, hit_position)
		_spawn_damage_number(hit_position, "HIT", false)

func spawn_castle_damage_effect() -> void:
	if hit_effects == null or projectile_layer == null or castle == null:
		return
	var castle_size := _get_sprite_size(castle)
	var pos := castle.position + Vector2(castle_size.x * 0.3, -castle_size.y * 0.2)
	hit_effects.spawn_damage_flash(projectile_layer, pos)
	castle_damaged.emit()

func spawn_word_complete_effect() -> void:
	# Spawn celebratory particle burst at castle position (where projectiles originate)
	if hit_effects == null or projectile_layer == null or castle == null:
		return
	var castle_size := _get_sprite_size(castle)
	var pos := castle.position + Vector2(castle_size.x * 0.5, -castle_size.y * 0.3)
	hit_effects.spawn_word_complete_burst(projectile_layer, pos)


func spawn_enemy_death_effect() -> void:
	if hit_effects == null or projectile_layer == null or enemy == null:
		return

	var death_pos := enemy.position

	# Get enemy color based on type for tinted death particles
	var enemy_color := _get_enemy_color(current_enemy_kind)

	# Spawn death particles
	hit_effects.spawn_enemy_death(projectile_layer, death_pos, enemy_color)

	# Spawn "DEFEATED!" text
	_spawn_damage_number(death_pos + Vector2(0, -20), "DEFEATED!", true)

	# Trigger screen shake
	var screen_shake = get_node_or_null("/root/ScreenShake")
	if screen_shake != null:
		screen_shake.add_trauma(0.35)

	# Trigger hit pause
	var hit_pause = get_node_or_null("/root/HitPause")
	if hit_pause != null:
		hit_pause.pause_light()

	# Play death sound
	if audio_manager != null:
		audio_manager.play_enemy_death()


func _get_enemy_color(kind: String) -> Color:
	match kind:
		"runner":
			return Color(0.8, 0.3, 0.3)  # Red
		"tank":
			return Color(0.5, 0.5, 0.6)  # Gray-blue
		"fast":
			return Color(0.3, 0.8, 0.4)  # Green
		"boss_fen_seer", "boss_fen_knight", "boss_fen_queen":
			return Color(0.6, 0.2, 0.8)  # Purple for bosses
		_:
			return Color(0.8, 0.2, 0.2)  # Default red


func add_enemy_status(status_type: String, duration: float = -1.0) -> void:
	if status_indicators == null or projectile_layer == null or enemy == null:
		return
	status_indicators.add_indicator(projectile_layer, enemy, status_type, duration)
	# Play status apply sound
	if audio_manager != null:
		audio_manager.play_status_apply()


func remove_enemy_status(status_type: String) -> void:
	if status_indicators == null or enemy == null:
		return
	status_indicators.remove_indicator(enemy, status_type)
	# Play status expire sound
	if audio_manager != null:
		audio_manager.play_status_expire()


func clear_enemy_statuses() -> void:
	if status_indicators == null or enemy == null:
		return
	status_indicators.remove_all_for_target(enemy)


func _update_castle_recoil(delta: float) -> void:
	if castle == null:
		return

	if _castle_base_position == Vector2.ZERO:
		_castle_base_position = castle.position

	# Decay recoil
	if _castle_recoil > 0.0:
		_castle_recoil = maxf(0.0, _castle_recoil - CASTLE_RECOIL_RECOVERY * delta)

	# Apply recoil offset (push back then return)
	var recoil_curve := _castle_recoil * _castle_recoil  # Quadratic for snap
	var offset := Vector2(-CASTLE_RECOIL_AMOUNT * recoil_curve, 0.0)
	castle.position = _castle_base_position + offset


func _spawn_damage_number(hit_position: Vector2, text: String, is_power: bool) -> void:
	if projectile_layer == null:
		return

	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = hit_position + Vector2(randf_range(-10, 10), -20)

	var font_size := DAMAGE_NUMBER_POWER_FONT_SIZE if is_power else DAMAGE_NUMBER_FONT_SIZE
	label.add_theme_font_size_override("font_size", font_size)

	var color := Color(1.0, 0.9, 0.3, 1.0) if is_power else Color(1.0, 1.0, 1.0, 1.0)
	label.add_theme_color_override("font_color", color)

	# Add outline for readability
	label.add_theme_constant_override("outline_size", 2)
	label.add_theme_color_override("font_outline_color", Color(0.1, 0.1, 0.15, 1.0))

	projectile_layer.add_child(label)

	damage_numbers.append({
		"node": label,
		"velocity": Vector2(randf_range(-15, 15), -DAMAGE_NUMBER_SPEED),
		"lifetime": DAMAGE_NUMBER_LIFETIME,
		"initial_lifetime": DAMAGE_NUMBER_LIFETIME
	})

func _update_damage_numbers(delta: float) -> void:
	for i in range(damage_numbers.size() - 1, -1, -1):
		var entry = damage_numbers[i]
		if not entry is Dictionary:
			damage_numbers.remove_at(i)
			continue

		var node = entry.get("node")
		if node == null or not is_instance_valid(node):
			damage_numbers.remove_at(i)
			continue

		var velocity: Vector2 = entry.get("velocity", Vector2.ZERO)
		var lifetime: float = entry.get("lifetime", 0.0)
		var initial_lifetime: float = entry.get("initial_lifetime", DAMAGE_NUMBER_LIFETIME)

		lifetime -= delta
		entry["lifetime"] = lifetime

		if lifetime <= 0.0:
			node.queue_free()
			damage_numbers.remove_at(i)
			continue

		# Slow down vertical movement (deceleration)
		velocity.y *= 0.95
		entry["velocity"] = velocity
		node.position += velocity * delta

		# Fade out in last 30% of lifetime
		var fade_threshold := initial_lifetime * 0.3
		if lifetime < fade_threshold:
			node.modulate.a = lifetime / fade_threshold

func _clear_damage_numbers() -> void:
	for entry in damage_numbers:
		if entry is Dictionary:
			var node = entry.get("node")
			if node != null and is_instance_valid(node):
				node.queue_free()
	damage_numbers.clear()

func _spawn_trail_particle(pos: Vector2, is_power: bool) -> void:
	if projectile_layer == null:
		return

	var particle := ColorRect.new()
	var base_size := TRAIL_POWER_SIZE if is_power else TRAIL_PARTICLE_SIZE

	# Randomize size slightly
	var size := base_size * randf_range(0.6, 1.2)
	particle.size = Vector2(size, size)
	particle.position = pos + Vector2(randf_range(-3, 3), randf_range(-3, 3))

	# Color based on power
	var base_color: Color
	if is_power:
		base_color = Color(0.4, 0.7, 1.0, 0.9)  # Cyan/blue
	else:
		base_color = Color(1.0, 0.85, 0.4, 0.8)  # Gold/yellow

	particle.color = base_color
	projectile_layer.add_child(particle)

	trail_particles.append({
		"node": particle,
		"lifetime": TRAIL_PARTICLE_LIFETIME,
		"initial_lifetime": TRAIL_PARTICLE_LIFETIME,
		"initial_size": size,
		"color": base_color
	})

func _update_trail_particles(delta: float) -> void:
	for i in range(trail_particles.size() - 1, -1, -1):
		var entry = trail_particles[i]
		if not entry is Dictionary:
			trail_particles.remove_at(i)
			continue

		var node = entry.get("node")
		if node == null or not is_instance_valid(node):
			trail_particles.remove_at(i)
			continue

		var lifetime: float = entry.get("lifetime", 0.0)
		var initial_lifetime: float = entry.get("initial_lifetime", TRAIL_PARTICLE_LIFETIME)
		var initial_size: float = entry.get("initial_size", TRAIL_PARTICLE_SIZE)
		var base_color: Color = entry.get("color", Color.WHITE)

		lifetime -= delta
		entry["lifetime"] = lifetime

		if lifetime <= 0.0:
			node.queue_free()
			trail_particles.remove_at(i)
			continue

		# Fade and shrink
		var progress := lifetime / initial_lifetime
		node.modulate.a = progress * base_color.a
		var shrink_size := initial_size * progress
		node.size = Vector2(shrink_size, shrink_size)

func _clear_trail_particles() -> void:
	for entry in trail_particles:
		if entry is Dictionary:
			var node = entry.get("node")
			if node != null and is_instance_valid(node):
				node.queue_free()
	trail_particles.clear()
