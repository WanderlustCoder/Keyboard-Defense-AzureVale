extends Node
## AudioManager - Centralized audio playback for SFX and music

# Audio bus names
const BUS_MASTER := "Master"
const BUS_MUSIC := "Music"
const BUS_SFX := "SFX"

# Audio paths
const SFX_PATH := "res://assets/audio/sfx/"
const MUSIC_PATH := "res://assets/audio/music/"

# Rate limiting for high-frequency sounds (seconds)
const RATE_LIMIT_KEYTAP := 0.05
const RATE_LIMIT_TYPE := 0.03

# Music crossfade duration (seconds)
const MUSIC_FADE_DURATION := 1.5

# SFX IDs
enum SFX {
	UI_KEYTAP,
	UI_CONFIRM,
	UI_CANCEL,
	TYPE_CORRECT,
	TYPE_MISTAKE,
	COMBO_UP,
	COMBO_BREAK,
	BUILD_PLACE,
	BUILD_COMPLETE,
	RESOURCE_PICKUP,
	UNIT_SPAWN,
	ENEMY_SPAWN,
	HIT_PLAYER,
	HIT_ENEMY,
	WAVE_START,
	WAVE_END,
	LEVEL_UP,
	ACHIEVEMENT_UNLOCK,
	UPGRADE_PURCHASE,
	TUTORIAL_DING,
	BOSS_APPEAR,
	BOSS_DEFEATED,
	VICTORY_FANFARE,
	DEFEAT_STINGER
}

# Music tracks
enum Music {
	MENU,
	KINGDOM,
	BATTLE_CALM,
	BATTLE_TENSE,
	VICTORY,
	DEFEAT
}

# SFX file mapping
var _sfx_files := {
	SFX.UI_KEYTAP: "ui_keytap.wav",
	SFX.UI_CONFIRM: "ui_confirm.wav",
	SFX.UI_CANCEL: "ui_cancel.wav",
	SFX.TYPE_CORRECT: "type_correct.wav",
	SFX.TYPE_MISTAKE: "type_mistake.wav",
	SFX.COMBO_UP: "combo_up.wav",
	SFX.COMBO_BREAK: "combo_break.wav",
	SFX.BUILD_PLACE: "build_place.wav",
	SFX.BUILD_COMPLETE: "build_complete.wav",
	SFX.RESOURCE_PICKUP: "resource_pickup.wav",
	SFX.UNIT_SPAWN: "unit_spawn.wav",
	SFX.ENEMY_SPAWN: "enemy_spawn.wav",
	SFX.HIT_PLAYER: "hit_player.wav",
	SFX.HIT_ENEMY: "hit_enemy.wav",
	SFX.WAVE_START: "wave_start.wav",
	SFX.WAVE_END: "wave_end.wav",
	SFX.LEVEL_UP: "level_up.wav",
	SFX.ACHIEVEMENT_UNLOCK: "achievement_unlock.wav",
	SFX.UPGRADE_PURCHASE: "upgrade_purchase.wav",
	SFX.TUTORIAL_DING: "tutorial_ding.wav",
	SFX.BOSS_APPEAR: "boss_appear.wav",
	SFX.BOSS_DEFEATED: "boss_defeated.wav",
	SFX.VICTORY_FANFARE: "victory_fanfare.wav",
	SFX.DEFEAT_STINGER: "defeat_stinger.wav"
}

# Music file mapping
var _music_files := {
	Music.MENU: "menu.wav",
	Music.KINGDOM: "kingdom.wav",
	Music.BATTLE_CALM: "battle_calm.wav",
	Music.BATTLE_TENSE: "battle_tense.wav",
	Music.VICTORY: "victory.wav",
	Music.DEFEAT: "defeat.wav"
}

# Cached audio streams
var _sfx_cache: Dictionary = {}
var _music_cache: Dictionary = {}

# Audio players
var _sfx_players: Array[AudioStreamPlayer] = []
var _music_player_a: AudioStreamPlayer
var _music_player_b: AudioStreamPlayer
var _active_music_player: AudioStreamPlayer
var _stinger_player: AudioStreamPlayer

# State
var _current_music: int = -1
var _music_volume_db: float = 0.0
var _sfx_volume_db: float = 0.0
var _music_enabled: bool = true
var _sfx_enabled: bool = true
var _is_fading: bool = false
var _fade_tween: Tween

# Rate limiting
var _last_play_time: Dictionary = {}

# Pool size for concurrent SFX
const SFX_POOL_SIZE := 8

