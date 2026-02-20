# Phase 5: Audio Enhancement - Granular Implementation Guide

## Overview

This document covers audio polish including new sound effects, adaptive music, and sound layering. Audio feedback makes typing feel satisfying and immersive.

---

## Task 5.1: Add New Combat Sound Presets

**Time**: 20 minutes
**File to modify**: `data/audio/sfx_presets.json`

### Step 5.1.1: Add critical hit sound preset

**File**: `data/audio/sfx_presets.json`
**Action**: Add to presets array

```json
{
  "id": "combat_critical",
  "description": "Critical hit impact - sharp metallic with reverb",
  "category": "combat",
  "oscillator": {
    "type": "sawtooth",
    "frequency": 440
  },
  "envelope": {
    "attack_ms": 1,
    "decay_ms": 80,
    "sustain": 0.15,
    "release_ms": 150
  },
  "volume": 0.5,
  "duration_ms": 250,
  "pitch_slide": {
    "start_offset": 200,
    "end_offset": -50,
    "curve": "exponential"
  },
  "filter": {
    "type": "bandpass",
    "cutoff_hz": 1500,
    "resonance": 0.5
  }
}
```

### Step 5.1.2: Add enemy death sound preset

**File**: `data/audio/sfx_presets.json`
**Action**: Add to presets array

```json
{
  "id": "combat_enemy_death",
  "description": "Enemy defeated - satisfying crunch with fade",
  "category": "combat",
  "oscillator": {
    "type": "noise",
    "frequency": 200
  },
  "envelope": {
    "attack_ms": 2,
    "decay_ms": 60,
    "sustain": 0.3,
    "release_ms": 200
  },
  "volume": 0.4,
  "duration_ms": 300,
  "pitch_slide": {
    "start_offset": 100,
    "end_offset": -150,
    "curve": "linear"
  },
  "filter": {
    "type": "lowpass",
    "cutoff_hz": 1200,
    "resonance": 0.2
  }
}
```

### Step 5.1.3: Add status effect sounds

**File**: `data/audio/sfx_presets.json`
**Action**: Add to presets array

```json
{
  "id": "status_apply_burn",
  "description": "Burn status applied - crackling fire",
  "category": "status",
  "oscillator": {
    "type": "noise",
    "frequency": 800
  },
  "envelope": {
    "attack_ms": 5,
    "decay_ms": 100,
    "sustain": 0.4,
    "release_ms": 100
  },
  "volume": 0.3,
  "duration_ms": 200,
  "filter": {
    "type": "bandpass",
    "cutoff_hz": 2000,
    "resonance": 0.4
  }
},
{
  "id": "status_apply_slow",
  "description": "Slow status applied - ice crack",
  "category": "status",
  "oscillator": {
    "type": "sine",
    "frequency": 1200
  },
  "envelope": {
    "attack_ms": 2,
    "decay_ms": 40,
    "sustain": 0.2,
    "release_ms": 80
  },
  "volume": 0.3,
  "duration_ms": 150,
  "pitch_slide": {
    "start_offset": 400,
    "end_offset": -200,
    "curve": "exponential"
  }
},
{
  "id": "status_expire",
  "description": "Status effect expires - subtle whoosh",
  "category": "status",
  "oscillator": {
    "type": "noise",
    "frequency": 600
  },
  "envelope": {
    "attack_ms": 10,
    "decay_ms": 80,
    "sustain": 0.1,
    "release_ms": 60
  },
  "volume": 0.15,
  "duration_ms": 150,
  "filter": {
    "type": "highpass",
    "cutoff_hz": 1000,
    "resonance": 0.1
  }
}
```

### Verification:
1. Run JSON validation
2. Sounds should be playable via AudioManager
3. Critical hit is sharp and impactful
4. Enemy death is satisfying crunch
5. Status sounds are distinct but not intrusive

---

## Task 5.2: Add Combo Milestone Audio Escalation

**Time**: 15 minutes
**File to modify**: `game/audio_manager.gd`

### Step 5.2.1: Add pitch escalation for combos

