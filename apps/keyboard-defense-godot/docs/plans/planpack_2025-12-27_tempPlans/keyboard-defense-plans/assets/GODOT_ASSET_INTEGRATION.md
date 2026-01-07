# Godot asset integration notes

## Art
If you ship an atlas:
- load textures in an early boot scene or singleton
- validate `data/assets_manifest.json` at runtime in dev builds
- expose helper functions:
  - `get_texture(id) -> Texture2D`
  - `has_texture(id) -> bool`

Fallback textures:
- create a `missing` texture at boot:
  - magenta checker or high-contrast MISSING
- if `has_texture(id)` is false, use `missing`

## Audio
Hook SFX to gameplay events:
- typing engine emits:
  - key tap, correct, mistake, combo
- battle systems emit:
  - build placed, wave start, damage

AudioManager should subscribe in the UI layer, not the sim.

## Performance guardrails
- pre-generate or pre-load all needed assets before first wave
- never generate PNGs or audio buffers mid-wave
