You are working in an existing repo for the game "Keyboard Defense" (Godot 4).

TASK: Define the art direction, palette, and asset requirements for MVP, then implement the initial text-based asset config.

CONSTRAINTS:
- Original visuals only.
- Typing-first game: readability over detail.
- Deterministic: configs will later be used by generators with a seed.

DELIVERABLES:
1) Create `apps/keyboard-defense-godot/assets/art/style/palette.json` with about 16-20 colors (name + hex).
2) Create `apps/keyboard-defense-godot/assets/art/style/style.json` with:
   - tile_size (16)
   - scale (e.g. 4)
   - outline_width (1)
   - shading params (highlight and shadow offsets)
3) Create or update docs:
   - `docs/keyboard-defense-plans/assets/ASSET_CREATION_OVERVIEW.md`
   - `docs/keyboard-defense-plans/assets/ART_STYLE_GUIDE.md`
   - `docs/keyboard-defense-plans/assets/ART_ASSET_LIST.md`
4) Add a small Godot tool script `apps/keyboard-defense-godot/scripts/tools/print_palette.gd` that prints the palette table and validates required keys.
5) Add a test in `apps/keyboard-defense-godot/scripts/tests/` that validates palette and style JSON (no duplicate names, valid hex strings).

TESTS:
- Run `apps/keyboard-defense-godot/scripts/run_tests.ps1`.

LANDMARKS (required in your final response):
- List all created or changed files.
- Provide exact commands to run.
- Provide acceptance checks (what should I see).

Proceed file-by-file with minimal diff risk.
