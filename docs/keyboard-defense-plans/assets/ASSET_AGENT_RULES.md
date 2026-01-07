# Asset agent rules (drop into AGENTS.md or keep separate)

These are additional instructions for Codex when working on assets.

## Non-negotiables
- Assets must be original. Do not copy, trace, or mimic specific copyrighted sprites.
- No external asset downloads unless explicitly approved and license-checked.
- Prefer procedural generation and/or SVG authored by code.
- When adding art or audio, update `apps/keyboard-defense-godot/data/assets_manifest.json`.

## Determinism
- Asset generation must accept a seed and produce stable outputs.
- Add tests for determinism (hash compare of manifests or sample hashes).

## Reviewability
- Prefer text-based sources:
  - SVG
  - JSON presets
  - GDScript generators
- Generated binary outputs should be committed only if you want reproducible builds without running generators.

## Landmarks in Codex responses
When you (Codex) finish a milestone, include:
1. Landmarks: list of created or changed files
2. How to run: commands
3. Acceptance checks: what to look for
