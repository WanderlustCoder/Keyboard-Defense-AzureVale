# P1 Visual Style Guide Plan
Roadmap IDs: P1-CNT-001

## Purpose and constraints
Define a readable, original visual style for a typing-first strategy game. The style must support fast word reading, low clutter, and original art. Do not copy any SFK layouts or assets; use SFK only as inspiration for clarity and tone.

## Palette guidance
- Use a small, high-contrast palette (16-20 colors) with clear value separation.
- Keep terrain colors muted and reserve high-saturation for interactive cues.
- Provide light and dark surface variants for panels and overlays.
- Ensure text contrast at 1280x720 and 1920x1080.

## Typography and spacing
- Prioritize legibility at small sizes; avoid ornate display faces.
- Keep line height generous in panels and logs (1.3-1.5x).
- Use consistent margins and padding across HUD, panels, and labels.
- Keep the command bar visually dominant without overwhelming the HUD.

## Icon and glyph rules
- Use consistent glyph shapes for terrain/buildings/enemies.
- Align glyph sizes to the grid cell to avoid overlap with text labels.
- Towers should be visually distinct from walls to communicate range threat.
- Enemy glyphs must remain readable when overlaid with path markers.

## Accessibility considerations
- Maintain contrast ratios suitable for fast reading.
- Provide color-blind safe distinctions (shape, icon, text labels) in addition to color.
- Avoid animated clutter; keep motion optional and minimal.

## Deliverables
- Style guide document with palette, spacing, and glyph rules.
- Example HUD and panel mocks for readability review.
- Asset naming conventions aligned to `assets_manifest.json`.

## Acceptance criteria
- UI remains legible at 1280x720 with no overlapping labels.
- Terrain, buildings, enemies, and cursor are distinguishable at a glance.
- Style guide is referenced by content and asset plans.

## Test plan
- Manual visual review at 720p and 1080p.
- Checklist review for contrast and icon consistency.

## Sources
- `docs/research/super_fantasy_kingdom/art_style.md`
- `docs/plans/planpack_2025-12-27_tempPlans/keyboard-defense-plans/assets/ART_STYLE_GUIDE.md`
- `docs/plans/planpack_2025-12-27_tempPlans/keyboard-defense-plans/assets/ART_UI_ASSET_SPEC.md`
- `docs/plans/planpack_2025-12-27_tempPlans/keyboard-defense-plans/assets/ART_ASSET_LIST.md`
- `docs/plans/planpack_2025-12-27_tempPlans/keyboard-defense-plans/assets/ASSET_CREATION_OVERVIEW.md`
