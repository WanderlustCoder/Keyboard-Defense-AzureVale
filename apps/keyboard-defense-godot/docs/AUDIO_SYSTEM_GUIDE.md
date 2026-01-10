# Audio System Guide

This document explains the centralized audio management system in Keyboard Defense, covering SFX playback, music crossfading, stingers, and volume control.

## Overview

The AudioManager is an autoload singleton that handles all game audio:

```
AudioManager (Node)
├── SFX Player Pool (8 players)
├── Music Player A (crossfade)
├── Music Player B (crossfade)
└── Stinger Player (overlays)
```

## Audio Bus Structure

```gdscript
# game/audio_manager.gd
const BUS_MASTER := "Master"
const BUS_MUSIC := "Music"
const BUS_SFX := "SFX"
```

Configure in Godot's Audio Bus Layout:
```
Master
├── Music  (for background music)
└── SFX    (for sound effects)
```

## SFX System

### SFX Enum

```gdscript
enum SFX {
    # UI sounds
    UI_KEYTAP,
    UI_CONFIRM,
    UI_CANCEL,

    # Typing feedback
    TYPE_CORRECT,
    TYPE_MISTAKE,
    COMBO_UP,
    COMBO_BREAK,

    # Building
    BUILD_PLACE,
    BUILD_COMPLETE,
    RESOURCE_PICKUP,

    # Combat
    UNIT_SPAWN,
    ENEMY_SPAWN,
    HIT_PLAYER,
    HIT_ENEMY,
    WAVE_START,
    WAVE_END,

    # Progression
    LEVEL_UP,
    ACHIEVEMENT_UNLOCK,
    UPGRADE_PURCHASE,
    TUTORIAL_DING,

    # Boss
    BOSS_APPEAR,
    BOSS_DEFEATED,
    VICTORY_FANFARE,
    DEFEAT_STINGER,

    # Events
    EVENT_SHOW,
    EVENT_CHOICE,
    EVENT_SUCCESS,
    EVENT_FAIL,
    EVENT_SKIP,
    POI_APPEAR
}
```

### SFX File Mapping

```gdscript
var _sfx_files := {
    SFX.UI_KEYTAP: "ui_keytap.wav",
    SFX.UI_CONFIRM: "ui_confirm.wav",
    SFX.TYPE_CORRECT: "type_correct.wav",
    // ...
}
```

Files are stored in `res://assets/audio/sfx/`.

### Playing SFX

```gdscript
# Basic playback
AudioManager.play_sfx(AudioManager.SFX.UI_CONFIRM)

# With volume offset
AudioManager.play_sfx(AudioManager.SFX.HIT_ENEMY, -3.0)  # Quieter

# Convenience methods
AudioManager.play_type_correct()
AudioManager.play_type_mistake()
AudioManager.play_combo_up()
AudioManager.play_hit_enemy()
```

### SFX Player Pool

The pool prevents audio cutoff when many sounds play simultaneously:

```gdscript
const SFX_POOL_SIZE := 8

func _setup_audio_players() -> void:
    for i in range(SFX_POOL_SIZE):
        var player := AudioStreamPlayer.new()
        player.bus = BUS_SFX
        add_child(player)
        _sfx_players.append(player)

func _get_available_sfx_player() -> AudioStreamPlayer:
    for player in _sfx_players:
        if not player.playing:
            return player
    # All busy, steal the first one
    return _sfx_players[0]
```

### Rate Limiting

High-frequency sounds are rate-limited to prevent audio spam:

```gdscript
const RATE_LIMIT_KEYTAP := 0.05   # 50ms between keytaps
const RATE_LIMIT_TYPE := 0.03     # 30ms between type sounds

func play_sfx(sfx_id: int, volume_offset_db: float = 0.0) -> void:
    var now := Time.get_ticks_msec() / 1000.0

    if _last_play_time.has(sfx_id):
        var limit := 0.0
        match sfx_id:
            SFX.UI_KEYTAP:
                limit = RATE_LIMIT_KEYTAP
            SFX.TYPE_CORRECT, SFX.TYPE_MISTAKE:
                limit = RATE_LIMIT_TYPE

        if limit > 0.0 and now - _last_play_time[sfx_id] < limit:
            return  # Too soon, skip

    _last_play_time[sfx_id] = now
    // ... play sound
```

