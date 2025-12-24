# Asset creation overview

## Objective
Produce a complete, original, coherent set of art and audio assets for Keyboard Defense (Godot):
- readable at a glance while typing
- low visual clutter to keep focus on prompts
- supports day/night cadence (economy vs defense)
- deterministic generation for reproducible builds

This document assumes:
- Godot 4 project at `apps/keyboard-defense-godot`
- assets live under `apps/keyboard-defense-godot/assets`
- data and manifests live under `apps/keyboard-defense-godot/data`
- tests run via `apps/keyboard-defense-godot/scripts/run_tests.ps1`

## Constraints and priorities
1. Typing-first UX: assets should never demand mouse precision.
2. Readability over detail: silhouettes and contrast matter most.
3. Originality: do not copy or trace existing game art.
4. Determinism: generators and presets take a seed and produce stable outputs.
5. Build-friendly: pipelines should be runnable on CI with open tooling.
6. Asset audit: when adding art or audio, update `apps/keyboard-defense-godot/data/assets_manifest.json`.

## Recommended approach
Stage A: procedural SVG or code-defined sources.
- Store palette and style in `assets/art/style`.
- Generate SVG under `assets/art/src-svg` for icons, tiles, and sprites.

Stage B: conversion and packing (optional).
- Convert SVG to PNG at a fixed scale.
- Optionally pack into an atlas for performance.
- Keep a preview sheet for human review.

Stage C: runtime fallbacks.
- If a frame is missing, generate a placeholder texture at boot using GDScript `Image`.

## Audio approach
Create a small synth and preset library:
- SFX presets cover typing feedback, upgrades, damage, wave cues.
- Music is optional and should remain sparse.
- Support runtime synthesis and optional offline renders for consistency.

## Outputs (definition of done)
- Art: required ids from `ART_ASSET_LIST.md` plus preview sheet.
- Audio: preset file + runtime playback hooks.
- Tests: asset manifest updated and passing, asset integrity tests green.