func _ready() -> void:
	_setup_audio_players()
	_preload_audio()

func _setup_audio_players() -> void:
	# Create SFX player pool
	for i in range(SFX_POOL_SIZE):
		var player := AudioStreamPlayer.new()
		player.bus = BUS_SFX if AudioServer.get_bus_index(BUS_SFX) >= 0 else BUS_MASTER
		add_child(player)
		_sfx_players.append(player)

	# Create music players for crossfading
	_music_player_a = AudioStreamPlayer.new()
	_music_player_a.bus = BUS_MUSIC if AudioServer.get_bus_index(BUS_MUSIC) >= 0 else BUS_MASTER
	add_child(_music_player_a)

	_music_player_b = AudioStreamPlayer.new()
	_music_player_b.bus = BUS_MUSIC if AudioServer.get_bus_index(BUS_MUSIC) >= 0 else BUS_MASTER
	add_child(_music_player_b)

	_active_music_player = _music_player_a

	# Create stinger player (for victory/defeat that play over music)
	_stinger_player = AudioStreamPlayer.new()
	_stinger_player.bus = BUS_MUSIC if AudioServer.get_bus_index(BUS_MUSIC) >= 0 else BUS_MASTER
	add_child(_stinger_player)

func _preload_audio() -> void:
	# Preload all SFX
	for sfx_id in _sfx_files:
		var path: String = SFX_PATH + str(_sfx_files[sfx_id])
		var stream := load(path) as AudioStream
		if stream != null:
			_sfx_cache[sfx_id] = stream

	# Preload all music
	for music_id in _music_files:
		var path: String = MUSIC_PATH + str(_music_files[music_id])
		var stream := load(path) as AudioStream
		if stream != null:
			_music_cache[music_id] = stream

## Play a sound effect
func play_sfx(sfx_id: int, volume_offset_db: float = 0.0) -> void:
	if not _sfx_enabled:
		return
	if not _sfx_cache.has(sfx_id):
		return

	# Rate limiting for high-frequency sounds
	var now := Time.get_ticks_msec() / 1000.0
	if _last_play_time.has(sfx_id):
		var limit := 0.0
		match sfx_id:
			SFX.UI_KEYTAP:
				limit = RATE_LIMIT_KEYTAP
			SFX.TYPE_CORRECT, SFX.TYPE_MISTAKE:
				limit = RATE_LIMIT_TYPE
		if limit > 0.0 and now - _last_play_time[sfx_id] < limit:
			return
	_last_play_time[sfx_id] = now

	# Find available player
	var player := _get_available_sfx_player()
	if player == null:
		return

	player.stream = _sfx_cache[sfx_id]
	player.volume_db = _sfx_volume_db + volume_offset_db
	player.play()

func _get_available_sfx_player() -> AudioStreamPlayer:
	for player in _sfx_players:
		if not player.playing:
			return player
	# All busy, steal the first one
	return _sfx_players[0]

## Play music with optional crossfade
func play_music(music_id: int, crossfade: bool = true) -> void:
	if not _music_enabled:
		return
	if music_id == _current_music:
		return
	if not _music_cache.has(music_id):
		return

	_current_music = music_id
	var stream: AudioStream = _music_cache[music_id]

	# Determine if this is a looping track or one-shot
	var is_loop := music_id in [Music.MENU, Music.KINGDOM, Music.BATTLE_CALM, Music.BATTLE_TENSE]

	if crossfade and _active_music_player.playing:
		_crossfade_to(stream, is_loop)
	else:
		_play_music_immediate(stream, is_loop)

func _play_music_immediate(stream: AudioStream, loop: bool) -> void:
	_music_player_a.stop()
	_music_player_b.stop()
	_active_music_player = _music_player_a
	_active_music_player.stream = stream
	_active_music_player.volume_db = _music_volume_db
	_active_music_player.play()

func _crossfade_to(stream: AudioStream, loop: bool) -> void:
	if _is_fading:
		if _fade_tween != null:
			_fade_tween.kill()

	_is_fading = true

	# Swap active player
	var old_player := _active_music_player
	var new_player := _music_player_b if _active_music_player == _music_player_a else _music_player_a
	_active_music_player = new_player

	# Setup new player
	new_player.stream = stream
	new_player.volume_db = -40.0
	new_player.play()

	# Create crossfade tween
	_fade_tween = create_tween()
	_fade_tween.set_parallel(true)
	_fade_tween.tween_property(old_player, "volume_db", -40.0, MUSIC_FADE_DURATION)
	_fade_tween.tween_property(new_player, "volume_db", _music_volume_db, MUSIC_FADE_DURATION)
	_fade_tween.set_parallel(false)
	_fade_tween.tween_callback(func():
		old_player.stop()
		_is_fading = false
	)

