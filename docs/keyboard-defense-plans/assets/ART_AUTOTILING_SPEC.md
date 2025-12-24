# Auto-tiling spec (roads, walls, water edges)

This spec tells generators how to build tiles so maps read cleanly without hand-authored art.

## Goals
- roads and walls connect automatically and look continuous
- water edges show a clear shoreline against land

## Tile categories
### Roads (minimal set)
For MVP you can implement a classic 4-direction bitmask and generate these canonical frames:
- `tile_road_end` (cap)
- `tile_road_straight`
- `tile_road_corner`
- `tile_road_t`
- `tile_road_cross`

Optional:
- `tile_road_diag` variants if you support diagonals

### Walls
Same approach as roads:
- `tile_wall_end`
- `tile_wall_straight`
- `tile_wall_corner`
- `tile_wall_t`
- `tile_wall_cross`

### Water edges (shoreline)
If you represent water as full tiles:
- `tile_water` (full)
- `tile_shore_n`, `tile_shore_s`, `tile_shore_e`, `tile_shore_w`
- `tile_shore_ne`, `tile_shore_nw`, `tile_shore_se`, `tile_shore_sw`

## Bitmask rules (4-direction)
A simple 4-direction mask is usually enough for readability.

Let N,E,S,W be 1,2,4,8 bits. Mask is based on same-type neighbors.

Example: road tile mask 0..15.
- 0: isolated -> `tile_road_end` (or isolated variant)
- 1/4/2/8: single neighbor -> `tile_road_end` (rotated)
- 5 (N+S): `tile_road_straight` (vertical)
- 10 (E+W): `tile_road_straight` (horizontal)
- 3 (N+E): `tile_road_corner` (NE)
- 6 (E+S): `tile_road_corner` (SE)
- 12 (S+W): `tile_road_corner` (SW)
- 9 (W+N): `tile_road_corner` (NW)
- 7/11/13/14: `tile_road_t` (missing one direction)
- 15: `tile_road_cross`

Godot 4 TileSet guidance:
- use a TerrainSet with 4-direction bitmask
- map each mask to the correct tile id and rotation

## Visual construction rules
- roads: base ground + darker path band + 1px border
- walls: block segments with crenellations and outline

## Acceptance checks
- draw a 10x10 map containing every mask case
- visually verify each connection type
