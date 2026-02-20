extends Node
class_name HitEffects
## Pooled particle effect spawner for combat feedback.
## Uses object pooling to reduce garbage collection overhead.

const ObjectPool = preload("res://game/object_pool.gd")

const PARTICLE_COUNT := 6
const PARTICLE_LIFETIME := 0.4
const PARTICLE_SPEED := 120.0
const PARTICLE_SIZE := Vector2(4, 4)
const SPARK_SIZE := Vector2(6, 2)
const POOL_SIZE := 100  # Pre-allocate this many particles
const MAX_POOL_SIZE := 200  # Maximum pooled objects

var _active_particles: Array = []
var _particle_pool: ObjectPool = null
var _parent_node: Node = null

func _ready() -> void:
	_setup_pool()

func _setup_pool() -> void:
	# Create pool with factory and reset functions
	_particle_pool = ObjectPool.new(
		_create_particle,
		_reset_particle,
		MAX_POOL_SIZE
	)

func set_parent(parent: Node) -> void:
	_parent_node = parent
	if _particle_pool != null:
		_particle_pool.set_parent(parent)
	# Pre-warm after parent is set
	_particle_pool.prewarm(POOL_SIZE)

func _create_particle() -> ColorRect:
	var particle := ColorRect.new()
	particle.size = PARTICLE_SIZE
	particle.visible = false
	return particle

func _reset_particle(particle: ColorRect) -> void:
	particle.modulate = Color.WHITE
	particle.rotation = 0.0
	particle.scale = Vector2.ONE

func spawn_hit_sparks(parent: Node, position: Vector2, color: Color = Color(1.0, 0.9, 0.5, 1.0)) -> void:
	_ensure_parent(parent)

	for i in range(PARTICLE_COUNT):
		var particle: ColorRect = _particle_pool.acquire()
		if particle == null:
			continue

		particle.size = SPARK_SIZE if i % 2 == 0 else PARTICLE_SIZE
		particle.color = color
		particle.position = position - particle.size * 0.5
		particle.visible = true

		# Ensure it's in the scene tree
		if particle.get_parent() == null:
			parent.add_child(particle)

		var angle := randf() * TAU
		var speed := PARTICLE_SPEED * (0.5 + randf() * 0.5)
		var velocity := Vector2(cos(angle), sin(angle)) * speed

		_active_particles.append({
			"node": particle,
			"velocity": velocity,
			"lifetime": PARTICLE_LIFETIME,
			"fade_start": PARTICLE_LIFETIME * 0.5
		})

func spawn_power_burst(parent: Node, position: Vector2) -> void:
	_ensure_parent(parent)

	for i in range(PARTICLE_COUNT + 4):
		var particle: ColorRect = _particle_pool.acquire()
		if particle == null:
			continue

		particle.size = SPARK_SIZE * 1.5 if i % 2 == 0 else PARTICLE_SIZE * 1.3
		particle.color = Color(1.0, 0.95, 0.6, 1.0)
		particle.position = position - particle.size * 0.5
		particle.visible = true

		if particle.get_parent() == null:
			parent.add_child(particle)

		var angle := randf() * TAU
		var speed := PARTICLE_SPEED * 1.5 * (0.5 + randf() * 0.5)
		var velocity := Vector2(cos(angle), sin(angle)) * speed

		_active_particles.append({
			"node": particle,
			"velocity": velocity,
			"lifetime": PARTICLE_LIFETIME * 1.2,
			"fade_start": PARTICLE_LIFETIME * 0.4
		})

func spawn_damage_flash(parent: Node, position: Vector2) -> void:
	_ensure_parent(parent)

	for i in range(8):
		var particle: ColorRect = _particle_pool.acquire()
		if particle == null:
			continue

		particle.size = PARTICLE_SIZE * 1.2
		particle.color = Color(1.0, 0.3, 0.2, 1.0)
		particle.position = position - particle.size * 0.5
		particle.visible = true

		if particle.get_parent() == null:
			parent.add_child(particle)

		var angle := randf() * TAU
		var speed := PARTICLE_SPEED * 0.8 * (0.3 + randf() * 0.7)
		var velocity := Vector2(cos(angle), sin(angle)) * speed

		_active_particles.append({
			"node": particle,
			"velocity": velocity,
			"lifetime": PARTICLE_LIFETIME * 0.8,
			"fade_start": PARTICLE_LIFETIME * 0.3
		})