## Music System

### Music Tracks

```gdscript
enum Music {
    MENU,           # Main menu theme
    KINGDOM,        # Day phase / kingdom view
    BATTLE_CALM,    # Night phase, low threat
    BATTLE_TENSE,   # Night phase, high threat
    VICTORY,        # Wave completion
    DEFEAT          # Game over
}

var _music_files := {
    Music.MENU: "menu.wav",
    Music.KINGDOM: "kingdom.wav",
    Music.BATTLE_CALM: "battle_calm.wav",
    Music.BATTLE_TENSE: "battle_tense.wav",
    Music.VICTORY: "victory.wav",
    Music.DEFEAT: "defeat.wav"
}
```

Files are stored in `res://assets/audio/music/`.

### Playing Music

```gdscript
# With crossfade (default)
AudioManager.play_music(AudioManager.Music.KINGDOM)

# Immediate switch (no crossfade)
AudioManager.play_music(AudioManager.Music.BATTLE_CALM, false)

# Convenience methods
AudioManager.switch_to_menu_music()
AudioManager.switch_to_kingdom_music()
AudioManager.switch_to_battle_music(tense: bool)
```

### Music Crossfading

Two music players enable smooth transitions:

```gdscript
const MUSIC_FADE_DURATION := 1.5  # seconds

var _music_player_a: AudioStreamPlayer
var _music_player_b: AudioStreamPlayer
var _active_music_player: AudioStreamPlayer

func _crossfade_to(stream: AudioStream, loop: bool) -> void:
    # Swap active player
    var old_player := _active_music_player
    var new_player := _music_player_b if _active_music_player == _music_player_a else _music_player_a
    _active_music_player = new_player

    # Setup new player at low volume
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
```

### Dynamic Battle Music

Switch between calm and tense based on threat level:

```gdscript
func set_battle_intensity(tense: bool) -> void:
    if _current_music in [Music.BATTLE_CALM, Music.BATTLE_TENSE]:
        var target := Music.BATTLE_TENSE if tense else Music.BATTLE_CALM
        if _current_music != target:
            play_music(target, true)  # Crossfade
```

Usage:
```gdscript
# In threat system
if state.threat > WAVE_ASSAULT_THRESHOLD * state.threat_max:
    AudioManager.set_battle_intensity(true)
else:
    AudioManager.set_battle_intensity(false)
```

## Stinger System

Stingers are one-shot music clips that play over the current music:

```gdscript
var _stinger_player: AudioStreamPlayer

func play_stinger(music_id: int) -> void:
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
```

### Victory/Defeat Stingers

```gdscript
func play_victory() -> void:
    play_sfx(SFX.VICTORY_FANFARE)
    play_stinger(Music.VICTORY)

func play_defeat() -> void:
    play_sfx(SFX.DEFEAT_STINGER)
    play_stinger(Music.DEFEAT)
```

## Volume Control

### Setting Volume

```gdscript
# Linear (0.0 - 1.0) to dB conversion
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
```

### Enable/Disable

```gdscript
func set_music_enabled(enabled: bool) -> void:
    _music_enabled = enabled
    if not enabled:
        stop_music(true)  # Fade out

func set_sfx_enabled(enabled: bool) -> void:
    _sfx_enabled = enabled
```

### Stopping Music

```gdscript
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
```

## Audio Preloading

All audio is preloaded at startup:

```gdscript
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

    # Log summary of missing files
    if not missing_sfx.is_empty():
        push_warning("AudioManager: Missing SFX (%d): %s" % [missing_sfx.size(), ", ".join(missing_sfx)])
```

## Adding New Sounds

### Step 1: Add to Enum

```gdscript
enum SFX {
    // ... existing ...
    NEW_SOUND
}
```

### Step 2: Add File Mapping

```gdscript
var _sfx_files := {
    // ... existing ...
    SFX.NEW_SOUND: "new_sound.wav"
}
```

### Step 3: Add Convenience Method (Optional)

```gdscript
func play_new_sound() -> void:
    play_sfx(SFX.NEW_SOUND)
```

