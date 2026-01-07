# Super Fantasy Kingdom Research Summary

Super Fantasy Kingdom is a fantasy kingdom roguelite referenced for high-level design
inspiration (day/night cadence, resource planning, and readable UI). This summary is
for reference only; the Keyboard Defense project does not reuse names, text, or assets.

## Key mechanics from research
- Day/night cadence with build by day and defense at night.
- Resource chains and workforce allocation (food, wood, stone; multi-step outputs).
- Auto-battle defense where placement and towers matter.
- Exploration via roads that reveal biomes and events.
- Roguelite meta progression with unlocks over multiple runs.
- Pixel-art strategy presentation with minimalist UI and clear silhouettes.

## Mapping to Keyboard Defense (Godot)
- Day/night cadence
  - Have: deterministic day and night phases with typing defense.
  - Missing: onboarding that teaches the full cadence.
  - Next: add a short first-run tutorial sequence.
- Resource chains and workforce
  - Have: baseline production and building bonuses.
  - Missing: staffed buildings and multi-step production.
  - Next: add a lightweight worker assignment and a two-step chain.
- Auto-battle defense
  - Have: typing-driven targeting, enemies on grid, towers, walls.
  - Missing: hero or unit synergy layer.
  - Next: add optional hero/guardian modifiers tied to typing performance.
- Exploration and roads
  - Have: explore command that reveals tiles and rewards resources.
  - Missing: roads and biome-specific events.
  - Next: add a road build type and a small event table per terrain.
- Roguelite meta progression
  - Have: per-run progression and a profile for typing stats.
  - Missing: run-to-run unlocks and faction selection.
  - Next: define a small unlock track tied to lesson mastery.
- Art style and UI principles
  - Have: grid renderers, HUD panels, and text-first layout.
  - Missing: consistent pixel-art palette and isometric presentation.
  - Next: create a style guide for HUD spacing, icons, and tile silhouettes.

## Non-goals
- No direct copying of names, assets, or story beats from the research.
- No real-time combat; night remains turn-based and typing-driven.

Reference files live in `docs/research/super_fantasy_kingdom/`.
