# Codex CLI playbook for creating art and audio

This playbook is structured as milestones with prompts in `docs/keyboard-defense-plans/assets/prompts/`.

## Expected operating mode
Run Codex with:
- sandbox: `workspace-write`
- approval: `on-request` until you trust the pipeline

Example (PowerShell):
```powershell
codex --sandbox workspace-write --ask-for-approval on-request "$(Get-Content -Raw docs/keyboard-defense-plans/assets/prompts/02_art_svg_generator.md)"
```

## Milestones
1. Art direction + palette + requirements
2. SVG generators for icons/tiles/sprites
3. PNG render + atlas + manifest + preview sheet
4. Runtime audio synth + SFX presets + AudioManager
5. Optional: offline WAV render scripts
6. Optional: procedural music generator + presets
7. Integration + tests + QA checklists

## How to evaluate output each step
- Inspect `apps/keyboard-defense-godot/assets/art/generated/preview.png` for coherence and readability.
- Open the project in Godot and run the main scene.
- Run tests:
  - `.\apps\keyboard-defense-godot\scripts\run_tests.ps1`

## Optional add-ons
- `docs/keyboard-defense-plans/assets/prompts/08_ui_nineslice.md`
- `docs/keyboard-defense-plans/assets/prompts/09_audio_ducking_and_rate_limit.md`
