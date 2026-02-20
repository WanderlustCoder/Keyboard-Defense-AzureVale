extends CanvasLayer
## Global screen shake system with trauma-based intensity.
## Respects SettingsManager.screen_shake and reduced_motion settings.
## Add as autoload named "ScreenShake" for global access.

signal trauma_changed(new_value: float)

# Configuration
const MAX_OFFSET := Vector2(20.0, 15.0)
const MAX_ROTATION := 0.04
const DECAY_RATE := 0.8
const TRAUMA_POWER := 2.0  # Quadratic for better feel

# Shake presets
const PRESET_LIGHT := 0.2
const PRESET_MEDIUM := 0.4
const PRESET_HEAVY := 0.6
const PRESET_EXTREME := 0.9

# State
var trauma: float = 0.0
var _noise: FastNoiseLite
var _noise_y: float = 0.0
var _camera: Camera2D
var _original_offset: Vector2 = Vector2.ZERO
var _original_rotation: float = 0.0

# Settings reference
var _settings_manager = null


func _ready() -> void:
	layer = 99  # High layer for overlay effects
	_setup_noise()
	_cache_settings_manager()
	call_deferred("_find_camera")


func _setup_noise() -> void:
	_noise = FastNoiseLite.new()
	_noise.seed = randi()
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_noise.frequency = 4.0


func _cache_settings_manager() -> void:
	_settings_manager = get_node_or_null("/root/SettingsManager")


func _find_camera() -> void:
	await get_tree().process_frame
	var viewport := get_viewport()
	if viewport:
		_camera = viewport.get_camera_2d()
		if _camera:
			_original_offset = _camera.offset
			_original_rotation = _camera.rotation


func set_camera(camera: Camera2D) -> void:
	## Manually set the camera to shake.
	_camera = camera
	if _camera:
		_original_offset = _camera.offset
		_original_rotation = _camera.rotation


func add_trauma(amount: float) -> void:
	## Add trauma (0.0-1.0). Clamps to max 1.0.
	if not _is_shake_enabled():
		return

	var old_trauma := trauma
	trauma = clampf(trauma + amount, 0.0, 1.0)

	if trauma != old_trauma:
		trauma_changed.emit(trauma)


func set_trauma(amount: float) -> void:
	## Set trauma directly (0.0-1.0).
	if not _is_shake_enabled():
		trauma = 0.0
		return

	trauma = clampf(amount, 0.0, 1.0)
	trauma_changed.emit(trauma)


func shake_light() -> void:
	## Light shake - small hits, UI feedback
	add_trauma(PRESET_LIGHT)


func shake_medium() -> void:
	## Medium shake - normal hits, word complete
	add_trauma(PRESET_MEDIUM)


func shake_heavy() -> void:
	## Heavy shake - critical hits, enemy death
	add_trauma(PRESET_HEAVY)


func shake_extreme() -> void:
	## Extreme shake - boss hits, defeat
	add_trauma(PRESET_EXTREME)


func _process(delta: float) -> void:
	if trauma <= 0.0 or _camera == null:
		return

	# Decay trauma
	trauma = maxf(0.0, trauma - DECAY_RATE * delta)

	# Calculate shake amount (quadratic for snappier feel)
	var shake_amount := pow(trauma, TRAUMA_POWER)

	# Reduced motion: use smaller offsets, no rotation
	var is_reduced := _is_reduced_motion()
	var effective_offset := MAX_OFFSET * (0.3 if is_reduced else 1.0)
	var effective_rotation := 0.0 if is_reduced else MAX_ROTATION

	# Sample noise
	_noise_y += delta * 50.0
	var offset_x := _noise.get_noise_2d(0.0, _noise_y) * effective_offset.x * shake_amount
	var offset_y := _noise.get_noise_2d(100.0, _noise_y) * effective_offset.y * shake_amount
	var rotation := _noise.get_noise_2d(200.0, _noise_y) * effective_rotation * shake_amount

	# Apply to camera
	_camera.offset = _original_offset + Vector2(offset_x, offset_y)
	_camera.rotation = _original_rotation + rotation

	# Reset when done
	if trauma <= 0.0:
		_camera.offset = _original_offset
		_camera.rotation = _original_rotation


func _is_shake_enabled() -> bool:
	if _settings_manager == null:
		_cache_settings_manager()
	if _settings_manager != null:
		return _settings_manager.screen_shake
	return true


func _is_reduced_motion() -> bool:
	if _settings_manager == null:
		_cache_settings_manager()
	if _settings_manager != null:
		return _settings_manager.reduced_motion
	return false


func get_trauma() -> float:
	return trauma


func is_shaking() -> bool:
	return trauma > 0.0


func reset() -> void:
	## Reset shake state and camera position.
	trauma = 0.0
	if _camera != null:
		_camera.offset = _original_offset
		_camera.rotation = _original_rotation
