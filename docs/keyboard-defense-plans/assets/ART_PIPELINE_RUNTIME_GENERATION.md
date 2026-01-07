# Art pipeline - Runtime generation (Godot Image)

This is an optional approach for early prototypes:
- ship almost no binary art files
- generate textures at runtime

## When to use
- you want to iterate fast without build-time conversion or packing
- you accept slightly higher CPU cost on first load
- you want guaranteed originality (pure code)

## Approach
1. Create `scripts/art/ArtFactory.gd`.
2. At boot, generate textures:
   - use `Image` to draw primitives
   - create `ImageTexture` via `ImageTexture.create_from_image`
   - store textures by id (same ids as `ART_ASSET_LIST.md`)

Example primitive language:
- buildings: rounded rect, roof triangle, outline
- enemies: circle + spikes
- tiles: flat colored squares + small noise dots

## Determinism
All textures must be generated from:
- palette
- style parameters
- seed

## Acceptance criteria
- game boots with no external art assets
- visual categories are distinct at a glance
- no texture generation happens mid-wave (avoid hitching)

## Recommendation
Use runtime generation only for:
- placeholders
- debug overlays
- prototyping

For shipping, prefer SVG -> PNG (or hand-authored PNG) for performance and predictable visuals.
