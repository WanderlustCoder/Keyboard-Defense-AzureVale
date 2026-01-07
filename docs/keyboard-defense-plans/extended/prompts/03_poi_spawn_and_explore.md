# Codex Milestone EXT-03 - POI Spawn and Explore Flow (Sim Layer)

## LANDMARK: Goal
Add POI spawning and exploration resolution to the sim loop.

## Tasks
1) Add POI spawn rule:
   - per map ring or per day
   - weighted by biome and rarity
2) Add sim action:
   - `explore_poi(poi_id)`
3) Exploration triggers:
   - lookup POI -> select event table -> present event payload to UI layer
4) Store exploration state in run save:
   - visited POIs
   - active event
   - event history

## Tests
- Deterministic POI placement with seed.
- Visiting the same POI twice respects visited rules (configurable).
