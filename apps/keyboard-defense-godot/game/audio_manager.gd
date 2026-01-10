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
	COMBO_MILESTONE_5,
	COMBO_MILESTONE_10,
	COMBO_MILESTONE_20,
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
	DEFEAT_STINGER,
	EVENT_SHOW,
	EVENT_CHOICE,
	EVENT_SUCCESS,
	EVENT_FAIL,
	EVENT_SKIP,
	POI_APPEAR,
	THREAT_PULSE_LOW,
	THREAT_PULSE_HIGH,
	WORD_COMPLETE
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
	SFX.COMBO_MILESTONE_5: "combo_up.wav",  # Reuse combo_up with pitch shift
	SFX.COMBO_MILESTONE_10: "combo_up.wav",
	SFX.COMBO_MILESTONE_20: "level_up.wav",  # Use level_up for major milestone
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
	SFX.DEFEAT_STINGER: "defeat_stinger.wav",
	SFX.EVENT_SHOW: "event_show.wav",
	SFX.EVENT_CHOICE: "event_choice.wav",
	SFX.EVENT_SUCCESS: "event_success.wav",
	SFX.EVENT_FAIL: "event_fail.wav",
	SFX.EVENT_SKIP: "event_skip.wav",
	SFX.POI_APPEAR: "poi_appear.wav",
	SFX.THREAT_PULSE_LOW: "hit_player.wav",  # Reuse hit_player with low pitch
	SFX.THREAT_PULSE_HIGH: "hit_player.wav",  # Reuse with higher pitch
	SFX.WORD_COMPLETE: "combo_up.wav"  # Reuse combo_up with slight pitch variation
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
	var missing_sfx: Array[String] = []
	var missing_music: Array[String] = []

	# Preload all SFX
	for sfx_id in _sfx_files:
		var path: String = SFX_PATH + str(_sfx_files[sfx_id])
		var stream := load(path) as AudioStream
		if stream != null:
			_sfx_cache[sfx_id] = stream
		else:
			missing_sfx.append(str(_sfx_files[sfx_id]))

	# Preload all music
	for music_id in _music_files:
		var path: String = MUSIC_PATH + str(_music_files[music_id])
		var stream := load(path) as AudioStream
		if stream != null:
			_music_cache[music_id] = stream
		else:
			missing_music.append(str(_music_files[music_id]))

	# Log summary of missing audio (avoids spamming console)
	if not missing_sfx.is_empty():
		push_warning("AudioManager: Missing SFX files (%d): %s" % [missing_sfx.size(), ", ".join(missing_sfx)])
	if not missing_music.is_empty():
		push_warning("AudioManager: Missing music files (%d): %s" % [missing_music.size(), ", ".join(missing_music)])

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
	if _active_music_player.playing and not _is_ducked:
		_active_music_player.volume_db = _music_volume_db

func set_sfx_volume(linear: float) -> void:
	_sfx_volume_db = linear_to_db(clamp(linear, 0.0, 1.0))

func get_music_volume() -> float:
	return db_to_linear(_music_volume_db)

## Audio ducking for dialogue/tutorial
var _is_ducked: bool = false
var _duck_tween: Tween = null
const DUCK_AMOUNT_DB := -12.0
const DUCK_FADE_DURATION := 0.3

func start_ducking() -> void:
	if _is_ducked:
		return
	_is_ducked = true

	# Kill existing tween
	if _duck_tween != null and _duck_tween.is_valid():
		_duck_tween.kill()

	# Fade music volume down
	_duck_tween = create_tween()
	var target_db := _music_volume_db + DUCK_AMOUNT_DB
	_duck_tween.tween_property(_active_music_player, "volume_db", target_db, DUCK_FADE_DURATION)

func stop_ducking() -> void:
	if not _is_ducked:
		return
	_is_ducked = false

	# Kill existing tween
	if _duck_tween != null and _duck_tween.is_valid():
		_duck_tween.kill()

	# Fade music volume back up
	_duck_tween = create_tween()
	_duck_tween.tween_property(_active_music_player, "volume_db", _music_volume_db, DUCK_FADE_DURATION)

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

func play_ui_hover() -> void:
	# Use keytap at lower volume for subtle hover feedback
	play_sfx(SFX.UI_KEYTAP, -8.0)

