TASK: Convert SVG -> PNG and pack an atlas plus manifest.

DELIVERABLES:
1) Implement a build script at `apps/keyboard-defense-godot/scripts/tools/build_art.ps1` or `build_art.gd` that:
   - runs `gen_svg` first (or expects SVGs already generated)
   - converts each SVG to PNG at the scale from `style.json`
   - writes outputs to `apps/keyboard-defense-godot/assets/art/generated/`
   - optionally packs into `atlas.png` + `atlas.json`
   - emits `preview.png` as a contact sheet
2) Update `apps/keyboard-defense-godot/data/assets_manifest.json` with generated PNGs, sizes, and constraints.
3) Add tests:
   - deterministic hash test: manifest hash for seed 123 matches a stored golden hash
   - required frame ids exist in manifest (subset for MVP)

NOTES:
- Use open-source tools (Inkscape CLI or rsvg-convert) if you need SVG conversion.
- Do not generate assets during gameplay; do this in the build step.

LANDMARKS in final response (mandatory).
