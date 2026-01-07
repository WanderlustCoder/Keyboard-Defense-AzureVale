extends Node
class_name HitEffects
## Simple particle effect spawner for combat feedback

const PARTICLE_COUNT := 6
const PARTICLE_LIFETIME := 0.4
const PARTICLE_SPEED := 120.0
const PARTICLE_SIZE := Vector2(4, 4)
const SPARK_SIZE := Vector2(6, 2)

var _active_particles: Array = []

func spawn_hit_sparks(parent: Node, position: Vector2, color: Color = Color(1.0, 0.9, 0.5, 1.0)) -> void:
	for i in range(PARTICLE_COUNT):
		var particle := ColorRect.new()
		particle.size = SPARK_SIZE if i % 2 == 0 else PARTICLE_SIZE
		particle.color = color
		particle.position = position - particle.size * 0.5
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
	# Larger, brighter burst for power shots
	for i in range(PARTICLE_COUNT + 4):
		var particle := ColorRect.new()
		particle.size = SPARK_SIZE * 1.5 if i % 2 == 0 else PARTICLE_SIZE * 1.3
		particle.color = Color(1.0, 0.95, 0.6, 1.0)
		particle.position = position - particle.size * 0.5
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
	# Red damage particles when castle is hit
	for i in range(8):
		var particle := ColorRect.new()
		particle.size = PARTICLE_SIZE * 1.2
		particle.color = Color(1.0, 0.3, 0.2, 1.0)
		particle.position = position - particle.size * 0.5
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

		lifetime -= delta
		p["lifetime"] = lifetime

		if lifetime <= 0.0:
			node.queue_free()
			_active_particles.remove_at(i)
			continue

		# Apply velocity with gravity
		velocity.y += 200.0 * delta
		p["velocity"] = velocity
		node.position += velocity * delta

		# Fade out
		if lifetime < fade_start:
			var alpha := lifetime / fade_start
			node.modulate.a = alpha

func clear() -> void:
	for p in _active_particles:
		if p is Dictionary:
			var node = p.get("node")
			if node != null and is_instance_valid(node):
				node.queue_free()
	_active_particles.clear()