func play_type_correct() -> void:
	play_sfx(SFX.TYPE_CORRECT)

func play_type_mistake() -> void:
	play_sfx(SFX.TYPE_MISTAKE)

func play_combo_up() -> void:
	play_sfx(SFX.COMBO_UP)

func play_combo_break() -> void:
	play_sfx(SFX.COMBO_BREAK)

func play_word_complete() -> void:
	# Slightly higher pitch for satisfying word completion feedback
	play_sfx_pitched(SFX.WORD_COMPLETE, 1.15, -3.0)

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

func play_event_show() -> void:
	play_sfx(SFX.EVENT_SHOW)

func play_event_choice() -> void:
	play_sfx(SFX.EVENT_CHOICE)

func play_event_success() -> void:
	play_sfx(SFX.EVENT_SUCCESS)

func play_event_fail() -> void:
	play_sfx(SFX.EVENT_FAIL)

func play_event_skip() -> void:
	play_sfx(SFX.EVENT_SKIP)

func play_poi_appear() -> void:
	play_sfx(SFX.POI_APPEAR)

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

## Threat pulse audio system
var _threat_pulse_timer: float = 0.0
var _threat_pulse_active: bool = false
var _threat_level: float = 0.0
const THREAT_PULSE_THRESHOLD_LOW := 0.6  # Start pulsing at 60%
const THREAT_PULSE_THRESHOLD_HIGH := 0.85  # Faster pulse at 85%

func update_threat_audio(threat_percent: float, delta: float) -> void:
	_threat_level = clamp(threat_percent, 0.0, 1.0)

	# No pulsing below threshold
	if _threat_level < THREAT_PULSE_THRESHOLD_LOW:
		_threat_pulse_active = false
		_threat_pulse_timer = 0.0
		return

	_threat_pulse_active = true

	# Calculate pulse interval based on threat level
	var pulse_interval: float
	if _threat_level >= THREAT_PULSE_THRESHOLD_HIGH:
		# Fast pulse at high threat (0.4s interval)
		pulse_interval = 0.4
	else:
		# Slower pulse at medium threat (0.8s interval)
		pulse_interval = 0.8

	_threat_pulse_timer += delta
	if _threat_pulse_timer >= pulse_interval:
		_threat_pulse_timer = 0.0
		_play_threat_pulse()

func _play_threat_pulse() -> void:
	if not _sfx_enabled:
		return

	# Use different sound based on threat level
	var sfx_id: int
	var pitch: float
	var volume_offset: float

	if _threat_level >= THREAT_PULSE_THRESHOLD_HIGH:
		sfx_id = SFX.THREAT_PULSE_HIGH
		pitch = 1.2
		volume_offset = -4.0
	else:
		sfx_id = SFX.THREAT_PULSE_LOW
		pitch = 0.8
		volume_offset = -8.0

	play_sfx_pitched(sfx_id, pitch, volume_offset)

## Play SFX with pitch shift
func play_sfx_pitched(sfx_id: int, pitch: float, volume_offset_db: float = 0.0) -> void:
	if not _sfx_enabled:
		return
	if not _sfx_cache.has(sfx_id):
		return

	var player := _get_available_sfx_player()
	if player == null:
		return

	player.stream = _sfx_cache[sfx_id]
	player.pitch_scale = pitch
	player.volume_db = _sfx_volume_db + volume_offset_db
	player.play()
	# Reset pitch after a frame to not affect other sounds
	await get_tree().process_frame
	player.pitch_scale = 1.0

## Combo milestone sounds
func play_combo_milestone(combo_count: int) -> void:
	if combo_count == 5:
		play_sfx_pitched(SFX.COMBO_MILESTONE_5, 1.1, -2.0)
	elif combo_count == 10:
		play_sfx_pitched(SFX.COMBO_MILESTONE_10, 1.2, 0.0)
	elif combo_count == 15:
		play_sfx_pitched(SFX.COMBO_MILESTONE_10, 1.3, 0.0)
	elif combo_count >= 20 and combo_count % 10 == 0:
		# Major milestone every 10 after 20
		play_sfx(SFX.COMBO_MILESTONE_20, 2.0)

func stop_threat_pulse() -> void:
	_threat_pulse_active = false
	_threat_pulse_timer = 0.0
	_threat_level = 0.0