func spawn_word_complete_burst(parent: Node, position: Vector2) -> void:
	_ensure_parent(parent)

	var particle_count := 12
	for i in range(particle_count):
		var particle: ColorRect = _particle_pool.acquire()
		if particle == null:
			continue

		if i % 3 == 0:
			particle.size = SPARK_SIZE * 1.2
		else:
			particle.size = PARTICLE_SIZE * 1.1

		var t := float(i) / float(particle_count)
		var gold := Color(1.0, 0.85, 0.3, 1.0)
		var cyan := Color(0.4, 0.9, 1.0, 1.0)
		particle.color = gold.lerp(cyan, t * 0.6)
		particle.position = position - particle.size * 0.5 + Vector2(randf_range(-8, 8), 0)
		particle.visible = true

		if particle.get_parent() == null:
			parent.add_child(particle)

		var angle := -PI / 2.0 + randf_range(-0.5, 0.5)
		var speed := PARTICLE_SPEED * 1.3 * (0.6 + randf() * 0.6)
		var velocity := Vector2(cos(angle), sin(angle)) * speed

		_active_particles.append({
			"node": particle,
			"velocity": velocity,
			"lifetime": PARTICLE_LIFETIME * 1.0,
			"fade_start": PARTICLE_LIFETIME * 0.4,
			"no_gravity": false
		})

func spawn_critical_hit(parent: Node, position: Vector2) -> void:
	_ensure_parent(parent)

	# Spawn expanding ring effect (8 particles in circle)
	for i in range(8):
		var particle: ColorRect = _particle_pool.acquire()
		if particle == null:
			continue

		particle.size = SPARK_SIZE * 2.0
		particle.color = Color(1.0, 0.2, 0.1, 1.0)  # Red-orange
		particle.position = position - particle.size * 0.5
		particle.visible = true

		if particle.get_parent() == null:
			parent.add_child(particle)

		var angle := (float(i) / 8.0) * TAU
		var speed := PARTICLE_SPEED * 2.0
		var velocity := Vector2(cos(angle), sin(angle)) * speed

		_active_particles.append({
			"node": particle,
			"velocity": velocity,
			"lifetime": PARTICLE_LIFETIME * 0.6,
			"fade_start": PARTICLE_LIFETIME * 0.3,
			"no_gravity": true
		})

	# Spawn secondary burst (golden sparks)
	for i in range(12):
		var particle: ColorRect = _particle_pool.acquire()
		if particle == null:
			continue

		particle.size = PARTICLE_SIZE if i % 2 == 0 else SPARK_SIZE
		particle.color = Color(1.0, 0.85, 0.3, 1.0)  # Gold
		particle.position = position - particle.size * 0.5
		particle.visible = true

		if particle.get_parent() == null:
			parent.add_child(particle)

		var angle := randf() * TAU
		var speed := PARTICLE_SPEED * 1.8 * (0.6 + randf() * 0.4)
		var velocity := Vector2(cos(angle), sin(angle)) * speed

		_active_particles.append({
			"node": particle,
			"velocity": velocity,
			"lifetime": PARTICLE_LIFETIME * 0.8,
			"fade_start": PARTICLE_LIFETIME * 0.4,
			"no_gravity": false
		})


