OPTIONAL TASK: Offline render SFX presets to WAV files for packaging.

DELIVERABLES:
1) Implement `apps/keyboard-defense-godot/scripts/audio/render_sfx.gd` that:
   - reads `data/audio/sfx_presets.json`
   - renders each preset to PCM samples
   - writes `apps/keyboard-defense-godot/assets/audio/generated/sfx/<id>.wav`
2) Add a helper command or script to run the render step in headless mode.
3) Add tests:
   - validate WAV headers and sample counts

NOTES:
- Keep sample rate 44100 Hz or 48000 Hz (choose one).
- PCM 16-bit little-endian is fine.

LANDMARKS in final response (mandatory).
