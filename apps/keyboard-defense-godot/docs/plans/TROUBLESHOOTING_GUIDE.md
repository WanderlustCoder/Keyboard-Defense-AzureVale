# Troubleshooting Guide

## Common Issues & Solutions

---

## Screen Shake Issues

### Issue: No screen shake at all
**Symptoms**: Camera never moves despite triggers

**Checklist**:
1. Is ScreenShake autoload registered in `project.godot`?
   ```ini
   ScreenShake="*res://game/screen_shake.gd"
   ```

2. Is `SettingsManager.screen_shake` enabled?
   ```gdscript
   var settings = get_node_or_null("/root/SettingsManager")
   print(settings.screen_shake)  # Should be true
   ```

3. Is camera being found?
   ```gdscript
   var shake = get_node_or_null("/root/ScreenShake")
   print(shake._camera)  # Should not be null
   ```

**Fix**: Manually set camera if auto-detection fails:
```gdscript
func _ready() -> void:
	var shake = get_node_or_null("/root/ScreenShake")
	if shake != null:
		shake.set_camera($Camera2D)
```

### Issue: Screen shake too strong/weak
**Symptoms**: Shake is too intense or barely visible

**Fix**: Adjust constants in `game/screen_shake.gd`:
```gdscript
# Reduce intensity
const MAX_OFFSET := Vector2(12.0, 8.0)  # Was (20.0, 15.0)
const MAX_ROTATION := 0.02  # Was 0.04

# Or adjust decay for shorter duration
const DECAY_RATE := 1.2  # Was 0.8
```

### Issue: Screen shake persists after scene change
**Symptoms**: New scene has shake from previous scene

**Fix**: Reset shake on scene exit:
```gdscript
func _exit_tree() -> void:
	var shake = get_node_or_null("/root/ScreenShake")
	if shake != null:
		shake.set_trauma(0.0)
```

---

## Hit Pause Issues

### Issue: Game freezes permanently
**Symptoms**: Game stops and never resumes

**Checklist**:
1. Is `process_mode` set correctly?
   ```gdscript
   # In HitPause._ready():
   process_mode = Node.PROCESS_MODE_ALWAYS
   ```

2. Is pause being cancelled on scene exit?
   ```gdscript
   func _exit_tree() -> void:
		var pause = get_node_or_null("/root/HitPause")
		if pause != null:
			pause.cancel_pause()
   ```

**Fix**: Add safety timeout:
```gdscript
const ABSOLUTE_MAX_PAUSE := 0.5  # Never pause longer than this

func pause(duration: float) -> void:
	duration = minf(duration, ABSOLUTE_MAX_PAUSE)
	# ...
```

### Issue: Hit pause feels sluggish
**Symptoms**: Pauses interrupt flow negatively

**Fix**: Reduce durations:
```gdscript
const PRESET_LIGHT := 0.03   # Was 0.05
const PRESET_MEDIUM := 0.05  # Was 0.08
const PRESET_HEAVY := 0.08   # Was 0.12
```

---

## Damage Number Issues

### Issue: Numbers appear at wrong position
**Symptoms**: Numbers spawn far from impact point

**Checklist**:
1. Is position in global or local coordinates?
   ```gdscript
   # Use global position
   damage_numbers.spawn(enemy.global_position, 50, "damage")

   # Not local
   # damage_numbers.spawn(enemy.position, 50, "damage")
   ```

2. Is parent set correctly?
   ```gdscript
   damage_numbers.set_parent(some_control_that_exists)
   ```

**Fix**: Ensure correct coordinate space:
```gdscript
func spawn_at_node(node: Node2D, value: int) -> void:
	var global_pos := node.global_position
	# Offset above the node
	spawn(global_pos + Vector2(0, -20), value, "damage")
```

### Issue: Numbers don't appear
**Symptoms**: No floating numbers visible

**Checklist**:
1. Is parent set?
   ```gdscript
   print(damage_numbers._parent)  # Should not be null
   ```

2. Is parent in scene tree?
   ```gdscript
   print(damage_numbers._parent.is_inside_tree())  # Should be true
   ```

3. Is pool exhausted?
   ```gdscript
   print(damage_numbers.get_active_count())  # Check if at limit
   ```

**Fix**: Initialize properly:
```gdscript
func _ready() -> void:
	damage_numbers = DamageNumbers.new()
	add_child(damage_numbers)
	damage_numbers.set_parent(self)  # Or a specific container
```

### Issue: Too many numbers cause lag
**Symptoms**: FPS drops with many damage numbers

**Fix**: Reduce pool size and spawn rate:
```gdscript
const POOL_SIZE := 10      # Was 20
const MAX_POOL_SIZE := 25  # Was 50

# Add spawn throttle
var _last_spawn_time: float = 0.0
const MIN_SPAWN_INTERVAL := 0.05

func spawn(...) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	if now - _last_spawn_time < MIN_SPAWN_INTERVAL:
		return
	_last_spawn_time = now
	# ... spawn logic
```

---

## Particle Issues

### Issue: Particles don't render
**Symptoms**: No visual particles appear

**Checklist**:
1. Is hit_effects instance created?
   ```gdscript
   print(hit_effects)  # Should not be null
   ```

2. Is parent set?
   ```gdscript
   hit_effects.set_parent(projectile_layer)
   ```

3. Is update being called?
   ```gdscript
   # In _process:
   hit_effects.update(delta)
   ```

**Fix**: Ensure proper initialization:
```gdscript
func _ready() -> void:
	hit_effects = HitEffects.new()
	add_child(hit_effects)
	hit_effects.set_parent($ParticleLayer)
```

