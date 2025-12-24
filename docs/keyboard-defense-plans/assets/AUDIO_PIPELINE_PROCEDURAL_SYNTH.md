# Audio pipeline - Procedural synth (runtime + optional offline render)

## Overview
Codex should implement a small synthesizer in Godot:
- generates SFX from presets (JSON)
- supports runtime playback via AudioStreamGenerator or AudioStreamWAV
- optionally renders WAV files offline for packaging

This avoids third-party samples and keeps licensing simple.

## Folder structure
Recommended:
```
apps/keyboard-defense-godot/
  data/
    audio/
      sfx_presets.json
      music_presets.json
  assets/
    audio/
      generated/          # optional outputs (offline render)
  scripts/
    audio/
      SfxSynth.gd
      AudioManager.gd
      MusicGenerator.gd   # optional
```

## Preset format (SFX)
Use a compact, explicit schema:
- oscillator: `sine | square | triangle | saw | noise`
- envelope: attack/decay/sustain/release seconds
- pitch: base freq, slide (Hz/sec), vibrato (depth/rate)
- filter: cutoff, resonance (optional)
- gain: volume scalar
- duration: computed or explicit

Example:
```json
{
  "type_correct": {
    "osc": "triangle",
    "attack": 0.002,
    "decay": 0.06,
    "sustain": 0.0,
    "release": 0.04,
    "freq": 520,
    "slide": 80,
    "gain": 0.18
  }
}
```

Validation:
- `docs/keyboard-defense-plans/assets/schemas/sfx-presets.schema.json`
- `docs/keyboard-defense-plans/assets/schemas/music-presets.schema.json`

## Runtime playback (Godot)
Implement `play_sfx(id)`:
- load preset by id
- render samples into a buffer (or cached buffers per preset)
- play via an `AudioStreamPlayer` using a generated stream

Cache strategy:
- pre-render buffers on boot to avoid stutter during combat
- keep buffers short

## Offline render (optional)
Offline render is useful when:
- you want deterministic latency
- you want to avoid runtime CPU cost
- you want to ship assets for platforms with strict audio limits

Approaches:
1) GDScript render into `AudioStreamWAV` and save as `.wav`
2) External script using the same presets and math

## Acceptance criteria
- `AudioManager.gd` supports:
  - `set_master_volume(x)`
  - `set_sfx_volume(x)`
  - `set_music_volume(x)`
  - `mute()` / `unmute()`
- SFX exist for all events listed in `SOUND_STYLE_GUIDE.md`
- a typing-only mode can reduce world SFX during prompt sequences
