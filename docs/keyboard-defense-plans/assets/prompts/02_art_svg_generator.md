TASK: Implement a procedural SVG generator for MVP icons and a few core sprites.

GOAL:
Generate text-based SVG sources that will later be converted to PNG and packed.

DELIVERABLES:
1) Create folder `apps/keyboard-defense-godot/assets/art/src-svg/` with:
   - `icons/` (UI icons)
   - `tiles/` (basic tiles)
   - `sprites/` (castle + wall + tower + 1 unit + 1 enemy)
2) Implement `apps/keyboard-defense-godot/scripts/tools/gen_svg.gd` that:
   - takes `--seed` and `--outDir`
   - reads `apps/keyboard-defense-godot/assets/art/style/palette.json` and `style.json`
   - deterministically emits SVG files for at least:
     Icons: gold, accuracy, typing_power, wave, threat, keyboard
     Tiles: grass, dirt, road_straight
     Sprites: bld_castle, bld_wall, bld_tower_arrow, unit_scribe, enemy_runner
3) Add a small README in `apps/keyboard-defense-godot/assets/art/src-svg/README.md` explaining how they are generated and how to preview them.

RULES:
- Each SVG must include a consistent outline rule and use only palette colors.
- Use primitive shapes only (rect, circle, polygon, path) with simple shading.

TESTS:
- Add a test that runs `gen_svg` into a temp dir and asserts required SVG files exist.

LANDMARKS in final response (mandatory).