### Issue: Particles persist after clear
**Symptoms**: Old particles remain visible

**Fix**: Ensure proper cleanup:
```gdscript
func clear() -> void:
	for p in _active_particles:
		if p is Dictionary:
			var node = p.get("node")
			if node != null and is_instance_valid(node):
				node.visible = false
				node.queue_free()  # Or release to pool
	_active_particles.clear()
```

---

## Scene Transition Issues

### Issue: Black screen after transition
**Symptoms**: Screen stays black, scene doesn't appear

**Checklist**:
1. Is scene path correct?
   ```gdscript
   print(FileAccess.file_exists("res://scenes/Target.tscn"))
   ```

2. Is overlay being hidden?
   ```gdscript
   # In _play_transition_in, ensure:
   tween.tween_property(_overlay, "color:a", 0.0, duration)
   ```

**Fix**: Add safety reset:
```gdscript
func _reset_overlay() -> void:
	if _overlay != null:
		_overlay.color.a = 0.0
		_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
```

### Issue: Transition never completes
**Symptoms**: Stuck mid-transition

**Fix**: Add timeout safety:
```gdscript
func transition_to_scene(path: String, ...) -> void:
	# ...

	# Safety timeout
	get_tree().create_timer(5.0).timeout.connect(func():
		if _is_transitioning:
			push_warning("Transition timed out, forcing completion")
			_is_transitioning = false
			_reset_overlay()
	)
```

---

## Audio Issues

### Issue: Sounds don't play
**Symptoms**: No audio output

**Checklist**:
1. Is AudioManager autoload registered?
2. Is SFX enabled in settings?
   ```gdscript
   var settings = get_node_or_null("/root/SettingsManager")
   print(settings.sfx_enabled)
   ```

3. Are audio files present?
   ```bash
   ls assets/audio/sfx/
   ```

**Fix**: Check audio bus configuration in Godot:
- Open Project > Project Settings > Audio
- Ensure buses exist: Master, Music, SFX

### Issue: Sound plays too often (spam)
**Symptoms**: Rapid-fire sounds are annoying

**Fix**: Implement rate limiting:
```gdscript
var _sound_cooldowns: Dictionary = {}
const DEFAULT_COOLDOWN := 0.05

func play_with_cooldown(sfx_id: SFX, cooldown: float = DEFAULT_COOLDOWN) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	var last: float = _sound_cooldowns.get(sfx_id, 0.0)

	if now - last < cooldown:
		return

	_sound_cooldowns[sfx_id] = now
	play_sfx(sfx_id)
```

---

## Settings Integration Issues

### Issue: Settings not persisting
**Symptoms**: Settings reset on game restart

**Checklist**:
1. Is `save_settings()` being called?
   ```gdscript
   var settings = get_node_or_null("/root/SettingsManager")
   settings.screen_shake = false
	settings.save_settings()  # Must call this!
   ```

2. Is file writable?
   ```gdscript
   print(OS.get_user_data_dir())
   # Check if user://settings.cfg can be written
   ```

**Fix**: Auto-save on change:
```gdscript
func set_screen_shake(value: bool) -> void:
	screen_shake = value
	settings_changed.emit()
	save_settings()  # Auto-save
```

### Issue: Settings not applied to new features
**Symptoms**: New polish feature ignores settings

**Fix**: Always check settings in new features:
```gdscript
# Template for new feature:
var _settings_manager = null

func _ready() -> void:
	_settings_manager = get_node_or_null("/root/SettingsManager")

func _is_enabled() -> bool:
	if _settings_manager != null:
		return _settings_manager.screen_shake  # Or relevant setting
	return true
```

---

## Performance Issues

### Issue: FPS drops during effects
**Symptoms**: Game slows down with many effects

**Diagnosis**:
```gdscript
func _process(delta: float) -> void:
	var fps := Engine.get_frames_per_second()
	if fps < 50:
		print("FPS: %d, Active particles: %d, Active numbers: %d" % [
			fps,
			hit_effects.get_active_count() if hit_effects else 0,
			damage_numbers.get_active_count() if damage_numbers else 0
		])
```

**Fixes**:
1. Reduce pool sizes
2. Reduce particle counts
3. Simplify particle physics
4. Use spatial hash for particle culling

### Issue: Memory growing over time
**Symptoms**: Memory usage increases continuously

**Diagnosis**:
```gdscript
func _process(delta: float) -> void:
	print("Memory: %d MB" % (OS.get_static_memory_usage() / 1048576))
```

**Fixes**:
1. Ensure all particles are released to pool
2. Check for orphan nodes
3. Verify queue_free() is called

---

## Debug Commands

Add these to your debug panel:

```gdscript
func _debug_command(cmd: String) -> void:
	match cmd:
		"shake":
			var shake = get_node_or_null("/root/ScreenShake")
			if shake: shake.shake_heavy()

		"pause":
			var pause = get_node_or_null("/root/HitPause")
			if pause: pause.pause_heavy()

		"damage":
			damage_numbers.spawn_damage(Vector2(400, 300), 999, true)

		"particles":
			hit_effects.spawn_power_burst(self, Vector2(400, 300))

		"pool_stats":
			print("Particles: %d" % hit_effects.get_active_count())
			print("Numbers: %d" % damage_numbers.get_active_count())

		"settings":
			var s = get_node_or_null("/root/SettingsManager")
			print("shake=%s motion=%s contrast=%s" % [
				s.screen_shake, s.reduced_motion, s.high_contrast
			])
```
