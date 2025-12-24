# Art style guide (original, typing-first)

## Visual goals
- calm by day, tense by night
- minimal distractions while typing; animation is subtle
- map readability: lanes, gates, towers, and threats are obvious
- edutainment feel: welcoming and friendly, not grimdark

## Grid and sizing (recommended)
- world tiles: 16x16 base grid (scaled 3x or 4x)
- structures: 16x16 to 48x48 footprints, consistent anchors
- units/enemies: 16x16 to 24x24 silhouettes
- UI icons: 16x16 or 24x24 (scaled by UI)
- stroke: 1px outline at native size

## Palette rules
Use a small palette (12-20 colors):
- strong contrast for text and key interactables
- avoid relying on red/green differences alone
- use shape or pattern differences for categories

Recommended palette structure:
- 2 neutrals for UI backgrounds and frames
- 2 neutrals for text (light and dark)
- 3 nature colors (ground, grass, water)
- 3 materials colors (wood, stone, metal)
- 2 danger colors (enemy highlight, damage)
- 1 accent (selection/focus)

## Primitive language (draw everything from these)
- buildings: rounded rectangles, small roof shapes, simple slats
- walls: repeated blocks with crenellations
- towers: tall rectangle + cap + slit window
- learning props: scroll, book, quill, keyboard badge
- units: circle head + rectangle body + one clear tool
- enemies: exaggerated silhouette; spikes for brute, wings for flyer

## Shading rule (simple and consistent)
- base fill color
- 1 highlight on top-left
- 1 shadow on bottom-right
- optional 1-2 pixel noise for wood/stone

## Animation guidelines
- avoid constant motion in day mode
- triggered micro-animations only:
  - build pop-in scale 0.95 to 1.0
  - resource pickup sparkle 100-150ms
  - damage flash 80ms

## UI iconography
Icons must map to command vocabulary and always pair with text:
- gold, accuracy, typing power, wave, threat, pause
Icons must be legible at base size.

## Accessibility notes
- provide a high-contrast mode option
- option to disable screen shake and flashing