**File**: `game/audio_manager.gd`
**Action**: Add combo audio method

```gdscript
## Play combo sound with pitch based on combo level
func play_combo_sound(combo: int) -> void:
	if combo < 2:
		return

	# Calculate pitch based on combo tier
	var base_pitch := 1.0
	var volume_offset := 0.0

	if combo >= 50:
		base_pitch = 1.5
		volume_offset = 3.0
		play_sfx(SFX.COMBO_MILESTONE_20, base_pitch, volume_offset)
	elif combo >= 20:
		base_pitch = 1.3
		volume_offset = 2.0
		play_sfx(SFX.COMBO_MILESTONE_10, base_pitch, volume_offset)
	elif combo >= 10:
		base_pitch = 1.2
		volume_offset = 1.0
		play_sfx(SFX.COMBO_MILESTONE_10, base_pitch, volume_offset)
	elif combo >= 5:
		base_pitch = 1.1
		play_sfx(SFX.COMBO_MILESTONE_5, base_pitch, volume_offset)
	else:
		# Small combos just get combo_up with slight pitch variation
		base_pitch = 1.0 + (combo - 2) * 0.02
		play_sfx(SFX.COMBO_UP, base_pitch, -2.0)  # Quieter
```

### Step 5.2.2: Add typing rhythm sound

**File**: `game/audio_manager.gd`
**Action**: Add rhythm tracking for typing sounds

```gdscript
# Rhythm tracking for varied typing sounds
var _last_type_time: float = 0.0
var _type_rhythm_count: int = 0

## Play typing sound with rhythm-based variation
func play_type_correct_rhythmic() -> void:
	var current_time := Time.get_ticks_msec() / 1000.0
	var delta := current_time - _last_type_time
	_last_type_time = current_time

	# If typing in rhythm (between 0.1-0.3 seconds), vary pitch upward
	if delta > 0.08 and delta < 0.35:
		_type_rhythm_count = mini(_type_rhythm_count + 1, 8)
	else:
		_type_rhythm_count = 0

	var pitch := 1.0 + _type_rhythm_count * 0.03  # Slight pitch increase
	play_sfx(SFX.TYPE_CORRECT, pitch, 0.0)
```

### Verification:
1. Type in rhythm - pitch subtly increases
2. High combos have distinctly higher pitched sounds
3. Combo milestones (5, 10, 20, 50) have clear audio cues
4. Sounds don't become annoying at high speeds

---

## Task 5.3: Add Adaptive Music System

**Time**: 25 minutes
**File to modify**: `game/audio_manager.gd`

### Step 5.3.1: Add threat-based music intensity

**File**: `game/audio_manager.gd`
**Action**: Add adaptive music methods

```gdscript
# Adaptive music state
var _target_music_intensity: float = 0.0
var _current_music_intensity: float = 0.0
const MUSIC_INTENSITY_LERP_SPEED := 1.0

## Set music intensity (0.0 = calm, 1.0 = intense)
func set_music_intensity(intensity: float) -> void:
	_target_music_intensity = clampf(intensity, 0.0, 1.0)


## Update music based on threat level
func update_music_for_threat(threat_percent: float) -> void:
	# Map threat to intensity
	if threat_percent < 30.0:
		set_music_intensity(0.0)  # Calm
	elif threat_percent < 50.0:
		set_music_intensity(0.3)  # Slightly tense
	elif threat_percent < 70.0:
		set_music_intensity(0.6)  # Building tension
	else:
		set_music_intensity(1.0)  # Full intensity


func _process(delta: float) -> void:
	# Smoothly interpolate music intensity
	if _current_music_intensity != _target_music_intensity:
		_current_music_intensity = move_toward(
			_current_music_intensity,
			_target_music_intensity,
			MUSIC_INTENSITY_LERP_SPEED * delta
		)
		_apply_music_intensity(_current_music_intensity)


func _apply_music_intensity(intensity: float) -> void:
	# Crossfade between calm and tense music tracks
	if _music_player_a == null or _music_player_b == null:
		return

	# Player A = calm, Player B = tense
	var calm_volume := linear_to_db(1.0 - intensity) + _music_volume_db
	var tense_volume := linear_to_db(intensity) + _music_volume_db

	_music_player_a.volume_db = maxf(calm_volume, -40.0)
	_music_player_b.volume_db = maxf(tense_volume, -40.0)
```

