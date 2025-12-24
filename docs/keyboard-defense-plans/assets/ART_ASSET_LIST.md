# Art asset list (MVP to full)

This is a requirements list so generators know what to output.

## MVP (first playable)
### Tiles (16x16)
- `tile_grass`
- `tile_dirt`
- `tile_road_end`
- `tile_road_straight`
- `tile_road_corner`
- `tile_road_t`
- `tile_road_cross`
- `tile_water`
- `tile_bridge` (optional)
- `tile_wall_end`
- `tile_wall_straight`
- `tile_wall_corner`
- `tile_wall_t`
- `tile_wall_cross`

### Structures (sprites)
- `bld_castle`
- `bld_gate`
- `bld_wall`
- `bld_tower_arrow`
- `bld_tower_slow` (optional)
- `bld_library`
- `bld_barracks`

### Units and enemies
- `unit_scribe`
- `unit_archer`
- `unit_scout`
- `enemy_runner`
- `enemy_brute`
- `enemy_flyer` (optional for MVP)

### UI icons
- `ico_gold`
- `ico_accuracy`
- `ico_wpm`
- `ico_typing_power`
- `ico_castle_hp`
- `ico_target`
- `ico_wave`
- `ico_threat`
- `ico_pause`
- `ico_resume`
- `ico_keyboard`
- `ico_buff`

### UI panels (9-slice)
- `ui_panel_bg`
- `ui_panel_header`
- `ui_button`
- `ui_prompt_bg`
- `ui_threat_card_bg`

### FX (small overlays)
- `fx_build_dust_1..3`
- `fx_hit_flash`
- `fx_typing_streak`
- `fx_reward_sparkle`

## Post-MVP (polish)
- biome variants (snow, desert)
- more enemy silhouettes (shielded, sapper, swarm)
- portraits for instructors or advisors
- tutorial illustrations for hand placement

## Naming convention
- lowercase
- prefix by category (`tile_`, `bld_`, `unit_`, `enemy_`, `ico_`, `ui_`, `fx_`)
- do not reuse ids for different visuals; version with suffix if needed

## Recommended delivery
- keep all frames in a single atlas for performance, or group by category
- keep UI icons in the same atlas or a separate `ui_atlas` if preferred
