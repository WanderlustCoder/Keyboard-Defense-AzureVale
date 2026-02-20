class_name AmbientAudio
extends RefCounted
## Manages ambient sound layers for atmosphere.

const AMBIENT_FADE_DURATION := 2.0

enum AmbientType {
	NONE,
	KINGDOM,      # Birds, wind, distant activity
	BATTLE,       # Distant thunder, tension
	MENU,         # Subtle wind
	VICTORY,      # Celebration, cheering
	DEFEAT        # Wind, desolation
}

var _audio_manager = null
var _current_ambient: AmbientType = AmbientType.NONE
var _ambient_player: AudioStreamPlayer = null
var _ambient_volume: float = -6.0
var _fade_tween: Tween = null


func _init() -> void:
	# Create ambient player
	_ambient_player = AudioStreamPlayer.new()
	_ambient_player.bus = "SFX"
	_ambient_player.volume_db = -40.0  # Start silent


func set_audio_manager(manager) -> void:
	_audio_manager = manager
	if _audio_manager != null and _ambient_player.get_parent() == null:
		_audio_manager.add_child(_ambient_player)


func get_ambient_player() -> AudioStreamPlayer:
	return _ambient_player


func set_ambient(ambient_type: AmbientType, fade_duration: float = AMBIENT_FADE_DURATION) -> void:
	if ambient_type == _current_ambient:
		return

	_current_ambient = ambient_type

	if ambient_type == AmbientType.NONE:
		_fade_out_ambient(fade_duration)
		return

	# Would load ambient sound file here
	# For now, just manage the state
	_fade_in_ambient(fade_duration)


func get_current_ambient() -> AmbientType:
	return _current_ambient


func _fade_in_ambient(duration: float) -> void:
	if _ambient_player == null:
		return

	_kill_fade_tween()

	_fade_tween = _ambient_player.create_tween()
	if _fade_tween != null:
		_fade_tween.tween_property(_ambient_player, "volume_db", _ambient_volume, duration)


func _fade_out_ambient(duration: float) -> void:
	if _ambient_player == null:
		return

	_kill_fade_tween()

	_fade_tween = _ambient_player.create_tween()
	if _fade_tween != null:
		_fade_tween.tween_property(_ambient_player, "volume_db", -40.0, duration)
		_fade_tween.tween_callback(func(): _ambient_player.stop())


func _kill_fade_tween() -> void:
	if _fade_tween != null and _fade_tween.is_valid():
		_fade_tween.kill()
		_fade_tween = null


func set_ambient_volume(volume_db: float) -> void:
	_ambient_volume = volume_db
	if _ambient_player != null and _current_ambient != AmbientType.NONE:
		_ambient_player.volume_db = volume_db


func stop() -> void:
	_current_ambient = AmbientType.NONE
	_kill_fade_tween()
	if _ambient_player != null:
		_ambient_player.stop()