### Step 5.3.2: Start both music tracks for layering

**File**: `game/audio_manager.gd`
**Action**: Modify music start to play both layers

```gdscript
## Start adaptive battle music with both layers
func start_battle_music() -> void:
	if _music_player_a == null or _music_player_b == null:
		return

	# Load both tracks
	var calm_stream := _load_music_stream(Music.BATTLE_CALM)
	var tense_stream := _load_music_stream(Music.BATTLE_TENSE)

	if calm_stream != null:
		_music_player_a.stream = calm_stream
		_music_player_a.volume_db = _music_volume_db
		_music_player_a.play()

	if tense_stream != null:
		_music_player_b.stream = tense_stream
		_music_player_b.volume_db = -40.0  # Start silent
		_music_player_b.play()

	_current_music_intensity = 0.0
	_target_music_intensity = 0.0
```

### Verification:
1. Start battle - calm music plays
2. As threat increases, tense music fades in
3. At max threat, only tense music is audible
4. Transitions are smooth, not jarring

---

## Task 5.4: Add Ambient Sound Layer

**Time**: 20 minutes
**File to create**: `game/ambient_audio.gd`

### Step 5.4.1: Create ambient audio manager

**Action**: Create new file `game/ambient_audio.gd`

**Complete file contents**:

```gdscript
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


func _init() -> void:
	# Create ambient player
	_ambient_player = AudioStreamPlayer.new()
	_ambient_player.bus = "SFX"
	_ambient_player.volume_db = -40.0  # Start silent


func set_audio_manager(manager) -> void:
	_audio_manager = manager
	if _audio_manager != null and _ambient_player.get_parent() == null:
		_audio_manager.add_child(_ambient_player)


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


func _fade_in_ambient(duration: float) -> void:
	if _ambient_player == null:
		return

	var tween := _ambient_player.create_tween()
	if tween != null:
		tween.tween_property(_ambient_player, "volume_db", _ambient_volume, duration)


func _fade_out_ambient(duration: float) -> void:
	if _ambient_player == null:
		return

	var tween := _ambient_player.create_tween()
	if tween != null:
		tween.tween_property(_ambient_player, "volume_db", -40.0, duration)
		tween.tween_callback(func(): _ambient_player.stop())


func set_ambient_volume(volume_db: float) -> void:
	_ambient_volume = volume_db
	if _ambient_player != null and _current_ambient != AmbientType.NONE:
		_ambient_player.volume_db = volume_db
```

### Verification:
1. Different scenes set different ambient types
2. Ambient fades in/out smoothly
3. Ambient doesn't overpower music or SFX

---

## Task 5.5: Add Sound Variation System

**Time**: 15 minutes
**File to modify**: `game/audio_manager.gd`

### Step 5.5.1: Add random pitch variation

**File**: `game/audio_manager.gd`
**Action**: Modify play_sfx to support variation

```gdscript
## Play SFX with optional random variation
func play_sfx_varied(
	sfx_id: SFX,
	pitch_variation: float = 0.1,
	volume_variation: float = 2.0
) -> void:
	var pitch := 1.0 + randf_range(-pitch_variation, pitch_variation)
	var volume := randf_range(-volume_variation, volume_variation)
	play_sfx(sfx_id, pitch, volume)


## Play multiple layered SFX for richness
func play_sfx_layered(sfx_ids: Array[SFX], stagger_ms: float = 10.0) -> void:
	for i in range(sfx_ids.size()):
		if i > 0:
			await get_tree().create_timer(stagger_ms / 1000.0).timeout
		play_sfx_varied(sfx_ids[i], 0.05, 1.0)
```

### Step 5.5.2: Add hit sound variation

**File**: `game/audio_manager.gd`
**Action**: Add varied hit sound method

