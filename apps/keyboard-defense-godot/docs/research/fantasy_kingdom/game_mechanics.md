# Reference Game Mechanics Notes (Fantasy Kingdom Roguelite)

Context: These notes summarize a reference fantasy kingdom roguelite to inform the
Keyboard Defense (Godot 4) design. This is not the project name.

## Run start
- Begin with a ruined castle, a handful of villagers, and a hero.
- Goal: rebuild through food, wood, and stone.
- Core buildings: farms, sawmills, quarries, walls, towers.

## Day-night cycle
- Day: build, gather, plan defenses.
- Night: waves attack; difficulty ramps with days.

## Production chains
- Workers assigned to buildings; multi-step chains (grain -> flour -> bread).
- Food availability affects hero growth; resource planning is central.

## Automatic battles and heroes
- Combat is automatic; placement and tower positions matter.
- Heroes have abilities; recruitment via events or exploration.

## Exploration
- Roads expand the map; discover biomes, quests, relics, and resources.
- Exploration increases options and risk.

## Meta-progression
- Runs feed permanent upgrades and unlocks.
- Failure yields new opportunities; repeated runs deepen strategy.

## Takeaways for Keyboard Defense (Godot)
- Emphasize day/night rhythm and readable resource flow.
- Tie upgrades and defenses to typing mastery and performance rewards.
