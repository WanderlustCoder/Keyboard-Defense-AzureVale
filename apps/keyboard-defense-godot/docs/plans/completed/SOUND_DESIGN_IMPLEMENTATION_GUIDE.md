# Sound Design Implementation Guide

## Overview

This guide provides complete JSON presets ready to copy into `data/audio/sfx_presets.json`. Each preset is fully specified with all parameters.

**Target File**: `data/audio/sfx_presets.json`
**Current Presets**: 48
**New Presets to Add**: ~80

---

## Part 1: Understanding the Preset Format

### 1.1 Complete Preset Structure

```json
{
  "id": "unique_sound_id",
  "description": "Human-readable description",
  "category": "ui|typing|combat|world|tower|status|progression|stinger|ambient",
  "oscillator": {
    "type": "sine|triangle|square|sawtooth|noise",
    "frequency": 440
  },
  "envelope": {
    "attack_ms": 10,
    "decay_ms": 100,
    "sustain": 0.5,
    "release_ms": 100
  },
  "volume": 0.35,
  "duration_ms": 200,
  "pitch_slide": {
    "start_offset": 0,
    "end_offset": 100,
    "curve": "linear|exponential"
  },
  "filter": {
    "type": "lowpass|highpass|bandpass",
    "cutoff_hz": 1000,
    "resonance": 0.5
  },
  "harmonics": [
    { "ratio": 2.0, "amplitude": 0.3 },
    { "ratio": 3.0, "amplitude": 0.15 }
  ]
}
```

### 1.2 Parameter Reference