```gdscript
## Play hit sound with variation based on damage
func play_hit_varied(damage_amount: int = 1, is_critical: bool = false) -> void:
	var base_pitch := 1.0

	# Higher damage = lower pitch (more impactful)
	if damage_amount >= 10:
		base_pitch = 0.85
	elif damage_amount >= 5:
		base_pitch = 0.92
	else:
		base_pitch = 1.0

	# Critical hits have slight pitch boost
	if is_critical:
		base_pitch *= 1.1

	# Add random variation
	var pitch := base_pitch + randf_range(-0.05, 0.05)
	var volume := randf_range(-1.0, 1.0)

	play_sfx(SFX.HIT_ENEMY, pitch, volume)

	# Layer a second hit for criticals
	if is_critical:
		play_sfx(SFX.CRITICAL_HIT, pitch * 0.9, volume - 3.0)
```

### Verification:
1. Repeated sounds don't sound identical
2. Critical hits have layered audio
3. High damage sounds more impactful
4. Variation is subtle, not chaotic

---

## Task 5.6: Add Word Completion Sound Escalation

**Time**: 15 minutes
**File to modify**: `game/audio_manager.gd`

### Step 5.6.1: Add word length-based sound

**File**: `game/audio_manager.gd`
**Action**: Add word completion method

```gdscript
## Play word completion sound scaled to word length
func play_word_complete(word_length: int, was_perfect: bool = true) -> void:
	var base_pitch := 1.0
	var volume := 0.0

	# Longer words = more satisfying sound
	if word_length >= 10:
		base_pitch = 1.3
		volume = 2.0
	elif word_length >= 7:
		base_pitch = 1.2
		volume = 1.0
	elif word_length >= 5:
		base_pitch = 1.1
		volume = 0.0
	else:
		base_pitch = 1.0
		volume = -1.0

	# Perfect completion (no mistakes) gets slight boost
	if was_perfect:
		base_pitch *= 1.05
		volume += 1.0

	play_sfx(SFX.WORD_COMPLETE, base_pitch, volume)

	# Very long words get layered sound
	if word_length >= 8:
		play_sfx(SFX.COMBO_UP, base_pitch * 0.95, volume - 2.0)
```

### Step 5.6.2: Integrate with Battlefield

**File**: `scripts/Battlefield.gd`
**Action**: Call word complete sound when word finishes

**Find word completion logic and add**:
```gdscript
# When word is completed:
if audio_manager != null:
	var was_perfect := typing_system.get_current_word_errors() == 0
	audio_manager.play_word_complete(completed_word.length(), was_perfect)
```

### Verification:
1. Short words have standard completion sound
2. Long words (8+) have more impactful sound
3. Perfect completion sounds slightly better
4. Very long words have layered audio

---

## Summary Checklist

After completing all Phase 5 tasks, verify:

- [ ] Critical hit has distinct sharp sound
- [ ] Enemy death has satisfying crunch
- [ ] Status effects have unique sounds
- [ ] Combo sounds escalate with combo level
- [ ] Typing in rhythm subtly raises pitch
- [ ] Music intensity responds to threat level
- [ ] Ambient sounds fade in/out smoothly
- [ ] Hit sounds vary based on damage
- [ ] Word completion scales with word length
- [ ] No sound feels repetitive or annoying

---

## New SFX Presets Summary

Add these to `data/audio/sfx_presets.json`:

| ID | Description | Category |
|----|-------------|----------|
| `combat_critical` | Sharp metallic critical hit | combat |
| `combat_enemy_death` | Satisfying death crunch | combat |
| `status_apply_burn` | Fire crackling | status |
| `status_apply_slow` | Ice crack | status |
| `status_expire` | Subtle whoosh | status |

---

## Files Modified/Created Summary

| File | Action | Lines Changed |
|------|--------|--------------|
| `data/audio/sfx_presets.json` | Modified | +60 lines (new presets) |
| `game/audio_manager.gd` | Modified | +100 lines |
| `game/ambient_audio.gd` | Created | ~90 lines |
| `scripts/Battlefield.gd` | Modified | +10 lines |

**Total new code**: ~260 lines
