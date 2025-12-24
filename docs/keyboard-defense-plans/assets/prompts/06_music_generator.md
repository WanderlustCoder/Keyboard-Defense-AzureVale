OPTIONAL TASK: Add procedural music (simple loop) for day/night.

DELIVERABLES:
1) Create `apps/keyboard-defense-godot/data/audio/music_presets.json` with:
   - tempo per mode
   - scale
   - chord progression
   - instrument presets (simple)
2) Implement `apps/keyboard-defense-godot/scripts/audio/MusicGenerator.gd`:
   - generates a loop buffer for day
   - generates a loop buffer for night
   - crossfades on mode switch
3) Add debug commands:
   - `music off/on`
   - `music mode day/night` (dev)

TESTS:
- deterministic output with seed
- loop is seamless (first/last samples match within tolerance)

LANDMARKS in final response (mandatory).