func spawn_enemy_death(parent: Node, position: Vector2, enemy_color: Color = Color(0.8, 0.2, 0.2)) -> void:
	_ensure_parent(parent)

	# Large explosion burst - 16 particles outward
	for i in range(16):
		var particle: ColorRect = _particle_pool.acquire()
		if particle == null:
			continue

		var base_size := SPARK_SIZE if i % 3 == 0 else PARTICLE_SIZE
		particle.size = base_size * (1.5 + randf() * 0.5)

		# Mix enemy color with orange/yellow for fire effect
		var t := float(i) / 16.0
		var fire_color := Color(1.0, 0.6, 0.2, 1.0)
		particle.color = enemy_color.lerp(fire_color, t * 0.6 + randf() * 0.3)
		particle.position = position - particle.size * 0.5
		particle.visible = true

		if particle.get_parent() == null:
			parent.add_child(particle)

		var angle := randf() * TAU
		var speed := PARTICLE_SPEED * 2.2 * (0.5 + randf() * 0.5)
		var velocity := Vector2(cos(angle), sin(angle)) * speed

		_active_particles.append({
			"node": particle,
			"velocity": velocity,
			"lifetime": PARTICLE_LIFETIME * 1.3,
			"fade_start": PARTICLE_LIFETIME * 0.5,
			"no_gravity": false
		})

	# Smoke particles - rise upward
	for i in range(6):
		var particle: ColorRect = _particle_pool.acquire()
		if particle == null:
			continue

		particle.size = PARTICLE_SIZE * 2.5
		particle.color = Color(0.3, 0.3, 0.3, 0.6)  # Gray smoke
		particle.position = position - particle.size * 0.5 + Vector2(randf_range(-12, 12), 0)
		particle.visible = true

		if particle.get_parent() == null:
			parent.add_child(particle)

		var velocity := Vector2(randf_range(-20, 20), -60 - randf() * 30)

		_active_particles.append({
			"node": particle,
			"velocity": velocity,
			"lifetime": PARTICLE_LIFETIME * 2.0,
			"fade_start": PARTICLE_LIFETIME * 1.0,
			"no_gravity": true
		})


func spawn_tower_shot(parent: Node, from_pos: Vector2, to_pos: Vector2, color: Color = Color(0.5, 0.8, 1.0)) -> void:
	_ensure_parent(parent)

	# Create 3-4 particles that travel toward target
	var count := 3 + randi() % 2
	for i in range(count):
		var particle: ColorRect = _particle_pool.acquire()
		if particle == null:
			continue

		particle.size = SPARK_SIZE
		particle.color = color
		particle.position = from_pos - particle.size * 0.5
		particle.visible = true

		if particle.get_parent() == null:
			parent.add_child(particle)

		var direction := (to_pos - from_pos).normalized()
		var spread := randf_range(-0.2, 0.2)
		var velocity := direction.rotated(spread) * PARTICLE_SPEED * 2.5

		_active_particles.append({
			"node": particle,
			"velocity": velocity,
			"lifetime": 0.25,
			"fade_start": 0.1,
			"no_gravity": true,
			"target": to_pos
		})

func update(delta: float) -> void:
	for i in range(_active_particles.size() - 1, -1, -1):
		var p = _active_particles[i]
		if not p is Dictionary:
			_active_particles.remove_at(i)
			continue

		var node = p.get("node")
		if node == null or not is_instance_valid(node):
			_active_particles.remove_at(i)
			continue

		var velocity: Vector2 = p.get("velocity", Vector2.ZERO)
		var lifetime: float = p.get("lifetime", 0.0)
		var fade_start: float = p.get("fade_start", 0.0)
		var no_gravity: bool = p.get("no_gravity", false)

		lifetime -= delta
		p["lifetime"] = lifetime

		if lifetime <= 0.0:
			_release_particle(node)
			_active_particles.remove_at(i)
			continue

		# Apply velocity with optional gravity
		if not no_gravity:
			velocity.y += 200.0 * delta
			p["velocity"] = velocity
		node.position += velocity * delta

		# Fade out
		if lifetime < fade_start:
			var alpha := lifetime / fade_start
			node.modulate.a = alpha

func _release_particle(particle: ColorRect) -> void:
	particle.visible = false
	_particle_pool.release(particle)

func _ensure_parent(parent: Node) -> void:
	if _parent_node == null:
		_parent_node = parent
		_particle_pool.set_parent(parent)

func clear() -> void:
	for p in _active_particles:
		if p is Dictionary:
			var node = p.get("node")
			if node != null and is_instance_valid(node):
				_release_particle(node)
	_active_particles.clear()

func get_pool_stats() -> Dictionary:
	if _particle_pool != null:
		return _particle_pool.get_stats()
	return {}

func get_active_count() -> int:
	return _active_particles.size()