| Parameter | Type | Range | Description |
|-----------|------|-------|-------------|
| `frequency` | int | 20-4000 | Base oscillator frequency in Hz |
| `attack_ms` | int | 1-500 | Time to reach peak volume |
| `decay_ms` | int | 10-500 | Time from peak to sustain |
| `sustain` | float | 0.0-1.0 | Sustain level (0=silent, 1=full) |
| `release_ms` | int | 10-1000 | Fade out time |
| `volume` | float | 0.1-0.8 | Output volume (don't exceed 0.6 normally) |
| `duration_ms` | int | 30-1000 | Total sound length |
| `start_offset` | int | -2000-2000 | Pitch offset at start (Hz) |
| `end_offset` | int | -2000-2000 | Pitch offset at end (Hz) |
| `cutoff_hz` | int | 100-8000 | Filter cutoff frequency |
| `resonance` | float | 0.0-1.0 | Filter resonance/Q |

### 1.3 Sound Design Principles

| Feeling | Oscillator | Envelope | Pitch |
|---------|------------|----------|-------|
| Pleasant/Rewarding | sine | fast attack, medium decay | rising |
| Urgent/Alert | square/sawtooth | instant attack | falling then rising |
| Impact/Hit | noise | instant attack, fast decay | falling |
| Error/Wrong | sawtooth | fast attack | falling |
| Magical | sine + harmonics | slow attack | rising |
| Mechanical | square | instant attack | stable |

---

## Part 2: UI Sound Presets

Add these to the `"presets"` array:

### 2.1 Button Interactions

```json
{
  "id": "ui_hover",
  "description": "Button/menu hover feedback",
  "category": "ui",
  "oscillator": {
    "type": "sine",
    "frequency": 1200
  },
  "envelope": {
    "attack_ms": 2,
    "decay_ms": 25,
    "sustain": 0.0,
    "release_ms": 20
  },
  "volume": 0.12,
  "duration_ms": 45
},
{
  "id": "ui_click",
  "description": "Generic button click",
  "category": "ui",
  "oscillator": {
    "type": "square",
    "frequency": 600
  },
  "envelope": {
    "attack_ms": 2,
    "decay_ms": 30,
    "sustain": 0.0,
    "release_ms": 25
  },
  "volume": 0.2,
  "duration_ms": 55,
  "filter": {
    "type": "lowpass",
    "cutoff_hz": 1500,
    "resonance": 0.2
  }
},
{
  "id": "ui_open_panel",
  "description": "Panel/menu opens",
  "category": "ui",
  "oscillator": {
    "type": "sine",
    "frequency": 400
  },
  "envelope": {
    "attack_ms": 10,
    "decay_ms": 80,
    "sustain": 0.2,
    "release_ms": 60
  },
  "volume": 0.25,
  "duration_ms": 160,
  "pitch_slide": {
    "start_offset": -100,
    "end_offset": 200,
    "curve": "exponential"
  }
},
{
  "id": "ui_close_panel",
  "description": "Panel/menu closes",
  "category": "ui",
  "oscillator": {
    "type": "sine",
    "frequency": 500
  },
  "envelope": {
    "attack_ms": 5,
    "decay_ms": 60,
    "sustain": 0.1,
    "release_ms": 50
  },
  "volume": 0.2,
  "duration_ms": 120,
  "pitch_slide": {
    "start_offset": 100,
    "end_offset": -150,
    "curve": "exponential"
  }
},
{
  "id": "ui_tab_switch",
  "description": "Tab navigation click",
  "category": "ui",
  "oscillator": {
    "type": "triangle",
    "frequency": 900
  },
  "envelope": {
    "attack_ms": 2,
    "decay_ms": 35,
    "sustain": 0.0,
    "release_ms": 30
  },
  "volume": 0.18,
  "duration_ms": 65
},
{
  "id": "ui_toggle_on",
  "description": "Toggle switch enabled",
  "category": "ui",
  "oscillator": {
    "type": "sine",
    "frequency": 700
  },
  "envelope": {
    "attack_ms": 3,
    "decay_ms": 40,
    "sustain": 0.2,
    "release_ms": 40
  },
  "volume": 0.22,
  "duration_ms": 90,
  "pitch_slide": {
    "start_offset": -50,
    "end_offset": 100,
    "curve": "exponential"
  }
},
{
  "id": "ui_toggle_off",
  "description": "Toggle switch disabled",
  "category": "ui",
  "oscillator": {
    "type": "sine",
    "frequency": 600
  },
  "envelope": {
    "attack_ms": 3,
    "decay_ms": 40,
    "sustain": 0.1,
    "release_ms": 40
  },
  "volume": 0.2,
  "duration_ms": 85,
  "pitch_slide": {
    "start_offset": 50,
    "end_offset": -100,
    "curve": "exponential"
  }
},
{
  "id": "ui_error",
  "description": "Invalid action attempted",
  "category": "ui",
  "oscillator": {
    "type": "sawtooth",
    "frequency": 180
  },
  "envelope": {
    "attack_ms": 5,
    "decay_ms": 50,
    "sustain": 0.15,
    "release_ms": 60
  },
  "volume": 0.3,
  "duration_ms": 120,
  "pitch_slide": {
    "start_offset": 40,
    "end_offset": -60,
    "curve": "linear"
  },
  "filter": {
    "type": "lowpass",
    "cutoff_hz": 600,
    "resonance": 0.4
  }
},
{
  "id": "ui_scroll",
  "description": "Scroll feedback tick",
  "category": "ui",
  "oscillator": {
    "type": "noise",
    "frequency": 0
  },
  "envelope": {
    "attack_ms": 1,
    "decay_ms": 15,
    "sustain": 0.0,
    "release_ms": 10
  },
  "volume": 0.08,
  "duration_ms": 25,
  "filter": {
    "type": "highpass",
    "cutoff_hz": 3000,
    "resonance": 0.1
  }
},
{
  "id": "ui_slider_tick",
  "description": "Volume slider notch",
  "category": "ui",
  "oscillator": {
    "type": "sine",
    "frequency": 1000
  },
  "envelope": {
    "attack_ms": 1,
    "decay_ms": 20,
    "sustain": 0.0,
    "release_ms": 15
  },
  "volume": 0.1,
  "duration_ms": 35
}
```

---

## Part 3: Typing Sound Presets

### 3.1 Additional Typing Feedback

```json
{
  "id": "type_space",
  "description": "Spacebar hit - distinct from letters",
  "category": "typing",
  "oscillator": {
    "type": "noise",
    "frequency": 0
  },
  "envelope": {
    "attack_ms": 2,
    "decay_ms": 35,
    "sustain": 0.0,
    "release_ms": 25
  },
  "volume": 0.18,
  "duration_ms": 60,
  "filter": {
    "type": "bandpass",
    "cutoff_hz": 1800,
    "resonance": 0.3
  }
},
{
  "id": "type_backspace",
  "description": "Delete/backspace character",
  "category": "typing",
  "oscillator": {
    "type": "square",
    "frequency": 350
  },
  "envelope": {
    "attack_ms": 3,
    "decay_ms": 35,
    "sustain": 0.0,
    "release_ms": 30
  },
  "volume": 0.2,
  "duration_ms": 70,
  "pitch_slide": {
    "start_offset": 50,
    "end_offset": -100,
    "curve": "linear"
  },
  "filter": {
    "type": "lowpass",
    "cutoff_hz": 1000,
    "resonance": 0.2
  }
},
{
  "id": "type_enter",
  "description": "Submit command/enter key",
  "category": "typing",
  "oscillator": {
    "type": "sine",
    "frequency": 550
  },
  "envelope": {
    "attack_ms": 5,
    "decay_ms": 60,
    "sustain": 0.25,
    "release_ms": 70
  },
  "volume": 0.3,
  "duration_ms": 140,
  "pitch_slide": {
    "start_offset": 0,
    "end_offset": 200,
    "curve": "exponential"
  },
  "harmonics": [
    { "ratio": 2.0, "amplitude": 0.25 }
  ]
},
{
  "id": "type_target_lock",
  "description": "First letter matches - target locked",
  "category": "typing",
  "oscillator": {
    "type": "sine",
    "frequency": 800
  },
  "envelope": {
    "attack_ms": 3,
    "decay_ms": 45,
    "sustain": 0.2,
    "release_ms": 50
  },
  "volume": 0.25,
  "duration_ms": 100,
  "pitch_slide": {
    "start_offset": -50,
    "end_offset": 100,
    "curve": "exponential"
  }
},
{
  "id": "type_target_lost",
  "description": "Target escaped or killed by other",
  "category": "typing",
  "oscillator": {
    "type": "triangle",
    "frequency": 450
  },
  "envelope": {
    "attack_ms": 10,
    "decay_ms": 70,
    "sustain": 0.1,
    "release_ms": 60
  },
  "volume": 0.22,
  "duration_ms": 140,
  "pitch_slide": {
    "start_offset": 100,
    "end_offset": -150,
    "curve": "exponential"
  }
},
{
  "id": "word_perfect",
  "description": "Word completed with no mistakes",
  "category": "typing",
  "oscillator": {
    "type": "sine",
    "frequency": 600
  },
  "envelope": {
    "attack_ms": 5,
    "decay_ms": 100,
    "sustain": 0.35,
    "release_ms": 100
  },
  "volume": 0.4,
  "duration_ms": 220,
  "pitch_slide": {
    "start_offset": 0,
    "end_offset": 600,
    "curve": "exponential"
  },
  "harmonics": [
    { "ratio": 2.0, "amplitude": 0.35 },
    { "ratio": 3.0, "amplitude": 0.2 },
    { "ratio": 4.0, "amplitude": 0.1 }
  ]
},
{
  "id": "speed_bonus",
  "description": "Fast word completion bonus",
  "category": "typing",
  "oscillator": {
    "type": "sine",
    "frequency": 900
  },
  "envelope": {
    "attack_ms": 3,
    "decay_ms": 50,
    "sustain": 0.25,
    "release_ms": 60
  },
  "volume": 0.3,
  "duration_ms": 120,
  "pitch_slide": {
    "start_offset": 0,
    "end_offset": 450,
    "curve": "exponential"
  },
  "harmonics": [
    { "ratio": 1.5, "amplitude": 0.3 }
  ]
},
{
  "id": "accuracy_bonus",
  "description": "High accuracy bonus sound",
  "category": "typing",
  "oscillator": {
    "type": "sine",
    "frequency": 750
  },
  "envelope": {
    "attack_ms": 5,
    "decay_ms": 70,
    "sustain": 0.3,
    "release_ms": 80
  },
  "volume": 0.32,
  "duration_ms": 160,
  "pitch_slide": {
    "start_offset": -100,
    "end_offset": 300,
    "curve": "exponential"
  },
  "harmonics": [
    { "ratio": 2.0, "amplitude": 0.25 }
  ]
}
```

---

## Part 4: Combat Sound Presets

### 4.1 Projectile Sounds

```json
{
  "id": "projectile_launch",
  "description": "Generic projectile fired",
  "category": "combat",
  "oscillator": {
    "type": "noise",
    "frequency": 0
  },
  "envelope": {
    "attack_ms": 2,
    "decay_ms": 25,
    "sustain": 0.0,
    "release_ms": 20
  },
  "volume": 0.25,
  "duration_ms": 50,
  "filter": {
    "type": "highpass",
    "cutoff_hz": 2500,
    "resonance": 0.25
  },
  "pitch_slide": {
    "start_offset": 300,
    "end_offset": -100,
    "curve": "linear"
  }
},
{
  "id": "projectile_impact",
  "description": "Generic projectile hit",
  "category": "combat",
  "oscillator": {
    "type": "noise",
    "frequency": 0
  },
  "envelope": {
    "attack_ms": 2,
    "decay_ms": 40,
    "sustain": 0.05,
    "release_ms": 35
  },
  "volume": 0.3,
  "duration_ms": 80,
  "filter": {
    "type": "lowpass",
    "cutoff_hz": 800,
    "resonance": 0.5
  }
},
{
  "id": "enemy_attack",
  "description": "Enemy attacks castle",
  "category": "combat",
  "oscillator": {
    "type": "sawtooth",
    "frequency": 180
  },
  "envelope": {
    "attack_ms": 8,
    "decay_ms": 70,
    "sustain": 0.15,
    "release_ms": 50
  },
  "volume": 0.35,
  "duration_ms": 130,
  "pitch_slide": {
    "start_offset": 80,
    "end_offset": -120,
    "curve": "exponential"
  },
  "filter": {
    "type": "lowpass",
    "cutoff_hz": 600,
    "resonance": 0.5
  }
},
{
  "id": "enemy_special",
  "description": "Elite/affix ability activation",
  "category": "combat",
  "oscillator": {
    "type": "sawtooth",
    "frequency": 250
  },
  "envelope": {
    "attack_ms": 15,
    "decay_ms": 100,
    "sustain": 0.3,
    "release_ms": 80
  },
  "volume": 0.4,
  "duration_ms": 200,
  "pitch_slide": {
    "start_offset": -50,
    "end_offset": 150,
    "curve": "exponential"
  },
  "filter": {
    "type": "bandpass",
    "cutoff_hz": 800,
    "resonance": 0.6
  }
},
{
  "id": "armor_hit",
  "description": "Armored enemy reduces damage",
  "category": "combat",
  "oscillator": {
    "type": "noise",
    "frequency": 0
  },
  "envelope": {
    "attack_ms": 2,
    "decay_ms": 30,
    "sustain": 0.0,
    "release_ms": 40
  },
  "volume": 0.35,
  "duration_ms": 75,
  "filter": {
    "type": "bandpass",
    "cutoff_hz": 2500,
    "resonance": 0.7
  }
},
{
  "id": "chain_lightning",
  "description": "Lightning chains between enemies",
  "category": "combat",
  "oscillator": {
    "type": "square",
    "frequency": 200
  },
  "envelope": {
    "attack_ms": 1,
    "decay_ms": 15,
    "sustain": 0.4,
    "release_ms": 30
  },
  "volume": 0.35,
  "duration_ms": 60,
  "pitch_slide": {
    "start_offset": 1500,
    "end_offset": -300,
    "curve": "exponential"
  },
  "filter": {
    "type": "bandpass",
    "cutoff_hz": 2500,
    "resonance": 0.5
  }
},
{
  "id": "splash_damage",
  "description": "Area damage explosion",
  "category": "combat",
  "oscillator": {
    "type": "noise",
    "frequency": 0
  },
  "envelope": {
    "attack_ms": 5,
    "decay_ms": 60,
    "sustain": 0.1,
    "release_ms": 50
  },
  "volume": 0.4,
  "duration_ms": 120,
  "filter": {
    "type": "lowpass",
    "cutoff_hz": 500,
    "resonance": 0.6
  },
  "pitch_slide": {
    "start_offset": 150,
    "end_offset": -250,
    "curve": "exponential"
  }
},
{
  "id": "overkill",
  "description": "Excessive damage dealt",
  "category": "combat",
  "oscillator": {
    "type": "square",
    "frequency": 300
  },
  "envelope": {
    "attack_ms": 3,
    "decay_ms": 50,
    "sustain": 0.2,
    "release_ms": 70
  },
  "volume": 0.4,
  "duration_ms": 130,
  "pitch_slide": {
    "start_offset": 100,
    "end_offset": -200,
    "curve": "exponential"
  },
  "filter": {
    "type": "lowpass",
    "cutoff_hz": 1200,
    "resonance": 0.4
  },
  "harmonics": [
    { "ratio": 0.5, "amplitude": 0.3 }
  ]
}
```

### 4.2 Enemy Sounds

```json
{
  "id": "enemy_grunt_hit",
  "description": "Basic enemy takes damage",
  "category": "combat",
  "oscillator": {
    "type": "sawtooth",
    "frequency": 220
  },
  "envelope": {
    "attack_ms": 3,
    "decay_ms": 45,
    "sustain": 0.1,
    "release_ms": 40
  },
  "volume": 0.28,
  "duration_ms": 90,
  "pitch_slide": {
    "start_offset": 60,
    "end_offset": -80,
    "curve": "linear"
  },
  "filter": {
    "type": "lowpass",
    "cutoff_hz": 900,
    "resonance": 0.4
  }
},
{
  "id": "enemy_grunt_death",
  "description": "Basic enemy dies",
  "category": "combat",
  "oscillator": {
    "type": "sawtooth",
    "frequency": 180
  },
  "envelope": {
    "attack_ms": 5,
    "decay_ms": 80,
    "sustain": 0.1,
    "release_ms": 60
  },
  "volume": 0.32,
  "duration_ms": 150,
  "pitch_slide": {
    "start_offset": 100,
    "end_offset": -200,
    "curve": "exponential"
  },
  "filter": {
    "type": "lowpass",
    "cutoff_hz": 700,
    "resonance": 0.5
  }
},
{
  "id": "enemy_elite_roar",
  "description": "Elite enemy spawn announcement",
  "category": "combat",
  "oscillator": {
    "type": "sawtooth",
    "frequency": 130
  },
  "envelope": {
    "attack_ms": 30,
    "decay_ms": 150,
    "sustain": 0.4,
    "release_ms": 100
  },
  "volume": 0.45,
  "duration_ms": 350,
  "pitch_slide": {
    "start_offset": 50,
    "end_offset": -40,
    "curve": "exponential"
  },
  "filter": {
    "type": "lowpass",
    "cutoff_hz": 500,
    "resonance": 0.6
  },
  "harmonics": [
    { "ratio": 0.5, "amplitude": 0.35 },
    { "ratio": 1.5, "amplitude": 0.25 }
  ]
},
{
  "id": "enemy_elite_death",
  "description": "Elite enemy defeated",
  "category": "combat",
  "oscillator": {
    "type": "sine",
    "frequency": 280
  },
  "envelope": {
    "attack_ms": 10,
    "decay_ms": 150,
    "sustain": 0.3,
    "release_ms": 150
  },
  "volume": 0.45,
  "duration_ms": 350,
  "pitch_slide": {
    "start_offset": 0,
    "end_offset": 400,
    "curve": "exponential"
  },
  "harmonics": [
    { "ratio": 1.5, "amplitude": 0.35 },
    { "ratio": 2.0, "amplitude": 0.25 },
    { "ratio": 3.0, "amplitude": 0.15 }
  ]
}
```

---

## Part 5: Combo System Sounds

```json
{
  "id": "combo_2x",
  "description": "2x combo multiplier reached",
  "category": "typing",
  "oscillator": {
    "type": "sine",
    "frequency": 500
  },
  "envelope": {
    "attack_ms": 5,
    "decay_ms": 60,
    "sustain": 0.3,
    "release_ms": 60
  },
  "volume": 0.32,
  "duration_ms": 130,
  "pitch_slide": {
    "start_offset": 0,
    "end_offset": 250,
    "curve": "exponential"
  },
  "harmonics": [
    { "ratio": 2.0, "amplitude": 0.25 }
  ]
},
{
  "id": "combo_3x",
  "description": "3x combo multiplier reached",
  "category": "typing",
  "oscillator": {
    "type": "sine",
    "frequency": 550
  },
  "envelope": {
    "attack_ms": 5,
    "decay_ms": 70,
    "sustain": 0.35,
    "release_ms": 70
  },
  "volume": 0.35,
  "duration_ms": 150,
  "pitch_slide": {
    "start_offset": 0,
    "end_offset": 330,
    "curve": "exponential"
  },
  "harmonics": [
    { "ratio": 2.0, "amplitude": 0.3 },
    { "ratio": 3.0, "amplitude": 0.15 }
  ]
},
{
  "id": "combo_4x",
  "description": "4x combo multiplier reached",
  "category": "typing",
  "oscillator": {
    "type": "sine",
    "frequency": 600
  },
  "envelope": {
    "attack_ms": 5,
    "decay_ms": 80,
    "sustain": 0.4,
    "release_ms": 80
  },
  "volume": 0.38,
  "duration_ms": 170,
  "pitch_slide": {
    "start_offset": 0,
    "end_offset": 400,
    "curve": "exponential"
  },
  "harmonics": [
    { "ratio": 2.0, "amplitude": 0.35 },
    { "ratio": 3.0, "amplitude": 0.2 },
    { "ratio": 4.0, "amplitude": 0.1 }
  ]
},
{
  "id": "combo_5x",
  "description": "5x combo - maximum multiplier",
  "category": "typing",
  "oscillator": {
    "type": "sine",
    "frequency": 650
  },
  "envelope": {
    "attack_ms": 5,
    "decay_ms": 100,
    "sustain": 0.45,
    "release_ms": 100
  },
  "volume": 0.42,
  "duration_ms": 220,
  "pitch_slide": {
    "start_offset": 0,
    "end_offset": 500,
    "curve": "exponential"
  },
  "harmonics": [
    { "ratio": 1.5, "amplitude": 0.4 },
    { "ratio": 2.0, "amplitude": 0.35 },
    { "ratio": 3.0, "amplitude": 0.25 },
    { "ratio": 4.0, "amplitude": 0.15 }
  ]
},
{
  "id": "combo_max",
  "description": "Maximum combo ever achieved",
  "category": "typing",
  "oscillator": {
    "type": "sine",
    "frequency": 700
  },
  "envelope": {
    "attack_ms": 10,
    "decay_ms": 150,
    "sustain": 0.5,
    "release_ms": 150
  },
  "volume": 0.5,
  "duration_ms": 350,
  "pitch_slide": {
    "start_offset": 0,
    "end_offset": 700,
    "curve": "exponential"
  },
  "harmonics": [
    { "ratio": 1.25, "amplitude": 0.45 },
    { "ratio": 1.5, "amplitude": 0.4 },
    { "ratio": 2.0, "amplitude": 0.35 },
    { "ratio": 3.0, "amplitude": 0.25 },
    { "ratio": 4.0, "amplitude": 0.15 }
  ]
},
{
  "id": "streak_5",
  "description": "5 perfect words streak",
  "category": "typing",
  "oscillator": {
    "type": "sine",
    "frequency": 520
  },
  "envelope": {
    "attack_ms": 8,
    "decay_ms": 80,
    "sustain": 0.3,
    "release_ms": 80
  },
  "volume": 0.35,
  "duration_ms": 180,
  "pitch_slide": {
    "start_offset": -50,
    "end_offset": 260,
    "curve": "exponential"
  },
  "harmonics": [
    { "ratio": 2.0, "amplitude": 0.3 }
  ]
},
{
  "id": "streak_10",
  "description": "10 perfect words streak",
  "category": "typing",
  "oscillator": {
    "type": "sine",
    "frequency": 580
  },
  "envelope": {
    "attack_ms": 8,
    "decay_ms": 100,
    "sustain": 0.35,
    "release_ms": 100
  },
  "volume": 0.4,
  "duration_ms": 220,
  "pitch_slide": {
    "start_offset": -80,
    "end_offset": 350,
    "curve": "exponential"
  },
  "harmonics": [
    { "ratio": 2.0, "amplitude": 0.35 },
    { "ratio": 3.0, "amplitude": 0.2 }
  ]
},
{
  "id": "streak_25",
  "description": "25 perfect words streak",
  "category": "typing",
  "oscillator": {
    "type": "sine",
    "frequency": 640
  },
  "envelope": {
    "attack_ms": 10,
    "decay_ms": 120,
    "sustain": 0.4,
    "release_ms": 120
  },
  "volume": 0.45,
  "duration_ms": 280,
  "pitch_slide": {
    "start_offset": -100,
    "end_offset": 480,
    "curve": "exponential"
  },
  "harmonics": [
    { "ratio": 1.5, "amplitude": 0.35 },
    { "ratio": 2.0, "amplitude": 0.3 },
    { "ratio": 3.0, "amplitude": 0.2 }
  ]
},
{
  "id": "streak_50",
  "description": "50 perfect words - legendary streak",
  "category": "typing",
  "oscillator": {
    "type": "sine",
    "frequency": 700
  },
  "envelope": {
    "attack_ms": 15,
    "decay_ms": 180,
    "sustain": 0.5,
    "release_ms": 180
  },
  "volume": 0.52,
  "duration_ms": 400,
  "pitch_slide": {
    "start_offset": -150,
    "end_offset": 700,
    "curve": "exponential"
  },
  "harmonics": [
    { "ratio": 1.25, "amplitude": 0.4 },
    { "ratio": 1.5, "amplitude": 0.35 },
    { "ratio": 2.0, "amplitude": 0.3 },
    { "ratio": 3.0, "amplitude": 0.2 },
    { "ratio": 4.0, "amplitude": 0.1 }
  ]
}
```

---

## Part 6: Ambient & Environmental Sounds

```json
{
  "id": "ambient_wind_light",
  "description": "Soft background wind",
  "category": "ambient",
  "oscillator": {
    "type": "noise",
    "frequency": 0
  },
  "envelope": {
    "attack_ms": 500,
    "decay_ms": 200,
    "sustain": 0.8,
    "release_ms": 500
  },
  "volume": 0.08,
  "duration_ms": 3000,
  "filter": {
    "type": "bandpass",
    "cutoff_hz": 400,
    "resonance": 0.2
  }
},
{
  "id": "ambient_tension",
  "description": "Night phase tension atmosphere",
  "category": "ambient",
  "oscillator": {
    "type": "sawtooth",
    "frequency": 55
  },
  "envelope": {
    "attack_ms": 1000,
    "decay_ms": 500,
    "sustain": 0.6,
    "release_ms": 1000
  },
  "volume": 0.1,
  "duration_ms": 5000,
  "filter": {
    "type": "lowpass",
    "cutoff_hz": 200,
    "resonance": 0.4
  }
},
{
  "id": "day_dawn",
  "description": "Day phase begins",
  "category": "world",
  "oscillator": {
    "type": "sine",
    "frequency": 350
  },
  "envelope": {
    "attack_ms": 100,
    "decay_ms": 300,
    "sustain": 0.4,
    "release_ms": 400
  },
  "volume": 0.35,
  "duration_ms": 800,
  "pitch_slide": {
    "start_offset": -100,
    "end_offset": 200,
    "curve": "exponential"
  },
  "harmonics": [
    { "ratio": 2.0, "amplitude": 0.3 },
    { "ratio": 3.0, "amplitude": 0.15 }
  ]
},
{
  "id": "night_fall",
  "description": "Night phase begins - ominous",
  "category": "world",
  "oscillator": {
    "type": "sawtooth",
    "frequency": 180
  },
  "envelope": {
    "attack_ms": 50,
    "decay_ms": 200,
    "sustain": 0.35,
    "release_ms": 300
  },
  "volume": 0.4,
  "duration_ms": 600,
  "pitch_slide": {
    "start_offset": 80,
    "end_offset": -120,
    "curve": "exponential"
  },
  "filter": {
    "type": "lowpass",
    "cutoff_hz": 600,
    "resonance": 0.5
  },
  "harmonics": [
    { "ratio": 0.5, "amplitude": 0.3 },
    { "ratio": 1.5, "amplitude": 0.2 }
  ]
},
{
  "id": "thunder_distant",
  "description": "Distant thunder rumble",
  "category": "ambient",
  "oscillator": {
    "type": "noise",
    "frequency": 0
  },
  "envelope": {
    "attack_ms": 30,
    "decay_ms": 300,
    "sustain": 0.2,
    "release_ms": 500
  },
  "volume": 0.35,
  "duration_ms": 900,
  "filter": {
    "type": "lowpass",
    "cutoff_hz": 200,
    "resonance": 0.6
  }
},
{
  "id": "earthquake_rumble",
  "description": "Boss approaching rumble",
  "category": "ambient",
  "oscillator": {
    "type": "noise",
    "frequency": 0
  },
  "envelope": {
    "attack_ms": 200,
    "decay_ms": 300,
    "sustain": 0.5,
    "release_ms": 400
  },
  "volume": 0.45,
  "duration_ms": 1200,
  "filter": {
    "type": "lowpass",
    "cutoff_hz": 100,
    "resonance": 0.8
  }
}
```

---

## Part 7: Building & Economy Sounds

```json
{
  "id": "building_upgrade",
  "description": "Structure leveled up",
  "category": "world",
  "oscillator": {
    "type": "sine",
    "frequency": 450
  },
  "envelope": {
    "attack_ms": 10,
    "decay_ms": 120,
    "sustain": 0.4,
    "release_ms": 100
  },
  "volume": 0.4,
  "duration_ms": 250,
  "pitch_slide": {
    "start_offset": -50,
    "end_offset": 350,
    "curve": "exponential"
  },
  "harmonics": [
    { "ratio": 2.0, "amplitude": 0.35 },
    { "ratio": 3.0, "amplitude": 0.2 }
  ]
},
{
  "id": "building_destroy",
  "description": "Structure destroyed",
  "category": "world",
  "oscillator": {
    "type": "noise",
    "frequency": 0
  },
  "envelope": {
    "attack_ms": 10,
    "decay_ms": 150,
    "sustain": 0.15,
    "release_ms": 200
  },
  "volume": 0.45,
  "duration_ms": 400,
  "filter": {
    "type": "lowpass",
    "cutoff_hz": 400,
    "resonance": 0.6
  },
  "pitch_slide": {
    "start_offset": 200,
    "end_offset": -400,
    "curve": "exponential"
  }
},
{
  "id": "gold_coins",
  "description": "Gold received - coin jingle",
  "category": "world",
  "oscillator": {
    "type": "sine",
    "frequency": 1200
  },
  "envelope": {
    "attack_ms": 2,
    "decay_ms": 50,
    "sustain": 0.2,
    "release_ms": 60
  },
  "volume": 0.3,
  "duration_ms": 120,
  "pitch_slide": {
    "start_offset": -100,
    "end_offset": 150,
    "curve": "exponential"
  },
  "harmonics": [
    { "ratio": 2.5, "amplitude": 0.4 },
    { "ratio": 4.0, "amplitude": 0.25 }
  ]
},
{
  "id": "research_complete",
  "description": "Research finished",
  "category": "progression",
  "oscillator": {
    "type": "sine",
    "frequency": 550
  },
  "envelope": {
    "attack_ms": 15,
    "decay_ms": 150,
    "sustain": 0.45,
    "release_ms": 150
  },
  "volume": 0.45,
  "duration_ms": 350,
  "pitch_slide": {
    "start_offset": -100,
    "end_offset": 400,
    "curve": "exponential"
  },
  "harmonics": [
    { "ratio": 1.5, "amplitude": 0.35 },
    { "ratio": 2.0, "amplitude": 0.3 },
    { "ratio": 3.0, "amplitude": 0.2 }
  ]
},
{
  "id": "tech_unlock",
  "description": "Technology unlocked",
  "category": "progression",
  "oscillator": {
    "type": "sine",
    "frequency": 600
  },
  "envelope": {
    "attack_ms": 10,
    "decay_ms": 180,
    "sustain": 0.5,
    "release_ms": 200
  },
  "volume": 0.5,
  "duration_ms": 450,
  "pitch_slide": {
    "start_offset": 0,
    "end_offset": 600,
    "curve": "exponential"
  },
  "harmonics": [
    { "ratio": 1.25, "amplitude": 0.4 },
    { "ratio": 1.5, "amplitude": 0.35 },
    { "ratio": 2.0, "amplitude": 0.3 },
    { "ratio": 3.0, "amplitude": 0.2 }
  ]
}
```

---

## Part 8: Integration Instructions

### 8.1 Adding Presets to sfx_presets.json

1. Open `data/audio/sfx_presets.json`
2. Find the `"presets"` array
3. Add new presets before the closing `]`
4. Ensure proper comma separation

### 8.2 Playing Sounds in Code

```gdscript
# In any script that needs audio
var audio_manager = get_node("/root/AudioManager")  # Or however you access it

# Play a sound
audio_manager.play_sfx("ui_click")
audio_manager.play_sfx("word_complete")
audio_manager.play_sfx("combo_3x")
```

### 8.3 Wiring Up Events

**In ui/components/typing_display.gd:**
```gdscript
func _on_character_typed(correct: bool) -> void:
    if correct:
        AudioManager.play_sfx("type_correct")
    else:
        AudioManager.play_sfx("type_mistake")

func _on_word_completed(perfect: bool) -> void:
    if perfect:
        AudioManager.play_sfx("word_perfect")
    else:
        AudioManager.play_sfx("word_complete")
```

**In scripts/Battlefield.gd:**
```gdscript
func _on_enemy_hit(enemy_id: int, damage: int) -> void:
    AudioManager.play_sfx("hit_enemy")

func _on_combo_milestone(combo: int) -> void:
    match combo:
        5: AudioManager.play_sfx("combo_up")
        10: AudioManager.play_sfx("combo_2x")
        15: AudioManager.play_sfx("combo_3x")
        20: AudioManager.play_sfx("combo_4x")
        25: AudioManager.play_sfx("combo_5x")
```

---

## Part 9: Testing Sounds

### 9.1 Manual Testing

Create a test scene or use the command bar:
```
# In game, type:
test_sfx ui_click
test_sfx combo_5x
test_sfx enemy_elite_roar
```

### 9.2 Volume Verification

All sounds should be tested at:
- Master volume 100%
- Category volume 100%
- No clipping should occur

### 9.3 Rate Limit Testing

For sounds that play frequently (typing, hits):
- Type rapidly for 30 seconds
- Verify no audio artifacts
- Verify rate limiting works

---

## Appendix: Complete New Presets List

| ID | Category | Priority |
|----|----------|----------|
| ui_hover | ui | Medium |
| ui_click | ui | High |
| ui_open_panel | ui | Medium |
| ui_close_panel | ui | Medium |
| ui_tab_switch | ui | Low |
| ui_toggle_on | ui | Low |
| ui_toggle_off | ui | Low |
| ui_error | ui | High |
| ui_scroll | ui | Low |
| ui_slider_tick | ui | Low |
| type_space | typing | High |
| type_backspace | typing | High |
| type_enter | typing | High |
| type_target_lock | typing | High |
| type_target_lost | typing | Medium |
| word_perfect | typing | High |
| speed_bonus | typing | Medium |
| accuracy_bonus | typing | Medium |
| projectile_launch | combat | Medium |
| projectile_impact | combat | Medium |
| enemy_attack | combat | High |
| enemy_special | combat | Medium |
| armor_hit | combat | Medium |
| chain_lightning | combat | Medium |
| splash_damage | combat | Medium |
| overkill | combat | Low |
| enemy_grunt_hit | combat | Medium |
| enemy_grunt_death | combat | Medium |
| enemy_elite_roar | combat | High |
| enemy_elite_death | combat | High |
| combo_2x | typing | High |
| combo_3x | typing | High |
| combo_4x | typing | High |
| combo_5x | typing | High |
| combo_max | typing | Medium |
| streak_5 | typing | Medium |
| streak_10 | typing | Medium |
| streak_25 | typing | Low |
| streak_50 | typing | Low |
| ambient_wind_light | ambient | Low |
| ambient_tension | ambient | Medium |
| day_dawn | world | Medium |
| night_fall | world | High |
| thunder_distant | ambient | Low |
| earthquake_rumble | ambient | Medium |
| building_upgrade | world | Medium |
| building_destroy | world | Medium |
| gold_coins | world | Medium |
| research_complete | progression | Medium |
| tech_unlock | progression | Medium |

**Total new presets: 50**
