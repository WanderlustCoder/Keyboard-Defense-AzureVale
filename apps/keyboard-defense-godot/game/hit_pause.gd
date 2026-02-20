extends Node
## Global hit pause system for impact feedback.
## Briefly freezes game time on impactful events.
## Respects SettingsManager.screen_shake and reduced_motion settings.
## Add as autoload named "HitPause" for global access.

signal pause_started(duration: float)
signal pause_ended

# Configuration
const MIN_PAUSE_DURATION := 0.016  # 1 frame minimum
const MAX_PAUSE_DURATION := 0.25   # Never pause longer than this
const ABSOLUTE_MAX_PAUSE := 0.5    # Safety timeout

# Presets
const PRESET_MICRO := 0.03   # Subtle confirmation
const PRESET_LIGHT := 0.05   # Light hit
const PRESET_MEDIUM := 0.08  # Normal hit
const PRESET_HEAVY := 0.12   # Critical hit
const PRESET_EXTREME := 0.18 # Boss hit, defeat

# State
var _is_paused: bool = false
var _pause_timer: float = 0.0
var _original_time_scale: float = 1.0

# Settings reference
var _settings_manager = null


func _ready() -> void:
	# Must process even when game is paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	_cache_settings_manager()


func _cache_settings_manager() -> void:
	_settings_manager = get_node_or_null("/root/SettingsManager")


func _process(delta: float) -> void:
	if not _is_paused:
		return

	# Use real delta since time_scale is 0
	var real_delta := delta / maxf(Engine.time_scale, 0.001)
	if Engine.time_scale <= 0.001:
		real_delta = delta  # Fallback when time is frozen

	_pause_timer -= get_process_delta_time()

	if _pause_timer <= 0.0:
		_end_pause()


func pause(duration: float) -> void:
	## Pause game time for specified duration (seconds).
	if not _is_pause_enabled():
		return

	# Reduce duration for reduced motion
	if _is_reduced_motion():
		duration *= 0.3

	# Clamp duration
	duration = clampf(duration, MIN_PAUSE_DURATION, MAX_PAUSE_DURATION)

	# If already pausing, extend if new duration is longer
	if _is_paused:
		if duration > _pause_timer:
			_pause_timer = duration
		return

	_start_pause(duration)


func _start_pause(duration: float) -> void:
	_is_paused = true
	_pause_timer = duration
	_original_time_scale = Engine.time_scale
	Engine.time_scale = 0.0
	pause_started.emit(duration)

	# Safety timeout in case something goes wrong
	get_tree().create_timer(ABSOLUTE_MAX_PAUSE, true, false, true).timeout.connect(
		func():
			if _is_paused:
				push_warning("HitPause: Safety timeout triggered, forcing unpause")
				_end_pause()
	)


func _end_pause() -> void:
	if not _is_paused:
		return

	_is_paused = false
	_pause_timer = 0.0
	Engine.time_scale = _original_time_scale
	pause_ended.emit()


func cancel_pause() -> void:
	## Cancel any active pause immediately.
	_end_pause()


func pause_micro() -> void:
	## Micro pause - subtle confirmation feedback.
	pause(PRESET_MICRO)


func pause_light() -> void:
	## Light pause - light hits, small events.
	pause(PRESET_LIGHT)


func pause_medium() -> void:
	## Medium pause - normal hits, word complete.
	pause(PRESET_MEDIUM)


func pause_heavy() -> void:
	## Heavy pause - critical hits, enemy death.
	pause(PRESET_HEAVY)


func pause_extreme() -> void:
	## Extreme pause - boss hits, defeat.
	pause(PRESET_EXTREME)


func is_pausing() -> bool:
	## Returns true if currently pausing.
	return _is_paused


func get_remaining_time() -> float:
	## Get remaining pause time in seconds.
	return _pause_timer if _is_paused else 0.0


func _is_pause_enabled() -> bool:
	# Hit pause follows screen_shake setting
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


func reset() -> void:
	## Reset hit pause state and restore time scale.
	_end_pause()
	Engine.time_scale = 1.0