## Play a stinger (one-shot music that plays over current music)
func play_stinger(music_id: int) -> void:
	if not _music_enabled:
		return
	if not _music_cache.has(music_id):
		return

	# Lower current music volume temporarily
	if _active_music_player.playing:
		var tween := create_tween()
		tween.tween_property(_active_music_player, "volume_db", _music_volume_db - 8.0, 0.2)

	_stinger_player.stream = _music_cache[music_id]
	_stinger_player.volume_db = _music_volume_db
	_stinger_player.play()

	# Restore music volume when stinger ends
	_stinger_player.finished.connect(_on_stinger_finished, CONNECT_ONE_SHOT)

func _on_stinger_finished() -> void:
	if _active_music_player.playing:
		var tween := create_tween()
		tween.tween_property(_active_music_player, "volume_db", _music_volume_db, 0.5)

## Stop all music
func stop_music(fade_out: bool = true) -> void:
	_current_music = -1
	if fade_out:
		var tween := create_tween()
		tween.tween_property(_music_player_a, "volume_db", -40.0, 0.5)
		tween.parallel().tween_property(_music_player_b, "volume_db", -40.0, 0.5)
		tween.tween_callback(func():
			_music_player_a.stop()
			_music_player_b.stop()
		)
	else:
		_music_player_a.stop()
		_music_player_b.stop()

## Volume controls
func set_music_volume(linear: float) -> void:
	_music_volume_db = linear_to_db(clamp(linear, 0.0, 1.0))
	if _active_music_player.playing:
		_active_music_player.volume_db = _music_volume_db

func set_sfx_volume(linear: float) -> void:
	_sfx_volume_db = linear_to_db(clamp(linear, 0.0, 1.0))

func get_music_volume() -> float:
	return db_to_linear(_music_volume_db)

func get_sfx_volume() -> float:
	return db_to_linear(_sfx_volume_db)

func set_music_enabled(enabled: bool) -> void:
	_music_enabled = enabled
	if not enabled:
		stop_music(true)

func set_sfx_enabled(enabled: bool) -> void:
	_sfx_enabled = enabled

func is_music_enabled() -> bool:
	return _music_enabled

func is_sfx_enabled() -> bool:
	return _sfx_enabled

## Convenience methods for common sounds
func play_ui_confirm() -> void:
	play_sfx(SFX.UI_CONFIRM)

func play_ui_cancel() -> void:
	play_sfx(SFX.UI_CANCEL)

func play_type_correct() -> void:
	play_sfx(SFX.TYPE_CORRECT)

func play_type_mistake() -> void:
	play_sfx(SFX.TYPE_MISTAKE)

func play_combo_up() -> void:
	play_sfx(SFX.COMBO_UP)

func play_combo_break() -> void:
	play_sfx(SFX.COMBO_BREAK)

func play_hit_enemy() -> void:
	play_sfx(SFX.HIT_ENEMY)

func play_hit_player() -> void:
	play_sfx(SFX.HIT_PLAYER)

func play_wave_start() -> void:
	play_sfx(SFX.WAVE_START)

func play_wave_end() -> void:
	play_sfx(SFX.WAVE_END)

func play_victory() -> void:
	play_sfx(SFX.VICTORY_FANFARE)
	play_stinger(Music.VICTORY)

func play_defeat() -> void:
	play_sfx(SFX.DEFEAT_STINGER)
	play_stinger(Music.DEFEAT)

func play_level_up() -> void:
	play_sfx(SFX.LEVEL_UP)

func play_upgrade_purchase() -> void:
	play_sfx(SFX.UPGRADE_PURCHASE)

## Music context switching
func switch_to_menu_music() -> void:
	play_music(Music.MENU)

func switch_to_kingdom_music() -> void:
	play_music(Music.KINGDOM)

func switch_to_battle_music(tense: bool = false) -> void:
	play_music(Music.BATTLE_TENSE if tense else Music.BATTLE_CALM)

func set_battle_intensity(tense: bool) -> void:
	if _current_music in [Music.BATTLE_CALM, Music.BATTLE_TENSE]:
		var target := Music.BATTLE_TENSE if tense else Music.BATTLE_CALM
		if _current_music != target:
			play_music(target, true)
