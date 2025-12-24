TASK: Implement procedural SFX synthesis, presets, and an AudioManager.

DELIVERABLES:
1) Create `apps/keyboard-defense-godot/data/audio/sfx_presets.json` with presets for:
   ui_keytap, ui_confirm, ui_cancel,
   type_correct, type_mistake,
   build_place, build_complete,
   wave_start, wave_end,
   hit_enemy, hit_player
2) Implement:
   - `apps/keyboard-defense-godot/scripts/audio/SfxSynth.gd` (pure functions to render samples into arrays)
   - `apps/keyboard-defense-godot/scripts/audio/AudioManager.gd` (AudioServer integration + volume controls)
   - `apps/keyboard-defense-godot/scripts/audio/SfxLibrary.gd` (loads presets and plays by id, pre-renders buffers)
3) Add a dev command or debug UI hook:
   - `mute`, `unmute`, `volume sfx 0.5`, `volume music 0.2`

TESTS:
- Unit tests for synth math:
  - no NaNs
  - peak amplitude <= 1.0
  - deterministic output for a preset and seed

LANDMARKS in final response (mandatory).