### Step 4: Add Audio File

Place the WAV file at `res://assets/audio/sfx/new_sound.wav`.

## Convenience Methods Reference

### UI Sounds
```gdscript
AudioManager.play_ui_confirm()
AudioManager.play_ui_cancel()
```

### Typing Feedback
```gdscript
AudioManager.play_type_correct()
AudioManager.play_type_mistake()
AudioManager.play_combo_up()
AudioManager.play_combo_break()
```

### Combat
```gdscript
AudioManager.play_hit_enemy()
AudioManager.play_hit_player()
AudioManager.play_wave_start()
AudioManager.play_wave_end()
```

### Events
```gdscript
AudioManager.play_event_show()
AudioManager.play_event_choice()
AudioManager.play_event_success()
AudioManager.play_event_fail()
AudioManager.play_event_skip()
AudioManager.play_poi_appear()
```

### Progression
```gdscript
AudioManager.play_level_up()
AudioManager.play_upgrade_purchase()
AudioManager.play_victory()
AudioManager.play_defeat()
```

### Music Context
```gdscript
AudioManager.switch_to_menu_music()
AudioManager.switch_to_kingdom_music()
AudioManager.switch_to_battle_music(tense: bool)
AudioManager.set_battle_intensity(tense: bool)
```

## Integration Examples

### Typing Input Handler

```gdscript
func _on_key_pressed(key: String) -> void:
    AudioManager.play_sfx(AudioManager.SFX.UI_KEYTAP)

func _on_word_completed(correct: bool) -> void:
    if correct:
        AudioManager.play_type_correct()
        if combo_increased:
            AudioManager.play_combo_up()
    else:
        AudioManager.play_type_mistake()
        if combo_broken:
            AudioManager.play_combo_break()
```

### Phase Transitions

```gdscript
func _on_phase_changed(new_phase: String) -> void:
    match new_phase:
        "menu":
            AudioManager.switch_to_menu_music()
        "day":
            AudioManager.switch_to_kingdom_music()
        "night":
            AudioManager.switch_to_battle_music(false)
            AudioManager.play_wave_start()
        "victory":
            AudioManager.play_victory()
        "defeat":
            AudioManager.play_defeat()
```

### Event Handling

```gdscript
func _on_event_triggered() -> void:
    AudioManager.play_event_show()

func _on_choice_selected(success: bool) -> void:
    AudioManager.play_event_choice()
    if success:
        AudioManager.play_event_success()
    else:
        AudioManager.play_event_fail()
```

### Achievement Unlock

```gdscript
func _on_achievement_unlocked(achievement_id: String) -> void:
    AudioManager.play_sfx(AudioManager.SFX.ACHIEVEMENT_UNLOCK)
```

## Audio File Guidelines

### Format Recommendations

| Type | Format | Sample Rate | Notes |
|------|--------|-------------|-------|
| SFX | WAV | 44100 Hz | Short, punchy |
| Music | OGG | 44100 Hz | Looping tracks |
| Stingers | WAV/OGG | 44100 Hz | One-shot |

### Naming Convention

```
res://assets/audio/
├── sfx/
│   ├── ui_keytap.wav
│   ├── type_correct.wav
│   ├── hit_enemy.wav
│   └── ...
└── music/
    ├── menu.wav
    ├── kingdom.wav
    ├── battle_calm.wav
    └── ...
```

### Volume Normalization

- SFX: Normalize to -3dB peak
- Music: Normalize to -6dB peak (leave headroom)
- Keep consistent loudness across similar sound types

## Testing Audio

```gdscript
func test_audio_playback():
    # Test SFX plays without error
    AudioManager.play_sfx(AudioManager.SFX.UI_CONFIRM)
    await get_tree().create_timer(0.1).timeout
    _pass("test_audio_playback")

func test_music_crossfade():
    AudioManager.play_music(AudioManager.Music.MENU)
    await get_tree().create_timer(0.5).timeout
    AudioManager.play_music(AudioManager.Music.KINGDOM)
    # Verify crossfade started
    assert(AudioManager._is_fading, "Should be crossfading")
    _pass("test_music_crossfade")
```
