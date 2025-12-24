# POI Templates

POIs are exploration nodes on the world map. Each points to an event table.

## Template
```json
{
  "id": "poi_evergrove_abandoned_wagon",
  "biome": "Evergrove",
  "name": "Abandoned Wagon",
  "icon": "poi_wagon",
  "event_table_id": "table_salvage_small",
  "rarity": 30,
  "tags": ["salvage", "early"],
  "min_day": 1,
  "max_day": 8
}
```

## Example POIs (seed set)
- Abandoned Wagon (salvage)
- Cracked Milestone (road lore)
- Fallen Watchtower (scouting)
- Herb Patch (food)
- Shallow Vein (ore)
- Quiet Shrine (morale)
- Broken Cart (repair)
- Fox Den (risk/reward)
- Weathered Signpost (navigation)
- Small Streamford (route choice)
- Mistfen Cache (timber)
- Sunfield Ridge (visibility)
- Old Survey Marker (map reveal)
- Lost Toolkit (build speed buff)
- Traders Marker (shop)
- Burned Camp (warning)
- Bee Hollow (food + sting risk)
- Shattered Gatepost (defense hint)

## Tagging guidance
- Use tags for filtering and pacing:
  - `early`, `mid`, `late`
  - `risk_low`, `risk_med`, `risk_high`
  - `combat`, `trade`, `lore`, `salvage`, `weather`, `ally`
