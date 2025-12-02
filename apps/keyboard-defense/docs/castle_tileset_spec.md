# Castle Tileset Specification

Pixel-art tileset guidelines for castle walls, gates, towers, and damaged states used in HUD and gameplay views. Audience: ages 8–16; platform: Edge/Chrome laptops; style: cartoonish pixel art.

## Grid & Sizing
- Base tile: 16x16 px; large masonry blocks: 32x32 px for hero elements (gate, banners, towers).
- Safe inset: 1px bleed inside each tile; avoid overhangs that clip when packed into atlases.
- Outline: 1px stroke; interior brick lines 1px; avoid subpixel AA.

## Palette
- Base stone: fill `#475569`, stroke `#1f2937`, highlight `#94a3b8`, shadow `#0f172a`.
- Accent trims: `#22d3ee` (healthy), `#fb923c` (damaged ember), `#f87171` (critical).
- Wood/gate: fill `#92400e`, stroke `#713f12`, metal studs `#e2e8f0`.
- Damage cracks: `#0b1729` with occasional ember dots `#fb923c`.

## States
- Intact: clean masonry, subtle highlight top-left, crisp merlons.
- Damaged: add 2–3 cracks per 32x32 block, 10–15% missing pixels on edges, embers optional.
- Critical: deepen cracks, add gaps, darken fill by ~12%, tint accents with `#f87171`.
- Gate: closed, half-open, open frames; add separate damage variants.
- Banner slots: optional overlay tiles (8x16) with color swaps for upgrades.

## Components
- Wall segments: straight (16x16, 32x16), corner (inner/outer), cap tiles.
- Merlons/crests: 16x8 overlays; ensure alignment with wall top.
- Towers: 32x48 base with 16x16 roof cap; 3 damage states; window glows (healthy `#a5f3fc`, critical `#fb7185`).
- Gate: 32x48 door, hinges, and 2-frame opening animation; add matching shadow floor tile.
- Rubble: 16x16 debris tiles for post-destruction overlays.

## Animation & Effects
- Idle shimmer (optional): 2-frame highlight shift for intact state; disabled in reduced-motion.
- Damage blink: 2-frame flicker on hit, using accent tints; keep under 150ms, skip when reduced-motion is active.

## Export & Naming
- Individual PNGs: `castle/wall-16.png`, `castle/wall-32.png`, `castle/corner-inner.png`, `castle/corner-outer.png`, `castle/gate-closed.png`, `castle/gate-open.png`, `castle/tower-healthy.png`, `castle/tower-damaged.png`, `castle/tower-critical.png`, `castle/rubble.png`, `castle/merlon.png`, `castle/banner-blue.png`, etc.
- Sprite sheet: `castle/tileset-1x.png`, `castle/tileset-2x.png` with JSON map `{ name, x, y, w, h }` snapped to 16px grid slots.
- Keep palette locked; avoid embedded color profiles; image-rendering pixelated.

## Integration Notes
- Place castle tiles in a dedicated atlas section separate from UI icons and enemies.
- Align with the asset manifest/atlas generator paths; add integrity hashes during build.
- Respect reduced-motion: disable shimmer/flicker when the game is in reduced-motion mode.
